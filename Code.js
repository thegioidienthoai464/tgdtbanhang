function doGet(e) {
  if (e && e.parameter && e.parameter.action === 'debugNhapHang') {
    const ss = SpreadsheetApp.getActiveSpreadsheet() || SpreadsheetApp.openById("1MZyIP9j7AQbUOgeGPmbA9EsWyhc0C1vXG9t1FWw_uFU");
    const sheet = getSheetNhapHang(ss);
    const rows = sheet ? sheet.getDataRange().getValues() : [];
    return ContentService.createTextOutput(JSON.stringify({
      sheetName: sheet ? sheet.getName() : null,
      rows: rows
    }, null, 2)).setMimeType(ContentService.MimeType.JSON);
  }
  if (e && e.parameter && e.parameter.action === 'resetDuLieuGiaoDichVaTonKho') {
    const ss = SpreadsheetApp.getActiveSpreadsheet() || SpreadsheetApp.openById("1MZyIP9j7AQbUOgeGPmbA9EsWyhc0C1vXG9t1FWw_uFU");
    const result = thucHienResetGiaoDichVaTonKhoSheets(ss);
    return ContentService.createTextOutput(JSON.stringify(result, null, 2)).setMimeType(ContentService.MimeType.JSON);
  }
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    if (ss) {
      try {
        ss.addEditor("thegioidienthoai464@gmail.com");
      } catch(errEd) {
        Logger.log("addEditor warning: " + errEd.message);
      }
    }
    if (typeof initAllSheets === 'function') initAllSheets();
  } catch(e) {
    Logger.log("initAllSheets error: " + e.message);
  }
  return HtmlService.createTemplateFromFile('Index')
    .evaluate()
    .setTitle('Hệ Thống Quản Lý Bán Hàng & Kho')
    .addMetaTag('viewport', 'width=device-width, initial-scale=1')
    .setXFrameOptionsMode(HtmlService.XFrameOptionsMode.ALLOWALL);
}

function include(filename) {
  return HtmlService.createHtmlOutputFromFile(filename).getContent();
}

// Xóa trắng toàn bộ giao dịch và đưa tồn kho về 0 trên Google Sheets (Bảo tồn 100% Khách hàng, NCC, Nhóm hàng, Chi nhánh)
function thucHienResetGiaoDichVaTonKhoSheets(ss) {
  if (!ss) {
    try {
      ss = SpreadsheetApp.getActiveSpreadsheet();
    } catch(e) {}
  }
  if (!ss) {
    try {
      ss = SpreadsheetApp.openById("1MZyIP9j7AQbUOgeGPmbA9EsWyhc0C1vXG9t1FWw_uFU");
    } catch(e) {}
  }
  const log = [];
  
  // 1. Các sheet giao dịch cần xóa trắng dữ liệu (giữ nguyên dòng tiêu đề header số 1)
  const transactionSheets = [
    "DonHang", "Don_Hang", "GiaoDich_DonHang", "ChiTiet_DonHang",
    "SoQuy", "Kho_IMEI", "KiemKho", "XuatHuy",
    "NhapHang", "GiaoDich_NhapHang", "DonNhapHang", "TraHangNCC", "GiaoDich_TraNCC", "DonDatHang"
  ];
  
  transactionSheets.forEach(sName => {
    try {
      const sh = ss.getSheetByName(sName);
      if (sh) {
        const lastRow = sh.getLastRow();
        const lastCol = sh.getLastColumn();
        if (lastRow > 1 && lastCol > 0) {
          sh.getRange(2, 1, lastRow - 1, lastCol).clearContent();
          log.push(`Đã xóa ${lastRow - 1} dòng trong sheet ${sName}`);
        } else {
          log.push(`Sheet ${sName} đã trống`);
        }
      }
    } catch(err) {
      log.push(`Lỗi xử lý sheet ${sName}: ${err.message}`);
    }
  });

  // 2. Đưa cột Tồn kho về 0 trong DM_HangHoa và HangHoa
  ["DM_HangHoa", "HangHoa"].forEach(sName => {
    try {
      const sh = ss.getSheetByName(sName);
      if (sh) {
        const lastRow = sh.getLastRow();
        const lastCol = sh.getLastColumn();
        if (lastRow > 1 && lastCol > 0) {
          const headers = sh.getRange(1, 1, 1, lastCol).getValues()[0].map(h => String(h || "").trim().toLowerCase());
          headers.forEach((h, colIdx) => {
            if (h === "tonkho" || h === "tồn kho" || h === "ton_kho") {
              const zeros = new Array(lastRow - 1).fill([0]);
              sh.getRange(2, colIdx + 1, lastRow - 1, 1).setValues(zeros);
              log.push(`Đã đưa tồn kho ${lastRow - 1} sản phẩm về 0 trong sheet ${sName}`);
            }
          });
        }
      }
    } catch(err) {
      log.push(`Lỗi reset tồn kho sheet ${sName}: ${err.message}`);
    }
  });

  // BẢO VỆ NGUYÊN VẸN DM_DoiTac, DM_NhomHang, DM_ChiNhanh (TUYỆT ĐỐI KHÔNG CHẠM)
  log.push("Bảo lưu 100% dữ liệu Khách hàng & Nhà cung cấp (DM_DoiTac), Nhóm hàng (DM_NhomHang), Chi nhánh (DM_ChiNhanh)");

  return { success: true, timestamp: new Date().toISOString(), log: log };
}
// Đọc danh sách đối tác (Khách hàng hoặc Nhà cung cấp) từ Google Sheets
function apiGetDanhSachDoiTac(loai) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  if (typeof dongBoTienCocDonDatHang === 'function') {
    dongBoTienCocDonDatHang(ss);
  }
  const sheet = ss.getSheetByName("DM_DoiTac");
  if (!sheet) return [];
  const rows = sheet.getDataRange().getValues();
  if (rows.length < 2) return [];

  // Đọc tiêu đề ở hàng 1 để map đúng tên cột tự động
  const headers = rows[0].map(h => String(h).trim().toLowerCase());
  const idxMa = headers.indexOf("madoitac");
  const idxLoai = headers.indexOf("loaidoitac");
  const idxTen = headers.indexOf("tendoitac");
  const idxSdt = headers.indexOf("sodienthoai");
  const idxDiaChi = headers.indexOf("diachi");
  const idxGioiTinh = headers.indexOf("gioitinh");
  const idxNgaySinh = headers.indexOf("ngaysinh");
  const idxCongNo = headers.indexOf("congno");
  const idxTrangThai = headers.indexOf("trangthai");

  let result = [];
  for (let i = 1; i < rows.length; i++) {
    let r = rows[i];
    if (idxMa > -1 && !r[idxMa]) continue;

    let loaiVal = idxLoai > -1 ? String(r[idxLoai]).toUpperCase() : "KH";
    if (!loai || loaiVal === String(loai).toUpperCase()) {
      result.push({
        maDoiTac: idxMa > -1 ? r[idxMa] : r[0],
        loaiDoiTac: loaiVal,
        tenDoiTac: idxTen > -1 ? r[idxTen] : r[2],
        soDienThoai: idxSdt > -1 ? r[idxSdt] : r[3],
        diaChi: idxDiaChi > -1 ? r[idxDiaChi] : r[4],
        gioiTinh: idxGioiTinh > -1 ? (r[idxGioiTinh] || "") : "",
        ngaySinh: idxNgaySinh > -1 && r[idxNgaySinh] ? String(r[idxNgaySinh]).slice(0, 10) : "",
        congNo: idxCongNo > -1 ? (Number(r[idxCongNo]) || 0) : 0,
        trangThai: idxTrangThai > -1 ? (r[idxTrangThai] || "HoatDong") : "HoatDong"
      });
    }
  }
  return result;
}

// Ghi danh sách hàng hóa nhập từ Excel lên Google Sheets
function apiLuuDanhSachHangHoa(list) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheetDM = ss.getSheetByName("DM_HangHoa");
  const sheetIMEI = ss.getSheetByName("Kho_IMEI");
  
  if (!sheetDM) return { success: false, error: "Không tìm thấy sheet DM_HangHoa" };

  // --- 1. XỬ LÝ GHI VÀO SHEET DM_HangHoa ---
  const rowsDM = sheetDM.getDataRange().getValues();
  const headersDM = rowsDM.length > 0 ? rowsDM[0].map(h => String(h || "").trim().toLowerCase()) : [];
  
  function getColIndexDM(names) {
    for (let name of names) {
      let idx = headersDM.indexOf(name.toLowerCase());
      if (idx > -1) return idx + 1; // Vị trí cột (tính từ 1)
    }
    return -1;
  }

  const colChiNhanhDM = getColIndexDM(["chinhanh", "chi nhánh"]);
  const colMaHangDM = getColIndexDM(["mahang", "mã hàng", "mã sản phẩm"]);
  const colTenHangDM = getColIndexDM(["tenhang", "tên hàng", "tên sản phẩm"]);
  const colMaNhomDM = getColIndexDM(["manhom", "mã nhóm"]);
  const colDVTDm = getColIndexDM(["donvitinh", "đơn vị tính", "dvt"]);
  const colGiaVonDM = getColIndexDM(["giavon", "giá vốn"]);
  const colGiaBanDM = getColIndexDM(["giaban", "giá bán"]);
  const colIMEIDm = getColIndexDM(["coquanlyimei", "quản lý imei", "co_quan_ly_imei"]);
  const colTonKhoDM = getColIndexDM(["tonkho", "tồn kho"]);
  const colTrangThaiDM = getColIndexDM(["trangthai", "trạng thái"]);

  if (colMaHangDM === -1 || colTenHangDM === -1) {
    return { success: false, error: "Sheet DM_HangHoa thiếu cột Mã hàng hoặc Tên hàng!" };
  }

  let mapRowDM = {};
  for (let i = 1; i < rowsDM.length; i++) {
    let ma = String(rowsDM[i][colMaHangDM - 1] || "").trim().toUpperCase();
    if (ma) mapRowDM[ma] = i + 1;
  }

  // --- 2. XỬ LÝ GHI VÀO SHEET Kho_IMEI (Nếu có) ---
  let headersIMEI = [];
  let colChiNhanhIMEI = -1, colIMEICol = -1, colMaHangIMEI = -1, colTrangThaiIMEI = -1, colNgayCapNhatIMEI = -1;
  let existingIMEIs = new Set();

  if (sheetIMEI) {
    const rowsIMEI = sheetIMEI.getDataRange().getValues();
    headersIMEI = rowsIMEI.length > 0 ? rowsIMEI[0].map(h => String(h || "").trim().toLowerCase()) : [];
    
    function getColIndexIMEI(names) {
      for (let name of names) {
        let idx = headersIMEI.indexOf(name.toLowerCase());
        if (idx > -1) return idx + 1;
      }
      return -1;
    }

    colChiNhanhIMEI = getColIndexIMEI(["chinhanh", "chi nhánh"]);
    colIMEICol = getColIndexIMEI(["imei", "serial", "mã imei"]);
    colMaHangIMEI = getColIndexIMEI(["mahang", "mã hàng"]);
    colTrangThaiIMEI = getColIndexIMEI(["trangthai", "trạng thái"]);
    colNgayCapNhatIMEI = getColIndexIMEI(["ngaycapnhat", "ngày cập nhật", "ngaynhap"]);

    // Lưu lại các IMEI đã tồn tại để tránh ghi trùng lặp
    if (colIMEICol > -1) {
      for (let j = 1; j < rowsIMEI.length; j++) {
        let im = String(rowsIMEI[j][colIMEICol - 1] || "").trim();
        if (im) existingIMEIs.add(im.toUpperCase());
      }
    }
  }

  // --- 3. TIẾN HÀNH DUYỆT VÀ GHI DỮ LIỆU ---
  list.forEach(h => {
    const ma = String(h.maHang || "").trim().toUpperCase();
    const ten = String(h.tenHang || "").trim();
    if (!ma || !ten) return;

    const rowIdx = mapRowDM[ma];
    const currentCN = h.chiNhanh || "CN01";

    // Ghi vào DM_HangHoa
    if (rowIdx) {
      if (colChiNhanhDM > -1) sheetDM.getRange(rowIdx, colChiNhanhDM).setValue(currentCN);
      if (colTenHangDM > -1) sheetDM.getRange(rowIdx, colTenHangDM).setValue(ten);
      if (colMaNhomDM > -1) sheetDM.getRange(rowIdx, colMaNhomDM).setValue(h.maNhom || "");
      if (colDVTDm > -1) sheetDM.getRange(rowIdx, colDVTDm).setValue(h.donViTinh || "Cái");
      if (colGiaVonDM > -1) sheetDM.getRange(rowIdx, colGiaVonDM).setValue(Number(h.giaVon) || 0);
      if (colGiaBanDM > -1) sheetDM.getRange(rowIdx, colGiaBanDM).setValue(Number(h.giaBan) || 0);
      if (colIMEIDm > -1) sheetDM.getRange(rowIdx, colIMEIDm).setValue(h.coQuanLyIMEI ? "Có" : "Không");
      if (colTonKhoDM > -1) sheetDM.getRange(rowIdx, colTonKhoDM).setValue(Number(h.tonKho) || 0);
      if (colTrangThaiDM > -1) sheetDM.getRange(rowIdx, colTrangThaiDM).setValue(h.trangThai || "Kinh doanh");
    } else {
      let newRowDM = new Array(headersDM.length).fill("");
      if (colChiNhanhDM > -1) newRowDM[colChiNhanhDM - 1] = currentCN;
      newRowDM[colMaHangDM - 1] = ma;
      if (colTenHangDM > -1) newRowDM[colTenHangDM - 1] = ten;
      if (colMaNhomDM > -1) newRowDM[colMaNhomDM - 1] = h.maNhom || "";
      if (colDVTDm > -1) newRowDM[colDVTDm - 1] = h.donViTinh || "Cái";
      if (colGiaVonDM > -1) newRowDM[colGiaVonDM - 1] = Number(h.giaVon) || 0;
      if (colGiaBanDM > -1) newRowDM[colGiaBanDM - 1] = Number(h.giaBan) || 0;
      if (colIMEIDm > -1) newRowDM[colIMEIDm - 1] = h.coQuanLyIMEI ? "Có" : "Không";
      if (colTonKhoDM > -1) newRowDM[colTonKhoDM - 1] = Number(h.tonKho) || 0;
      if (colTrangThaiDM > -1) newRowDM[colTrangThaiDM - 1] = h.trangThai || "Kinh doanh";
      sheetDM.appendRow(newRowDM);
    }

    // Ghi chi tiết vào Kho_IMEI nếu sản phẩm quản lý IMEI và có danh sách IMEI
    if (sheetIMEI && h.coQuanLyIMEI && Array.isArray(h.danhSachIMEI) && h.danhSachIMEI.length > 0 && colIMEICol > -1) {
      h.danhSachIMEI.forEach(imeiCode => {
        const cleanIMEI = String(imeiCode || "").trim();
        if (!cleanIMEI || existingIMEIs.has(cleanIMEI.toUpperCase())) return;

        let newRowIMEI = new Array(headersIMEI.length).fill("");
        if (colChiNhanhIMEI > -1) newRowIMEI[colChiNhanhIMEI - 1] = currentCN;
        if (colIMEICol > -1) newRowIMEI[colIMEICol - 1] = cleanIMEI;
        if (colMaHangIMEI > -1) newRowIMEI[colMaHangIMEI - 1] = ma;
        if (colTrangThaiIMEI > -1) newRowIMEI[colTrangThaiIMEI - 1] = "TrongKho";
        if (colNgayCapNhatIMEI > -1) newRowIMEI[colNgayCapNhatIMEI - 1] = new Date();

        sheetIMEI.appendRow(newRowIMEI);
        existingIMEIs.add(cleanIMEI.toUpperCase()); // Đánh dấu đã thêm để không bị trùng trong cùng đợt nhập
      });
    }
  });

  return { success: true };
}

// Xóa hàng loạt hàng hóa trên Google Sheets
function apiXoaHangHoa(maHangList) {
  try {
    if (!maHangList || !Array.isArray(maHangList) || !maHangList.length) {
      return { success: false, error: "Danh sách mã hàng rỗng!" };
    }
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    const sheetDM = ss.getSheetByName("DM_HangHoa");
    if (!sheetDM) return { success: false, error: "Không tìm thấy sheet DM_HangHoa!" };

    const rowsDM = sheetDM.getDataRange().getValues();
    if (rowsDM.length <= 1) return { success: true, count: 0 };

    const headersDM = rowsDM[0].map(h => String(h || "").trim().toLowerCase());
    let colMa = -1;
    for (let name of ["mahang", "mã hàng", "mã sản phẩm"]) {
      let idx = headersDM.indexOf(name);
      if (idx > -1) { colMa = idx; break; }
    }
    if (colMa === -1) colMa = 0;

    const targetSet = new Set(maHangList.map(m => String(m).trim().toUpperCase()));
    let count = 0;

    // Duyệt từ dưới lên để xóa không bị lệch index
    for (let i = rowsDM.length - 1; i >= 1; i--) {
      let ma = String(rowsDM[i][colMa] || "").trim().toUpperCase();
      if (targetSet.has(ma)) {
        sheetDM.deleteRow(i + 1);
        count++;
      }
    }

    // Xóa trong sheet Kho_IMEI nếu có
    const sheetIMEI = ss.getSheetByName("Kho_IMEI");
    if (sheetIMEI) {
      const rowsIMEI = sheetIMEI.getDataRange().getValues();
      if (rowsIMEI.length > 1) {
        const headersIMEI = rowsIMEI[0].map(h => String(h || "").trim().toLowerCase());
        let colMaH = headersIMEI.indexOf("mahang");
        if (colMaH === -1) colMaH = headersIMEI.indexOf("mã hàng");
        if (colMaH === -1) colMaH = 2;

        for (let j = rowsIMEI.length - 1; j >= 1; j--) {
          let ma = String(rowsIMEI[j][colMaH] || "").trim().toUpperCase();
          if (targetSet.has(ma)) {
            sheetIMEI.deleteRow(j + 1);
          }
        }
      }
    }

    return { success: true, count: count };
  } catch(err) {
    Logger.log("Lỗi apiXoaHangHoa: " + err.message);
    return { success: false, error: err.toString() };
  }
}

// Chuyển nhóm hàng loạt cho hàng hóa trên Google Sheets
function apiChuyenNhomHangHoa(maHangList, maNhomMoi) {
  try {
    if (!maHangList || !Array.isArray(maHangList) || !maHangList.length) {
      return { success: false, error: "Danh sách mã hàng rỗng!" };
    }
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    const sheetDM = ss.getSheetByName("DM_HangHoa");
    if (!sheetDM) return { success: false, error: "Không tìm thấy sheet DM_HangHoa!" };

    const rowsDM = sheetDM.getDataRange().getValues();
    if (rowsDM.length <= 1) return { success: true, count: 0 };

    const headersDM = rowsDM[0].map(h => String(h || "").trim().toLowerCase());
    let colMa = -1, colNhom = -1;
    for (let name of ["mahang", "mã hàng", "mã sản phẩm"]) {
      let idx = headersDM.indexOf(name);
      if (idx > -1) { colMa = idx; break; }
    }
    for (let name of ["manhom", "mã nhóm"]) {
      let idx = headersDM.indexOf(name);
      if (idx > -1) { colNhom = idx; break; }
    }
    if (colMa === -1) colMa = 0;
    if (colNhom === -1) colNhom = 2;

    const targetSet = new Set(maHangList.map(m => String(m).trim().toUpperCase()));
    let count = 0;

    for (let i = 1; i < rowsDM.length; i++) {
      let ma = String(rowsDM[i][colMa] || "").trim().toUpperCase();
      if (targetSet.has(ma)) {
        sheetDM.getRange(i + 1, colNhom + 1).setValue(maNhomMoi || "");
        count++;
      }
    }

    return { success: true, count: count };
  } catch(err) {
    Logger.log("Lỗi apiChuyenNhomHangHoa: " + err.message);
    return { success: false, error: err.toString() };
  }
}

// Đọc danh sách phiếu kiểm kho từ Google Sheets
function apiGetDanhSachKiemKho() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = ss.getSheetByName("KiemKho");
  if (!sheet) return [];
  const rows = sheet.getDataRange().getValues();
  if (rows.length < 2) return [];

  const headers = rows[0].map(h => String(h || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
  const idxMa = headers.indexOf("maphieu");
  const idxNgay = headers.indexOf("ngaykiem");
  const idxCN = headers.indexOf("chinhanh");
  const idxNV = headers.indexOf("nhanvien");
  const idxSS = headers.indexOf("tongsosach");
  const idxTT = headers.indexOf("tongthucte");
  const idxCL = headers.indexOf("tongchenhlech");
  const idxTrangThai = headers.indexOf("trangthai");
  const idxGhiChu = headers.indexOf("ghichu");
  const idxChiTiet = headers.indexOf("chitietsanpham");

  let list = [];
  for (let i = 1; i < rows.length; i++) {
    const r = rows[i];
    if (idxMa > -1 && !r[idxMa]) continue;
    let chiTiet = [];
    if (idxChiTiet > -1 && r[idxChiTiet]) {
      try {
        chiTiet = typeof r[idxChiTiet] === 'string' ? JSON.parse(r[idxChiTiet]) : r[idxChiTiet];
      } catch(e) {
        chiTiet = [];
      }
    }
    list.push({
      maChungTu: idxMa > -1 ? String(r[idxMa]) : ("PKK" + i),
      ngayTao: idxNgay > -1 ? String(r[idxNgay]) : "",
      chiNhanh: idxCN > -1 ? String(r[idxCN]) : "",
      nhanVien: idxNV > -1 ? String(r[idxNV]) : "",
      slSoSach: idxSS > -1 ? Number(r[idxSS]) || 0 : 0,
      slThucTe: idxTT > -1 ? Number(r[idxTT]) || 0 : 0,
      chenhLech: idxCL > -1 ? Number(r[idxCL]) || 0 : 0,
      trangThai: idxTrangThai > -1 ? String(r[idxTrangThai]) : "HoanThanh",
      ghiChu: idxGhiChu > -1 ? String(r[idxGhiChu]) : "",
      chiTietSanPham: chiTiet
    });
  }
  return list.reverse();
}

// Lưu phiếu kiểm kho và cân bằng tồn kho hàng hóa
function apiLuuPhieuKiemKho(phieu) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = ss.getSheetByName("KiemKho");
  if (!sheet) {
    sheet = ss.insertSheet("KiemKho");
    sheet.appendRow(["MaPhieu", "NgayKiem", "ChiNhanh", "NhanVien", "TongSoSach", "TongThucTe", "TongChenhLech", "TrangThai", "GhiChu", "ChiTietSanPham"]);
  }

  const maPhieu = phieu.maChungTu || ("PKK" + Date.now().toString().slice(-6));
  const ngayKiem = phieu.ngayTao || new Date().toISOString().replace('T', ' ').slice(0, 16);
  const chiNhanh = phieu.chiNhanh || "CN01: Trụ sở chính Thanh Miện";
  const nhanVien = phieu.nhanVien || "Quản trị viên";
  const slSoSach = Number(phieu.slSoSach) || 0;
  const slThucTe = Number(phieu.slThucTe) || 0;
  const chenhLech = Number(phieu.chenhLech) || 0;
  const trangThai = phieu.trangThai || "Đã cân bằng";
  const ghiChu = phieu.ghiChu || "";
  const chiTiet = Array.isArray(phieu.chiTietSanPham) ? phieu.chiTietSanPham : [];

  sheet.appendRow([
    maPhieu,
    ngayKiem,
    chiNhanh,
    nhanVien,
    slSoSach,
    slThucTe,
    chenhLech,
    trangThai,
    ghiChu,
    JSON.stringify(chiTiet)
  ]);

  // Cân bằng tồn kho vào DM_HangHoa nếu được yêu cầu
  if (phieu.canBangKho && chiTiet.length > 0) {
    const sheetDM = ss.getSheetByName("DM_HangHoa");
    if (sheetDM) {
      const rowsDM = sheetDM.getDataRange().getValues();
      if (rowsDM.length > 1) {
        const headersDM = rowsDM[0].map(h => String(h || "").trim().toLowerCase());
        const colMa = headersDM.indexOf("mahang") > -1 ? headersDM.indexOf("mahang") : headersDM.indexOf("mã hàng");
        const colTon = headersDM.indexOf("tonkho") > -1 ? headersDM.indexOf("tonkho") : headersDM.indexOf("tồn kho");
        
        if (colMa > -1 && colTon > -1) {
          let mapRow = {};
          for (let i = 1; i < rowsDM.length; i++) {
            let m = String(rowsDM[i][colMa] || "").trim().toUpperCase();
            if (m) mapRow[m] = i + 1;
          }
          chiTiet.forEach(item => {
            let m = String(item.maHang || "").trim().toUpperCase();
            if (mapRow[m]) {
              sheetDM.getRange(mapRow[m], colTon + 1).setValue(Number(item.slThucTe) || 0);
            }
          });
        }
      }
    }

    // Cập nhật lên Supabase dm_hanghoa
    try {
      if (typeof postToSupabaseServer === 'function') {
        const supabaseUpdates = chiTiet.map(item => ({
          ma_hang: String(item.maHang).trim(),
          ton_kho: Number(item.slThucTe) || 0
        }));
        postToSupabaseServer("dm_hanghoa", supabaseUpdates);
      }
    } catch(err) {
      Logger.log("Lỗi cập nhật tồn kho Supabase: " + err.message);
    }
  }

  return { success: true, maPhieu: maPhieu };
}

// Đọc danh sách phiếu xuất hủy từ Google Sheets
function apiGetDanhSachXuatHuy() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = ss.getSheetByName("XuatHuy");
  if (!sheet) return [];
  const rows = sheet.getDataRange().getValues();
  if (rows.length < 2) return [];

  const headers = rows[0].map(h => String(h || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
  
  function getIdx(names) {
    for (let name of names) {
      let cleanName = name.toLowerCase().replace(/[\s_]+/g, '');
      let idx = headers.indexOf(cleanName);
      if (idx > -1) return idx;
    }
    return -1;
  }

  const idxMa = getIdx(["maphieu", "machungtu", "mãphiếu", "mãchứngtừ"]);
  const idxNgay = getIdx(["ngaytao", "ngayhuy", "ngàyhủy", "ngàytạo"]);
  const idxCN = getIdx(["chinhanh", "chi nhánh"]);
  const idxNV = getIdx(["nhanvien", "nguoihuy", "nhânviên", "ngườihủy"]);
  const idxSL = getIdx(["tongsoluong", "soluong", "soluonghuy", "tổngsl", "tổngsốlượng"]);
  const idxGiaTri = getIdx(["tonggiatri", "giatrihuy", "giatri", "tổnggiátrị", "thànhtiền"]);
  const idxLyDo = getIdx(["lydohuy", "lydo", "lýdo", "lýdohủy"]);
  const idxTrangThai = getIdx(["trangthai", "trạngthái"]);
  const idxChiTiet = getIdx(["chitietsanpham", "chitiet", "chitiếtsảnphẩm"]);

  let list = [];
  for (let i = 1; i < rows.length; i++) {
    const r = rows[i];
    if (idxMa > -1 && !r[idxMa]) continue;
    let chiTiet = [];
    if (idxChiTiet > -1 && r[idxChiTiet]) {
      try {
        chiTiet = typeof r[idxChiTiet] === 'string' ? JSON.parse(r[idxChiTiet]) : r[idxChiTiet];
      } catch(e) {
        chiTiet = [];
      }
    }
    // Fallback: nếu chiTiet vẫn rỗng, duyệt toàn bộ các ô trong dòng để tìm JSON Array
    if (!Array.isArray(chiTiet) || !chiTiet.length) {
      for (let j = 0; j < r.length; j++) {
        let cellVal = r[j];
        if (typeof cellVal === 'string' && cellVal.trim().startsWith('[') && cellVal.trim().endsWith(']')) {
          try {
            let parsed = JSON.parse(cellVal.trim());
            if (Array.isArray(parsed) && parsed.length > 0) {
              chiTiet = parsed;
              break;
            }
          } catch(e) {}
        }
      }
    }
    if (!Array.isArray(chiTiet)) chiTiet = [];

    let totalSL = idxSL > -1 ? Number(r[idxSL]) || 0 : 0;
    let totalGT = idxGiaTri > -1 ? Number(r[idxGiaTri]) || 0 : 0;
    if (!totalSL && chiTiet.length) totalSL = chiTiet.reduce((s, it) => s + (Number(it.soLuong) || 0), 0);
    if (!totalGT && chiTiet.length) totalGT = chiTiet.reduce((s, it) => s + (Number(it.thanhTien) || (Number(it.soLuong) * Number(it.giaVon)) || 0), 0);

    let ngayStr = idxNgay > -1 ? r[idxNgay] : "";
    if (ngayStr instanceof Date) {
      ngayStr = Utilities.formatDate(ngayStr, "GMT+7", "yyyy-MM-dd HH:mm");
    } else {
      ngayStr = String(ngayStr || "");
    }

    list.push({
      maChungTu: idxMa > -1 ? String(r[idxMa] || "") : ("PXH" + i),
      ngayTao: ngayStr,
      chiNhanh: idxCN > -1 ? String(r[idxCN] || "") : "",
      nhanVien: idxNV > -1 ? String(r[idxNV] || "") : "",
      soLuong: totalSL,
      tongSoLuong: totalSL,
      giaTriHuy: totalGT,
      tongGiaTri: totalGT,
      lyDo: idxLyDo > -1 ? String(r[idxLyDo] || "") : "",
      trangThai: idxTrangThai > -1 ? String(r[idxTrangThai] || "Hoàn thành") : "Hoàn thành",
      chiTietSanPham: chiTiet
    });
  }
  return list.reverse();
}

// Hủy phiếu xuất hủy và hồi lại tồn kho hàng hóa + IMEI
function apiHuyPhieuXuatHuy(maChungTu) {
  try {
    if (!maChungTu) return { success: false, error: "Mã chứng từ không hợp lệ!" };
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    let sheet = ss.getSheetByName("XuatHuy");
    if (!sheet) return { success: false, error: "Không tìm thấy sheet XuatHuy!" };

    const rows = sheet.getDataRange().getValues();
    if (rows.length < 2) return { success: false, error: "Không có dữ liệu phiếu xuất hủy!" };

    const headers = rows[0].map(h => String(h || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
    function getIdx(names) {
      for (let name of names) {
        let cleanName = name.toLowerCase().replace(/[\s_]+/g, '');
        let idx = headers.indexOf(cleanName);
        if (idx > -1) return idx;
      }
      return -1;
    }

    const idxMa = getIdx(["maphieu", "machungtu", "mãphiếu", "mãchứngtừ"]);
    const idxTrangThai = getIdx(["trangthai", "trạngthái"]);
    const idxChiTiet = getIdx(["chitietsanpham", "chitiet", "chitiếtsảnphẩm"]);

    if (idxMa === -1 || idxTrangThai === -1) {
      return { success: false, error: "Cấu trúc sheet XuatHuy không hợp lệ!" };
    }

    let targetRow = -1;
    let currentTT = "";
    let chiTiet = [];

    for (let i = 1; i < rows.length; i++) {
      if (String(rows[i][idxMa] || "").trim().toUpperCase() === String(maChungTu).trim().toUpperCase()) {
        targetRow = i + 1;
        currentTT = String(rows[i][idxTrangThai] || "").trim();
        if (idxChiTiet > -1 && rows[i][idxChiTiet]) {
          try {
            chiTiet = typeof rows[i][idxChiTiet] === 'string' ? JSON.parse(rows[i][idxChiTiet]) : rows[i][idxChiTiet];
          } catch(e) {
            chiTiet = [];
          }
        }
        if (!Array.isArray(chiTiet) || !chiTiet.length) {
          for (let j = 0; j < rows[i].length; j++) {
            let cellVal = rows[i][j];
            if (typeof cellVal === 'string' && cellVal.trim().startsWith('[') && cellVal.trim().endsWith(']')) {
              try {
                let parsed = JSON.parse(cellVal.trim());
                if (Array.isArray(parsed) && parsed.length > 0) {
                  chiTiet = parsed;
                  break;
                }
              } catch(e) {}
            }
          }
        }
        break;
      }
    }

    if (targetRow === -1) {
      return { success: false, error: "Không tìm thấy phiếu xuất hủy " + maChungTu };
    }

    if (currentTT === "Đã hủy") {
      return { success: false, error: "Phiếu xuất hủy này đã được hủy trước đó rồi!" };
    }

    // 1. Cập nhật trạng thái phiếu thành "Đã hủy"
    sheet.getRange(targetRow, idxTrangThai + 1).setValue("Đã hủy");

    // 2. Hồi tồn kho trong DM_HangHoa nếu phiếu trước đó không phải là Lưu tạm
    if (currentTT !== "Lưu tạm" && Array.isArray(chiTiet) && chiTiet.length > 0) {
      const sheetDM = ss.getSheetByName("DM_HangHoa");
      if (sheetDM) {
        const rowsDM = sheetDM.getDataRange().getValues();
        if (rowsDM.length > 1) {
          const headersDM = rowsDM[0].map(h => String(h || "").trim().toLowerCase());
          let colMa = -1;
          for (let name of ["mahang", "mã hàng", "mã sản phẩm", "masp"]) {
            let idx = headersDM.indexOf(name);
            if (idx > -1) { colMa = idx; break; }
          }
          if (colMa === -1) colMa = 0;

          let colTon = -1;
          for (let name of ["tonkho", "tồn kho", "tồn", "ton"]) {
            let idx = headersDM.indexOf(name);
            if (idx > -1) { colTon = idx; break; }
          }

          if (colTon > -1) {
            let mapRow = {};
            for (let i = 1; i < rowsDM.length; i++) {
              let m = String(rowsDM[i][colMa] || "").trim().toUpperCase();
              if (m) mapRow[m] = { row: i + 1, currentTon: Number(rowsDM[i][colTon]) || 0 };
            }
            let mapTonMoi = {};
            chiTiet.forEach(item => {
              if (!item) return;
              let m = String(item.maHang || "").trim().toUpperCase();
              if (mapRow[m]) {
                let slHuy = Number(item.soLuong) || 0;
                let newTon = mapRow[m].currentTon + slHuy;
                sheetDM.getRange(mapRow[m].row, colTon + 1).setValue(newTon);
                mapRow[m].currentTon = newTon;
                mapTonMoi[m] = newTon;
              }
            });

            // Đồng bộ tồn kho hồi phục sang Supabase
            try {
              if (typeof postToSupabaseServer === 'function') {
                let listStock = Object.keys(mapTonMoi).map(m => ({ ma_hang: m, ton_kho: mapTonMoi[m] }));
                if (listStock.length) postToSupabaseServer("dm_hanghoa", listStock);
              }
            } catch(e) {
              Logger.log("Lỗi đồng bộ tồn kho Supabase khi hủy phiếu: " + e.message);
            }
          }
        }
      }

      // 3. Hồi trạng thái IMEI thành 'TrongKho' trong Kho_IMEI
      const sheetIMEI = ss.getSheetByName("Kho_IMEI");
      let listIMEIHoi = [];
      chiTiet.forEach(item => {
        if (!item) return;
        if (Array.isArray(item.danhSachIMEI) && item.danhSachIMEI.length > 0) {
          listIMEIHoi.push(...item.danhSachIMEI.map(x => String(x || '').trim().toUpperCase()).filter(Boolean));
        } else if (item.imeiStr) {
          listIMEIHoi.push(...String(item.imeiStr).split(/[\n,;\r\t]+/).map(x => x.trim().toUpperCase()).filter(Boolean));
        }
      });

      if (sheetIMEI && listIMEIHoi.length > 0) {
        const rowsIMEI = sheetIMEI.getDataRange().getValues();
        if (rowsIMEI.length > 1) {
          const headersIMEI = rowsIMEI[0].map(h => String(h || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
          let colIMEI = headersIMEI.indexOf("imei") > -1 ? headersIMEI.indexOf("imei") : headersIMEI.indexOf("serial");
          let colTT = headersIMEI.indexOf("trangthai");
          if (colIMEI > -1 && colTT > -1) {
            for (let j = 1; j < rowsIMEI.length; j++) {
              let imVal = String(rowsIMEI[j][colIMEI] || "").trim().toUpperCase();
              if (listIMEIHoi.includes(imVal)) {
                sheetIMEI.getRange(j + 1, colTT + 1).setValue("TrongKho");
              }
            }
          }
        }
      }

      // 4. Đồng bộ Supabase
      try {
        if (typeof postToSupabaseServer === 'function' && listIMEIHoi.length > 0) {
          listIMEIHoi.forEach(im => {
            postToSupabaseServer("kho_imei", { imei: im, trang_thai: "TrongKho" });
          });
        }
      } catch(err) {
        Logger.log("Lỗi đồng bộ Supabase khi hủy phiếu: " + err.message);
      }
    }

    return { success: true, maChungTu: maChungTu, chiTiet: chiTiet };
  } catch(err) {
    Logger.log("Lỗi apiHuyPhieuXuatHuy: " + err.message);
    return { success: false, error: err.message };
  }
}

// Lưu phiếu xuất hủy và giảm tồn kho hàng hóa
function apiLuuPhieuXuatHuy(phieu) {
  try {
    if (!phieu) return { success: false, error: "Dữ liệu phiếu xuất hủy không hợp lệ!" };
    if (typeof phieu === 'string') {
      try { phieu = JSON.parse(phieu); } catch(e) {}
    }

    const ss = SpreadsheetApp.getActiveSpreadsheet();
    let sheet = ss.getSheetByName("XuatHuy");
    const standardHeaders = ["MaPhieu", "NgayTao", "ChiNhanh", "NhanVien", "TongSoLuong", "TongGiaTri", "LyDoHuy", "TrangThai", "ChiTietSanPham"];
    if (!sheet) {
      sheet = ss.insertSheet("XuatHuy");
      sheet.appendRow(standardHeaders);
    }

    // Đọc header hiện tại của sheet
    let lastCol = Math.max(sheet.getLastColumn(), 1);
    let headerRow = sheet.getRange(1, 1, 1, lastCol).getValues()[0];
    let headers = headerRow.map(h => String(h || "").trim().toLowerCase().replace(/[\s_]+/g, ''));

    // Nếu dòng 1 trống hoặc chưa có MaPhieu, khởi tạo lại header chuẩn
    if (!headers[0] || (!headers.includes("maphieu") && !headers.includes("machungtu"))) {
      sheet.getRange(1, 1, 1, standardHeaders.length).setValues([standardHeaders]);
      headerRow = standardHeaders;
      headers = headerRow.map(h => String(h || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
    }

    function getIdx(names) {
      for (let name of names) {
        let cleanName = name.toLowerCase().replace(/[\s_]+/g, '');
        let idx = headers.indexOf(cleanName);
        if (idx > -1) return idx;
      }
      return -1;
    }

    let idxMa = getIdx(["maphieu", "machungtu", "mãphiếu", "mãchứngtừ"]);
    let idxNgay = getIdx(["ngaytao", "ngayhuy", "ngàyhủy", "ngàytạo"]);
    let idxCN = getIdx(["chinhanh", "chi nhánh"]);
    let idxNV = getIdx(["nhanvien", "nguoihuy", "nhânviên", "ngườihủy"]);
    let idxSL = getIdx(["tongsoluong", "soluong", "soluonghuy", "tổngsl", "tổngsốlượng"]);
    let idxGiaTri = getIdx(["tonggiatri", "giatrihuy", "giatri", "tổnggiátrị", "thànhtiền"]);
    let idxLyDo = getIdx(["lydohuy", "lydo", "lýdo", "lýdohủy"]);
    let idxTrangThai = getIdx(["trangthai", "trạngthái"]);
    let idxChiTiet = getIdx(["chitietsanpham", "chitiet", "chitiếtsảnphẩm"]);

    // Nếu thiếu cột ChiTietSanPham trong header, thêm nó vào cuối
    if (idxChiTiet === -1) {
      idxChiTiet = headers.length;
      headers.push("chitietsanpham");
      sheet.getRange(1, idxChiTiet + 1).setValue("ChiTietSanPham");
    }

    const maPhieu = phieu.maChungTu || phieu.maPhieu || ("PXH" + Date.now().toString().slice(-6));
    const ngayHuy = phieu.ngayTao || phieu.ngayHuy || new Date().toISOString().replace('T', ' ').slice(0, 16);
    const chiNhanh = phieu.chiNhanh || "CN01: Trụ sở chính Thanh Miện";
    const nhanVien = phieu.nhanVien || "Quản trị viên";
    const soLuong = Number(phieu.tongSoLuong) || Number(phieu.soLuong) || 0;
    const giaTriHuy = Number(phieu.tongGiaTri) || Number(phieu.giaTriHuy) || 0;
    const lyDo = phieu.lyDo || phieu.lyDoHuy || "";
    const trangThai = phieu.trangThai || "Hoàn thành";
    const chiTiet = Array.isArray(phieu.chiTietSanPham) ? phieu.chiTietSanPham : [];

    let rowData = new Array(headers.length).fill("");
    if (idxMa > -1) rowData[idxMa] = maPhieu;
    if (idxNgay > -1) rowData[idxNgay] = ngayHuy;
    if (idxCN > -1) rowData[idxCN] = chiNhanh;
    if (idxNV > -1) rowData[idxNV] = nhanVien;
    if (idxSL > -1) rowData[idxSL] = soLuong;
    if (idxGiaTri > -1) rowData[idxGiaTri] = giaTriHuy;
    if (idxLyDo > -1) rowData[idxLyDo] = lyDo;
    if (idxTrangThai > -1) rowData[idxTrangThai] = trangThai;
    if (idxChiTiet > -1) rowData[idxChiTiet] = JSON.stringify(chiTiet);

    sheet.appendRow(rowData);

    // Giảm tồn kho trong DM_HangHoa nếu là phiếu hoàn thành
    if (trangThai !== 'Lưu tạm' && chiTiet.length > 0) {
      const sheetDM = ss.getSheetByName("DM_HangHoa");
      if (sheetDM) {
        const rowsDM = sheetDM.getDataRange().getValues();
        if (rowsDM.length > 1) {
          const headersDM = rowsDM[0].map(h => String(h || "").trim().toLowerCase());
          let colMa = -1;
          for (let name of ["mahang", "mã hàng", "mã sản phẩm", "masp"]) {
            let idx = headersDM.indexOf(name);
            if (idx > -1) { colMa = idx; break; }
          }
          if (colMa === -1) colMa = 0;

          let colTon = -1;
          for (let name of ["tonkho", "tồn kho", "tồn", "ton"]) {
            let idx = headersDM.indexOf(name);
            if (idx > -1) { colTon = idx; break; }
          }

          if (colTon > -1) {
            let mapRow = {};
            for (let i = 1; i < rowsDM.length; i++) {
              let m = String(rowsDM[i][colMa] || "").trim().toUpperCase();
              if (m) mapRow[m] = { row: i + 1, currentTon: Number(rowsDM[i][colTon]) || 0 };
            }
            let mapTonMoi = {};
            chiTiet.forEach(item => {
              if (!item) return;
              let m = String(item.maHang || "").trim().toUpperCase();
              if (mapRow[m]) {
                let slHuy = Number(item.soLuong) || 0;
                let newTon = Math.max(0, mapRow[m].currentTon - slHuy);
                sheetDM.getRange(mapRow[m].row, colTon + 1).setValue(newTon);
                mapRow[m].currentTon = newTon;
                mapTonMoi[m] = newTon;
              }
            });

            // Đồng bộ tồn kho mới sang Supabase dm_hanghoa
            try {
              if (typeof postToSupabaseServer === 'function') {
                let listStock = Object.keys(mapTonMoi).map(m => ({ ma_hang: m, ton_kho: mapTonMoi[m] }));
                if (listStock.length) postToSupabaseServer("dm_hanghoa", listStock);
              }
            } catch(e) {
              Logger.log("Lỗi đồng bộ tồn kho Supabase khi xuất hủy: " + e.message);
            }
          }
        }
      }
    }

    // Cập nhật trạng thái IMEI thành 'DaXuatHuy' trong Kho_IMEI nếu có
    const sheetIMEI = ss.getSheetByName("Kho_IMEI");
    let listIMEIHuy = [];
    chiTiet.forEach(item => {
      if (!item) return;
      if (Array.isArray(item.danhSachIMEI) && item.danhSachIMEI.length > 0) {
        listIMEIHuy.push(...item.danhSachIMEI.map(x => String(x || '').trim().toUpperCase()).filter(Boolean));
      } else if (item.imeiStr) {
        listIMEIHuy.push(...String(item.imeiStr).split(/[\n,;\r\t]+/).map(x => x.trim().toUpperCase()).filter(Boolean));
      }
    });

    if (sheetIMEI && listIMEIHuy.length > 0) {
      const rowsIMEI = sheetIMEI.getDataRange().getValues();
      if (rowsIMEI.length > 1) {
        const headersIMEI = rowsIMEI[0].map(h => String(h || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
        let colIMEI = headersIMEI.indexOf("imei") > -1 ? headersIMEI.indexOf("imei") : headersIMEI.indexOf("serial");
        let colTT = headersIMEI.indexOf("trangthai");
        if (colIMEI > -1 && colTT > -1) {
          for (let j = 1; j < rowsIMEI.length; j++) {
            let imVal = String(rowsIMEI[j][colIMEI] || "").trim().toUpperCase();
            if (listIMEIHuy.includes(imVal)) {
              sheetIMEI.getRange(j + 1, colTT + 1).setValue("DaXuatHuy");
            }
          }
        }
      }
    }

    // Đồng bộ sang Supabase
    try {
      if (typeof postToSupabaseServer === 'function' && listIMEIHuy.length > 0) {
        listIMEIHuy.forEach(im => {
          postToSupabaseServer("kho_imei", { imei: im, trang_thai: "DaXuatHuy" });
        });
      }
    } catch(err) {
      Logger.log("Lỗi cập nhật xuất hủy Supabase: " + err.message);
    }

    return { success: true, maPhieu: maPhieu };
  } catch(err) {
    Logger.log("Lỗi apiLuuPhieuXuatHuy: " + err.message);
    return { success: false, error: err.message };
  }
}

// Lấy toàn bộ lịch sử Thẻ kho (Nhập, Bán, Trả hàng, Xuất hủy, Kiểm kê) của một sản phẩm
function apiGetTheKhoHangHoa(maHang, chiNhanh) {
  try {
    if (!maHang) return { success: false, error: "Mã hàng không hợp lệ!" };
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    const targetMa = String(maHang).trim().toUpperCase();
    let history = [];

    // 1. Quét từ XuatHuy
    let sheetXH = ss.getSheetByName("XuatHuy");
    if (sheetXH) {
      let rowsXH = sheetXH.getDataRange().getValues();
      if (rowsXH.length > 1) {
        let headersXH = rowsXH[0].map(h => String(h || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
        let idxMaP = headersXH.indexOf("maphieu") > -1 ? headersXH.indexOf("maphieu") : 0;
        let idxNgay = headersXH.indexOf("ngaytao") > -1 ? headersXH.indexOf("ngaytao") : (headersXH.indexOf("ngayhuy") > -1 ? headersXH.indexOf("ngayhuy") : 1);
        let idxNV = headersXH.indexOf("nhanvien") > -1 ? headersXH.indexOf("nhanvien") : 3;
        let idxLyDo = headersXH.indexOf("lydohuy") > -1 ? headersXH.indexOf("lydohuy") : (headersXH.indexOf("lydo") > -1 ? headersXH.indexOf("lydo") : 6);
        let idxTT = headersXH.indexOf("trangthai") > -1 ? headersXH.indexOf("trangthai") : 7;
        let idxCT = headersXH.indexOf("chitietsanpham") > -1 ? headersXH.indexOf("chitietsanpham") : (headersXH.indexOf("chitiet") > -1 ? headersXH.indexOf("chitiet") : -1);

        for (let i = 1; i < rowsXH.length; i++) {
          let r = rowsXH[i];
          let tt = idxTT > -1 ? String(r[idxTT] || "") : "";
          if (tt === "Đã hủy") continue;

          let chiTiet = [];
          if (idxCT > -1 && r[idxCT]) {
            try { chiTiet = typeof r[idxCT] === 'string' ? JSON.parse(r[idxCT]) : r[idxCT]; } catch(e) {}
          }
          if (!Array.isArray(chiTiet) || !chiTiet.length) {
            for (let j = 0; j < r.length; j++) {
              let val = r[j];
              if (typeof val === 'string' && val.trim().startsWith('[') && val.trim().endsWith(']')) {
                try {
                  let p = JSON.parse(val.trim());
                  if (Array.isArray(p) && p.length) { chiTiet = p; break; }
                } catch(e) {}
              }
            }
          }
          if (Array.isArray(chiTiet)) {
            chiTiet.forEach(it => {
              if (String(it.maHang || "").trim().toUpperCase() === targetMa) {
                let sl = Number(it.soLuong) || 0;
                let ngayStr = r[idxNgay];
                if (ngayStr instanceof Date) ngayStr = Utilities.formatDate(ngayStr, "GMT+7", "yyyy-MM-dd HH:mm");
                history.push({
                  ngay: String(ngayStr || ""),
                  maChungTu: idxMaP > -1 ? String(r[idxMaP] || "") : ("PXH" + i),
                  loaiGD: "XuatHuy",
                  tenLoaiGD: "Xuất hủy hàng lỗi",
                  doiTac: idxNV > -1 ? String(r[idxNV] || "Admin") : "Admin",
                  soLuongThayDoi: -sl,
                  donGia: Number(it.giaVon) || 0,
                  thanhTien: (Number(it.giaVon) || 0) * sl,
                  ghiChu: idxLyDo > -1 ? String(r[idxLyDo] || "") : (it.ghiChu || "Hàng hỏng/lỗi")
                });
              }
            });
          }
        }
      }
    }

    // 2. Quét từ DonHang (Bán lẻ / Khách trả hàng)
    let sheetDon = ss.getSheetByName("DonHang") || ss.getSheetByName("GiaoDich_DonHang");
    if (sheetDon) {
      let rowsDon = sheetDon.getDataRange().getValues();
      if (rowsDon.length > 1) {
        let headersDon = rowsDon[0].map(h => String(h || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
        let idxMaDon = headersDon.indexOf("madonhang") > -1 ? headersDon.indexOf("madonhang") : (headersDon.indexOf("madon") > -1 ? headersDon.indexOf("madon") : 0);
        let idxNgayBan = headersDon.indexOf("ngayban") > -1 ? headersDon.indexOf("ngayban") : (headersDon.indexOf("ngaytao") > -1 ? headersDon.indexOf("ngaytao") : 1);
        let idxTenKH = headersDon.indexOf("tenkh") > -1 ? headersDon.indexOf("tenkh") : (headersDon.indexOf("tenkhachhang") > -1 ? headersDon.indexOf("tenkhachhang") : 2);
        let idxTT = headersDon.indexOf("trangthai") > -1 ? headersDon.indexOf("trangthai") : -1;
        let idxCT = headersDon.indexOf("chitietsanpham") > -1 ? headersDon.indexOf("chitietsanpham") : (headersDon.indexOf("chitiet") > -1 ? headersDon.indexOf("chitiet") : -1);

        for (let i = 1; i < rowsDon.length; i++) {
          let r = rowsDon[i];
          let tt = idxTT > -1 ? String(r[idxTT] || "") : "";
          if (tt === "Đã hủy") continue;

          let maDH = idxMaDon > -1 ? String(r[idxMaDon] || "") : "";
          let isKhachTra = maDH.startsWith("TH") || tt.includes("Khách trả") || tt.includes("Trả hàng");

          let chiTiet = [];
          if (idxCT > -1 && r[idxCT]) {
            try { chiTiet = typeof r[idxCT] === 'string' ? JSON.parse(r[idxCT]) : r[idxCT]; } catch(e) {}
          }
          if (!Array.isArray(chiTiet) || !chiTiet.length) {
            for (let j = 0; j < r.length; j++) {
              let val = r[j];
              if (typeof val === 'string' && val.trim().startsWith('[') && val.trim().endsWith(']')) {
                try {
                  let p = JSON.parse(val.trim());
                  if (Array.isArray(p) && p.length) { chiTiet = p; break; }
                } catch(e) {}
              }
            }
          }

          if (Array.isArray(chiTiet)) {
            chiTiet.forEach(it => {
              if (String(it.maHang || "").trim().toUpperCase() === targetMa) {
                let sl = Number(it.soLuong) || 0;
                let ngayStr = r[idxNgayBan];
                if (ngayStr instanceof Date) ngayStr = Utilities.formatDate(ngayStr, "GMT+7", "yyyy-MM-dd HH:mm");
                history.push({
                  ngay: String(ngayStr || ""),
                  maChungTu: maDH || ("DH" + i),
                  loaiGD: isKhachTra ? "KhachTra" : "BanHang",
                  tenLoaiGD: isKhachTra ? "Khách trả hàng" : "Xuất bán hàng",
                  doiTac: idxTenKH > -1 ? String(r[idxTenKH] || "Khách lẻ") : "Khách lẻ",
                  soLuongThayDoi: isKhachTra ? sl : -sl,
                  donGia: Number(it.donGia) || Number(it.giaBan) || 0,
                  thanhTien: (Number(it.donGia) || Number(it.giaBan) || 0) * sl,
                  ghiChu: isKhachTra ? "Khách hoàn trả sản phẩm" : "Bán lẻ thu ngân POS"
                });
              }
            });
          }
        }
      }
    }

    // 3. Quét từ KiemKho
    let sheetKK = ss.getSheetByName("KiemKho");
    if (sheetKK) {
      let rowsKK = sheetKK.getDataRange().getValues();
      if (rowsKK.length > 1) {
        let headersKK = rowsKK[0].map(h => String(h || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
        let idxMaKK = headersKK.indexOf("maphieu") > -1 ? headersKK.indexOf("maphieu") : 0;
        let idxNgayKK = headersKK.indexOf("ngaykiem") > -1 ? headersKK.indexOf("ngaykiem") : 1;
        let idxNV = headersKK.indexOf("nhanvien") > -1 ? headersKK.indexOf("nhanvien") : 3;
        let idxCT = headersKK.indexOf("chitietsanpham") > -1 ? headersKK.indexOf("chitietsanpham") : (headersKK.indexOf("chitiet") > -1 ? headersKK.indexOf("chitiet") : -1);

        for (let i = 1; i < rowsKK.length; i++) {
          let r = rowsKK[i];
          let chiTiet = [];
          if (idxCT > -1 && r[idxCT]) {
            try { chiTiet = typeof r[idxCT] === 'string' ? JSON.parse(r[idxCT]) : r[idxCT]; } catch(e) {}
          }
          if (!Array.isArray(chiTiet) || !chiTiet.length) {
            for (let j = 0; j < r.length; j++) {
              let val = r[j];
              if (typeof val === 'string' && val.trim().startsWith('[') && val.trim().endsWith(']')) {
                try {
                  let p = JSON.parse(val.trim());
                  if (Array.isArray(p) && p.length) { chiTiet = p; break; }
                } catch(e) {}
              }
            }
          }
          if (Array.isArray(chiTiet)) {
            chiTiet.forEach(it => {
              if (String(it.maHang || "").trim().toUpperCase() === targetMa) {
                let chenhLech = Number(it.chenhLech) || (Number(it.slThucTe || 0) - Number(it.slSoSach || 0));
                let ngayStr = r[idxNgayKK];
                if (ngayStr instanceof Date) ngayStr = Utilities.formatDate(ngayStr, "GMT+7", "yyyy-MM-dd HH:mm");
                history.push({
                  ngay: String(ngayStr || ""),
                  maChungTu: idxMaKK > -1 ? String(r[idxMaKK] || "") : ("PKK" + i),
                  loaiGD: "KiemKho",
                  tenLoaiGD: "Kiểm kho / Cân bằng",
                  doiTac: idxNV > -1 ? String(r[idxNV] || "Admin") : "Admin",
                  soLuongThayDoi: chenhLech,
                  donGia: 0,
                  thanhTien: 0,
                  ghiChu: `Sổ sách: ${it.slSoSach || 0} → Thực tế: ${it.slThucTe || 0}`
                });
              }
            });
          }
        }
      }
    }

    // 4. Quét từ NhapHang nếu có
    let sheetNhap = ss.getSheetByName("NhapHang") || ss.getSheetByName("GiaoDich_NhapHang") || ss.getSheetByName("DonNhapHang");
    if (sheetNhap) {
      let rowsNhap = sheetNhap.getDataRange().getValues();
      if (rowsNhap.length > 1) {
        let headersNhap = rowsNhap[0].map(h => String(h || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
        let idxMaP = headersNhap.indexOf("maphieu") > -1 ? headersNhap.indexOf("maphieu") : (headersNhap.indexOf("madonnhap") > -1 ? headersNhap.indexOf("madonnhap") : 0);
        let idxNgay = headersNhap.indexOf("ngaynhap") > -1 ? headersNhap.indexOf("ngaynhap") : (headersNhap.indexOf("ngaytao") > -1 ? headersNhap.indexOf("ngaytao") : 1);
        let idxNCC = headersNhap.indexOf("tenncc") > -1 ? headersNhap.indexOf("tenncc") : (headersNhap.indexOf("mancc") > -1 ? headersNhap.indexOf("mancc") : 2);
        let idxCT = headersNhap.indexOf("chitietsanpham") > -1 ? headersNhap.indexOf("chitietsanpham") : (headersNhap.indexOf("chitiet") > -1 ? headersNhap.indexOf("chitiet") : -1);

        for (let i = 1; i < rowsNhap.length; i++) {
          let r = rowsNhap[i];
          let chiTiet = [];
          if (idxCT > -1 && r[idxCT]) {
            try { chiTiet = typeof r[idxCT] === 'string' ? JSON.parse(r[idxCT]) : r[idxCT]; } catch(e) {}
          }
          if (!Array.isArray(chiTiet) || !chiTiet.length) {
            for (let j = 0; j < r.length; j++) {
              let val = r[j];
              if (typeof val === 'string' && val.trim().startsWith('[') && val.trim().endsWith(']')) {
                try {
                  let p = JSON.parse(val.trim());
                  if (Array.isArray(p) && p.length) { chiTiet = p; break; }
                } catch(e) {}
              }
            }
          }
          if (Array.isArray(chiTiet)) {
            chiTiet.forEach(it => {
              if (String(it.maHang || "").trim().toUpperCase() === targetMa) {
                let sl = Number(it.soLuong) || 0;
                let ngayStr = r[idxNgay];
                if (ngayStr instanceof Date) ngayStr = Utilities.formatDate(ngayStr, "GMT+7", "yyyy-MM-dd HH:mm");
                history.push({
                  ngay: String(ngayStr || ""),
                  maChungTu: idxMaP > -1 ? String(r[idxMaP] || "") : ("PNH" + i),
                  loaiGD: "NhapHang",
                  tenLoaiGD: "Nhập hàng NCC",
                  doiTac: idxNCC > -1 ? String(r[idxNCC] || "Nhà cung cấp") : "Nhà cung cấp",
                  soLuongThayDoi: sl,
                  donGia: Number(it.donGia) || Number(it.giaVon) || 0,
                  thanhTien: (Number(it.donGia) || Number(it.giaVon) || 0) * sl,
                  ghiChu: it.ghiChu || "Nhập hàng kho"
                });
              }
            });
          }
        }
      }
    }

    // 5. Quét từ TraHangNCC nếu có
    let sheetTraNCC = ss.getSheetByName("TraHangNCC") || ss.getSheetByName("GiaoDich_TraNCC");
    if (sheetTraNCC) {
      let rowsTra = sheetTraNCC.getDataRange().getValues();
      if (rowsTra.length > 1) {
        let headersTra = rowsTra[0].map(h => String(h || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
        let idxMaP = headersTra.indexOf("maphieu") > -1 ? headersTra.indexOf("maphieu") : 0;
        let idxNgay = headersTra.indexOf("ngaytra") > -1 ? headersTra.indexOf("ngaytra") : (headersTra.indexOf("ngaytao") > -1 ? headersTra.indexOf("ngaytao") : 1);
        let idxNCC = headersTra.indexOf("tenncc") > -1 ? headersTra.indexOf("tenncc") : (headersTra.indexOf("mancc") > -1 ? headersTra.indexOf("mancc") : 2);
        let idxCT = headersTra.indexOf("chitietsanpham") > -1 ? headersTra.indexOf("chitietsanpham") : (headersTra.indexOf("chitiet") > -1 ? headersTra.indexOf("chitiet") : -1);

        for (let i = 1; i < rowsTra.length; i++) {
          let r = rowsTra[i];
          let chiTiet = [];
          if (idxCT > -1 && r[idxCT]) {
            try { chiTiet = typeof r[idxCT] === 'string' ? JSON.parse(r[idxCT]) : r[idxCT]; } catch(e) {}
          }
          if (Array.isArray(chiTiet)) {
            chiTiet.forEach(it => {
              if (String(it.maHang || "").trim().toUpperCase() === targetMa) {
                let sl = Number(it.soLuong) || 0;
                let ngayStr = r[idxNgay];
                if (ngayStr instanceof Date) ngayStr = Utilities.formatDate(ngayStr, "GMT+7", "yyyy-MM-dd HH:mm");
                history.push({
                  ngay: String(ngayStr || ""),
                  maChungTu: idxMaP > -1 ? String(r[idxMaP] || "") : ("PTN" + i),
                  loaiGD: "TraNCC",
                  tenLoaiGD: "Trả hàng Nhà Cung Cấp",
                  doiTac: idxNCC > -1 ? String(r[idxNCC] || "Nhà cung cấp") : "Nhà cung cấp",
                  soLuongThayDoi: -sl,
                  donGia: Number(it.donGia) || Number(it.giaVon) || 0,
                  thanhTien: (Number(it.donGia) || Number(it.giaVon) || 0) * sl,
                  ghiChu: it.ghiChu || "Trả hàng nhà cung cấp"
                });
              }
            });
          }
        }
      }
    }

    // Sắp xếp theo ngày tăng dần để tính tồn lũy kế
    history.sort((a, b) => new Date(a.ngay || 0) - new Date(b.ngay || 0));

    return { success: true, maHang: targetMa, history: history };
  } catch(err) {
    Logger.log("Lỗi apiGetTheKhoHangHoa: " + err.message);
    return { success: false, error: err.message };
  }
}

// Thêm mới hoặc cập nhật thông tin đối tác lên Google Sheets

function apiLuuDoiTac(data) {
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    let sheet = ss.getSheetByName("DM_DoiTac");
    if (!sheet) {
      sheet = ss.insertSheet("DM_DoiTac");
      sheet.appendRow(["Mã Đối Tác", "Loại Đối Tác", "Tên Đối Tác", "Số Điện Thoại", "Địa Chỉ", "Giới Tính", "Ngày Sinh", "Công Nợ", "Trạng Thái"]);
    }
    const rows = sheet.getDataRange().getValues();
    let foundRow = -1;
    const targetMa = String(data.maDoiTac || "").trim().toUpperCase();

    for (let i = 1; i < rows.length; i++) {
      if (String(rows[i][0]).trim().toUpperCase() === targetMa) {
        foundRow = i + 1;
        break;
      }
    }

    if (foundRow > -1) {
      // Cập nhật đối tác đã tồn tại
      sheet.getRange(foundRow, 2).setValue(data.loaiDoiTac || "KH");
      sheet.getRange(foundRow, 3).setValue(data.tenDoiTac || "");
      sheet.getRange(foundRow, 4).setValue(data.soDienThoai || "");
      sheet.getRange(foundRow, 5).setValue(data.diaChi || "");
      sheet.getRange(foundRow, 6).setValue(data.gioiTinh || "");
      sheet.getRange(foundRow, 7).setValue(data.ngaySinh || "");
      sheet.getRange(foundRow, 9).setValue(data.trangThai || "Hoạt động");
    } else {
      // Thêm mới đối tác
      sheet.appendRow([
        data.maDoiTac,
        data.loaiDoiTac || "KH",
        data.tenDoiTac || "",
        data.soDienThoai || "",
        data.diaChi || "",
        data.gioiTinh || "",
        data.ngaySinh || "",
        0, // Công nợ ban đầu = 0
        data.trangThai || "Hoạt động"
      ]);
    }

    // Đồng bộ sang Supabase server-side nếu có cấu hình
    try {
      if (typeof postToSupabaseServer === 'function') {
        postToSupabaseServer("dm_doitac", [{
          ma_doi_tac: data.maDoiTac,
          loai_doi_tac: data.loaiDoiTac || "KH",
          ten_doi_tac: data.tenDoiTac || "",
          so_dien_thoai: data.soDienThoai || "",
          dia_chi: data.diaChi || "",
          gioi_tinh: data.gioiTinh || "",
          cong_no: 0,
          trang_thai: data.trangThai || "Hoạt động"
        }]);
      }
    } catch(eSup) {
      Logger.log("Supabase error in apiLuuDoiTac: " + eSup);
    }

    return { success: true, message: "Lưu đối tác thành công!" };
  } catch(err) {
    Logger.log("Error in apiLuuDoiTac: " + err);
    return { success: false, error: err.toString() };
  }
}

// Cập nhật trạng thái hoạt động / ngừng hoạt động cho 1 hoặc nhiều đối tác
function apiCapNhatTrangThaiDoiTac(maList, trangThaiMoi, loaiDoiTac) {
  try {
    if (!Array.isArray(maList) || !maList.length) {
      return { success: false, error: "Danh sách mã đối tác trống!" };
    }
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    const sheet = ss.getSheetByName("DM_DoiTac");
    if (!sheet) return { success: false, error: "Không tìm thấy sheet DM_DoiTac" };

    const rows = sheet.getDataRange().getValues();
    if (rows.length < 2) return { success: false, error: "Dữ liệu đối tác trống" };

    const headers = rows[0].map(h => String(h || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
    let idxMa = headers.indexOf("madoitac");
    if (idxMa === -1) idxMa = 0;
    let idxTT = headers.indexOf("trangthai");
    if (idxTT === -1) {
      idxTT = headers.length;
      sheet.getRange(1, idxTT + 1).setValue("TrangThai");
    }

    const maUpperSet = new Set(maList.map(m => String(m).trim().toUpperCase()));
    let updatedCount = 0;

    for (let i = 1; i < rows.length; i++) {
      let maVal = String(rows[i][idxMa] || "").trim().toUpperCase();
      if (maUpperSet.has(maVal)) {
        sheet.getRange(i + 1, idxTT + 1).setValue(trangThaiMoi);
        updatedCount++;
      }
    }

    // Đồng bộ sang Supabase nếu có
    try {
      if (typeof postToSupabaseServer === 'function') {
        let records = maList.map(m => ({
          ma_doi_tac: String(m).trim(),
          trang_thai: trangThaiMoi
        }));
        postToSupabaseServer("dm_doitac", records);
      }
    } catch(eSup) {
      Logger.log("Lỗi đồng bộ Supabase cập nhật trạng thái đối tác: " + eSup.message);
    }

    return { success: true, count: updatedCount, trangThaiMoi: trangThaiMoi };
  } catch(err) {
    Logger.log("Lỗi apiCapNhatTrangThaiDoiTac: " + err.message);
    return { success: false, error: err.message };
  }
}

// Thanh toán công nợ Nhà Cung Cấp: Giảm công nợ trong DM_DoiTac và ghi phiếu chi vào SoQuy
function apiThanhToanCongNoNCC(payload) {
  try {
    const maNCC = String(payload.maNCC || payload.maDoiTac || "").trim().toUpperCase();
    const soTien = Number(payload.soTien) || 0;
    if (!maNCC) return { success: false, error: "Mã nhà cung cấp không hợp lệ!" };
    if (soTien <= 0) return { success: false, error: "Số tiền thanh toán phải lớn hơn 0!" };

    const ss = SpreadsheetApp.getActiveSpreadsheet();
    const sheetDT = ss.getSheetByName("DM_DoiTac");
    if (!sheetDT) return { success: false, error: "Không tìm thấy sheet DM_DoiTac" };

    const rowsDT = sheetDT.getDataRange().getValues();
    const headersDT = rowsDT.length > 0 ? rowsDT[0].map(h => String(h || "").trim().toLowerCase().replace(/[\s_]+/g, '')) : [];
    let idxMa = headersDT.indexOf("madoitac") > -1 ? headersDT.indexOf("madoitac") : 0;
    let idxCongNo = headersDT.indexOf("congno") > -1 ? headersDT.indexOf("congno") : 7;
    let idxTen = headersDT.indexOf("tendoitac") > -1 ? headersDT.indexOf("tendoitac") : 2;

    let foundRow = -1;
    let currentCongNo = 0;
    let tenNCC = payload.tenNCC || "";

    for (let i = 1; i < rowsDT.length; i++) {
      if (String(rowsDT[i][idxMa] || "").trim().toUpperCase() === maNCC) {
        foundRow = i + 1;
        currentCongNo = Number(rowsDT[i][idxCongNo]) || 0;
        if (!tenNCC && idxTen > -1) tenNCC = String(rowsDT[i][idxTen] || "");
        break;
      }
    }

    let newCongNo = Math.max(0, currentCongNo - soTien);
    if (foundRow > -1) {
      sheetDT.getRange(foundRow, idxCongNo + 1).setValue(newCongNo);
    }

    // Ghi nhận Phiếu chi vào Sổ Quỹ
    let maPhieu = payload.maPhieu || ("PC" + Date.now().toString().slice(-6));
    let ngayGD = payload.ngayGD || Utilities.formatDate(new Date(), Session.getScriptTimeZone() || "GMT+7", "yyyy-MM-dd HH:mm:ss");
    let loaiQuy = payload.loaiQuy || payload.hinhThucTT || "TIEN_MAT";
    let chiNhanh = payload.chiNhanh || "CN01: Trụ sở chính";
    let nguoiNhan = payload.nguoiNhan || payload.nguoiChi || payload.nhanVien || "";
    let ghiChu = payload.ghiChu || `Chi thanh toán công nợ cho NCC ${tenNCC || maNCC}`;
    if (nguoiNhan && ghiChu.indexOf(nguoiNhan) === -1) {
      ghiChu = `[Người chi: ${nguoiNhan}] ` + ghiChu;
    }

    let sheetQuy = ss.getSheetByName("SoQuy");
    if (!sheetQuy) {
      sheetQuy = ss.insertSheet("SoQuy");
      sheetQuy.appendRow(["ChiNhanh", "MaPhieu", "LoaiPhieu", "LoaiQuy", "NgayGD", "SoTien", "DoiTuong", "MaDoiTuong", "MaChungTu", "TrangThai", "GhiChu"]);
    }
    sheetQuy.appendRow([
      chiNhanh,
      maPhieu,
      "CHI",
      loaiQuy,
      ngayGD,
      soTien,
      "Nhà cung cấp",
      maNCC,
      "TT_CONG_NO",
      "DaThanhToan",
      ghiChu
    ]);

    // Đồng bộ sang Supabase
    try {
      if (typeof postToSupabaseServer === 'function') {
        if (typeof patchSupabaseServer === 'function') {
          patchSupabaseServer("dm_doitac", "ma_doi_tac=eq." + maNCC, {
            cong_no: newCongNo
          });
        } else if (typeof postToSupabaseServer === 'function') {
          postToSupabaseServer("dm_doitac", {
            ma_doi_tac: maNCC,
            cong_no: newCongNo
          });
        }
        let ngayGD_ISO = new Date().toISOString();
        if (payload.ngayGD) {
          try {
            let parsed = new Date(payload.ngayGD);
            if (!isNaN(parsed.getTime())) ngayGD_ISO = parsed.toISOString();
          } catch(eDate) {}
        }
        postToSupabaseServer("so_quy", {
          chi_nhanh: chiNhanh,
          ma_phieu: maPhieu,
          loai_phieu: "CHI",
          loai_quy: loaiQuy,
          ngay_gd: ngayGD_ISO,
          so_tien: soTien,
          doi_tuong: "Nhà cung cấp",
          ma_doi_tuong: maNCC,
          ma_chung_tu: "TT_CONG_NO",
          trang_thai: "DaThanhToan",
          ghi_chu: ghiChu
        });
      }
    } catch(eSup) {
      Logger.log("Lỗi đồng bộ Supabase thanh toán nợ NCC: " + eSup.message);
    }

    return {
      success: true,
      maNCC: maNCC,
      tenNCC: tenNCC,
      soTienDaTra: soTien,
      congNoCu: currentCongNo,
      congNoMoi: newCongNo,
      maPhieu: maPhieu
    };
  } catch(err) {
    Logger.log("Lỗi apiThanhToanCongNoNCC: " + err.message);
    return { success: false, error: err.message };
  }
}

// Lấy lịch sử giao dịch toàn diện của Nhà Cung Cấp (Nhập hàng, Trả hàng NCC, Thanh toán tiền hàng qua Sổ Quỹ)
function apiGetLichSuGiaoDichNCC(maNCC) {
  try {
    const targetMa = String(maNCC || "").trim().toUpperCase();
    if (!targetMa) return { success: false, error: "Thiếu mã nhà cung cấp" };

    const ss = SpreadsheetApp.getActiveSpreadsheet();
    let lichSuNhap = [];
    let lichSuTra = [];
    let lichSuThanhToan = [];
    let tongGiaTriNhap = 0;
    let tongGiaTriTra = 0;
    let tongDaThanhToan = 0;
    let infoNCC = null;

    // 1. Lấy thông tin & công nợ từ DM_DoiTac
    const sheetDT = ss.getSheetByName("DM_DoiTac");
    if (sheetDT) {
      let rDT = sheetDT.getDataRange().getValues();
      if (rDT.length > 1) {
        let hDT = rDT[0].map(h => String(h || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
        let idxMa = hDT.indexOf("madoitac") > -1 ? hDT.indexOf("madoitac") : 0;
        let idxTen = hDT.indexOf("tendoitac") > -1 ? hDT.indexOf("tendoitac") : 2;
        let idxSdt = hDT.indexOf("sodienthoai") > -1 ? hDT.indexOf("sodienthoai") : 3;
        let idxDiaChi = hDT.indexOf("diachi") > -1 ? hDT.indexOf("diachi") : 4;
        let idxCongNo = hDT.indexOf("congno") > -1 ? hDT.indexOf("congno") : 7;
        let idxTT = hDT.indexOf("trangthai") > -1 ? hDT.indexOf("trangthai") : 8;

        for (let i = 1; i < rDT.length; i++) {
          if (String(rDT[i][idxMa] || "").trim().toUpperCase() === targetMa) {
            infoNCC = {
              maDoiTac: String(rDT[i][idxMa] || targetMa),
              tenDoiTac: String(rDT[i][idxTen] || ""),
              soDienThoai: String(rDT[i][idxSdt] || ""),
              diaChi: String(rDT[i][idxDiaChi] || ""),
              congNo: Number(rDT[i][idxCongNo]) || 0,
              trangThai: String(rDT[i][idxTT] || "HoatDong")
            };
            break;
          }
        }
      }
    }

    const tenTarget = (infoNCC && infoNCC.tenDoiTac ? infoNCC.tenDoiTac.trim().toLowerCase() : "");

    // 2. Lịch sử Nhập hàng (sheet NhapHang hoặc GiaoDich_NhapHang hoặc DonNhapHang)
    let sheetNhap = ss.getSheetByName("NhapHang") || ss.getSheetByName("GiaoDich_NhapHang") || ss.getSheetByName("DonNhapHang");
    if (sheetNhap) {
      let rN = sheetNhap.getDataRange().getValues();
      if (rN.length > 1) {
        let hN = rN[0].map(h => String(h || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
        let idxMaP = hN.indexOf("maphieu") > -1 ? hN.indexOf("maphieu") : (hN.indexOf("madonnhap") > -1 ? hN.indexOf("madonnhap") : 0);
        let idxNgay = hN.indexOf("ngaynhap") > -1 ? hN.indexOf("ngaynhap") : (hN.indexOf("ngaytao") > -1 ? hN.indexOf("ngaytao") : 1);
        let idxNCC = hN.indexOf("mancc") > -1 ? hN.indexOf("mancc") : (hN.indexOf("tenncc") > -1 ? hN.indexOf("tenncc") : 2);
        let idxTong = hN.indexOf("tongtien") > -1 ? hN.indexOf("tongtien") : 4;
        let idxDaTra = hN.indexOf("datra") > -1 ? hN.indexOf("datra") : 5;
        let idxConNo = hN.indexOf("conno") > -1 ? hN.indexOf("conno") : 6;
        let idxTT = hN.indexOf("trangthai") > -1 ? hN.indexOf("trangthai") : 7;
        let idxGhiChu = hN.indexOf("ghichu") > -1 ? hN.indexOf("ghichu") : -1;
        let idxCT = hN.indexOf("chitietsanpham") > -1 ? hN.indexOf("chitietsanpham") : (hN.indexOf("chitiet") > -1 ? hN.indexOf("chitiet") : -1);

        for (let i = 1; i < rN.length; i++) {
          let r = rN[i];
          let valNCC = String(r[idxNCC] || "").trim().toLowerCase();
          let match = valNCC.includes(targetMa.toLowerCase()) || (tenTarget && valNCC.includes(tenTarget));
          if (!match && idxNCC > -1) {
            for (let j = 0; j < r.length; j++) {
              if (String(r[j] || "").trim().toUpperCase() === targetMa) { match = true; break; }
            }
          }

          if (match) {
            let tongTien = Number(r[idxTong]) || 0;
            let daTra = Number(r[idxDaTra]) || 0;
            let conNo = idxConNo > -1 ? (Number(r[idxConNo]) || (tongTien - daTra)) : (tongTien - daTra);
            let ngayStr = r[idxNgay];
            if (ngayStr instanceof Date) ngayStr = Utilities.formatDate(ngayStr, "GMT+7", "yyyy-MM-dd HH:mm:ss");

            tongGiaTriNhap += tongTien;
            tongDaThanhToan += daTra;

            let chiTiet = [];
            if (idxCT > -1 && r[idxCT]) {
              try { chiTiet = typeof r[idxCT] === 'string' ? JSON.parse(r[idxCT]) : r[idxCT]; } catch(e) {}
            }

            lichSuNhap.push({
              ngay: String(ngayStr || ""),
              maPhieu: String(r[idxMaP] || ("PNH" + i)),
              loaiGD: "NhapHang",
              tenLoaiGD: "Nhập hàng",
              tongTien: tongTien,
              daTra: daTra,
              conNo: conNo,
              trangThai: String(r[idxTT] || "Hoàn thành"),
              ghiChu: idxGhiChu > -1 ? String(r[idxGhiChu] || "") : "",
              chiTiet: chiTiet
            });
          }
        }
      }
    }

    // 3. Lịch sử Trả hàng NCC (sheet TraHangNCC hoặc GiaoDich_TraNCC)
    let sheetTra = ss.getSheetByName("TraHangNCC") || ss.getSheetByName("GiaoDich_TraNCC");
    if (sheetTra) {
      let rT = sheetTra.getDataRange().getValues();
      if (rT.length > 1) {
        let hT = rT[0].map(h => String(h || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
        let idxMaP = hT.indexOf("maphieu") > -1 ? hT.indexOf("maphieu") : 0;
        let idxNgay = hT.indexOf("ngaytra") > -1 ? hT.indexOf("ngaytra") : (hT.indexOf("ngaytao") > -1 ? hT.indexOf("ngaytao") : 1);
        let idxNCC = hT.indexOf("mancc") > -1 ? hT.indexOf("mancc") : (hT.indexOf("tenncc") > -1 ? hT.indexOf("tenncc") : 2);
        let idxTong = hT.indexOf("tongtien") > -1 ? hT.indexOf("tongtien") : 4;
        let idxGhiChu = hT.indexOf("ghichu") > -1 ? hT.indexOf("ghichu") : -1;
        let idxCT = hT.indexOf("chitietsanpham") > -1 ? hT.indexOf("chitietsanpham") : (hT.indexOf("chitiet") > -1 ? hT.indexOf("chitiet") : -1);

        for (let i = 1; i < rT.length; i++) {
          let r = rT[i];
          let valNCC = String(r[idxNCC] || "").trim().toLowerCase();
          let match = valNCC.includes(targetMa.toLowerCase()) || (tenTarget && valNCC.includes(tenTarget));

          if (match) {
            let tongTien = Number(r[idxTong]) || 0;
            let ngayStr = r[idxNgay];
            if (ngayStr instanceof Date) ngayStr = Utilities.formatDate(ngayStr, "GMT+7", "yyyy-MM-dd HH:mm:ss");

            tongGiaTriTra += tongTien;

            let chiTiet = [];
            if (idxCT > -1 && r[idxCT]) {
              try { chiTiet = typeof r[idxCT] === 'string' ? JSON.parse(r[idxCT]) : r[idxCT]; } catch(e) {}
            }

            lichSuTra.push({
              ngay: String(ngayStr || ""),
              maPhieu: String(r[idxMaP] || ("PTN" + i)),
              loaiGD: "TraNCC",
              tenLoaiGD: "Trả hàng NCC",
              tongTien: tongTien,
              ghiChu: idxGhiChu > -1 ? String(r[idxGhiChu] || "") : "",
              chiTiet: chiTiet
            });
          }
        }
      }
    }

    // 4. Lịch sử thanh toán tiền hàng (sheet SoQuy - LoaiPhieu = 'CHI')
    let sheetQuy = ss.getSheetByName("SoQuy");
    if (sheetQuy) {
      let rQ = sheetQuy.getDataRange().getValues();
      if (rQ.length > 1) {
        let hQ = rQ[0].map(h => String(h || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
        let idxMaP = hQ.indexOf("maphieu") > -1 ? hQ.indexOf("maphieu") : 1;
        let idxLoaiP = hQ.indexOf("loaiphieu") > -1 ? hQ.indexOf("loaiphieu") : 2;
        let idxLoaiQ = hQ.indexOf("loaiquy") > -1 ? hQ.indexOf("loaiquy") : 3;
        let idxNgay = hQ.indexOf("ngaygd") > -1 ? hQ.indexOf("ngaygd") : 4;
        let idxSoTien = hQ.indexOf("sotien") > -1 ? hQ.indexOf("sotien") : 5;
        let idxDoiTuong = hQ.indexOf("doituong") > -1 ? hQ.indexOf("doituong") : 6;
        let idxMaDT = hQ.indexOf("madoituong") > -1 ? hQ.indexOf("madoituong") : 7;
        let idxGhiChu = hQ.indexOf("ghichu") > -1 ? hQ.indexOf("ghichu") : 10;
        let idxTT = hQ.indexOf("trangthai") > -1 ? hQ.indexOf("trangthai") : 9;

        for (let i = 1; i < rQ.length; i++) {
          let r = rQ[i];
          let maDT = String(r[idxMaDT] || "").trim().toUpperCase();
          let doiTuong = String(r[idxDoiTuong] || "").trim();
          let ghiChu = String(r[idxGhiChu] || "");
          let loaiP = String(r[idxLoaiP] || "").toUpperCase();

          let match = (maDT === targetMa) || 
                      (doiTuong.toLowerCase().includes("nhà cung cấp") && (ghiChu.includes(targetMa) || (tenTarget && ghiChu.toLowerCase().includes(tenTarget))));

          if (match && (loaiP === "CHI" || loaiP.includes("CHI"))) {
            let soTien = Number(r[idxSoTien]) || 0;
            let ngayStr = r[idxNgay];
            if (ngayStr instanceof Date) ngayStr = Utilities.formatDate(ngayStr, "GMT+7", "yyyy-MM-dd HH:mm:ss");

            lichSuThanhToan.push({
              ngay: String(ngayStr || ""),
              maPhieu: String(r[idxMaP] || ("PC" + i)),
              loaiGD: "ThanhToanNCC",
              tenLoaiGD: "Thanh toán nợ",
              loaiQuy: String(r[idxLoaiQ] || "TIEN_MAT"),
              soTien: soTien,
              trangThai: String(r[idxTT] || "DaThanhToan"),
              ghiChu: ghiChu
            });
          }
        }
      }
    }

    // Sắp xếp lịch sử mới nhất lên đầu
    lichSuNhap.sort((a, b) => new Date(b.ngay || 0) - new Date(a.ngay || 0));
    lichSuTra.sort((a, b) => new Date(b.ngay || 0) - new Date(a.ngay || 0));
    lichSuThanhToan.sort((a, b) => new Date(b.ngay || 0) - new Date(a.ngay || 0));

    return {
      success: true,
      maNCC: targetMa,
      infoNCC: infoNCC,
      tongGiaTriNhap: tongGiaTriNhap,
      tongGiaTriTra: tongGiaTriTra,
      tongDaThanhToan: tongDaThanhToan,
      congNoHienTai: infoNCC ? infoNCC.congNo : 0,
      lichSuNhap: lichSuNhap,
      lichSuTra: lichSuTra,
      lichSuThanhToan: lichSuThanhToan
    };
  } catch(err) {
    Logger.log("Lỗi apiGetLichSuGiaoDichNCC: " + err.message);
    return { success: false, error: err.message };
  }
}

// 1. Lấy danh sách chi nhánh từ Google Sheets
function apiGetDanhSachChiNhanh() {
  const defaultBranches = [
    { ma: "CN01", ten: "Trụ sở chính Thanh Miện" },
    { ma: "CN02", ten: "Chi nhánh Thanh Giang" },
    { ma: "CN03", ten: "Chi nhánh Bình Giang" },
    { ma: "CN04", ten: "Bán Online" }
  ];

  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName("DM_ChiNhanh");
  if (!sheet) {
    try {
      const ss = SpreadsheetApp.getActiveSpreadsheet();
      const newSheet = ss.insertSheet("DM_ChiNhanh");
      newSheet.appendRow(["MaChiNhanh", "TenChiNhanh"]);
      defaultBranches.forEach(b => newSheet.appendRow([b.ma, b.ten]));
    } catch(e) {}
    return defaultBranches;
  }
  
  const rows = sheet.getDataRange().getValues();
  let result = [];
  for (let i = 1; i < rows.length; i++) {
    if (rows[i][0]) {
      result.push({
        ma: String(rows[i][0]).trim().toUpperCase(),
        ten: String(rows[i][1]).trim()
      });
    }
  }
  return result.length ? result : defaultBranches;
}

// 2. Lưu thông tin chi nhánh (Thêm mới hoặc Cập nhật sửa tên)
function apiLuuChiNhanh(data) {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName("DM_ChiNhanh");
  if (!sheet) return { success: false, error: "Không tìm thấy sheet DM_ChiNhanh" };
  const rows = sheet.getDataRange().getValues();
  const trimMa = String(data.ma || "").trim().toUpperCase();
  const trimTen = String(data.ten || "").trim();
  
  let foundRow = -1;
  for (let i = 1; i < rows.length; i++) {
    if (String(rows[i][0]).trim().toUpperCase() === trimMa) {
      foundRow = i + 1;
      break;
    }
  }

  if (foundRow > -1) {
    // Cập nhật tên chi nhánh nếu đã tồn tại mã
    sheet.getRange(foundRow, 2).setValue(trimTen);
  } else {
    // Thêm mới chi nhánh
    sheet.appendRow([trimMa, trimTen]);
  }
  return { success: true };
}

// 3. Xóa chi nhánh khỏi Google Sheets
function apiXoaChiNhanh(maCN) {
  const sheet = SpreadsheetApp.getActiveSpreadsheet().getSheetByName("DM_ChiNhanh");
  if (!sheet) return { success: false, error: "Không tìm thấy sheet DM_ChiNhanh" };
  const rows = sheet.getDataRange().getValues();
  
  if (rows.length <= 2) {
    return { success: false, error: "Hệ thống phải duy trì ít nhất 1 chi nhánh!" };
  }

  for (let i = 1; i < rows.length; i++) {
    if (String(rows[i][0]).trim().toUpperCase() === String(maCN).trim().toUpperCase()) {
      sheet.deleteRow(i + 1);
      return { success: true };
    }
  }
  return { success: false, error: "Không tìm thấy mã chi nhánh để xóa" };
}

function apiLuuDanhSachHangHoaVoiCheDo(list, importMode) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  const sheetDM = ss.getSheetByName("DM_HangHoa");
  const sheetIMEI = ss.getSheetByName("Kho_IMEI");
  
  if (!sheetDM) return { success: false, error: "Không tìm thấy sheet DM_HangHoa" };

  const rowsDM = sheetDM.getDataRange().getValues();
  const headersDM = rowsDM.length > 0 ? rowsDM[0].map(h => String(h || "").trim().toLowerCase()) : [];
  
  function getColIndexDM(names) {
    for (let name of names) {
      let idx = headersDM.indexOf(name.toLowerCase());
      if (idx > -1) return idx + 1;
    }
    return -1;
  }

  const colChiNhanhDM = getColIndexDM(["chinhanh", "chi nhánh"]);
  const colMaHangDM = getColIndexDM(["mahang", "mã hàng", "mã sản phẩm"]);
  const colTenHangDM = getColIndexDM(["tenhang", "tên hàng", "tên sản phẩm"]);
  const colMaNhomDM = getColIndexDM(["manhom", "mã nhóm"]);
  const colDVTDm = getColIndexDM(["donvitinh", "đơn vị tính", "dvt"]);
  const colGiaVonDM = getColIndexDM(["giavon", "giá vốn"]);
  const colGiaBanDM = getColIndexDM(["giaban", "giá bán"]);
  const colIMEIDm = getColIndexDM(["coquanlyimei", "quản lý imei", "co_quan_ly_imei"]);
  const colTonKhoDM = getColIndexDM(["tonkho", "tồn kho"]);
  const colTrangThaiDM = getColIndexDM(["trangthai", "trạng thái"]);

  if (colMaHangDM === -1 || colTenHangDM === -1) {
    return { success: false, error: "Sheet DM_HangHoa thiếu cột Mã hàng hoặc Tên hàng!" };
  }

  let mapRowDM = {};
  for (let i = 1; i < rowsDM.length; i++) {
    let ma = String(rowsDM[i][colMaHangDM - 1] || "").trim().toUpperCase();
    if (ma) mapRowDM[ma] = i + 1;
  }

  let headersIMEI = [];
  let colChiNhanhIMEI = -1, colIMEICol = -1, colMaHangIMEI = -1, colTrangThaiIMEI = -1, colNgayCapNhatIMEI = -1;
  let existingIMEIs = new Set();

  if (sheetIMEI) {
    const rowsIMEI = sheetIMEI.getDataRange().getValues();
    headersIMEI = rowsIMEI.length > 0 ? rowsIMEI[0].map(h => String(h || "").trim().toLowerCase()) : [];
    
    function getColIndexIMEI(names) {
      for (let name of names) {
        let idx = headersIMEI.indexOf(name.toLowerCase());
        if (idx > -1) return idx + 1;
      }
      return -1;
    }

    colChiNhanhIMEI = getColIndexIMEI(["chinhanh", "chi nhánh"]);
    colIMEICol = getColIndexIMEI(["imei", "serial", "mã imei"]);
    colMaHangIMEI = getColIndexIMEI(["mahang", "mã hàng"]);
    colTrangThaiIMEI = getColIndexIMEI(["trangthai", "trạng thái"]);
    colNgayCapNhatIMEI = getColIndexIMEI(["ngaycapnhat", "ngày cập nhật", "ngaynhap"]);

    if (colIMEICol > -1) {
      for (let j = 1; j < rowsIMEI.length; j++) {
        let im = String(rowsIMEI[j][colIMEICol - 1] || "").trim();
        if (im) existingIMEIs.add(im.toUpperCase());
      }
    }
  }

  list.forEach(h => {
    const ma = String(h.maHang || "").trim().toUpperCase();
    const ten = String(h.tenHang || "").trim();
    if (!ma || !ten) return;

    const rowIdx = mapRowDM[ma];
    const currentCN = h.chiNhanh || "CN01";

    if (rowIdx) {
      if (importMode === 'SKIP') return; // Bỏ qua nếu mã hàng đã tồn tại

      if (importMode === 'MERGE') {
        // Cộng dồn số lượng tồn kho cũ với số lượng trong file Excel mới
        if (colTonKhoDM > -1) {
          let oldTon = Number(rowsDM[rowIdx - 1][colTonKhoDM - 1]) || 0;
          sheetDM.getRange(rowIdx, colTonKhoDM).setValue(oldTon + (Number(h.tonKho) || 0));
        }
      } else {
        // OVERWRITE: Ghi đè toàn bộ thông tin mới
        if (colChiNhanhDM > -1) sheetDM.getRange(rowIdx, colChiNhanhDM).setValue(currentCN);
        if (colTenHangDM > -1) sheetDM.getRange(rowIdx, colTenHangDM).setValue(ten);
        if (colMaNhomDM > -1) sheetDM.getRange(rowIdx, colMaNhomDM).setValue(h.maNhom || "");
        if (colDVTDm > -1) sheetDM.getRange(rowIdx, colDVTDm).setValue(h.donViTinh || "Cái");
        if (colGiaVonDM > -1) sheetDM.getRange(rowIdx, colGiaVonDM).setValue(Number(h.giaVon) || 0);
        if (colGiaBanDM > -1) sheetDM.getRange(rowIdx, colGiaBanDM).setValue(Number(h.giaBan) || 0);
        if (colIMEIDm > -1) sheetDM.getRange(rowIdx, colIMEIDm).setValue(h.coQuanLyIMEI ? "Có" : "Không");
        if (colTonKhoDM > -1) sheetDM.getRange(rowIdx, colTonKhoDM).setValue(Number(h.tonKho) || 0);
        if (colTrangThaiDM > -1) sheetDM.getRange(rowIdx, colTrangThaiDM).setValue(h.trangThai || "Kinh doanh");
      }
    } else {
      // Nếu là sản phẩm mới hoàn toàn -> Thêm mới vào cuối sheet
      let newRowDM = new Array(headersDM.length).fill("");
      if (colChiNhanhDM > -1) newRowDM[colChiNhanhDM - 1] = currentCN;
      newRowDM[colMaHangDM - 1] = ma;
      if (colTenHangDM > -1) newRowDM[colTenHangDM - 1] = ten;
      if (colMaNhomDM > -1) newRowDM[colMaNhomDM - 1] = h.maNhom || "";
      if (colDVTDm > -1) newRowDM[colDVTDm - 1] = h.donViTinh || "Cái";
      if (colGiaVonDM > -1) newRowDM[colGiaVonDM - 1] = Number(h.giaVon) || 0;
      if (colGiaBanDM > -1) newRowDM[colGiaBanDM - 1] = Number(h.giaBan) || 0;
      if (colIMEIDm > -1) newRowDM[colIMEIDm - 1] = h.coQuanLyIMEI ? "Có" : "Không";
      if (colTonKhoDM > -1) newRowDM[colTonKhoDM - 1] = Number(h.tonKho) || 0;
      if (colTrangThaiDM > -1) newRowDM[colTrangThaiDM - 1] = h.trangThai || "Kinh doanh";
      sheetDM.appendRow(newRowDM);
    }

    // Ghi nhận danh sách mã IMEI vào sheet Kho_IMEI
    if (sheetIMEI && h.coQuanLyIMEI && Array.isArray(h.danhSachIMEI) && h.danhSachIMEI.length > 0 && colIMEICol > -1) {
      h.danhSachIMEI.forEach(imeiCode => {
        const cleanIMEI = String(imeiCode || "").trim();
        if (!cleanIMEI || existingIMEIs.has(cleanIMEI.toUpperCase())) return;

        let newRowIMEI = new Array(headersIMEI.length).fill("");
        if (colChiNhanhIMEI > -1) newRowIMEI[colChiNhanhIMEI - 1] = currentCN;
        if (colIMEICol > -1) newRowIMEI[colIMEICol - 1] = cleanIMEI;
        if (colMaHangIMEI > -1) newRowIMEI[colMaHangIMEI - 1] = ma;
        if (colTrangThaiIMEI > -1) newRowIMEI[colTrangThaiIMEI - 1] = "TrongKho";
        if (colNgayCapNhatIMEI > -1) newRowIMEI[colNgayCapNhatIMEI - 1] = new Date();

        sheetIMEI.appendRow(newRowIMEI);
        existingIMEIs.add(cleanIMEI.toUpperCase());
      });
    }
  });

  return { success: true };
}

function apiGetIMEITonKho(maHang, chiNhanh) {
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet() || SpreadsheetApp.openById("1MZyIP9j7AQbUOgeGPmbA9EsWyhc0C1vXG9t1FWw_uFU");
    let sheet = ss.getSheetByName("Kho_IMEI");
    if (!sheet) {
      sheet = ss.insertSheet("Kho_IMEI");
      sheet.appendRow(["ChiNhanh", "IMEI", "MaHang", "TrangThai", "MaPhieuNhap", "NgayCapNhat"]);
    }

    const rows = sheet.getDataRange().getValues();
    const cleanMaTarget = String(maHang || "").trim().toUpperCase();
    const cleanCNTarget = String(chiNhanh || "").trim().toUpperCase();
    let imeiList = [];

    if (rows.length > 1) {
      const headers = rows[0].map(h => String(h || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
      let colCN = headers.indexOf("chinhanh");
      let colIMEI = headers.indexOf("imei") > -1 ? headers.indexOf("imei") : headers.indexOf("serial");
      let colMa = headers.indexOf("mahang") > -1 ? headers.indexOf("mahang") : headers.indexOf("masanpham");
      let colTrangThai = headers.indexOf("trangthai");

      for (let i = 1; i < rows.length; i++) {
        let rVals = rows[i];
        let rMa = colMa > -1 ? String(rVals[colMa] || "").trim().toUpperCase() : "";
        let rIMEI = colIMEI > -1 ? String(rVals[colIMEI] || "").trim() : "";
        let rCN = colCN > -1 ? String(rVals[colCN] || "").trim().toUpperCase() : "";
        let rTT = colTrangThai > -1 ? String(rVals[colTrangThai] || "").trim().toLowerCase().replace(/[\s_]+/g, '') : "trongkho";

        // Tự sửa nếu cột bị lệch
        if (rIMEI && (rIMEI.startsWith("CN") || rIMEI.includes("CHI NHÁNH") || rIMEI.includes("TRỤ SỞ"))) {
          let tempCN = rIMEI;
          rIMEI = rCN || rMa;
          rCN = tempCN.toUpperCase();
        }
        if (!rMa || rMa === rIMEI.toUpperCase()) {
          for (let cell of rVals) {
            let s = String(cell || "").trim().toUpperCase();
            if (s === cleanMaTarget) { rMa = s; break; }
          }
        }

        let isTrongKho = (!rTT || rTT === "trongkho" || rTT === "hoatdong" || rTT === "1");
        if (rMa === cleanMaTarget && rIMEI !== "" && isTrongKho) {
          if (colCN === -1 || !cleanCNTarget || cleanCNTarget === "ALL") {
            if (!imeiList.includes(rIMEI)) imeiList.push(rIMEI);
          } else {
            const isMatch = (rCN === cleanCNTarget || rCN.startsWith(cleanCNTarget) || cleanCNTarget.startsWith(rCN) || (cleanCNTarget === "CN01" && (rCN === "" || rCN === "CN01")));
            if (isMatch && !imeiList.includes(rIMEI)) {
              imeiList.push(rIMEI);
            }
          }
        }
      }
    }

    // Dự phòng: Nếu chưa tìm thấy trong Kho_IMEI, quét từ đơn nhập hàng trong NhapHang
    if (imeiList.length === 0) {
      let sheetNhap = ss.getSheetByName("NhapHang") || ss.getSheetByName("GiaoDich_NhapHang") || ss.getSheetByName("DonNhapHang");
      if (sheetNhap) {
        const rowsNhap = sheetNhap.getDataRange().getValues();
        if (rowsNhap.length > 1) {
          let headersNhap = rowsNhap[0].map(h => String(h || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
          let idxCT = headersNhap.indexOf("chitietsanpham") > -1 ? headersNhap.indexOf("chitietsanpham") : headersNhap.indexOf("chitiet");
          let idxCN = headersNhap.indexOf("chinhanh");
          let idxTT = headersNhap.indexOf("trangthai");
          if (idxCT > -1) {
            for (let i = 1; i < rowsNhap.length; i++) {
              if (idxTT > -1 && String(rowsNhap[i][idxTT] || "").includes("Hủy")) continue;
              let rowCN = idxCN > -1 ? String(rowsNhap[i][idxCN] || "").toUpperCase() : "";
              let isCNMatch = (!cleanCNTarget || cleanCNTarget === "ALL" || rowCN === cleanCNTarget || rowCN.startsWith(cleanCNTarget) || cleanCNTarget.startsWith(rowCN) || (cleanCNTarget === "CN01" && !rowCN));
              if (!isCNMatch) continue;

              let ctStr = rowsNhap[i][idxCT];
              let ctList = [];
              try { ctList = typeof ctStr === 'string' ? JSON.parse(ctStr) : ctStr; } catch(e) {}
              if (Array.isArray(ctList)) {
                ctList.forEach(it => {
                  if (String(it.maHang || "").trim().toUpperCase() === cleanMaTarget && it.imeiStr) {
                    let imArr = String(it.imeiStr).split(/[\n,;\r\t]+/).map(s => s.trim().toUpperCase()).filter(Boolean);
                    imArr.forEach(im => {
                      if (!imeiList.includes(im)) imeiList.push(im);
                    });
                  }
                });
              }
            }
          }
        }
      }
    }

    return { success: true, data: imeiList };
  } catch (err) {
    return { success: false, error: err.message, data: [] };
  }
}

// Lấy số liệu KPI và Dashboard theo chi nhánh
function getDashboardData(period, chiNhanh) {
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    const sheetDH = ss.getSheetByName("Don_Hang");
    const cleanCN = chiNhanh ? String(chiNhanh).trim().toUpperCase() : "";

    let doanhThuHomNay = 0, soDonHomNay = 0, traHangHomNay = 0, soDonTraHomNay = 0;
    const topHang = {}, topNV = {};
    const todayStr = Utilities.formatDate(new Date(), Session.getScriptTimeZone() || "GMT+7", "yyyy-MM-dd");

    if (sheetDH) {
      const rows = sheetDH.getDataRange().getValues();
      if (rows.length > 1) {
        const headers = rows[0].map(h => String(h || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
        const colMa = headers.indexOf("madonhang");
        const colNgay = headers.indexOf("ngayban");
        const colTien = headers.indexOf("khachphaitra") > -1 ? headers.indexOf("khachphaitra") : headers.indexOf("tongtien");
        const colCN = headers.indexOf("chinhanh");
        const colNV = headers.indexOf("nhanvien");
        const colTT = headers.indexOf("trangthai");

        for (let i = 1; i < rows.length; i++) {
          const rCN = colCN > -1 ? String(rows[i][colCN] || "").trim().toUpperCase() : "";
          if (cleanCN && cleanCN !== "ALL") {
            const isMatch = (rCN === cleanCN || rCN.startsWith(cleanCN) || cleanCN.startsWith(rCN) || (cleanCN === "CN01" && rCN === ""));
            if (!isMatch) continue;
          }

          const rTT = colTT > -1 ? String(rows[i][colTT] || "") : "";
          if (rTT.includes("Hủy") || rTT.includes("Huy")) continue;

          const rMa = colMa > -1 ? String(rows[i][colMa] || "").trim().toUpperCase() : "";
          const rNV = colNV > -1 ? String(rows[i][colNV] || "").trim() : "";
          const rNVLower = rNV.toLowerCase();
          if (rMa.startsWith("PNH") || rMa.startsWith("DDH") || rNVLower === "hệ thống tự động" || rNVLower === "he thong tu dong") continue;

          let rNgay = colNgay > -1 ? rows[i][colNgay] : null;
          let rDateStr = "";
          if (rNgay instanceof Date) {
            rDateStr = Utilities.formatDate(rNgay, Session.getScriptTimeZone() || "GMT+7", "yyyy-MM-dd");
          } else if (rNgay) {
            rDateStr = String(rNgay).slice(0, 10);
          }

          const isTra = rMa.startsWith("TH") || rTT.includes("Trả");
          const tien = colTien > -1 ? (Number(rows[i][colTien]) || 0) : 0;

          if (rDateStr === todayStr) {
            if (isTra) {
              traHangHomNay += tien;
              soDonTraHomNay++;
            } else {
              doanhThuHomNay += tien;
              soDonHomNay++;
            }
          }

          if (!isTra) {
            const nv = colNV > -1 ? (String(rows[i][colNV] || "Quản trị viên")) : "Quản trị viên";
            topNV[nv] = (topNV[nv] || 0) + tien;
          }
        }
      }
    }

    return {
      kpi: {
        doanhThuHomNay: doanhThuHomNay,
        soDonHomNay: soDonHomNay,
        traHangHomNay: traHangHomNay,
        soDonTraHomNay: soDonTraHomNay,
        dtThuanHomNay: Math.max(0, doanhThuHomNay - traHangHomNay),
        tangTruongHomQua: 0
      },
      topHang: topHang,
      topNhanVien: topNV
    };
  } catch(e) {
    return {
      kpi: { doanhThuHomNay: 0, soDonHomNay: 0, traHangHomNay: 0, soDonTraHomNay: 0, dtThuanHomNay: 0, tangTruongHomQua: 0 },
      topHang: {},
      topNhanVien: {}
    };
  }
}

// Đọc danh sách hàng hóa - Khớp chính xác vị trí cột thực tế trên Google Sheets
function apiGetDanhSachHangHoa() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  
  // 1. Đọc trước sheet Kho_IMEI để lập bản đồ IMEI tồn kho
  let imeiMap = {};
  const sheetIMEI = ss.getSheetByName("Kho_IMEI");
  if (sheetIMEI) {
    const iRows = sheetIMEI.getDataRange().getValues();
    if (iRows.length > 1) {
      const iHeaders = iRows[0].map(h => String(h || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
      let colCN = iHeaders.indexOf("chinhanh");
      let colIMEI = iHeaders.indexOf("imei") > -1 ? iHeaders.indexOf("imei") : iHeaders.indexOf("serial");
      let colMa = iHeaders.indexOf("mahang") > -1 ? iHeaders.indexOf("mahang") : iHeaders.indexOf("masanpham");
      let colTT = iHeaders.indexOf("trangthai");

      for (let j = 1; j < iRows.length; j++) {
        let rowVals = iRows[j];
        let m = colMa > -1 ? String(rowVals[colMa] || "").trim().toUpperCase() : "";
        let im = colIMEI > -1 ? String(rowVals[colIMEI] || "").trim() : "";
        let tt = colTT > -1 ? String(rowVals[colTT] || "").trim().toLowerCase().replace(/[\s_]+/g, '') : "trongkho";

        // Tự động xử lý nếu cột bị lệch hoặc giá trị IMEI/ChiNhanh bị tráo đổi
        if (im && (im.startsWith("CN") || im.includes("Chi nhánh") || im.includes("Trụ sở"))) {
          im = "";
          for (let cell of rowVals) {
            let strC = String(cell || "").trim();
            if (strC && !strC.startsWith("CN") && !strC.includes("Chi nhánh") && !strC.includes("Trụ sở") && (strC.length >= 8 || /^\d+$/.test(strC))) {
              if (strC.toUpperCase() !== m) {
                im = strC;
                break;
              }
            }
          }
        }

        // Nếu mã hàng chưa có, quét các ô để nhận diện
        if (!m) {
          for (let cell of rowVals) {
            let strC = String(cell || "").trim().toUpperCase();
            if (strC && strC !== im.toUpperCase() && !strC.startsWith("CN") && strC !== "TRONGKHO" && strC !== "DABAN") {
              m = strC;
              break;
            }
          }
        }

        let isTrongKho = (!tt || tt === "trongkho" || tt === "hoatdong" || tt === "1");
        if (m && im && isTrongKho) {
          if (!imeiMap[m]) imeiMap[m] = [];
          if (!imeiMap[m].includes(im)) imeiMap[m].push(im);
        }
      }
    }
  }

  // 1.2 Quét bổ sung từ NhapHang để đảm bảo không sót IMEI vừa nhập từ các phiếu nhập kho
  let sheetNhap = ss.getSheetByName("NhapHang") || ss.getSheetByName("GiaoDich_NhapHang") || ss.getSheetByName("DonNhapHang");
  if (sheetNhap) {
    const rowsNhap = sheetNhap.getDataRange().getValues();
    if (rowsNhap.length > 1) {
      let headersNhap = rowsNhap[0].map(h => String(h || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
      let idxCT = headersNhap.indexOf("chitietsanpham") > -1 ? headersNhap.indexOf("chitietsanpham") : (headersNhap.indexOf("chitiet") > -1 ? headersNhap.indexOf("chitiet") : -1);
      let idxTT = headersNhap.indexOf("trangthai");
      if (idxCT > -1) {
        for (let i = 1; i < rowsNhap.length; i++) {
          if (idxTT > -1 && String(rowsNhap[i][idxTT] || "").includes("Hủy")) continue;
          let ctStr = rowsNhap[i][idxCT];
          if (!ctStr) continue;
          let ctList = [];
          try { ctList = typeof ctStr === 'string' ? JSON.parse(ctStr) : ctStr; } catch(e) {}
          if (Array.isArray(ctList)) {
            ctList.forEach(it => {
              let mItem = String(it.maHang || "").trim().toUpperCase();
              if (mItem && it.imeiStr) {
                let imArr = String(it.imeiStr).split(/[\n,;\r\t]+/).map(s => s.trim().toUpperCase()).filter(Boolean);
                if (!imeiMap[mItem]) imeiMap[mItem] = [];
                imArr.forEach(oneIm => {
                  if (!imeiMap[mItem].includes(oneIm)) {
                    imeiMap[mItem].push(oneIm);
                  }
                });
              }
            });
          }
        }
      }
    }
  }

  // 2. Đọc sheet DM_HangHoa
  const sheetDM = ss.getSheetByName("DM_HangHoa");
  if (!sheetDM) return [];
  
  const rows = sheetDM.getDataRange().getValues();
  if (rows.length < 2) return [];

  const headers = rows.length > 0 ? rows[0].map(h => String(h || "").trim().toLowerCase()) : [];
  function getColIdx(names) {
    for (let n of names) {
      let idx = headers.indexOf(n.toLowerCase());
      if (idx > -1) return idx;
    }
    return -1;
  }

  const colMa = getColIdx(["mahang", "mã hàng", "mã sản phẩm"]);
  const colTen = getColIdx(["tenhang", "tên hàng", "tên sản phẩm"]);
  const colNhom = getColIdx(["manhom", "mã nhóm"]);
  const colDVT = getColIdx(["donvitinh", "đơn vị tính", "dvt"]);
  const colGiaVon = getColIdx(["giavon", "giá vốn"]);
  const colGiaBan = getColIdx(["giaban", "giá bán"]);
  const colIMEI = getColIdx(["coquanlyimei", "quản lý imei", "co_quan_ly_imei"]);
  const colTon = getColIdx(["tonkho", "tồn kho"]);
  const colTT = getColIdx(["trangthai", "trạng thái"]);

  let list = [];
  for (let i = 1; i < rows.length; i++) {
    let r = rows[i];
    
    let ma = colMa > -1 ? String(r[colMa] || "").trim().toUpperCase() : "";
    let ten = colTen > -1 ? String(r[colTen] || "").trim() : "";
    let maNhom = colNhom > -1 ? String(r[colNhom] || "").trim() : "";
    let donViTinh = colDVT > -1 ? String(r[colDVT] || "").trim() : "Cái";
    let giaVon = colGiaVon > -1 ? Number(r[colGiaVon]) || 0 : 0;
    let giaBan = colGiaBan > -1 ? Number(r[colGiaBan]) || 0 : 0;
    let rawImeiFlag = false;
    if (colIMEI > -1) {
      let strIMEI = String(r[colIMEI] || "").trim().toLowerCase();
      rawImeiFlag = (strIMEI === 'có' || strIMEI === 'true' || strIMEI === 'co' || strIMEI === '1');
    }
    let tonKho = colTon > -1 ? Number(r[colTon]) || 0 : 0;
    let trangThai = colTT > -1 ? String(r[colTT] || "").trim() : "Kinh doanh";

    // Fallback nếu không xác định được qua headers
    if (!ma) {
      for (let cell of r) {
        let strVal = String(cell || "").trim();
        let upper = strVal.toUpperCase();
        if (!ma && upper.startsWith("SP")) {
          ma = upper;
        } else if (ma && !ten && strVal.length > 2 && !strVal.includes("NH00") && isNaN(strVal)) {
          ten = strVal;
        } else if (!rawImeiFlag && (strVal.toLowerCase() === 'có' || strVal.toLowerCase() === 'true' || strVal.toLowerCase() === 'co' || strVal === '1')) {
          rawImeiFlag = true;
        } else if (!isNaN(strVal) && Number(strVal) > 1000 && giaBan === 0) {
          giaBan = Number(strVal);
        } else if (!isNaN(strVal) && Number(strVal) >= 0 && Number(strVal) < 1000 && tonKho === 0) {
          tonKho = Number(strVal);
        }
      }
      if (!ma) ma = String(r[0] || "").trim().toUpperCase();
      if (!ma) continue;
      if (!ten) ten = String(r[1] || "").trim();
    }

    // KIỂM TRA QUYỀN IMEI TẦNG KÉP:
    let hasRealIMEIStock = imeiMap[ma] && imeiMap[ma].length > 0;
    let isImei = rawImeiFlag || hasRealIMEIStock;

    // Đối với sản phẩm quản lý theo IMEI: Tồn kho thực tế BẮT BUỘC bằng số lượng IMEI đang tồn trong kho!
    // Tuyệt đối không để số tồn tĩnh cũ trên sheet ghi đè làm sai lệch (ví dụ sheet ghi 7 nhưng chỉ có 1 IMEI tồn -> tồn phải là 1)
    let tonThucTe = isImei 
      ? (hasRealIMEIStock ? imeiMap[ma].length : 0)
      : (Number(tonKho) || 0);

    list.push({
      maHang: ma.slice(0, 50),
      tenHang: ten.slice(0, 255),
      maNhom: maNhom.slice(0, 50),
      donViTinh: (donViTinh || "Cái").slice(0, 50),
      giaVon: Number(giaVon) || 0,
      giaBan: Number(giaBan) || 0,
      coQuanLyIMEI: isImei,
      tonKho: tonThucTe,
      tonIMEI: isImei ? (hasRealIMEIStock ? imeiMap[ma].length : 0) : 0,
      danhSachIMEI: hasRealIMEIStock ? imeiMap[ma] : [],
      trangThai: (trangThai || "Kinh doanh").slice(0, 50)
    });
  }

  return list;
}

// ==================== CẤU HÌNH VÀ TIỆN ÍCH SUPABASE POSTGRESQL (SERVER) ====================
const SUPABASE_CONFIG_SERVER = {
  url: "https://gzcpwwcoaycxqbgrjvzn.supabase.co",
  key: "sb_publishable_kiCUjPVYWcQP7oyrsg3K7g_xySklDFY"
};

function postToSupabaseServer(table, records) {
  try {
    if (!records) return;
    const list = Array.isArray(records) ? records : [records];
    if (!list.length) return;
    const options = {
      method: "post",
      headers: {
        "apikey": SUPABASE_CONFIG_SERVER.key,
        "Authorization": "Bearer " + SUPABASE_CONFIG_SERVER.key,
        "Content-Type": "application/json",
        "Prefer": "resolution=merge-duplicates"
      },
      payload: JSON.stringify(list),
      muteHttpExceptions: true
    };
    UrlFetchApp.fetch(SUPABASE_CONFIG_SERVER.url + "/rest/v1/" + table, options);
  } catch(e) {
    Logger.log("Lỗi đồng bộ ngầm sang Supabase (" + table + "): " + e.message);
  }
}

function patchSupabaseServer(table, filterQuery, payload) {
  try {
    if (!table || !filterQuery || !payload) return;
    const options = {
      method: "patch",
      headers: {
        "apikey": SUPABASE_CONFIG_SERVER.key,
        "Authorization": "Bearer " + SUPABASE_CONFIG_SERVER.key,
        "Content-Type": "application/json",
        "Prefer": "return=minimal"
      },
      payload: JSON.stringify(payload),
      muteHttpExceptions: true
    };
    return UrlFetchApp.fetch(SUPABASE_CONFIG_SERVER.url + "/rest/v1/" + table + "?" + filterQuery, options);
  } catch(e) {
    Logger.log("Lỗi patch sang Supabase (" + table + "): " + e.message);
  }
}

// Lưu đơn hàng POS lên Google Sheets và cập nhật trạng thái IMEI
function apiLuuDonHangPOS(order) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = ss.getSheetByName("DonHang");
  if (!sheet) {
    sheet = ss.insertSheet("DonHang");
    sheet.appendRow(["MaDonHang", "NgayBan", "MaKH", "TenKH", "TongTien", "GiamGia", "KhachPhaiTra", "KhachTra", "HinhThucTT", "ChiTietSanPham", "TrangThai", "NhanVien"]);
  }
  // 👉 KIỂM TRA CHỐNG TRÙNG LẶP: Nếu mã đơn hàng này đã tồn tại trong sheet thì bỏ qua không ghi đúp
  const existingRows = sheet.getDataRange().getValues();
  for (let i = 1; i < existingRows.length; i++) {
    if (String(existingRows[i][0]).trim().toUpperCase() === String(order.maDonHang).trim().toUpperCase()) {
      return { success: true }; // Đã tồn tại, trả về thành công luôn tránh ghi trùng
    }
  }
  sheet.appendRow([
    order.maDonHang,
    order.ngayBan,
    order.maKH,
    order.tenKH,
    order.tongTien,
    order.giamGia,
    order.khachPhaiTra,
    order.khachTra,
    order.hinhThucTT,
    JSON.stringify(order.chiTietSanPham),
    order.trangThai || "HoanThanh",
    order.nhanVien || ""
  ]);
  
  // Tự động chuyển trạng thái IMEI thành "DaBan" trong sheet Kho_IMEI nếu đơn hàng có chọn IMEI
  const sheetIMEI = ss.getSheetByName("Kho_IMEI");
  let soldImeis = [];
  if (sheetIMEI && order.chiTietSanPham) {
    const iRows = sheetIMEI.getDataRange().getValues();
    if (iRows.length > 1) {
      const iHeaders = iRows[0].map(h => String(h || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
      let colIMEI = iHeaders.indexOf("imei") > -1 ? iHeaders.indexOf("imei") : iHeaders.indexOf("serial");
      let colTT = iHeaders.indexOf("trangthai");
      if (colIMEI > -1 && colTT > -1) {
        order.chiTietSanPham.forEach(item => {
          if (item.imeiStr) {
            let imeiArray = String(item.imeiStr).split(/[\n,;\r\t]+/).map(s => s.trim().toUpperCase()).filter(Boolean);
            soldImeis.push(...imeiArray);
            for (let j = 1; j < iRows.length; j++) {
              let imVal = String(iRows[j][colIMEI] || "").trim().toUpperCase();
              if (imeiArray.includes(imVal)) {
                sheetIMEI.getRange(j + 1, colTT + 1).setValue("DaBan");
              }
            }
          }
        });
      }
    }
  }

  // Tự động ghi phiếu thu vào sổ quỹ nếu khách có trả tiền
  let tienKhachTra = Number(order.khachTra) || 0;
  let chiNhanhDon = order.chiNhanh || "CN01: Trụ sở chính Thanh Miện";
  let loaiQuyGhiSo = order.hinhThucTT || "TIEN_MAT";
  if (order.hinhThucTT === "TAI_KHOAN" && order.nganHangNhan) {
    loaiQuyGhiSo = order.nganHangNhan; 
  }
  let maPhieuThu = "PT" + Date.now().toString().slice(-6);

  if (tienKhachTra > 0) {
    let sheetQuy = ss.getSheetByName("SoQuy");
    if (!sheetQuy) {
      sheetQuy = ss.insertSheet("SoQuy");
      sheetQuy.appendRow(["ChiNhanh", "MaPhieu", "LoaiPhieu", "LoaiQuy", "NgayGD", "SoTien", "DoiTuong", "MaDoiTuong", "MaChungTu", "TrangThai", "GhiChu"]);
    }
    
    sheetQuy.appendRow([
      chiNhanhDon,                                       // Cột A: Chi nhánh
      maPhieuThu,                                        // Cột B: Mã phiếu
      "THU",                                              // Cột C: Loại phiếu
      loaiQuyGhiSo,                                       // Cột D: Loại quỹ (Tiền mặt hoặc Tên ngân hàng cụ thể)
      order.ngayBan,                                      // Cột E: Ngày giao dịch
      tienKhachTra,                                       // Cột F: Số tiền (Bắt buộc là kiểu số)
      "Khách hàng",                                       // Cột G: Đối tượng
      order.maKH,                                         // Cột H: Mã đối tượng
      order.maDonHang,                                    // Cột I: Mã chứng từ
      "DaThanhToan",                                      // Cột J: Trạng thái
      "Thu tiền hóa đơn bán lẻ POS " + order.maDonHang + (order.nganHangNhan ? " (" + order.nganHangNhan + ")" : "") // Cột K: Ghi chú
    ]);
  }

  // 👉 ĐỒNG BỘ THỜI GIAN THỰC SANG SUPABASE POSTGRESQL (< 100MS)
  try {
    postToSupabaseServer("don_hang", {
      ma_don_hang: String(order.maDonHang).trim(),
      ngay_ban: order.ngayBan || new Date().toISOString(),
      ma_kh: String(order.maKH || 'KL').trim(),
      ten_kh: String(order.tenKH || 'Khách lẻ').trim(),
      so_dien_thoai: String(order.soDienThoai || '').trim(),
      chi_nhanh: chiNhanhDon,
      tong_tien: Number(order.tongTien) || 0,
      giam_gia: Number(order.giamGia) || 0,
      khach_phai_tra: Number(order.khachPhaiTra) || 0,
      khach_tra: tienKhachTra,
      hinh_thuc_tt: String(order.hinhThucTT || 'TIEN_MAT').trim(),
      ngan_hang_nhan: String(order.nganHangNhan || '').trim(),
      chi_tiet_san_pham: order.chiTietSanPham || [],
      trang_thai: String(order.trangThai || 'Hoàn thành').trim(),
      nhan_vien: String(order.nhanVien || '').trim()
    });

    if (tienKhachTra > 0) {
      postToSupabaseServer("so_quy", {
        chi_nhanh: chiNhanhDon,
        ma_phieu: maPhieuThu,
        loai_phieu: "THU",
        loai_quy: loaiQuyGhiSo,
        ngay_gd: order.ngayBan || new Date().toISOString(),
        so_tien: tienKhachTra,
        doi_tuong: "Khách hàng",
        ma_doi_tuong: String(order.maKH || ""),
        ma_chung_tu: String(order.maDonHang || ""),
        trang_thai: "DaThanhToan",
        ghi_chu: "Thu tiền hóa đơn bán lẻ POS " + order.maDonHang + (order.nganHangNhan ? " (" + order.nganHangNhan + ")" : "")
      });
    }

    if (soldImeis.length > 0) {
      soldImeis.forEach(im => {
        postToSupabaseServer("kho_imei", {
          imei: im,
          trang_thai: "DaBan",
          ma_don_ban: String(order.maDonHang)
        });
      });
    }
  } catch(eSup) {
    Logger.log("Lỗi đồng bộ Supabase cho đơn POS: " + eSup.message);
  }

  return { success: true };
}

// Cập nhật thông tin ngày giờ & người bán của hóa đơn đã bán
function apiCapNhatThongTinDonHang(payload) {
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    if (!ss) return { success: false, error: "Không tìm thấy Spreadsheet" };
    const maDonHang = String(payload.maDonHang || '').trim();
    if (!maDonHang) return { success: false, error: "Thiếu mã đơn hàng" };

    // Cập nhật thông tin trong sheet DonHang và GiaoDich_DonHang
    ["DonHang", "GiaoDich_DonHang"].forEach(sheetName => {
      let sheet = ss.getSheetByName(sheetName);
      if (!sheet) {
        ss.getSheets().forEach(s => {
          let n = s.getName().toLowerCase().replace(/[\s_]+/g, '');
          if (n === sheetName.toLowerCase().replace(/[\s_]+/g, '')) sheet = s;
        });
      }

      if (sheet) {
        const rows = sheet.getDataRange().getValues();
        let headers = rows[0].map(h => String(h || '').toLowerCase().replace(/[\s_]+/g, ''));
        let colMa = headers.indexOf("madonhang") > -1 ? headers.indexOf("madonhang") : headers.indexOf("madon");
        let colNgay = headers.indexOf("ngayban") > -1 ? headers.indexOf("ngayban") : (headers.indexOf("ngay") > -1 ? headers.indexOf("ngay") : headers.indexOf("ngaytao"));
        let colNV = headers.indexOf("nhanvien") > -1 ? headers.indexOf("nhanvien") : headers.indexOf("nguoiban");

        if (colMa === -1) colMa = 0;
        if (colNgay === -1) colNgay = 1;
        if (colNV === -1) colNV = 11;

        for (let i = 1; i < rows.length; i++) {
          if (String(rows[i][colMa] || '').trim().toUpperCase() === maDonHang.toUpperCase()) {
            if (payload.ngayBan && colNgay > -1) {
              sheet.getRange(i + 1, colNgay + 1).setValue(payload.ngayBan);
            }
            if (payload.nhanVien && colNV > -1) {
              sheet.getRange(i + 1, colNV + 1).setValue(payload.nhanVien);
            }
            break;
          }
        }
      }
    });

    // Cập nhật ngày giờ trong SoQuy nếu có phiếu thu tương ứng
    let sheetQuy = ss.getSheetByName("SoQuy");
    if (sheetQuy && payload.ngayBan) {
      const qRows = sheetQuy.getDataRange().getValues();
      if (qRows.length > 1) {
        let qHeaders = qRows[0].map(h => String(h || '').toLowerCase().replace(/[\s_]+/g, ''));
        let colChungTu = qHeaders.indexOf("machungtu");
        let colNgayGD = qHeaders.indexOf("ngaygd") > -1 ? qHeaders.indexOf("ngaygd") : qHeaders.indexOf("ngay");
        if (colChungTu > -1 && colNgayGD > -1) {
          for (let k = 1; k < qRows.length; k++) {
            if (String(qRows[k][colChungTu] || '').trim().toUpperCase() === maDonHang.toUpperCase()) {
              sheetQuy.getRange(k + 1, colNgayGD + 1).setValue(payload.ngayBan);
              break;
            }
          }
        }
      }
    }

    // Cập nhật sang Supabase
    try {
      let sbDate = payload.ngayBanISO || payload.ngayBan;
      if (!payload.ngayBanISO) {
        try {
          let dDate = new Date(payload.ngayBan);
          if (!isNaN(dDate.getTime())) sbDate = dDate.toISOString();
        } catch(eD) {}
      }
      if (typeof patchSupabaseServer === 'function') {
        patchSupabaseServer("don_hang", "ma_don_hang=eq." + encodeURIComponent(maDonHang), {
          ngay_ban: sbDate,
          nhan_vien: payload.nhanVien
        });
        patchSupabaseServer("so_quy", "ma_chung_tu=eq." + encodeURIComponent(maDonHang), {
          ngay_gd: sbDate
        });
      }
    } catch(eSup) {}

    return { success: true };
  } catch(err) {
    Logger.log("Lỗi apiCapNhatThongTinDonHang: " + err.message);
    return { success: false, error: err.message };
  }
}

// Lấy danh sách toàn bộ đơn hàng đã bán từ Google Sheets (hỗ trợ cả sheet DonHang và GiaoDich_DonHang)
function apiGetDanhSachDonHang() {
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    if (!ss) return [];

    const timeZone = ss.getSpreadsheetTimeZone() || "GMT+7";

    // 1. Lấy danh sách đối tác để lấy SĐT và địa chỉ của khách hàng
    let customerMap = {};
    let sheetDT = ss.getSheetByName("DM_DoiTac");
    if (!sheetDT) {
      ss.getSheets().forEach(s => {
        let n = s.getName().toLowerCase().replace(/[\s_]+/g, '');
        if (n === "dmdoitac" || n === "doitac") sheetDT = s;
      });
    }
    if (sheetDT) {
      let rowsDT = sheetDT.getDataRange().getValues();
      for (let k = 1; k < rowsDT.length; k++) {
        let m = String(rowsDT[k][0] || "").trim().toUpperCase();
        if (m) {
          customerMap[m] = {
            ten: String(rowsDT[k][2] || "").trim(),
            sdt: String(rowsDT[k][3] || "").trim(),
            diaChi: String(rowsDT[k][4] || "").trim()
          };
        }
      }
    }

    // 2. Lấy danh mục hàng hóa để dự phòng tên hàng
    let hangHoaMap = {};
    let sheetHang = ss.getSheetByName("DM_HangHoa") || ss.getSheetByName("HangHoa");
    if (sheetHang) {
      let rowsH = sheetHang.getDataRange().getValues();
      for (let h = 1; h < rowsH.length; h++) {
        let m = String(rowsH[h][0] || "").trim().toUpperCase();
        if (m) hangHoaMap[m] = String(rowsH[h][1] || "").trim();
      }
    }

    let result = [];
    let seenMaDon = new Set();

    // 3. Đọc từ sheet DonHang (cấu trúc POS chuẩn)
    let sheetDon = ss.getSheetByName("DonHang");
    if (!sheetDon) {
      ss.getSheets().forEach(s => {
        let n = s.getName().toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/đ/g, "d").replace(/[\s_]+/g, "");
        if (n === "donhang") sheetDon = s;
      });
    }

    if (sheetDon) {
      const rows = sheetDon.getDataRange().getValues();
      if (rows && rows.length > 1) {
        for (let i = 1; i < rows.length; i++) {
          let r = rows[i];
          if (!r || !r[0]) continue;
          let maDon = String(r[0] || "").trim();
          if (!maDon) continue;
          let rNV = String(r[11] || "").trim().toLowerCase();
          if (maDon.toUpperCase().startsWith("PNH") || maDon.toUpperCase().startsWith("DDH") || rNV === "hệ thống tự động" || rNV === "he thong tu dong") continue;
          seenMaDon.add(maDon.toUpperCase());

          let chiTiet = [];
          try {
            if (typeof r[9] === 'string' && r[9].trim().startsWith('[')) {
              chiTiet = JSON.parse(r[9]);
            } else if (Array.isArray(r[9])) {
              chiTiet = r[9];
            }
          } catch(e) {
            chiTiet = [];
          }

          chiTiet = chiTiet.map(item => {
            let imeisArray = [];
            if (item.imeiStr && typeof item.imeiStr === 'string') {
              imeisArray = String(item.imeiStr).split(/[\n,;\r\t]+/).map(s => s.trim()).filter(Boolean);
            } else if (Array.isArray(item.danhSachIMEI)) {
              imeisArray = item.danhSachIMEI;
            } else if (Array.isArray(item.imeiList)) {
              imeisArray = item.imeiList;
            }
            let maH = String(item.maHang || "").trim();
            let tenH = String(item.tenHang || hangHoaMap[maH.toUpperCase()] || maH);
            return {
              maHang: maH,
              tenHang: tenH,
              soLuong: Number(item.soLuong) || 1,
              donGia: Number(item.donGia) || 0,
              thanhTien: Number(item.thanhTien) || ((Number(item.soLuong) || 1) * (Number(item.donGia) || 0)),
              hasIMEI: Boolean(item.hasIMEI || imeisArray.length > 0),
              imeiStr: item.imeiStr || imeisArray.join(', '),
              danhSachIMEI: imeisArray
            };
          });

          let maKH = String(r[2] || "").trim();
          let custInfo = customerMap[maKH.toUpperCase()] || {};
          let tenKH = String(r[3] || custInfo.ten || "Khách lẻ");
          let soDienThoai = custInfo.sdt || "";

          let ngayStr = "";
          if (r[1] instanceof Date) {
            ngayStr = Utilities.formatDate(r[1], timeZone, "yyyy-MM-dd HH:mm:ss");
          } else {
            ngayStr = String(r[1] || "");
          }

          result.push({
            maDonHang: maDon,
            ngayBan: ngayStr,
            maKH: maKH,
            tenKH: tenKH,
            soDienThoai: soDienThoai,
            tongTien: Number(r[4]) || 0,
            giamGia: Number(r[5]) || 0,
            khachPhaiTra: Number(r[6]) || Number(r[4]) || 0,
            khachTra: Number(r[7]) || 0,
            hinhThucTT: String(r[8] || "TIEN_MAT"),
            chiTietSanPham: chiTiet,
            trangThai: String(r[10] || "Hoàn thành"),
            nhanVien: String(r[11] || "")
          });
        }
      }
    }

    // 4. Đọc thêm từ sheet GiaoDich_DonHang nếu có (để lấy trọn vẹn toàn bộ đơn)
    let sheetGD = ss.getSheetByName("GiaoDich_DonHang");
    if (!sheetGD) {
      ss.getSheets().forEach(s => {
        let n = s.getName().toLowerCase().replace(/[\s_]+/g, '');
        if (n === "giaodichdonhang") sheetGD = s;
      });
    }

    if (sheetGD) {
      let sheetCT = ss.getSheetByName("ChiTiet_DonHang");
      let ctMap = {};
      if (sheetCT) {
        let ctRows = sheetCT.getDataRange().getValues();
        for (let c = 1; c < ctRows.length; c++) {
          let rCT = ctRows[c];
          let maD = String(rCT[1] || "").trim();
          if (!maD) continue;
          if (!ctMap[maD]) ctMap[maD] = [];

          let imeiList = [];
          if (rCT[6]) {
            let imRaw = String(rCT[6]).trim();
            if (imRaw.startsWith('[')) {
              try { imeiList = JSON.parse(imRaw); } catch(e) { imeiList = [imRaw]; }
            } else if (imRaw) {
              imeiList = imRaw.split(',').map(s => s.trim()).filter(Boolean);
            }
          }
          let mHang = String(rCT[2] || "").trim();
          ctMap[maD].push({
            maHang: mHang,
            tenHang: hangHoaMap[mHang.toUpperCase()] || mHang,
            soLuong: Number(rCT[3]) || 1,
            donGia: Number(rCT[4]) || 0,
            thanhTien: (Number(rCT[3]) || 1) * (Number(rCT[4]) || 0),
            hasIMEI: imeiList.length > 0,
            imeiStr: imeiList.join(', '),
            danhSachIMEI: imeiList
          });
        }
      }

      let gdRows = sheetGD.getDataRange().getValues();
      for (let g = 1; g < gdRows.length; g++) {
        let rG = gdRows[g];
        let maDon = String(rG[0] || "").trim();
        if (!maDon || seenMaDon.has(maDon.toUpperCase())) continue;
        seenMaDon.add(maDon.toUpperCase());

        let maKH = String(rG[3] || "").trim();
        let custInfo = customerMap[maKH.toUpperCase()] || {};
        let tenKH = custInfo.ten || "Khách lẻ";
        let sdt = custInfo.sdt || "";

        let ngayStr = "";
        if (rG[2] instanceof Date) {
          ngayStr = Utilities.formatDate(rG[2], timeZone, "yyyy-MM-dd HH:mm:ss");
        } else {
          ngayStr = String(rG[2] || "");
        }

        result.push({
          maDonHang: maDon,
          ngayBan: ngayStr,
          maKH: maKH,
          tenKH: tenKH,
          soDienThoai: sdt,
          tongTien: Number(rG[5]) || 0,
          giamGia: Number(rG[6]) || 0,
          khachPhaiTra: Number(rG[5]) || 0,
          khachTra: Number(rG[7]) || 0,
          hinhThucTT: String(rG[8] || "TIEN_MAT"),
          chiTietSanPham: ctMap[maDon] || [],
          trangThai: String(rG[9] || "Hoàn thành"),
          nhanVien: String(rG[4] || "")
        });
      }
    }

    return result.reverse(); // Đảo ngược để đơn mới nhất lên đầu
  } catch (err) {
    return [{ maDonHang: "EXCEPTION", ngayBan: "", maKH: "", tenKH: "❌ Lỗi hệ thống: " + err.toString(), tongTien: 0, khachTra: 0, trangThai: "Lỗi", chiTietSanPham: [] }];
  }
}

// Xóa một hoặc nhiều đơn hàng theo danh sách mã
function apiXoaDonHang(maDonList) {
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    let sheetDon = ss.getSheetByName("DonHang");
    let sheetHang = ss.getSheetByName("HangHoa") || ss.getSheetByName("DM_HangHoa");
    
    if (!sheetDon) return { success: false, error: "Không tìm thấy sheet DonHang" };
    
    const rowsDon = sheetDon.getDataRange().getValues();
    let count = 0;
    
    // Duyệt từ dưới lên để xóa dòng an toàn không bị lệch index
    for (let i = rowsDon.length - 1; i >= 1; i--) {
      let r = rowsDon[i];
      let maDon = String(r[0] || "").trim();
      
      if (maDonList.includes(maDon)) {
        // 1. Phục hồi tồn kho trước khi xóa đơn hàng
        let chiTietJson = r[9]; // Cột J (Index 9) chứa JSON chi tiết sản phẩm của đơn hàng
        try {
          let chiTiet = typeof chiTietJson === 'string' ? JSON.parse(chiTietJson) : (chiTietJson || []);
          if (Array.isArray(chiTiet) && chiTiet.length > 0 && sheetHang) {
            let rowsHang = sheetHang.getDataRange().getValues();
            let headerHang = rowsHang[0].map(h => String(h).trim().toLowerCase());
            
            // Tìm vị trí cột Mã hàng và Tồn kho tự động
            let idxMaHang = headerHang.findIndex(h => h.includes('ma') && (h.includes('hang') || h.includes('sp')));
            if (idxMaHang === -1) idxMaHang = 0; // Mặc định Cột A
            
            let idxTonKho = headerHang.findIndex(h => h.includes('ton') || h.includes('kho') || h.includes('soluong'));
            if (idxTonKho === -1) idxTonKho = 6; // Mặc định Cột G (hoặc điều chỉnh theo sheet của bạn)
            
            // Cộng ngược số lượng từng sản phẩm về kho
            chiTiet.forEach(item => {
              let itemMa = String(item.maHang || "").trim().toUpperCase();
              let itemSL = Number(item.soLuong) || 0;
              
              for (let j = 1; j < rowsHang.length; j++) {
                let sheetMa = String(rowsHang[j][idxMaHang] || "").trim().toUpperCase();
                if (sheetMa === itemMa) {
                  let currentTon = Number(rowsHang[j][idxTonKho]) || 0;
                  let newTon = currentTon + itemSL;
                  sheetHang.getRange(j + 1, idxTonKho + 1).setValue(newTon);
                  break;
                }
              }
            });
          }
        } catch(e) {
          Logger.log("Lỗi phân tích chi tiết sản phẩm để hồi kho: " + e.toString());
        }
        
        // 2. Xóa dòng đơn hàng khỏi sheet DonHang
        sheetDon.deleteRow(i + 1);
        count++;
      }
    }
    
    return { success: true, count: count };
  } catch (err) {
    return { success: false, error: err.toString() };
  }
}

// Lưu phiếu khách trả hàng: Hồi tồn kho, cập nhật IMEI, ghi phiếu chi sổ quỹ, ghi nhận phiếu trả
function apiLuuPhieuTraHangKhach(payload) {
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    if (!ss) return { success: false, error: "Không tìm thấy Spreadsheet đang hoạt động!" };
    
    if (!payload || !payload.maDonHangGoc || !payload.danhSachTra || !payload.danhSachTra.length) {
      return { success: false, error: "Dữ liệu trả hàng không hợp lệ hoặc danh sách hàng trả trống!" };
    }

    const timeZone = ss.getSpreadsheetTimeZone() || "GMT+7";
    const ngayHienTai = Utilities.formatDate(new Date(), timeZone, "yyyy-MM-dd HH:mm:ss");
    const maPhieuTra = payload.maPhieuTra || ("TH" + Date.now().toString().slice(-6));
    const maDonGoc = String(payload.maDonHangGoc || "").trim();

    // 👉 CHỐNG GHI ĐÚP: Nếu mã phiếu trả này đã tồn tại trong DonHang thì bỏ qua ngay lập tức
    let sheetDonCheck = ss.getSheetByName("DonHang");
    if (sheetDonCheck) {
      const existingRows = sheetDonCheck.getDataRange().getValues();
      for (let i = 1; i < existingRows.length; i++) {
        if (String(existingRows[i][0] || "").trim().toUpperCase() === maPhieuTra.toUpperCase()) {
          return { success: true, maPhieuTra: maPhieuTra, daTonTai: true };
        }
      }
    }
    const chiNhanh = payload.chiNhanh || "CN01: Trụ sở chính Thanh Miện";
    const tongTienHoan = Number(payload.tongTienHoan) || 0;
    const hinhThucTT = payload.hinhThucTT || "TIEN_MAT";
    const nganHangChi = payload.nganHangChi || "";
    const lyDoTra = payload.lyDoTra || "Khách trả hàng";
    const nhanVien = payload.nhanVien || "Quản trị viên";
    const maKH = String(payload.maKH || "").trim();
    const tenKH = String(payload.tenKH || "Khách lẻ").trim();
    const danhSachTra = payload.danhSachTra || [];

    // Hàm chuẩn hóa chuỗi tiếng Việt để so khớp tiêu đề cột chính xác
    const cleanHeaderStr = (str) => {
      return String(str || "").toLowerCase().trim()
        .normalize("NFD").replace(/[\u0300-\u036f]/g, "")
        .replace(/đ/g, "d").replace(/[\s_-]+/g, "");
    };

    // --- 1. PHỤC HỒI TỒN KHO TRONG DM_HangHoa ---
    const sheetHang = ss.getSheetByName("DM_HangHoa") || ss.getSheetByName("HangHoa");
    if (sheetHang) {
      const rowsHang = sheetHang.getDataRange().getValues();
      if (rowsHang.length > 1) {
        const headerHang = rowsHang[0].map(cleanHeaderStr);
        let idxMa = -1;
        let idxTon = -1;

        // Quét tìm cột Mã hàng
        for (let c = 0; c < headerHang.length; c++) {
          let h = headerHang[c];
          if (idxMa === -1 && (h === "mahang" || h === "masanpham" || h === "ma" || h.includes("mahang") || h.includes("masanpham"))) {
            idxMa = c;
          }
          if (idxTon === -1 && (h === "tonkho" || h === "soluongton" || h === "ton" || h.includes("tonkho") || h.includes("soluong"))) {
            idxTon = c;
          }
        }

        // Fallback vị trí cột nếu không tìm thấy trong tiêu đề
        if (idxMa === -1) idxMa = 1; // Cột B (index 1)
        if (idxTon === -1) {
          idxTon = (headerHang.length >= 9) ? 8 : 7; // Cột I (index 8) hoặc Cột H (index 7)
        }

        danhSachTra.forEach(item => {
          let itemMa = String(item.maHang || "").trim().toUpperCase();
          let itemSL = Number(item.soLuongTra) || Number(item.soLuong) || 0;
          if (!itemMa || itemSL <= 0) return;

          let targetRow = -1;
          for (let j = 1; j < rowsHang.length; j++) {
            let rowVals = rowsHang[j];
            // 1. Kiểm tra trực tiếp tại cột idxMa
            if (idxMa > -1 && String(rowVals[idxMa] || "").trim().toUpperCase() === itemMa) {
              targetRow = j + 1;
              break;
            }
            // 2. Quét mọi cột trong dòng nếu idxMa chưa trúng
            for (let c = 0; c < rowVals.length; c++) {
              if (String(rowVals[c] || "").trim().toUpperCase() === itemMa) {
                targetRow = j + 1;
                idxMa = c; // Khóa lại cột mã chuẩn
                break;
              }
            }
            if (targetRow > -1) break;
          }

          if (targetRow > -1) {
            let curTon = Number(rowsHang[targetRow - 1][idxTon]) || 0;
            let newTon = curTon + itemSL;
            sheetHang.getRange(targetRow, idxTon + 1).setValue(newTon);
            rowsHang[targetRow - 1][idxTon] = newTon; // Cập nhật bộ nhớ tạm
          }
        });

        SpreadsheetApp.flush();
      }
    }

    // --- 2. CẬP NHẬT TRẠNG THÁI IMEI VỀ "TrongKho" TRONG Kho_IMEI ---
    const sheetIMEI = ss.getSheetByName("Kho_IMEI");
    let allImeisToRestore = [];
    danhSachTra.forEach(item => {
      if (Array.isArray(item.imeiList)) {
        item.imeiList.forEach(im => {
          let clean = String(im || "").trim().toUpperCase();
          if (clean) allImeisToRestore.push(clean);
        });
      } else if (typeof item.imeiStr === 'string' && item.imeiStr) {
        String(item.imeiStr).split(/[\n,;\r\t]+/).map(s => s.trim().toUpperCase()).filter(Boolean).forEach(im => {
          allImeisToRestore.push(im);
        });
      }
    });

    if (sheetIMEI && allImeisToRestore.length > 0) {
      const rowsIMEI = sheetIMEI.getDataRange().getValues();
      if (rowsIMEI.length > 1) {
        const headerIMEI = rowsIMEI[0].map(cleanHeaderStr);
        let colIMEI = -1;
        let colTT = -1;
        let colNgay = -1;

        for (let c = 0; c < headerIMEI.length; c++) {
          let h = headerIMEI[c];
          if (colIMEI === -1 && (h.includes("imei") || h.includes("serial"))) colIMEI = c;
          if (colTT === -1 && (h.includes("trangthai") || h.includes("status"))) colTT = c;
          if (colNgay === -1 && (h.includes("ngaycapnhat") || h.includes("ngaynhap") || h.includes("ngay"))) colNgay = c;
        }

        if (colIMEI > -1 && colTT > -1) {
          for (let r = 1; r < rowsIMEI.length; r++) {
            let imVal = String(rowsIMEI[r][colIMEI] || "").trim().toUpperCase();
            if (allImeisToRestore.includes(imVal)) {
              sheetIMEI.getRange(r + 1, colTT + 1).setValue("TrongKho");
              if (colNgay > -1) {
                sheetIMEI.getRange(r + 1, colNgay + 1).setValue(new Date());
              }
            }
          }
          SpreadsheetApp.flush();
        }
      }
    }

    // --- 3. GHI PHIẾU CHI VÀO SỔ QUỸ NẾU CÓ HOÀN TIỀN CHO KHÁCH ---
    if (tongTienHoan > 0) {
      let sheetQuy = ss.getSheetByName("SoQuy");
      if (!sheetQuy) {
        sheetQuy = ss.insertSheet("SoQuy");
        sheetQuy.appendRow(["ChiNhanh", "MaPhieu", "LoaiPhieu", "LoaiQuy", "NgayGD", "SoTien", "DoiTuong", "MaDoiTuong", "MaChungTu", "TrangThai", "GhiChu"]);
      }

      let loaiQuyChi = hinhThucTT || "TIEN_MAT";
      if (hinhThucTT === "TAI_KHOAN" && nganHangChi) {
        loaiQuyChi = nganHangChi;
      }

      const maPhieuChi = "PC" + Date.now().toString().slice(-6);
      sheetQuy.appendRow([
        chiNhanh,                                             // Cột A: Chi nhánh
        maPhieuChi,                                           // Cột B: Mã phiếu chi
        "CHI",                                                // Cột C: Loại phiếu (CHI)
        loaiQuyChi,                                           // Cột D: Loại quỹ (TIEN_MAT hoặc Tên NH)
        ngayHienTai,                                          // Cột E: Ngày giao dịch
        tongTienHoan,                                         // Cột F: Số tiền hoàn trả (Number)
        "Khách hàng",                                         // Cột G: Đối tượng
        maKH,                                                 // Cột H: Mã đối tượng
        maPhieuTra,                                           // Cột I: Mã chứng từ phiếu trả
        "DaThanhToan",                                        // Cột J: Trạng thái
        "Chi hoàn tiền khách trả hàng - Đơn gốc: " + maDonGoc + (lyDoTra ? " (" + lyDoTra + ")" : "") // Cột K: Ghi chú
      ]);
    }

    // --- 4. GHI PHIẾU TRẢ HÀNG VÀO SHEET DonHang VÀ CẬP NHẬT TRẠNG THÁI ĐƠN GỐC ---
    let sheetDon = ss.getSheetByName("DonHang");
    if (!sheetDon) {
      sheetDon = ss.insertSheet("DonHang");
      sheetDon.appendRow(["MaDonHang", "NgayBan", "MaKH", "TenKH", "TongTien", "GiamGia", "KhachPhaiTra", "KhachTra", "HinhThucTT", "ChiTietSanPham", "TrangThai", "NhanVien"]);
    }

    // Chuẩn bị chi tiết sản phẩm trả
    let chiTietLuu = danhSachTra.map(it => ({
      maHang: it.maHang,
      tenHang: it.tenHang,
      soLuong: Number(it.soLuongTra) || Number(it.soLuong) || 0,
      donGia: Number(it.donGia) || 0,
      thanhTien: Number(it.thanhTienTra) || ((Number(it.soLuongTra) || 0) * (Number(it.donGia) || 0)),
      imeiStr: Array.isArray(it.imeiList) ? it.imeiList.join(', ') : (it.imeiStr || "")
    }));

    // Ghi dòng phiếu trả hàng vào sheet DonHang
    sheetDon.appendRow([
      maPhieuTra,
      ngayHienTai,
      maKH,
      tenKH,
      tongTienHoan,
      0,
      tongTienHoan,
      tongTienHoan,
      hinhThucTT,
      JSON.stringify(chiTietLuu),
      "Khách trả hàng",
      nhanVien
    ]);

    // Cập nhật trạng thái của đơn hàng gốc trong sheet DonHang
    const rowsDon = sheetDon.getDataRange().getValues();
    for (let i = 1; i < rowsDon.length; i++) {
      if (String(rowsDon[i][0] || "").trim().toUpperCase() === maDonGoc.toUpperCase()) {
        let curTT = String(rowsDon[i][10] || "");
        sheetDon.getRange(i + 1, 11).setValue(curTT.includes("Trả hàng") ? curTT : (curTT + " (Có trả hàng)"));
        break;
      }
    }

    // Cập nhật trạng thái của đơn hàng gốc trong sheet GiaoDich_DonHang nếu có
    let sheetGD = ss.getSheetByName("GiaoDich_DonHang");
    if (!sheetGD) {
      ss.getSheets().forEach(s => {
        let n = s.getName().toLowerCase().replace(/[\s_]+/g, '');
        if (n === "giaodichdonhang") sheetGD = s;
      });
    }
    if (sheetGD) {
      const rowsGD = sheetGD.getDataRange().getValues();
      for (let g = 1; g < rowsGD.length; g++) {
        if (String(rowsGD[g][0] || "").trim().toUpperCase() === maDonGoc.toUpperCase()) {
          let curTT = String(rowsGD[g][9] || "");
          sheetGD.getRange(g + 1, 10).setValue(curTT.includes("Trả hàng") ? curTT : (curTT + " (Có trả hàng)"));
          break;
        }
      }
    }

    // 👉 ĐỒNG BỘ THỜI GIAN THỰC SANG SUPABASE POSTGRESQL (< 100MS)
    try {
      postToSupabaseServer("phieu_tra_hang", {
        ma_phieu_tra: maPhieuTra,
        ma_don_goc: maDonGoc,
        ngay_tra: new Date().toISOString(),
        ma_kh: maKH,
        ten_kh: tenKH,
        so_dien_thoai: String(payload.soDienThoai || ''),
        chi_nhanh: chiNhanh,
        danh_sach_tra: danhSachTra,
        tong_tien_hoan: tongTienHoan,
        phi_khau_tru: Number(payload.phiKhauTru) || 0,
        hinh_thuc_tt: hinhThucTT,
        ngan_hang_chi: nganHangChi,
        ly_do_tra: lyDoTra,
        nhan_vien: nhanVien
      });

      postToSupabaseServer("don_hang", {
        ma_don_hang: maPhieuTra,
        ngay_ban: new Date().toISOString(),
        ma_kh: maKH,
        ten_kh: tenKH,
        so_dien_thoai: String(payload.soDienThoai || ''),
        chi_nhanh: chiNhanh,
        tong_tien: tongTienHoan,
        giam_gia: 0,
        khach_phai_tra: tongTienHoan,
        khach_tra: tongTienHoan,
        hinh_thuc_tt: hinhThucTT,
        ngan_hang_nhan: nganHangChi,
        chi_tiet_san_pham: chiTietLuu,
        trang_thai: "Khách trả hàng",
        nhan_vien: nhanVien
      });

      if (tongTienHoan > 0) {
        let loaiQuyChi = hinhThucTT || "TIEN_MAT";
        if (hinhThucTT === "TAI_KHOAN" && nganHangChi) {
          loaiQuyChi = nganHangChi;
        }
        postToSupabaseServer("so_quy", {
          chi_nhanh: chiNhanh,
          ma_phieu: "PC" + Date.now().toString().slice(-6),
          loai_phieu: "CHI",
          loai_quy: loaiQuyChi,
          ngay_gd: new Date().toISOString(),
          so_tien: tongTienHoan,
          doi_tuong: "Khách hàng",
          ma_doi_tuong: maKH,
          ma_chung_tu: maPhieuTra,
          trang_thai: "DaThanhToan",
          ghi_chu: "Chi hoàn tiền khách trả hàng - Đơn gốc: " + maDonGoc + (lyDoTra ? " (" + lyDoTra + ")" : "")
        });
      }

      if (allImeisToRestore && allImeisToRestore.length > 0) {
        allImeisToRestore.forEach(im => {
          postToSupabaseServer("kho_imei", {
            imei: im,
            trang_thai: "TrongKho"
          });
        });
      }
    } catch(eSup) {
      Logger.log("Lỗi đồng bộ Supabase cho phiếu trả hàng: " + eSup.message);
    }

    SpreadsheetApp.flush();

    return { 
      success: true, 
      maPhieuTra: maPhieuTra,
      maDonGoc: maDonGoc,
      ngayTra: ngayHienTai,
      tongTienHoan: tongTienHoan
    };
  } catch (err) {
    return { success: false, error: err.toString() };
  }
}

// ==================== QUẢN LÝ TÀI KHOẢN NGÂN HÀNG ====================

function apiGetDanhSachNganHang() {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = ss.getSheetByName("DM_NganHang");
  if (!sheet) {
    sheet = ss.insertSheet("DM_NganHang");
    sheet.appendRow(["MaNH", "TenNH", "SoTK", "ChuTK", "GhiChu"]);
    // Tạo mẫu mặc định
    sheet.appendRow(["VCB", "Ngân hàng Vietcombank", "1234567890", "NGUYEN THANH TUNG", "Tài khoản chính kinh doanh"]);
  }
  const rows = sheet.getDataRange().getValues();
  if (rows.length < 2) return [];
  
  let result = [];
  for (let i = 1; i < rows.length; i++) {
    let r = rows[i];
    if (!r[0]) continue;
    result.push({
      maNH: String(r[0]),
      tenNH: String(r[1]),
      soTK: String(r[2]),
      chuTK: String(r[3]),
      ghiChu: String(r[4] || "")
    });
  }
  return result;
}

function apiLuuNganHang(acc) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = ss.getSheetByName("DM_NganHang");
  if (!sheet) {
    sheet = ss.insertSheet("DM_NganHang");
    sheet.appendRow(["MaNH", "TenNH", "SoTK", "ChuTK", "GhiChu"]);
  }
  const rows = sheet.getDataRange().getValues();
  let foundRow = -1;
  for (let i = 1; i < rows.length; i++) {
    if (String(rows[i][0]).trim().toUpperCase() === String(acc.maNH).trim().toUpperCase()) {
      foundRow = i + 1;
      break;
    }
  }
  
  if (foundRow > -1) {
    sheet.getRange(foundRow, 1, 1, 5).setValues([[
      acc.maNH, acc.tenNH, acc.soTK, acc.chuTK, acc.ghiChu
    ]]);
  } else {
    sheet.appendRow([acc.maNH, acc.tenNH, acc.soTK, acc.chuTK, acc.ghiChu]);
  }
  return { success: true };
}

function apiXoaNganHang(maList) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = ss.getSheetByName("DM_NganHang");
  if (!sheet) return { success: false };
  const rows = sheet.getDataRange().getValues();
  let count = 0;
  for (let i = rows.length - 1; i >= 1; i--) {
    if (maList.includes(String(rows[i][0]).trim())) {
      sheet.deleteRow(i + 1);
      count++;
    }
  }
  return { success: true, count: count };
}


/**
 * API LẤY CHI TIẾT SỔ QUỸ & TÍNH KPI CHUẨN XÁC THEO TỪNG QUỸ
 * Khớp 100% với Frontend và tự động định vị tiêu đề cột chống lệch dòng
 */
function apiGetChiTietSoQuy(loaiQuy) {
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    if (typeof dongBoTienCocDonDatHang === 'function') {
      dongBoTienCocDonDatHang(ss);
    }
    let sheet = ss.getSheetByName("SoQuy");
    
    // Nếu chưa có sheet, tự động khởi tạo cấu trúc chuẩn 11 cột
    if (!sheet) {
      sheet = ss.insertSheet("SoQuy");
      sheet.appendRow(["ChiNhanh", "MaPhieu", "LoaiPhieu", "LoaiQuy", "NgayGD", "SoTien", "DoiTuong", "MaDoiTuong", "MaChungTu", "TrangThai", "GhiChu"]);
      return { dauKy: 0, tongThu: 0, tongChi: 0, tonQuy: 0, danhSach: [] };
    }
    const values = sheet.getDataRange().getValues();
    if (values.length <= 1) {
      return { dauKy: 0, tongThu: 0, tongChi: 0, tonQuy: 0, danhSach: [] };
    }
    // 1. Quét tìm vị trí cột linh hoạt (tự động loại bỏ dấu, khoảng trắng, viết hoa/thường)
    const headers = values[0].map(h => String(h || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
    
    const findCol = (keywords) => {
      for (let kw of keywords) {
        let cleanKw = kw.toLowerCase().replace(/[\s_]+/g, '');
        let idx = headers.indexOf(cleanKw);
        if (idx > -1) return idx;
      }
      return -1;
    };
    const col = {
      chiNhanh:     findCol(["chinhanh", "chi nhánh"]),
      maPhieu:      findCol(["maphieu", "mã phiếu"]),
      loaiPhieu:    findCol(["loaiphieu", "loại phiếu"]),
      loaiQuy:      findCol(["loaiquy", "quỹ nguồn", "loại quỹ", "hinhthuctt", "hinhthuc"]),
      ngayGD:       findCol(["ngaygd", "ngaygiaodich", "ngày giao dịch", "ngày", "ngay"]),
      soTien:       findCol(["sotien", "số tiền", "tongtien"]),
      doiTuong:     findCol(["doituong", "đối tượng", "doitac"]),
      maDoiTuong:   findCol(["madoituong", "mã đối tượng", "madoitac"]),
      maChungTu:    findCol(["machungtu", "mã chứng từ", "madonhang"]),
      trangThai:    findCol(["trangthai", "trạng thái"]),
      ghiChu:       findCol(["ghichu", "ghi chú", "lydothuchi"])
    };
    const timeZone = Session.getScriptTimeZone() || "Asia/Ho_Chi_Minh";
    let allRows = [];
    let tongThu = 0;
    let tongChi = 0;
    const dauKy = 0; // Tồn đầu kỳ mặc định là 0 đ khi chưa phát sinh giao dịch

    // Hàm kiểm tra có phải tiền mặt không (chống lệch dấu tiếng Việt)
    const checkIsTienMat = (val) => {
      if (!val) return true;
      let s = String(val).toLowerCase().trim()
        .normalize("NFD").replace(/[\u0300-\u036f]/g, "")
        .replace(/[\s_-]+/g, "");
      return s === "tienmat" || s === "tm";
    };

    // 2. Duyệt dữ liệu từ hàng 2
    for (let i = 1; i < values.length; i++) {
      const row = values[i];
      
      // Nhận diện dòng 10 cột cũ (cột 0 là MaPhieu bắt đầu bằng PT hoặc PC) hay dòng 11 cột mới
      let firstCell = String(row[0] || "").trim().toUpperCase();
      let isLegacy10 = (firstCell.startsWith("PT") || firstCell.startsWith("PC"));

      let chiNhanhVal = "CN01: Trụ sở chính";
      let maPhieuVal = "";
      let loaiPhieuVal = "THU";
      let quyNguonVal = "TIEN_MAT";
      let ngayRaw = "";
      let rawTien = 0;
      let doiTuongVal = "";
      let maDoiTuongVal = "";
      let maChungTuVal = "";
      let trangThaiVal = "DaThanhToan";
      let ghiChuVal = "";

      if (isLegacy10) {
        maPhieuVal   = firstCell;
        loaiPhieuVal = String(row[1] || "").toUpperCase().trim();
        quyNguonVal  = String(row[2] || "").trim();
        ngayRaw      = row[3];
        rawTien      = row[4];
        doiTuongVal  = String(row[5] || "").trim();
        maDoiTuongVal= String(row[6] || "").trim();
        maChungTuVal = String(row[7] || "").trim();
        trangThaiVal = String(row[8] || "DaThanhToan").trim();
        ghiChuVal    = String(row[9] || "").trim();
      } else {
        chiNhanhVal  = col.chiNhanh > -1 ? String(row[col.chiNhanh] || "").trim() : "CN01: Trụ sở chính";
        maPhieuVal   = col.maPhieu > -1 ? String(row[col.maPhieu] || "").trim() : String(row[1] || "").trim();
        loaiPhieuVal = col.loaiPhieu > -1 ? String(row[col.loaiPhieu] || "").toUpperCase().trim() : "THU";
        quyNguonVal  = col.loaiQuy > -1 ? String(row[col.loaiQuy] || "").trim() : "TIEN_MAT";
        ngayRaw      = col.ngayGD > -1 ? row[col.ngayGD] : (col.ngayGD === -1 ? row[4] : "");
        rawTien      = col.soTien > -1 ? row[col.soTien] : 0;
        doiTuongVal  = col.doiTuong > -1 ? String(row[col.doiTuong] || "").trim() : "";
        maDoiTuongVal= col.maDoiTuong > -1 ? String(row[col.maDoiTuong] || "").trim() : "";
        maChungTuVal = col.maChungTu > -1 ? String(row[col.maChungTu] || "").trim() : "";
        trangThaiVal = col.trangThai > -1 ? String(row[col.trangThai] || "DaThanhToan").trim() : "DaThanhToan";
        ghiChuVal    = col.ghiChu > -1 ? String(row[col.ghiChu] || "").trim() : "";
      }

      // Bỏ qua dòng trống
      if (!maPhieuVal && !ngayRaw) continue;

      // Chuẩn hóa loại phiếu THU / CHI
      let lpClean = loaiPhieuVal.toLowerCase().normalize("NFD").replace(/[\u0300-\u036f]/g, "");
      if (lpClean.includes("thu") || maPhieuVal.toUpperCase().startsWith("PT")) {
        loaiPhieuVal = "THU";
      } else if (lpClean.includes("chi") || maPhieuVal.toUpperCase().startsWith("PC")) {
        loaiPhieuVal = "CHI";
      }

      // Chuẩn hóa ngày hiển thị dạng chuỗi
      let ngayFormatted = "";
      if (ngayRaw instanceof Date && !isNaN(ngayRaw.getTime())) {
        ngayFormatted = Utilities.formatDate(ngayRaw, timeZone, "yyyy-MM-dd HH:mm:ss");
      } else if (ngayRaw) {
        let strNgay = String(ngayRaw).trim();
        if (/^\d{12,14}$/.test(strNgay)) {
          try {
            let d = new Date(Number(strNgay));
            if (!isNaN(d.getTime())) {
              ngayFormatted = Utilities.formatDate(d, timeZone, "yyyy-MM-dd HH:mm:ss");
            } else {
              ngayFormatted = strNgay;
            }
          } catch(e) { ngayFormatted = strNgay; }
        } else {
          ngayFormatted = strNgay;
        }
      }

      // Chuẩn hóa số tiền (chuyển sang số thực, loại bỏ định dạng text)
      if (typeof rawTien === "string") {
        rawTien = rawTien.replace(/[^0-9.-]+/g, "");
      }
      let soTienNum = Math.abs(parseFloat(rawTien) || 0);

      // 3. Bộ lọc theo từng phân hệ: 5.1 TIEN_MAT | 5.2 TAI_KHOAN | 5.3 ALL
      let isTienMat = checkIsTienMat(quyNguonVal);
      let passFilter = true;
      let qFilter = String(loaiQuy || "ALL").toUpperCase().trim();

      if (qFilter === 'TIEN_MAT') {
        passFilter = isTienMat;
      } else if (qFilter === 'TAI_KHOAN' || qFilter === 'NGAN_HANG') {
        passFilter = !isTienMat && quyNguonVal !== '';
      } else if (qFilter !== 'ALL') {
        // Lọc theo từng tài khoản ngân hàng cụ thể nếu chọn từ dropdown
        passFilter = quyNguonVal.toLowerCase().includes(loaiQuy.toLowerCase());
      }

      if (passFilter) {
        // Cộng dồn KPI Thu / Chi nếu giao dịch hợp lệ
        if (trangThaiVal !== "DaHuy") {
          if (loaiPhieuVal === "THU") {
            tongThu += soTienNum;
          } else if (loaiPhieuVal === "CHI") {
            tongChi += soTienNum;
          }
        }
        allRows.push({
          chiNhanh:     chiNhanhVal || "CN01: Trụ sở chính",
          maPhieu:      maPhieuVal,
          loaiPhieu:    loaiPhieuVal,
          loaiQuy:      quyNguonVal || (isTienMat ? "TIEN_MAT" : "TAI_KHOAN"),
          quyNguon:     quyNguonVal || (isTienMat ? "TIEN_MAT" : "TAI_KHOAN"),
          ngayGiaoDich: ngayFormatted,
          ngayGD:       ngayFormatted,
          soTien:       soTienNum,
          doiTuong:     doiTuongVal,
          maDoiTuong:   maDoiTuongVal,
          maChungTu:    maChungTuVal,
          trangThai:    trangThaiVal,
          ghiChu:       ghiChuVal,
          lyDoThuChi:   ghiChuVal
        });
      }
    }
    // Đảo ngược để giao dịch mới nhất hiển thị lên đầu
    allRows.reverse();
    // 4. Trả về đúng cấu trúc Object hoàn chỉnh
    return {
      dauKy: dauKy,
      tongThu: tongThu,
      tongChi: tongChi,
      tonQuy: dauKy + tongThu - tongChi,
      danhSach: allRows
    };
  } catch (err) {
    Logger.log("Lỗi apiGetChiTietSoQuy: " + err.toString());
    return { dauKy: 0, tongThu: 0, tongChi: 0, tonQuy: 0, danhSach: [], error: err.message };
  }
}

// Giữ lại alias này cho các chức năng cũ nếu có
function getSoQuyData() {
  return apiGetChiTietSoQuy("ALL").danhSach;
}

function apiTaoPhieuSoQuy(payload) {
  return apiLuuPhieuSoQuy(payload);
}

function apiLuuPhieuSoQuy(data) {
  const ss = SpreadsheetApp.getActiveSpreadsheet();
  let sheet = ss.getSheetByName("SoQuy");
  if (!sheet) {
    sheet = ss.insertSheet("SoQuy");
    sheet.appendRow(["ChiNhanh", "MaPhieu", "LoaiPhieu", "LoaiQuy", "NgayGD", "SoTien", "DoiTuong", "MaDoiTuong", "MaChungTu", "TrangThai", "GhiChu"]);
  }
  let maPhieu = data.maPhieu || ((data.loaiPhieu === "CHI" ? "PC" : "PT") + Date.now().toString().slice(-6));
  let ngayGD = data.ngayGD || Utilities.formatDate(new Date(), Session.getScriptTimeZone() || "GMT+7", "yyyy-MM-dd HH:mm:ss");

  const rowValues = [
    data.chiNhanh || "CN01: Trụ sở chính",
    maPhieu,
    data.loaiPhieu || "THU",
    data.loaiQuy || data.hinhThucTT || "TIEN_MAT",
    ngayGD,
    Number(data.soTien) || 0,
    data.doiTuong || "Khách hàng",
    data.maDoiTuong || "",
    data.maChungTu || "THU_CHI_THU_CONG",
    data.trangThai || "DaThanhToan",
    data.ghiChu || ""
  ];

  // Kiểm tra nếu phiếu đã tồn tại trong sheet thì cập nhật dòng đó
  const rowsSQ = sheet.getDataRange().getValues();
  let foundRowSQ = -1;
  for (let i = 1; i < rowsSQ.length; i++) {
    if (String(rowsSQ[i][1] || '').trim().toUpperCase() === String(maPhieu).trim().toUpperCase()) {
      foundRowSQ = i + 1;
      break;
    }
  }

  if (foundRowSQ > 0) {
    sheet.getRange(foundRowSQ, 1, 1, rowValues.length).setValues([rowValues]);
  } else {
    sheet.appendRow(rowValues);
  }

  // 👉 ĐỒNG BỘ THỜI GIAN THỰC SANG SUPABASE POSTGRESQL (< 100MS)
  try {
    postToSupabaseServer("so_quy", {
      chi_nhanh: data.chiNhanh || "CN01: Trụ sở chính",
      ma_phieu: maPhieu,
      loai_phieu: data.loaiPhieu || "THU",
      loai_quy: data.loaiQuy || data.hinhThucTT || "TIEN_MAT",
      ngay_gd: new Date().toISOString(),
      so_tien: Number(data.soTien) || 0,
      doi_tuong: data.doiTuong || "Khách hàng",
      ma_doi_tuong: data.maDoiTuong || "",
      ma_chung_tu: data.maChungTu || "THU_CHI_THU_CONG",
      trang_thai: data.trangThai || "DaThanhToan",
      ghi_chu: data.ghiChu || ""
    });
  } catch(eSup) {
    Logger.log("Lỗi đồng bộ Supabase cho phiếu thu chi: " + eSup.message);
  }

  return { success: true, maPhieu: maPhieu };
}

// ==================== ĐỒNG BỘ DỮ LIỆU TỪ GOOGLE SHEET SANG SUPABASE ====================

// Hàm hỗ trợ khử trùng lặp bản ghi theo khóa chính trước khi gửi sang Supabase
function deduplicateRecords(arr, keyName) {
  if (!Array.isArray(arr)) return [];
  const map = {};
  arr.forEach(item => {
    if (!item) return;
    const k = String(item[keyName] || '').trim();
    if (k) {
      map[k] = item;
    }
  });
  return Object.values(map);
}

// Trích xuất toàn bộ dữ liệu từ Google Sheets để đồng bộ trực tiếp lên Supabase từ trình duyệt (hoàn toàn không cần quyền UrlFetchApp)
function apiGetDuLieuDongBoSupabase() {
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    if (!ss) return { success: false, error: "Không tìm thấy Spreadsheet!" };

    // 0. Chi Nhánh
    const listCN = (typeof apiGetDanhSachChiNhanh === 'function' ? apiGetDanhSachChiNhanh() : []) || [];
    let recordsCN = listCN.map(c => ({
      ma_cn: String(c.ma || c.maCN || c.ma_cn || '').trim().slice(0, 50),
      ten_cn: String(c.ten || c.tenCN || c.ten_cn || '').trim().slice(0, 255)
    })).filter(c => c.ma_cn);
    recordsCN = deduplicateRecords(recordsCN, "ma_cn");

    // 0.1 Nhóm Hàng
    let recordsNhom = [];
    let sheetNhom = ss.getSheetByName("DM_NhomHang");
    if (sheetNhom) {
      let rNhom = sheetNhom.getDataRange().getValues();
      for (let i = 1; i < rNhom.length; i++) {
        let maN = String(rNhom[i][0] || '').trim().slice(0, 50);
        let tenN = String(rNhom[i][1] || '').trim().slice(0, 255);
        if (maN && tenN) {
          recordsNhom.push({
            ma_nhom: maN,
            ten_nhom: tenN,
            ma_nhom_cha: String(rNhom[i][2] || '').trim().slice(0, 50),
            ghi_chu: String(rNhom[i][3] || '').trim()
          });
        }
      }
    }
    recordsNhom = deduplicateRecords(recordsNhom, "ma_nhom");

    // 1. Hàng Hóa
    const listHangHoa = (typeof apiGetDanhSachHangHoa === 'function' ? apiGetDanhSachHangHoa() : []) || [];
    let recordsHH = listHangHoa.map(h => ({
      ma_hang: String(h.maHang || h.ma_hang || '').trim().slice(0, 50),
      ten_hang: String(h.tenHang || h.ten_hang || '').trim().slice(0, 255),
      ma_nhom: String(h.maNhom || h.ma_nhom || '').trim().slice(0, 50),
      don_vi_tinh: String(h.donViTinh || h.don_vi_tinh || 'Cái').trim().slice(0, 50),
      gia_von: Number(h.giaVon || h.gia_von) || 0,
      gia_ban: Number(h.giaBan || h.gia_ban) || 0,
      co_quan_ly_imei: Boolean(h.coQuanLyIMEI || h.co_quan_ly_imei),
      ton_kho: Number(h.tonKho || h.ton_kho) || 0,
      trang_thai: String(h.trangThai || h.trang_thai || 'Kinh doanh').trim().slice(0, 50)
    })).filter(h => h.ma_hang);
    recordsHH = deduplicateRecords(recordsHH, "ma_hang");

    // 2. Kho IMEI
    let recordsIMEI = [];
    const sheetIMEI = ss.getSheetByName("Kho_IMEI");
    if (sheetIMEI) {
      const rIMEI = sheetIMEI.getDataRange().getValues();
      for (let i = 1; i < rIMEI.length; i++) {
        let row = rIMEI[i];
        let imeiVal = String(row[1] || row[0] || '').trim().slice(0, 100);
        let maH = String(row[2] || row[1] || '').trim().slice(0, 50);
        if (imeiVal && imeiVal.length > 5) {
          recordsIMEI.push({
            imei: imeiVal,
            ma_hang: maH,
            trang_thai: String(row[3] || 'TrongKho').trim().slice(0, 50)
          });
        }
      }
    }
    recordsIMEI = deduplicateRecords(recordsIMEI, "imei");

    // 3. Khách hàng & Nhà cung cấp
    const listKH = (typeof apiGetDanhSachDoiTac === 'function' ? apiGetDanhSachDoiTac("KH") : []) || [];
    const listNCC = (typeof apiGetDanhSachDoiTac === 'function' ? apiGetDanhSachDoiTac("NCC") : []) || [];
    const allDT = [...listKH, ...listNCC];
    let recordsDT = allDT.map(d => ({
      ma_doi_tac: String(d.maDoiTac || d.ma_doi_tac || '').trim().slice(0, 50),
      loai_doi_tac: String(d.loaiDoiTac || d.loai_doi_tac || 'KH').trim().slice(0, 20),
      ten_doi_tac: String(d.tenDoiTac || d.ten_doi_tac || '').trim().slice(0, 255),
      so_dien_thoai: String(d.soDienThoai || d.so_dien_thoai || '').trim().slice(0, 50),
      dia_chi: String(d.diaChi || d.dia_chi || '').trim(),
      gioi_tinh: String(d.gioiTinh || d.gioi_tinh || '').trim().slice(0, 20),
      cong_no: Number(d.congNo || d.cong_no) || 0,
      trang_thai: String(d.trangThai || d.trang_thai || 'HoatDong').trim().slice(0, 50)
    })).filter(d => d.ma_doi_tac);
    recordsDT = deduplicateRecords(recordsDT, "ma_doi_tac");

    // 4. Đơn Hàng
    const listDon = (typeof apiGetDanhSachDonHang === 'function' ? apiGetDanhSachDonHang() : []) || [];
    let recordsDon = listDon.filter(d => d.maDonHang && !String(d.maDonHang).startsWith('ERR')).map(d => ({
      ma_don_hang: String(d.maDonHang || d.ma_don_hang).trim().slice(0, 50),
      ngay_ban: d.ngayBan || d.ngay_ban || new Date().toISOString(),
      ma_kh: String(d.maKH || d.ma_kh || 'KL').trim().slice(0, 50),
      ten_kh: String(d.tenKH || d.ten_kh || 'Khách lẻ').trim().slice(0, 255),
      so_dien_thoai: String(d.soDienThoai || d.so_dien_thoai || '').trim().slice(0, 50),
      tong_tien: Number(d.tongTien || d.tong_tien) || 0,
      giam_gia: Number(d.giamGia || d.giam_gia) || 0,
      khach_phai_tra: Number(d.khachPhaiTra || d.khach_phai_tra) || 0,
      khach_tra: Number(d.khachTra || d.khach_tra) || 0,
      hinh_thuc_tt: String(d.hinhThucTT || d.hinh_thuc_tt || 'TIEN_MAT').trim().slice(0, 50),
      chi_tiet_san_pham: d.chiTietSanPham || d.chi_tiet_san_pham || [],
      trang_thai: String(d.trangThai || d.trang_thai || 'Hoàn thành').trim().slice(0, 50),
      nhan_vien: String(d.nhanVien || d.nhan_vien || '').trim().slice(0, 100)
    })).filter(d => d.ma_don_hang);
    recordsDon = deduplicateRecords(recordsDon, "ma_don_hang");

    // 5. Sổ Quỹ
    let recordsQuy = [];
    try {
      if (typeof apiGetChiTietSoQuy === 'function') {
        const soQuyData = apiGetChiTietSoQuy("ALL") || {};
        if (soQuyData && soQuyData.danhSach) {
          recordsQuy = soQuyData.danhSach.filter(q => q.maPhieu || q.ma_phieu).map(q => ({
            chi_nhanh: String(q.chiNhanh || q.chi_nhanh || "CN01: Trụ sở chính Thanh Miện").trim().slice(0, 100),
            ma_phieu: String(q.maPhieu || q.ma_phieu).trim().slice(0, 50),
            loai_phieu: String(q.loaiPhieu || q.loai_phieu || "THU").trim().slice(0, 20),
            loai_quy: String(q.loaiQuy || q.loai_quy || "TIEN_MAT").trim().slice(0, 100),
            ngay_gd: q.ngayGiaoDich || q.ngay_gd || new Date().toISOString(),
            so_tien: Number(q.soTien || q.so_tien) || 0,
            doi_tuong: String(q.doiTuong || q.doi_tuong || "Khách hàng").trim().slice(0, 100),
            ma_doi_tuong: String(q.maDoiTuong || q.ma_doi_tuong || "").trim().slice(0, 50),
            ma_chung_tu: String(q.maChungTu || q.ma_chung_tu || "").trim().slice(0, 50),
            trang_thai: String(q.trangThai || q.trang_thai || "DaThanhToan").trim().slice(0, 50),
            ghi_chu: q.ghiChu || q.ghi_chu || ""
          })).filter(q => q.ma_phieu);
        }
      }
    } catch(eQ) {
      Logger.log("Lỗi sổ quỹ: " + eQ.message);
    }
    recordsQuy = deduplicateRecords(recordsQuy, "ma_phieu");

    // 6. Ngân hàng
    const listNH = (typeof apiGetDanhSachNganHang === 'function' ? apiGetDanhSachNganHang() : []) || [];
    let recordsNH = listNH.map(n => ({
      ma_nh: String(n.maNH || n.ma_nh || '').trim().slice(0, 50),
      ten_nh: String(n.tenNH || n.ten_nh || '').trim().slice(0, 255),
      so_tk: String(n.soTK || n.so_tk || '').trim().slice(0, 50),
      chu_tk: String(n.chuTK || n.chu_tk || '').trim().slice(0, 255),
      ghi_chu: String(n.ghiChu || n.ghi_chu || '').trim()
    })).filter(n => n.ma_nh);
    recordsNH = deduplicateRecords(recordsNH, "ma_nh");

    return {
      success: true,
      data: {
        chiNhanh: recordsCN,
        nhomHang: recordsNhom,
        hangHoa: recordsHH,
        imei: recordsIMEI,
        doiTac: recordsDT,
        donHang: recordsDon,
        soQuy: recordsQuy,
        nganHang: recordsNH
      }
    };
  } catch(err) {
    Logger.log("Lỗi apiGetDuLieuDongBoSupabase: " + err.message);
    return { success: false, error: err.toString() };
  }
}

function apiDongBoDuLieuSangSupabase(supabaseUrl, supabaseKey) {
  try {
    supabaseUrl = String(supabaseUrl || "https://gzcpwwcoaycxqbgrjvzn.supabase.co").trim().replace(/\/+$/, '');
    supabaseKey = String(supabaseKey || "sb_publishable_kiCUjPVYWcQP7oyrsg3K7g_xySklDFY").trim();

    const headers = {
      "apikey": supabaseKey,
      "Authorization": "Bearer " + supabaseKey,
      "Content-Type": "application/json",
      "Prefer": "resolution=merge-duplicates"
    };

    function postToSupabase(table, records) {
      if (!records || !records.length) return 0;
      const options = {
        method: "post",
        headers: headers,
        payload: JSON.stringify(records),
        muteHttpExceptions: true
      };
      const response = UrlFetchApp.fetch(supabaseUrl + "/rest/v1/" + table, options);
      const code = response.getResponseCode();
      if (code >= 400) {
        throw new Error("Lỗi đẩy bảng " + table + " (HTTP " + code + "): " + response.getContentText());
      }
      return records.length;
    }

    let stats = { chiNhanh: 0, nhomHang: 0, hangHoa: 0, imei: 0, doiTac: 0, donHang: 0, soQuy: 0, nganHang: 0 };
    const ss = SpreadsheetApp.getActiveSpreadsheet();

    // 0. Đồng bộ Chi Nhánh
    const listCN = apiGetDanhSachChiNhanh();
    if (listCN && listCN.length) {
      const recordsCN = listCN.map(c => ({
        ma_cn: String(c.ma || c.maCN || '').trim().slice(0, 50),
        ten_cn: String(c.ten || c.tenCN || '').trim().slice(0, 255)
      })).filter(c => c.ma_cn);
      stats.chiNhanh = postToSupabase("dm_chinhanh", deduplicateRecords(recordsCN, "ma_cn"));
    }

    // 0.1 Đồng bộ Nhóm Hàng
    let sheetNhom = ss ? ss.getSheetByName("DM_NhomHang") : null;
    if (sheetNhom) {
      let rNhom = sheetNhom.getDataRange().getValues();
      if (rNhom.length > 1) {
        let recordsNhom = [];
        for (let i = 1; i < rNhom.length; i++) {
          let maN = String(rNhom[i][0] || '').trim().slice(0, 50);
          let tenN = String(rNhom[i][1] || '').trim().slice(0, 255);
          if (maN && tenN) {
            recordsNhom.push({
              ma_nhom: maN,
              ten_nhom: tenN,
              ma_nhom_cha: String(rNhom[i][2] || '').trim().slice(0, 50),
              ghi_chu: String(rNhom[i][3] || '').trim()
            });
          }
        }
        if (recordsNhom.length) {
          stats.nhomHang = postToSupabase("dm_nhomhang", deduplicateRecords(recordsNhom, "ma_nhom"));
        }
      }
    }

    // 1. Đồng bộ Hàng Hóa
    const listHangHoa = apiGetDanhSachHangHoa();
    if (listHangHoa && listHangHoa.length) {
      const recordsHH = listHangHoa.map(h => ({
        ma_hang: String(h.maHang || '').trim().slice(0, 50),
        ten_hang: String(h.tenHang || '').trim().slice(0, 255),
        ma_nhom: String(h.maNhom || '').trim().slice(0, 50),
        don_vi_tinh: String(h.donViTinh || 'Cái').trim().slice(0, 50),
        gia_von: Number(h.giaVon) || 0,
        gia_ban: Number(h.giaBan) || 0,
        co_quan_ly_imei: Boolean(h.coQuanLyIMEI),
        ton_kho: Number(h.tonKho) || 0,
        trang_thai: String(h.trangThai || 'Kinh doanh').trim().slice(0, 50)
      })).filter(h => h.ma_hang);
      stats.hangHoa = postToSupabase("dm_hanghoa", deduplicateRecords(recordsHH, "ma_hang"));
    }

    // 2. Đồng bộ Kho IMEI
    const sheetIMEI = ss ? ss.getSheetByName("Kho_IMEI") : null;
    if (sheetIMEI) {
      const rIMEI = sheetIMEI.getDataRange().getValues();
      if (rIMEI.length > 1) {
        let recordsIMEI = [];
        for (let i = 1; i < rIMEI.length; i++) {
          let row = rIMEI[i];
          let imeiVal = String(row[1] || row[0] || '').trim().slice(0, 100);
          let maH = String(row[2] || row[1] || '').trim().slice(0, 50);
          if (imeiVal && imeiVal.length > 5) {
            recordsIMEI.push({
              imei: imeiVal,
              ma_hang: maH,
              trang_thai: String(row[3] || 'TrongKho').trim().slice(0, 50)
            });
          }
        }
        if (recordsIMEI.length) {
          stats.imei = postToSupabase("kho_imei", deduplicateRecords(recordsIMEI, "imei"));
        }
      }
    }

    // 3. Đồng bộ Khách hàng & Nhà cung cấp
    const listKH = apiGetDanhSachDoiTac("KH");
    const listNCC = apiGetDanhSachDoiTac("NCC");
    const allDT = [...(listKH || []), ...(listNCC || [])];
    if (allDT.length) {
      const recordsDT = allDT.map(d => ({
        ma_doi_tac: String(d.maDoiTac || '').trim().slice(0, 50),
        loai_doi_tac: String(d.loaiDoiTac || 'KH').trim().slice(0, 20),
        ten_doi_tac: String(d.tenDoiTac || '').trim().slice(0, 255),
        so_dien_thoai: String(d.soDienThoai || '').trim().slice(0, 50),
        dia_chi: String(d.diaChi || '').trim(),
        gioi_tinh: String(d.gioiTinh || '').trim().slice(0, 20),
        cong_no: Number(d.congNo) || 0,
        trang_thai: String(d.trangThai || 'HoatDong').trim().slice(0, 50)
      })).filter(d => d.ma_doi_tac);
      stats.doiTac = postToSupabase("dm_doitac", deduplicateRecords(recordsDT, "ma_doi_tac"));
    }

    // 4. Đồng bộ Đơn Hàng
    const listDon = apiGetDanhSachDonHang();
    if (listDon && listDon.length) {
      const recordsDon = listDon.filter(d => d.maDonHang && !d.maDonHang.startsWith('ERR')).map(d => ({
        ma_don_hang: String(d.maDonHang).trim().slice(0, 50),
        ngay_ban: d.ngayBan || new Date().toISOString(),
        ma_kh: String(d.maKH || 'KL').trim().slice(0, 50),
        ten_kh: String(d.tenKH || 'Khách lẻ').trim().slice(0, 255),
        so_dien_thoai: String(d.soDienThoai || '').trim().slice(0, 50),
        tong_tien: Number(d.tongTien) || 0,
        giam_gia: Number(d.giamGia) || 0,
        khach_phai_tra: Number(d.khachPhaiTra) || 0,
        khach_tra: Number(d.khachTra) || 0,
        hinh_thuc_tt: String(d.hinhThucTT || 'TIEN_MAT').trim().slice(0, 50),
        chi_tiet_san_pham: d.chiTietSanPham || [],
        trang_thai: String(d.trangThai || 'Hoàn thành').trim().slice(0, 50),
        nhan_vien: String(d.nhanVien || '').trim().slice(0, 100)
      })).filter(d => d.ma_don_hang);
      stats.donHang = postToSupabase("don_hang", deduplicateRecords(recordsDon, "ma_don_hang"));
    }

    // 5. Đồng bộ Sổ Quỹ
    const soQuyData = apiGetChiTietSoQuy("ALL");
    if (soQuyData && soQuyData.danhSach && soQuyData.danhSach.length) {
      const recordsQuy = soQuyData.danhSach.filter(q => q.maPhieu).map(q => ({
        chi_nhanh: String(q.chiNhanh || "CN01: Trụ sở chính Thanh Miện").trim().slice(0, 100),
        ma_phieu: String(q.maPhieu).trim().slice(0, 50),
        loai_phieu: String(q.loaiPhieu || "THU").trim().slice(0, 20),
        loai_quy: String(q.loaiQuy || "TIEN_MAT").trim().slice(0, 100),
        ngay_gd: q.ngayGiaoDich || new Date().toISOString(),
        so_tien: Number(q.soTien) || 0,
        doi_tuong: String(q.doiTuong || "Khách hàng").trim().slice(0, 100),
        ma_doi_tuong: String(q.maDoiTuong || "").trim().slice(0, 50),
        ma_chung_tu: String(q.maChungTu || "").trim().slice(0, 50),
        trang_thai: String(q.trangThai || "DaThanhToan").trim().slice(0, 50),
        ghi_chu: q.ghiChu || ""
      })).filter(q => q.ma_phieu);
      stats.soQuy = postToSupabase("so_quy", deduplicateRecords(recordsQuy, "ma_phieu"));
    }

    // 6. Đồng bộ Tài khoản Ngân hàng
    const listNH = apiGetDanhSachNganHang();
    if (listNH && listNH.length) {
      const recordsNH = listNH.map(n => ({
        ma_nh: String(n.maNH || '').trim().slice(0, 50),
        ten_nh: String(n.tenNH || '').trim().slice(0, 255),
        so_tk: String(n.soTK || '').trim().slice(0, 50),
        chu_tk: String(n.chuTK || '').trim().slice(0, 255),
        ghi_chu: String(n.ghiChu || '').trim()
      })).filter(n => n.ma_nh);
      stats.nganHang = postToSupabase("dm_nganhang", deduplicateRecords(recordsNH, "ma_nh"));
    }

    return {
      success: true,
      stats: stats,
      message: `Đồng bộ thành công: ${stats.hangHoa} hàng hóa, ${stats.imei} IMEI, ${stats.doiTac} đối tác, ${stats.donHang} đơn hàng, ${stats.soQuy} giao dịch sổ quỹ!`
    };
  } catch (err) {
    return { success: false, error: err.toString() };
  }
}

// ====================================================================
// MODULE 6: BÁO CÁO TỔNG HỢP & PHÂN TÍCH KINH DOANH CHUYÊN SÂU
// ====================================================================
function apiGetBaoCaoTongHop(filter) {
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    const now = new Date();
    const filterTime = String(filter || "ALL").toUpperCase();

    // 1. Lấy danh sách hàng hóa
    let hangHoaList = [];
    try {
      hangHoaList = (typeof apiGetDanhSachHangHoa === 'function' ? apiGetDanhSachHangHoa() : []) || [];
    } catch(eHH) {
      Logger.log("Lỗi apiGetDanhSachHangHoa: " + eHH.message);
    }
    let tongMaHang = hangHoaList.length;
    let tongTonKho = 0;
    let tongGiaTriVonTon = 0;
    let tongGiaTriBanTon = 0;
    const hangHoaMap = {};

    hangHoaList.forEach(h => {
      let ton = Number(h.tonKho) || 0;
      let giaVon = Number(h.giaVon) || 0;
      let giaBan = Number(h.giaBan) || 0;
      tongTonKho += ton;
      tongGiaTriVonTon += (ton * giaVon);
      tongGiaTriBanTon += (ton * giaBan);
      hangHoaMap[String(h.maHang).toUpperCase()] = h;
    });

    // 2. Lấy danh sách đơn hàng đã bán
    let donHangList = [];
    try {
      donHangList = (typeof apiGetDanhSachDonHang === 'function' ? apiGetDanhSachDonHang() : []) || [];
    } catch(eDH) {
      Logger.log("Lỗi apiGetDanhSachDonHang: " + eDH.message);
    }

    let tongBan = 0;
    let tongGiamGia = 0;
    let soDonBan = 0;
    let tongTraHang = 0;
    let soDonTra = 0;
    let giaVonHangBan = 0;
    const topHangBan = {};
    const topNhanVien = {};
    const donHangFiltered = [];

    donHangList.forEach(d => {
      let ngayD = d.ngayBan ? new Date(d.ngayBan) : null;
      let pass = true;

      if (ngayD && !isNaN(ngayD.getTime())) {
        if (filterTime === 'TODAY') {
          pass = (ngayD.toDateString() === now.toDateString());
        } else if (filterTime === '7DAYS') {
          pass = (now.getTime() - ngayD.getTime() <= 7 * 24 * 3600 * 1000);
        } else if (filterTime === 'THIS_MONTH') {
          pass = (ngayD.getMonth() === now.getMonth() && ngayD.getFullYear() === now.getFullYear());
        }
      }

      if (pass) {
        let maDon = String(d.maDonHang || "").trim().toUpperCase();
        let nv = String(d.nhanVien || "Admin").trim();
        let nvLower = nv.toLowerCase();
        if (maDon.startsWith("PNH") || maDon.startsWith("DDH") || nvLower === "hệ thống tự động" || nvLower === "he thong tu dong") return;

        let isTra = String(d.trangThai || "").includes("Trả") || maDon.startsWith("TH");
        let tt = Number(d.khachPhaiTra || d.tongTien || 0);

        if (isTra) {
          tongTraHang += tt;
          soDonTra++;
        } else {
          tongBan += tt;
          tongGiamGia += (Number(d.giamGia) || 0);
          soDonBan++;

          let nv = d.nhanVien || "Admin";
          topNhanVien[nv] = (topNhanVien[nv] || 0) + tt;

          // Tính giá vốn và top sản phẩm
          if (Array.isArray(d.chiTietSanPham)) {
            d.chiTietSanPham.forEach(item => {
              let sl = Number(item.soLuong) || 1;
              let maH = String(item.maHang || "").toUpperCase();
              let hInfo = hangHoaMap[maH] || {};
              let gVon = Number(item.giaVon || hInfo.giaVon || 0);
              giaVonHangBan += (sl * gVon);

              if (maH) {
                if (!topHangBan[maH]) {
                  topHangBan[maH] = {
                    maHang: item.maHang,
                    tenHang: item.tenHang || hInfo.tenHang || item.maHang,
                    soLuong: 0,
                    doanhThu: 0
                  };
                }
                topHangBan[maH].soLuong += sl;
                topHangBan[maH].doanhThu += (Number(item.thanhTien) || (sl * Number(item.donGia || 0)));
              }
            });
          }
        }
        donHangFiltered.push(d);
      }
    });

    let doanhThuThuan = tongBan - tongTraHang;
    let loiNhuanGop = doanhThuThuan - giaVonHangBan;
    let tySuatLoiNhuan = doanhThuThuan > 0 ? Math.round((loiNhuanGop / doanhThuThuan) * 100) : 0;

    // 3. Lấy dữ liệu Sổ Quỹ
    let tongThuQuy = 0;
    let tongChiQuy = 0;
    let tonQuyThucTe = 0;
    let tonQuyTM = 0;
    let tonQuyNH = 0;
    try {
      if (typeof apiGetChiTietSoQuy === 'function') {
        const soQuyRes = apiGetChiTietSoQuy("ALL") || {};
        tongThuQuy = Number(soQuyRes.tongThu) || 0;
        tongChiQuy = Number(soQuyRes.tongChi) || 0;
        tonQuyThucTe = Number(soQuyRes.tonQuy) || 0;
        const soQuyTM = apiGetChiTietSoQuy("TIEN_MAT") || {};
        tonQuyTM = Number(soQuyTM.tonQuy) || 0;
        const soQuyNH = apiGetChiTietSoQuy("TAI_KHOAN") || {};
        tonQuyNH = Number(soQuyNH.tonQuy) || 0;
      }
    } catch(eQuy) {
      Logger.log("Lỗi tính sổ quỹ: " + eQuy.message);
    }

    // 4. Lấy dữ liệu Đối tác Khách hàng & Nhà cung cấp
    let listKH = [];
    let tongCongNoKH = 0;
    try {
      listKH = (typeof apiGetDanhSachDoiTac === 'function' ? apiGetDanhSachDoiTac("KH") : []) || [];
      tongCongNoKH = listKH.reduce((acc, k) => acc + (Number(k.congNo) || 0), 0);
    } catch(eKH) {
      Logger.log("Lỗi tính khách hàng: " + eKH.message);
    }

    let listNCC = [];
    let tongNoNCC = 0;
    try {
      listNCC = (typeof apiGetDanhSachDoiTac === 'function' ? apiGetDanhSachDoiTac("NCC") : []) || [];
      tongNoNCC = listNCC.reduce((acc, n) => acc + (Number(n.congNo) || 0), 0);
    } catch(eNCC) {
      Logger.log("Lỗi tính nhà cung cấp: " + eNCC.message);
    }

    // 5. Lấy danh sách nhập hàng
    let tongNhapHang = 0;
    let nhapList = [];
    try {
      if (ss) {
        let sheetNhap = ss.getSheetByName("GiaoDich_NhapHang") || ss.getSheetByName("NhapHang");
        if (sheetNhap) {
          let rNhap = sheetNhap.getDataRange().getValues();
          for (let i = 1; i < rNhap.length; i++) {
            let tTien = Number(rNhap[i][4]) || 0;
            tongNhapHang += tTien;
            nhapList.push({
              maNhap: rNhap[i][0],
              ngayTao: rNhap[i][2],
              maNCC: rNhap[i][3],
              tongTien: tTien,
              daTra: Number(rNhap[i][5]) || 0,
              trangThai: rNhap[i][7]
            });
          }
        }
      }
    } catch(eNhap) {
      Logger.log("Lỗi tính nhập hàng: " + eNhap.message);
    }

    // Chuyển top hàng bán thành array sắp xếp giảm dần
    const topHangList = Object.values(topHangBan).sort((a, b) => b.soLuong - a.soLuong).slice(0, 10);

    return {
      success: true,
      filter: filterTime,
      banHang: {
        tongBan: tongBan,
        tongGiamGia: tongGiamGia,
        soDonBan: soDonBan,
        tongTraHang: tongTraHang,
        soDonTra: soDonTra,
        doanhThuThuan: doanhThuThuan,
        topNhanVien: topNhanVien,
        danhSachDonHang: donHangFiltered.slice(0, 100)
      },
      hangHoa: {
        tongMaHang: tongMaHang,
        tongTonKho: tongTonKho,
        tongGiaTriVonTon: tongGiaTriVonTon,
        tongGiaTriBanTon: tongGiaTriBanTon,
        topHangBan: topHangList,
        danhSachHangHoa: hangHoaList.slice(0, 200)
      },
      khachHang: {
        tongSoKH: listKH.length,
        tongCongNoKH: tongCongNoKH,
        danhSachKH: listKH
      },
      ncc: {
        tongSoNCC: listNCC.length,
        tongNhapHang: tongNhapHang,
        tongNoNCC: tongNoNCC,
        danhSachNCC: listNCC
      },
      taiChinh: {
        doanhThuThuan: doanhThuThuan,
        giaVonHangBan: giaVonHangBan,
        loiNhuanGop: loiNhuanGop,
        tySuatLoiNhuan: tySuatLoiNhuan,
        tongThuQuy: tongThuQuy,
        tongChiQuy: tongChiQuy,
        tonQuyThucTe: tonQuyThucTe,
        tonQuyTienMat: tonQuyTM,
        tonQuyNganHang: tonQuyNH
      }
    };
  } catch (err) {
    Logger.log("Lỗi apiGetBaoCaoTongHop: " + err.message);
    return { success: false, error: err.toString() };
  }
} 




// Backend API additions for Code.js

/**
 * Tự động đối soát và đồng bộ tiền cọc từ Đơn Đặt Hàng sang Sổ Quỹ và Công Nợ Khách Hàng
 * - Tự động liên kết mã khách hàng thật (ví dụ Nguyễn Thị Hoa -> KH000949)
 * - Tự động ghi phiếu thu tiền cọc (PT...) vào SoQuy nếu chưa có
 * - Tự động cộng tiền cọc vào công nợ khách hàng trong DM_DoiTac
 * - Đồng bộ tức thì sang Supabase (so_quy, dm_doitac)
 */
function dongBoTienCocDonDatHang(ss) {
  try {
    if (!ss) ss = SpreadsheetApp.getActiveSpreadsheet();
    let sheetDonDat = ss.getSheetByName("DonDatHang");
    if (!sheetDonDat) return;

    let rowsDonDat = sheetDonDat.getDataRange().getValues();
    if (rowsDonDat.length < 2) return;

    let hDD = rowsDonDat[0].map(x => String(x || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
    let idxMaDon = hDD.indexOf("madondat") > -1 ? hDD.indexOf("madondat") : 0;
    let idxNgay = hDD.indexOf("ngaydat") > -1 ? hDD.indexOf("ngaydat") : 1;
    let idxMaKH = hDD.indexOf("makh") > -1 ? hDD.indexOf("makh") : 2;
    let idxTenKH = hDD.indexOf("tenkh") > -1 ? hDD.indexOf("tenkh") : 3;
    let idxSDT = hDD.indexOf("sodienthoai") > -1 ? hDD.indexOf("sodienthoai") : 4;
    let idxTong = hDD.indexOf("tongtien") > -1 ? hDD.indexOf("tongtien") : 5;
    let idxCoc = hDD.indexOf("tiencoc") > -1 ? hDD.indexOf("tiencoc") : 6;
    let idxTT = hDD.indexOf("trangthai") > -1 ? hDD.indexOf("trangthai") : 7;
    let idxCN = hDD.indexOf("chinhanh") > -1 ? hDD.indexOf("chinhanh") : -1;

    let sheetQuy = ss.getSheetByName("SoQuy");
    if (!sheetQuy) {
      sheetQuy = ss.insertSheet("SoQuy");
      sheetQuy.appendRow(["ChiNhanh", "MaPhieu", "LoaiPhieu", "LoaiQuy", "NgayGD", "SoTien", "DoiTuong", "MaDoiTuong", "MaChungTu", "TrangThai", "GhiChu"]);
    }
    let rowsQuy = sheetQuy.getDataRange().getValues();
    let existingChungTuQuy = new Set();
    let existingMaPhieuQuy = new Set();
    if (rowsQuy.length > 1) {
      let hQ = rowsQuy[0].map(x => String(x || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
      let idxCTu = hQ.indexOf("machungtu") > -1 ? hQ.indexOf("machungtu") : 8;
      let idxMaP = hQ.indexOf("maphieu") > -1 ? hQ.indexOf("maphieu") : 1;
      for (let q = 1; q < rowsQuy.length; q++) {
        let ct = String(rowsQuy[q][idxCTu] || "").trim().toUpperCase();
        let mp = String(rowsQuy[q][idxMaP] || "").trim().toUpperCase();
        if (ct) existingChungTuQuy.add(ct);
        if (mp) existingMaPhieuQuy.add(mp);
      }
    }

    let sheetDT = ss.getSheetByName("DM_DoiTac");
    if (!sheetDT) return;
    let rowsDT = sheetDT.getDataRange().getValues();
    if (rowsDT.length < 1) return;
    let hDT = rowsDT[0].map(x => String(x || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
    let idxMaDT = hDT.indexOf("madoitac") > -1 ? hDT.indexOf("madoitac") : 0;
    let idxLoaiDT = hDT.indexOf("loaidoitac") > -1 ? hDT.indexOf("loaidoitac") : 1;
    let idxTenDT = hDT.indexOf("tendoitac") > -1 ? hDT.indexOf("tendoitac") : 2;
    let idxSdtDT = hDT.indexOf("sodienthoai") > -1 ? hDT.indexOf("sodienthoai") : 3;
    let idxCongNoDT = hDT.indexOf("congno") > -1 ? hDT.indexOf("congno") : 7;

    const cleanStr = (s) => String(s || "").toLowerCase().trim().normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/\s+/g, " ");

    let updatedCongNoByKH = {};

    for (let i = 1; i < rowsDonDat.length; i++) {
      let r = rowsDonDat[i];
      let maDon = String(r[idxMaDon] || "").trim();
      if (!maDon) continue;

      let tienCoc = Number(r[idxCoc]) || 0;
      let trangThai = String(r[idxTT] || "").trim();
      if (trangThai === "Đã hủy") continue;

      let maKH = idxMaKH > -1 ? String(r[idxMaKH] || "").trim() : "";
      let tenKH = idxTenKH > -1 ? String(r[idxTenKH] || "").trim() : "";
      let sdt = idxSDT > -1 ? String(r[idxSDT] || "").trim() : "";
      let ngayDat = r[idxNgay];
      if (ngayDat instanceof Date) ngayDat = Utilities.formatDate(ngayDat, "GMT+7", "yyyy-MM-dd HH:mm:ss");
      else ngayDat = String(ngayDat || "");
      let chiNhanh = (idxCN > -1 && r[idxCN]) ? String(r[idxCN]) : "CN01: Trụ sở chính";

      // 1. Tự động liên kết mã khách hàng thật nếu mã đang là KL hoặc rỗng
      let matchedDTRow = -1;
      let matchedMaKH = maKH;
      let matchedTenKH = tenKH;
      let matchedSDT = sdt;

      if (!matchedMaKH || matchedMaKH.toUpperCase() === "KL") {
        for (let d = 1; d < rowsDT.length; d++) {
          let dtLoai = String(rowsDT[d][idxLoaiDT] || "KH").toUpperCase();
          if (dtLoai !== "KH") continue;
          let dtMa = String(rowsDT[d][idxMaDT] || "").trim();
          let dtTen = String(rowsDT[d][idxTenDT] || "").trim();
          let dtSdt = String(rowsDT[d][idxSdtDT] || "").trim();

          let matchSdt = (sdt && dtSdt && sdt.replace(/\D/g, '') === dtSdt.replace(/\D/g, ''));
          let matchTen = (tenKH && dtTen && cleanStr(tenKH) === cleanStr(dtTen));

          if (matchSdt || matchTen) {
            matchedDTRow = d + 1;
            matchedMaKH = dtMa;
            matchedTenKH = dtTen;
            matchedSDT = dtSdt || sdt;
            break;
          }
        }
        if (matchedDTRow > -1 && matchedMaKH !== maKH) {
          if (idxMaKH > -1) sheetDonDat.getRange(i + 1, idxMaKH + 1).setValue(matchedMaKH);
          if (idxSDT > -1 && matchedSDT) sheetDonDat.getRange(i + 1, idxSDT + 1).setValue(matchedSDT);
          if (idxTenKH > -1 && matchedTenKH) sheetDonDat.getRange(i + 1, idxTenKH + 1).setValue(matchedTenKH);
          maKH = matchedMaKH;
          tenKH = matchedTenKH;
          sdt = matchedSDT;
        }
      }

      // 2. Xử lý tiền cọc > 0: Tự động ghi Sổ Quỹ và cộng vào công nợ
      if (tienCoc > 0) {
        let upperMaDon = maDon.toUpperCase();
        if (!existingChungTuQuy.has(upperMaDon)) {
          let maPT = "PT" + (maDon.replace(/\D/g, '') || Date.now().toString().slice(-6));
          if (existingMaPhieuQuy.has(maPT.toUpperCase())) {
            maPT = "PT" + (Date.now() + i).toString().slice(-6);
          }

          let rowQuy = [
            chiNhanh,
            maPT,
            "THU",
            "TIEN_MAT",
            ngayDat || Utilities.formatDate(new Date(), "GMT+7", "yyyy-MM-dd HH:mm:ss"),
            tienCoc,
            "Khách hàng",
            maKH || "KL",
            maDon,
            "DaThanhToan",
            `Thu tiền đặt cọc đơn đặt hàng ${maDon} - Khách: ${tenKH || 'Khách lẻ'}`
          ];
          sheetQuy.appendRow(rowQuy);
          existingChungTuQuy.add(upperMaDon);
          existingMaPhieuQuy.add(maPT.toUpperCase());

          // Đồng bộ tức thì Supabase so_quy
          try {
            if (typeof postToSupabaseServer === 'function') {
              postToSupabaseServer("so_quy", {
                chi_nhanh: chiNhanh,
                ma_phieu: maPT,
                loai_phieu: "THU",
                loai_quy: "TIEN_MAT",
                ngay_gd: ngayDat || new Date().toISOString(),
                so_tien: tienCoc,
                doi_tuong: "Khách hàng",
                ma_doi_tuong: maKH || "KL",
                ma_chung_tu: maDon,
                trang_thai: "DaThanhToan",
                ghi_chu: `Thu tiền đặt cọc đơn đặt hàng ${maDon} - Khách: ${tenKH || 'Khách lẻ'}`
              });
            }
          } catch(eSq) {}

          if (maKH && maKH.toUpperCase() !== "KL") {
            updatedCongNoByKH[maKH] = (updatedCongNoByKH[maKH] || 0) + tienCoc;
          }
        }
      }
    }

    // 3. Cập nhật công nợ cho khách hàng (Tiền cọc là tiền khách trả trước => âm công nợ, ví dụ: -2.000.000 đ)
    for (let targetKH in updatedCongNoByKH) {
      let addAmount = updatedCongNoByKH[targetKH];
      if (addAmount <= 0) continue;

      for (let d = 1; d < rowsDT.length; d++) {
        let dtMa = String(rowsDT[d][idxMaDT] || "").trim().toUpperCase();
        if (dtMa === targetKH.toUpperCase()) {
          let currDebt = Number(rowsDT[d][idxCongNoDT]) || 0;
          // Nếu khách chưa mua hàng hoặc chưa nợ gì, tiền cọc làm nợ âm: -addAmount (-2.000.000 đ)
          let newDebt = (currDebt > 0) ? (currDebt - addAmount) : (-addAmount);
          sheetDT.getRange(d + 1, idxCongNoDT + 1).setValue(newDebt);

          try {
            if (typeof patchSupabaseServer === 'function') {
              patchSupabaseServer("dm_doitac", "ma_doi_tac=eq." + encodeURIComponent(targetKH), {
                cong_no: newDebt
              });
            } else if (typeof postToSupabaseServer === 'function') {
              postToSupabaseServer("dm_doitac", {
                ma_doi_tac: targetKH,
                cong_no: newDebt
              });
            }
          } catch(eDT) {}
          break;
        }
      }
    }
  } catch(err) {
    Logger.log("Lỗi dongBoTienCocDonDatHang: " + err.message);
  }
}

// 1. Lấy lịch sử giao dịch toàn diện của Khách Hàng (Hóa đơn mua hàng, Đơn đặt cọc, Trả hàng, Thu nợ/Thanh toán)
function apiGetLichSuGiaoDichKH(maKH, tenKH, sdt) {
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    if (typeof dongBoTienCocDonDatHang === 'function') {
      dongBoTienCocDonDatHang(ss);
    }

    let targetMa = String(maKH || "").trim().toUpperCase();
    let searchTen = String(tenKH || "").trim();
    let searchSdt = String(sdt || "").trim().replace(/\D/g, '');

    let lichSuMua = [];
    let lichSuDat = [];
    let lichSuTra = [];
    let lichSuThanhToan = [];
    let danhSachGiaoDich = [];
    let tongGiaTriMua = 0;
    let tongGiaTriTra = 0;
    let tongDaThanhToan = 0;
    let infoKH = null;

    const cleanStr = (s) => String(s || "").toLowerCase().trim().normalize("NFD").replace(/[\u0300-\u036f]/g, "").replace(/\s+/g, " ");

    // 1. Lấy thông tin & công nợ từ DM_DoiTac
    const sheetDT = ss.getSheetByName("DM_DoiTac");
    if (sheetDT) {
      let rDT = sheetDT.getDataRange().getValues();
      if (rDT.length > 1) {
        let hDT = rDT[0].map(h => String(h || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
        let idxMa = hDT.indexOf("madoitac") > -1 ? hDT.indexOf("madoitac") : 0;
        let idxTen = hDT.indexOf("tendoitac") > -1 ? hDT.indexOf("tendoitac") : 2;
        let idxSdt = hDT.indexOf("sodienthoai") > -1 ? hDT.indexOf("sodienthoai") : 3;
        let idxDiaChi = hDT.indexOf("diachi") > -1 ? hDT.indexOf("diachi") : 4;
        let idxGioiTinh = hDT.indexOf("gioitinh") > -1 ? hDT.indexOf("gioitinh") : 5;
        let idxNgaySinh = hDT.indexOf("ngaysinh") > -1 ? hDT.indexOf("ngaysinh") : 6;
        let idxCongNo = hDT.indexOf("congno") > -1 ? hDT.indexOf("congno") : 7;
        let idxTT = hDT.indexOf("trangthai") > -1 ? hDT.indexOf("trangthai") : 8;

        for (let i = 1; i < rDT.length; i++) {
          let rowMa = String(rDT[i][idxMa] || "").trim().toUpperCase();
          let rowTen = String(rDT[i][idxTen] || "").trim();
          let rowSdt = String(rDT[i][idxSdt] || "").trim().replace(/\D/g, '');

          let isMatch = false;
          if (targetMa && targetMa !== "KL" && rowMa === targetMa) isMatch = true;
          else if (searchSdt && rowSdt && searchSdt === rowSdt) isMatch = true;
          else if (searchTen && rowTen && cleanStr(searchTen) === cleanStr(rowTen)) isMatch = true;

          if (isMatch) {
            infoKH = {
              maDoiTac: rowMa || targetMa,
              tenDoiTac: rowTen,
              soDienThoai: String(rDT[i][idxSdt] || ""),
              diaChi: String(rDT[i][idxDiaChi] || ""),
              gioiTinh: String(rDT[i][idxGioiTinh] || ""),
              ngaySinh: String(rDT[i][idxNgaySinh] || ""),
              congNo: Number(rDT[i][idxCongNo]) || 0,
              trangThai: String(rDT[i][idxTT] || "HoatDong")
            };
            targetMa = rowMa;
            if (!searchTen) searchTen = rowTen;
            if (!searchSdt) searchSdt = rowSdt;
            break;
          }
        }
      }
    }

    const tenTargetClean = searchTen ? cleanStr(searchTen) : "";

    // 2. Lịch sử mua hàng từ DonHang (POS)
    let allDonHang = (typeof apiGetDanhSachDonHang === 'function' ? apiGetDanhSachDonHang() : []) || [];
    allDonHang.forEach(d => {
      let mKH = String(d.maKH || "").trim().toUpperCase();
      let tKH = String(d.tenKH || "").trim();
      let sdtKH = String(d.soDienThoai || "").trim().replace(/\D/g, '');

      let match = (targetMa && mKH === targetMa) ||
                  (searchSdt && sdtKH && searchSdt === sdtKH) ||
                  (tenTargetClean && tKH && cleanStr(tKH).includes(tenTargetClean));

      if (match) {
        let isTra = String(d.trangThai || "").includes("Trả") || String(d.maDonHang || "").startsWith("PTH");
        if (isTra) {
          let tTien = Number(d.tongTien) || 0;
          tongGiaTriTra += tTien;
          let itemTra = {
            thoiGian: d.ngayBan || "",
            ngay: d.ngayBan || "",
            maChungTu: d.maDonHang,
            maPhieu: d.maDonHang,
            loaiGD: "KhachTra",
            tenLoaiGD: "Khách trả hàng",
            soTien: tTien,
            tongTien: tTien,
            hinhThuc: d.hinhThucTT || "TIEN_MAT",
            trangThai: d.trangThai || "Đã nhận trả",
            ghiChu: (d.chiTietSanPham && d.chiTietSanPham.length) ? (d.chiTietSanPham.map(p => `${p.tenHang} (x${p.soLuong})`).join(", ")) : "Trả lại hàng hóa",
            chiTiet: d.chiTietSanPham || []
          };
          lichSuTra.push(itemTra);
          danhSachGiaoDich.push(itemTra);
        } else {
          let tTien = Number(d.tongTien) || Number(d.khachPhaiTra) || 0;
          let dTra = Number(d.khachTra) || 0;
          tongGiaTriMua += tTien;
          tongDaThanhToan += dTra;
          let itemMua = {
            thoiGian: d.ngayBan || "",
            ngay: d.ngayBan || "",
            maChungTu: d.maDonHang,
            maPhieu: d.maDonHang,
            loaiGD: "BanHang",
            tenLoaiGD: "Hóa đơn bán hàng",
            soTien: tTien,
            tongTien: tTien,
            daTra: dTra,
            conNo: Math.max(0, tTien - dTra),
            hinhThuc: d.hinhThucTT || "TIEN_MAT",
            trangThai: d.trangThai || "Hoàn thành",
            ghiChu: (d.chiTietSanPham && d.chiTietSanPham.length) ? (d.chiTietSanPham.map(p => `${p.tenHang} (x${p.soLuong})`).join(", ")) : "Bán lẻ POS",
            chiTiet: d.chiTietSanPham || []
          };
          lichSuMua.push(itemMua);
          danhSachGiaoDich.push(itemMua);
        }
      }
    });

    // 3. Lịch sử Đơn Đặt Hàng từ DonDatHang (Bao gồm tiền cọc)
    let sheetDonDat = ss.getSheetByName("DonDatHang");
    if (sheetDonDat) {
      let rDD = sheetDonDat.getDataRange().getValues();
      if (rDD.length > 1) {
        let hDD = rDD[0].map(h => String(h || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
        let idxMaDon = hDD.indexOf("madondat") > -1 ? hDD.indexOf("madondat") : 0;
        let idxNgay = hDD.indexOf("ngaydat") > -1 ? hDD.indexOf("ngaydat") : 1;
        let idxMaKH = hDD.indexOf("makh") > -1 ? hDD.indexOf("makh") : 2;
        let idxTenKH = hDD.indexOf("tenkh") > -1 ? hDD.indexOf("tenkh") : 3;
        let idxSDT = hDD.indexOf("sodienthoai") > -1 ? hDD.indexOf("sodienthoai") : 4;
        let idxTong = hDD.indexOf("tongtien") > -1 ? hDD.indexOf("tongtien") : 5;
        let idxCoc = hDD.indexOf("tiencoc") > -1 ? hDD.indexOf("tiencoc") : 6;
        let idxTT = hDD.indexOf("trangthai") > -1 ? hDD.indexOf("trangthai") : 7;
        let idxCT = hDD.indexOf("chitietsanpham") > -1 ? hDD.indexOf("chitietsanpham") : -1;
        let idxGhiChu = hDD.indexOf("ghichu") > -1 ? hDD.indexOf("ghichu") : -1;

        for (let i = 1; i < rDD.length; i++) {
          let r = rDD[i];
          let maDon = String(r[idxMaDon] || "").trim();
          if (!maDon) continue;

          let mKH = idxMaKH > -1 ? String(r[idxMaKH] || "").trim().toUpperCase() : "";
          let tKH = idxTenKH > -1 ? String(r[idxTenKH] || "").trim() : "";
          let sdtKH = idxSDT > -1 ? String(r[idxSDT] || "").trim().replace(/\D/g, '') : "";

          let match = (targetMa && mKH === targetMa) ||
                      (searchSdt && sdtKH && searchSdt === sdtKH) ||
                      (tenTargetClean && tKH && cleanStr(tKH).includes(tenTargetClean));

          if (match) {
            let tongTien = Number(r[idxTong]) || 0;
            let tienCoc = Number(r[idxCoc]) || 0;
            let tt = String(r[idxTT] || "Chờ xử lý");
            let ngayStr = r[idxNgay];
            if (ngayStr instanceof Date) ngayStr = Utilities.formatDate(ngayStr, "GMT+7", "yyyy-MM-dd HH:mm:ss");

            let chiTiet = [];
            if (idxCT > -1 && r[idxCT]) {
              try { chiTiet = typeof r[idxCT] === 'string' ? JSON.parse(r[idxCT]) : r[idxCT]; } catch(e) {}
            }

            let spText = Array.isArray(chiTiet) ? chiTiet.map(p => `${p.tenHang || p.tenSP} (x${p.soLuong || 1})`).join(", ") : "";
            let noteStr = `Đơn đặt hàng ${maDon}` + (tienCoc > 0 ? ` (Đã cọc ${tienCoc.toLocaleString('vi-VN')} đ)` : "") + (spText ? ` - SP: ${spText}` : "");

            if (tt !== "Đã hủy") {
              tongGiaTriMua += tongTien;
              tongDaThanhToan += tienCoc;
            }

            let itemDat = {
              thoiGian: String(ngayStr || ""),
              ngay: String(ngayStr || ""),
              maChungTu: maDon,
              maPhieu: maDon,
              loaiGD: "DatHang",
              tenLoaiGD: "Đơn đặt hàng (Có cọc)",
              soTien: tongTien,
              tienCoc: tienCoc,
              hinhThuc: tienCoc > 0 ? "Tiền mặt (Cọc)" : "Chưa cọc",
              trangThai: tt,
              ghiChu: noteStr,
              chiTiet: chiTiet
            };
            lichSuDat.push(itemDat);
            danhSachGiaoDich.push(itemDat);
          }
        }
      }
    }

    // 4. Lịch sử Thu tiền / Thanh toán nợ / Đặt cọc từ Sổ Quỹ
    let sheetQuy = ss.getSheetByName("SoQuy");
    if (sheetQuy) {
      let rQ = sheetQuy.getDataRange().getValues();
      if (rQ.length > 1) {
        let hQ = rQ[0].map(h => String(h || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
        let idxMaP = hQ.indexOf("maphieu") > -1 ? hQ.indexOf("maphieu") : 1;
        let idxLoaiP = hQ.indexOf("loaiphieu") > -1 ? hQ.indexOf("loaiphieu") : 2;
        let idxLoaiQ = hQ.indexOf("loaiquy") > -1 ? hQ.indexOf("loaiquy") : 3;
        let idxNgay = hQ.indexOf("ngaygd") > -1 ? hQ.indexOf("ngaygd") : 4;
        let idxSoTien = hQ.indexOf("sotien") > -1 ? hQ.indexOf("sotien") : 5;
        let idxDoiTuong = hQ.indexOf("doituong") > -1 ? hQ.indexOf("doituong") : 6;
        let idxMaDT = hQ.indexOf("madoituong") > -1 ? hQ.indexOf("madoituong") : 7;
        let idxMaCT = hQ.indexOf("machungtu") > -1 ? hQ.indexOf("machungtu") : 8;
        let idxGhiChu = hQ.indexOf("ghichu") > -1 ? hQ.indexOf("ghichu") : 10;
        let idxTT = hQ.indexOf("trangthai") > -1 ? hQ.indexOf("trangthai") : 9;

        for (let i = 1; i < rQ.length; i++) {
          let r = rQ[i];
          let maDT = String(r[idxMaDT] || "").trim().toUpperCase();
          let maCT = String(r[idxMaCT] || "").trim().toUpperCase();
          let doiTuong = String(r[idxDoiTuong] || "").trim();
          let ghiChu = String(r[idxGhiChu] || "");
          let loaiP = String(r[idxLoaiP] || "").toUpperCase();

          let match = (targetMa && maDT === targetMa) ||
                      (targetMa && ghiChu.includes(targetMa)) ||
                      (tenTargetClean && ghiChu && cleanStr(ghiChu).includes(tenTargetClean)) ||
                      (lichSuDat.some(d => d.maChungTu.toUpperCase() === maCT));

          if (match && (loaiP === "THU" || loaiP.includes("THU"))) {
            let soTien = Number(r[idxSoTien]) || 0;
            let ngayStr = r[idxNgay];
            if (ngayStr instanceof Date) ngayStr = Utilities.formatDate(ngayStr, "GMT+7", "yyyy-MM-dd HH:mm:ss");

            let isCoc = maCT.startsWith("DDH") || ghiChu.toLowerCase().includes("cọc");
            let itemQuy = {
              thoiGian: String(ngayStr || ""),
              ngay: String(ngayStr || ""),
              maChungTu: String(r[idxMaP] || ("PT" + i)),
              maPhieu: String(r[idxMaP] || ("PT" + i)),
              loaiGD: isCoc ? "DatCoc" : "ThuNoKH",
              tenLoaiGD: isCoc ? "Thu tiền đặt cọc" : "Thu tiền nợ KH",
              loaiQuy: String(r[idxLoaiQ] || "TIEN_MAT"),
              hinhThuc: String(r[idxLoaiQ] || "TIEN_MAT"),
              soTien: soTien,
              trangThai: String(r[idxTT] || "DaThanhToan"),
              ghiChu: ghiChu
            };
            lichSuThanhToan.push(itemQuy);
            danhSachGiaoDich.push(itemQuy);
          }
        }
      }
    }

    // Sắp xếp giảm dần theo thời gian (mới nhất lên đầu)
    const getTime = (x) => new Date(x.thoiGian || x.ngay || 0).getTime() || 0;
    danhSachGiaoDich.sort((a, b) => getTime(b) - getTime(a));
    lichSuMua.sort((a, b) => getTime(b) - getTime(a));
    lichSuDat.sort((a, b) => getTime(b) - getTime(a));
    lichSuTra.sort((a, b) => getTime(b) - getTime(a));
    lichSuThanhToan.sort((a, b) => getTime(b) - getTime(a));

    return {
      success: true,
      maKH: targetMa,
      infoKH: infoKH,
      tongGiaTriMua: tongGiaTriMua,
      tongGiaTriTra: tongGiaTriTra,
      tongDaThanhToan: tongDaThanhToan,
      congNoHienTai: infoKH ? infoKH.congNo : 0,
      danhSachGiaoDich: danhSachGiaoDich,
      lichSuMua: lichSuMua,
      lichSuDat: lichSuDat,
      lichSuTra: lichSuTra,
      lichSuThanhToan: lichSuThanhToan
    };
  } catch(err) {
    Logger.log("Lỗi apiGetLichSuGiaoDichKH: " + err.message);
    return { success: false, error: err.message };
  }
}

// 2. Thu nợ Khách Hàng: Giảm công nợ trong DM_DoiTac và ghi phiếu thu vào SoQuy
function apiThanhToanCongNoKH(payload) {
  try {
    const maKH = String(payload.maKH || payload.maDoiTac || "").trim().toUpperCase();
    const soTien = Number(payload.soTien) || 0;
    if (!maKH) return { success: false, error: "Mã khách hàng không hợp lệ!" };
    if (soTien <= 0) return { success: false, error: "Số tiền thu phải lớn hơn 0!" };

    const ss = SpreadsheetApp.getActiveSpreadsheet();
    const sheetDT = ss.getSheetByName("DM_DoiTac");
    if (!sheetDT) return { success: false, error: "Không tìm thấy sheet DM_DoiTac" };

    const rowsDT = sheetDT.getDataRange().getValues();
    const headersDT = rowsDT.length > 0 ? rowsDT[0].map(h => String(h || "").trim().toLowerCase().replace(/[\s_]+/g, '')) : [];
    let idxMa = headersDT.indexOf("madoitac") > -1 ? headersDT.indexOf("madoitac") : 0;
    let idxCongNo = headersDT.indexOf("congno") > -1 ? headersDT.indexOf("congno") : 7;
    let idxTen = headersDT.indexOf("tendoitac") > -1 ? headersDT.indexOf("tendoitac") : 2;

    let foundRow = -1;
    let currentCongNo = 0;
    let tenKH = payload.tenKH || "";

    for (let i = 1; i < rowsDT.length; i++) {
      if (String(rowsDT[i][idxMa] || "").trim().toUpperCase() === maKH) {
        foundRow = i + 1;
        currentCongNo = Number(rowsDT[i][idxCongNo]) || 0;
        if (!tenKH && idxTen > -1) tenKH = String(rowsDT[i][idxTen] || "");
        break;
      }
    }

    let newCongNo = Math.max(0, currentCongNo - soTien);
    if (foundRow > -1) {
      sheetDT.getRange(foundRow, idxCongNo + 1).setValue(newCongNo);
    }

    // Ghi nhận Phiếu thu vào Sổ Quỹ
    let maPhieu = payload.maPhieu || ("PT" + Date.now().toString().slice(-6));
    let ngayGD = payload.ngayGD || Utilities.formatDate(new Date(), Session.getScriptTimeZone() || "GMT+7", "yyyy-MM-dd HH:mm:ss");
    let loaiQuy = payload.loaiQuy || payload.hinhThucTT || "TIEN_MAT";
    let chiNhanh = payload.chiNhanh || "CN01: Trụ sở chính";
    let nguoiNhan = payload.nguoiNhan || payload.nhanVien || "";
    let ghiChu = payload.ghiChu || `Thu tiền công nợ khách hàng ${tenKH || maKH}`;
    if (nguoiNhan && ghiChu.indexOf(nguoiNhan) === -1) {
      ghiChu = `[Người nhận: ${nguoiNhan}] ` + ghiChu;
    }

    let sheetQuy = ss.getSheetByName("SoQuy");
    if (!sheetQuy) {
      sheetQuy = ss.insertSheet("SoQuy");
      sheetQuy.appendRow(["ChiNhanh", "MaPhieu", "LoaiPhieu", "LoaiQuy", "NgayGD", "SoTien", "DoiTuong", "MaDoiTuong", "MaChungTu", "TrangThai", "GhiChu"]);
    }
    sheetQuy.appendRow([
      chiNhanh,
      maPhieu,
      "THU",
      loaiQuy,
      ngayGD,
      soTien,
      "Khách hàng",
      maKH,
      "THU_NO_KH",
      "DaThanhToan",
      ghiChu
    ]);

    // Đồng bộ sang Supabase
    try {
      if (typeof postToSupabaseServer === 'function') {
        if (typeof patchSupabaseServer === 'function') {
          patchSupabaseServer("dm_doitac", "ma_doi_tac=eq." + maKH, {
            cong_no: newCongNo
          });
        } else if (typeof postToSupabaseServer === 'function') {
          postToSupabaseServer("dm_doitac", {
            ma_doi_tac: maKH,
            cong_no: newCongNo
          });
        }
        let ngayGD_ISO = new Date().toISOString();
        if (payload.ngayGD) {
          try {
            let parsed = new Date(payload.ngayGD);
            if (!isNaN(parsed.getTime())) ngayGD_ISO = parsed.toISOString();
          } catch(eDate) {}
        }
        postToSupabaseServer("so_quy", {
          chi_nhanh: chiNhanh,
          ma_phieu: maPhieu,
          loai_phieu: "THU",
          loai_quy: loaiQuy,
          ngay_gd: ngayGD_ISO,
          so_tien: soTien,
          doi_tuong: "Khách hàng",
          ma_doi_tuong: maKH,
          ma_chung_tu: "THU_NO_KH",
          trang_thai: "DaThanhToan",
          ghi_chu: ghiChu
        });
      }
    } catch(eSup) {
      Logger.log("Lỗi đồng bộ Supabase thu nợ KH: " + eSup.message);
    }

    return {
      success: true,
      maKH: maKH,
      tenKH: tenKH,
      soTienDaThu: soTien,
      congNoCu: currentCongNo,
      congNoMoi: newCongNo,
      maPhieu: maPhieu
    };
  } catch(err) {
    Logger.log("Lỗi apiThanhToanCongNoKH: " + err.message);
    return { success: false, error: err.message };
  }
}

// 3. Quản lý Đơn Nhập Hàng (3.2)
const STANDARD_HEADERS_NHAPHANG = [
  "MaPhieu", "NgayNhap", "MaNCC", "TenNCC", "ChiNhanh",
  "TongTien", "DaTra", "ConNo", "TrangThai", "GhiChu", "ChiTietSanPham"
];

function getSheetNhapHang(ss) {
  let sheet = ss.getSheetByName("NhapHang");
  if (!sheet) {
    sheet = ss.insertSheet("NhapHang");
    sheet.appendRow(STANDARD_HEADERS_NHAPHANG);
    sheet.getRange(1, 1, 1, STANDARD_HEADERS_NHAPHANG.length).setFontWeight("bold").setBackground("#f1f5f9");
  } else {
    // Đảm bảo dòng 1 luôn là tiêu đề chuẩn
    const h = sheet.getRange(1, 1, 1, Math.max(sheet.getLastColumn(), 11)).getValues()[0];
    if (String(h[0] || '').trim().toLowerCase() !== 'maphieu' || String(h[1] || '').trim().toLowerCase() !== 'ngaynhap') {
      sheet.getRange(1, 1, 1, STANDARD_HEADERS_NHAPHANG.length).setValues([STANDARD_HEADERS_NHAPHANG]);
      sheet.getRange(1, 1, 1, STANDARD_HEADERS_NHAPHANG.length).setFontWeight("bold").setBackground("#f1f5f9");
    }
  }

  // Tự động kiểm tra và chuyển các phiếu PNH lỡ lưu ở sheet GiaoDich_NhapHang sang NhapHang
  try {
    const sheetGD = ss.getSheetByName("GiaoDich_NhapHang");
    if (sheetGD && sheetGD.getLastRow() > 1) {
      const rGD = sheetGD.getDataRange().getValues();
      let rowsToMove = [];
      for (let i = 1; i < rGD.length; i++) {
        let rowStr = rGD[i].map(c => String(c || '')).join(" ");
        if (rowStr.includes("PNH") || rowStr.includes("Laptop Vietstar") || String(rGD[i][0] || '').startsWith("PNH")) {
          rowsToMove.push({ index: i + 1, data: rGD[i] });
        }
      }
      if (rowsToMove.length > 0) {
        let mapDoiTac = getMapDoiTac(ss);
        rowsToMove.forEach(item => {
          let parsed = parseAndNormalizeDonNhapRow(item.data, mapDoiTac);
          sheet.appendRow([
            parsed.maPhieu,
            parsed.ngayNhap,
            parsed.maNCC,
            parsed.tenNCC,
            parsed.chiNhanh,
            parsed.tongTien,
            parsed.daTra,
            parsed.conNo,
            parsed.trangThai,
            parsed.ghiChu,
            JSON.stringify(parsed.chiTietSanPham)
          ]);
        });
        // Xóa từ dưới lên để không lệch index
        for (let k = rowsToMove.length - 1; k >= 0; k--) {
          try { sheetGD.deleteRow(rowsToMove[k].index); } catch(eD) {}
        }
      }
    }
  } catch(eMigrate) {
    Logger.log("Di chuyển dữ liệu nhập hàng cảnh báo: " + eMigrate.message);
  }

  return sheet;
}

function getMapDoiTac(ss) {
  let mapDoiTac = {};
  try {
    const sheetDT = ss.getSheetByName("DM_DoiTac");
    if (sheetDT) {
      const rowsDT = sheetDT.getDataRange().getValues();
      for (let k = 1; k < rowsDT.length; k++) {
        let m = String(rowsDT[k][0] || '').trim().toUpperCase();
        let t = String(rowsDT[k][2] || '').trim();
        if (m) mapDoiTac[m] = t || m;
      }
    }
  } catch(eDT) {}
  return mapDoiTac;
}

function parseAndNormalizeDonNhapRow(r, mapDoiTac) {
  // 1. Tìm chi tiết sản phẩm JSON
  let chiTiet = [];
  for (let j = 0; j < r.length; j++) {
    let val = r[j];
    if (typeof val === 'string') {
      let trimmed = val.trim();
      if ((trimmed.startsWith("[") && trimmed.endsWith("]")) || (trimmed.startsWith("{") && trimmed.endsWith("}"))) {
        try {
          let parsed = JSON.parse(trimmed);
          if (Array.isArray(parsed) && parsed.length > 0) {
            chiTiet = parsed;
            break;
          }
        } catch(e) {}
      }
    } else if (Array.isArray(val) && val.length > 0) {
      chiTiet = val;
      break;
    }
  }

  // 2. Tìm mã phiếu (bắt đầu bằng PN, PNH, NH)
  let maPhieu = "";
  for (let j = 0; j < r.length; j++) {
    let s = String(r[j] || "").trim();
    let m = s.match(/^(PN|PNH|NH)\d+/i);
    if (m) {
      maPhieu = m[0].toUpperCase();
      break;
    }
  }
  if (!maPhieu) {
    for (let j = 0; j < r.length; j++) {
      let s = String(r[j] || "").trim();
      let m = s.match(/(PNH\d+)/i);
      if (m) { maPhieu = m[1].toUpperCase(); break; }
    }
  }
  if (!maPhieu) maPhieu = "PNH" + Date.now().toString().slice(-6);

  // 3. Tìm ngày nhập
  let ngayNhap = "";
  for (let j = 0; j < r.length; j++) {
    let v = r[j];
    if (v instanceof Date) {
      ngayNhap = Utilities.formatDate(v, "GMT+7", "yyyy-MM-dd HH:mm:ss");
      break;
    } else if (typeof v === 'string') {
      let s = v.trim();
      if (/^\d{4}-\d{2}-\d{2}/.test(s) || /^\d{1,2}\/\d{1,2}\/\d{4}/.test(s) || s.includes("GMT") || s.includes("Giờ Đông Dương")) {
        try {
          let d = new Date(s);
          if (!isNaN(d.getTime())) {
            ngayNhap = Utilities.formatDate(d, "GMT+7", "yyyy-MM-dd HH:mm:ss");
            break;
          }
        } catch(e) {}
        ngayNhap = s;
        break;
      }
    }
  }
  if (!ngayNhap) ngayNhap = Utilities.formatDate(new Date(), "GMT+7", "yyyy-MM-dd HH:mm:ss");

  // 4. Tìm chi nhánh
  let chiNhanh = "";
  for (let j = 0; j < r.length; j++) {
    let s = String(r[j] || "").trim();
    if (s.includes("CN0") || s.includes("Trụ sở") || s.includes("Chi nhánh")) {
      chiNhanh = s;
      break;
    }
  }
  if (!chiNhanh) chiNhanh = "CN01: Trụ sở chính Thanh Miện";

  // 5. Tìm trạng thái
  let trangThai = "";
  for (let j = 0; j < r.length; j++) {
    let s = String(r[j] || "").trim();
    if (s === "Đã hủy" || s === "DaHuy") { trangThai = "Đã hủy"; break; }
    if (s === "Còn nợ" || s === "Một phần" || s === "Hoàn thành") { trangThai = s; }
  }

  // 6. Tính tổng tiền từ chi tiết sản phẩm nếu có
  let calcTong = 0;
  if (chiTiet.length > 0) {
    calcTong = chiTiet.reduce((sum, item) => sum + ((Number(item.soLuong) || 1) * (Number(item.donGia || item.giaNhap || item.thanhTien) || 0)), 0);
  }

  // Tìm các ô số (tổng tiền, đã trả, còn nợ)
  let numericValues = [];
  for (let j = 0; j < r.length; j++) {
    let val = r[j];
    if (typeof val === 'number' && !isNaN(val)) {
      numericValues.push(val);
    } else if (typeof val === 'string' && /^\d+$/.test(val.trim())) {
      let n = Number(val.trim());
      if (n > 0 && String(r[j]).trim() !== maPhieu) numericValues.push(n);
    }
  }

  let tongTien = calcTong > 0 ? calcTong : (numericValues.length > 0 ? Math.max(...numericValues) : 0);
  let daTra = (trangThai === "Đã hủy") ? 0 : tongTien;
  if (numericValues.length >= 2) {
    if (numericValues[0] === tongTien) daTra = numericValues[1];
    else if (numericValues[1] === tongTien && numericValues.length >= 3) daTra = numericValues[2];
  }
  let conNo = Math.max(0, tongTien - daTra);
  if (!trangThai) {
    trangThai = conNo > 0 ? (daTra > 0 ? "Một phần" : "Còn nợ") : "Hoàn thành";
  }

  // 7. Tìm Nhà cung cấp (Tên & Mã)
  let tenNCC = "";
  let maNCC = "";

  for (let j = 0; j < r.length; j++) {
    let s = String(r[j] || "").trim();
    let m = s.match(/^(NCC\w*)/i);
    if (m && m[1] !== s) {
      maNCC = m[1].toUpperCase();
    } else if (m && s.length <= 15) {
      maNCC = s.toUpperCase();
    }
  }

  for (let j = 0; j < r.length; j++) {
    let s = String(r[j] || "").trim();
    if (!s || s === maPhieu || s === chiNhanh || s === trangThai || s.startsWith("[") || s.match(/^\d+$/)) continue;
    if (s.includes("GMT") || s.includes("Giờ Đông Dương") || /^\d{4}-\d{2}-\d{2}/.test(s) || /^\d{1,2}\/\d{1,2}\/\d{4}/.test(s)) continue;
    if (s.includes("CN01") || s.includes("Trụ sở")) continue;
    if (s === "Đã hủy" || s === "Hoàn thành" || s === "Còn nợ" || s === "Một phần") continue;
    if (s.length >= 2 && !s.match(/^PNH\d+/i)) {
      tenNCC = s;
      break;
    }
  }

  if (tenNCC) {
    let m = tenNCC.match(/\((NCC\w+)\)/i);
    if (m) {
      if (!maNCC || maNCC === "NCC") maNCC = m[1].toUpperCase();
      tenNCC = tenNCC.replace(/\s*\([^)]*\)$/, '').trim();
    }
  }

  if (maNCC && mapDoiTac && mapDoiTac[maNCC.toUpperCase()]) {
    if (!tenNCC || tenNCC === "NCC" || tenNCC === "Nhà cung cấp") tenNCC = mapDoiTac[maNCC.toUpperCase()];
  } else if (tenNCC && mapDoiTac) {
    for (let k in mapDoiTac) {
      if (mapDoiTac[k].toLowerCase() === tenNCC.toLowerCase()) {
        maNCC = k;
        break;
      }
    }
  }

  if (!tenNCC) tenNCC = "Nhà cung cấp";
  if (!maNCC) maNCC = "NCC_LE";

  // 8. Tìm ghi chú
  let ghiChu = "";
  for (let j = 0; j < r.length; j++) {
    let s = String(r[j] || "").trim();
    if (!s || s === maPhieu || s === ngayNhap || s === maNCC || s === tenNCC || s === chiNhanh || s === trangThai || s.startsWith("[")) continue;
    if (/^\d+$/.test(s)) continue;
    ghiChu = s;
    break;
  }

  return {
    maPhieu: maPhieu,
    ngayNhap: ngayNhap,
    maNCC: maNCC,
    tenNCC: tenNCC,
    chiNhanh: chiNhanh,
    tongTien: tongTien,
    daTra: daTra,
    conNo: conNo,
    trangThai: trangThai,
    ghiChu: ghiChu,
    chiTietSanPham: chiTiet
  };
}

function apiGetDanhSachNhapHang() {
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet() || SpreadsheetApp.openById("1MZyIP9j7AQbUOgeGPmbA9EsWyhc0C1vXG9t1FWw_uFU");
    let sheet = getSheetNhapHang(ss);
    if (!sheet) return { success: true, data: [] };

    const rows = sheet.getDataRange().getValues();
    if (rows.length < 2) return { success: true, data: [] };

    let mapDoiTac = getMapDoiTac(ss);
    let list = [];
    let needUpdateSheet = false;
    let updatedRowsData = [];

    for (let i = 1; i < rows.length; i++) {
      let r = rows[i];
      let rowJoined = r.map(c => String(c || "")).join(" ").trim();
      if (!rowJoined) continue;

      let parsed = parseAndNormalizeDonNhapRow(r, mapDoiTac);
      list.push(parsed);

      let isMismatch = (
        String(r[0] || '').trim().toUpperCase() !== parsed.maPhieu.toUpperCase() ||
        String(r[1] || '').trim() !== parsed.ngayNhap ||
        String(r[3] || '').trim() !== parsed.tenNCC ||
        Number(r[5] || 0) !== parsed.tongTien
      );
      if (isMismatch) needUpdateSheet = true;

      updatedRowsData.push([
        parsed.maPhieu,
        parsed.ngayNhap,
        parsed.maNCC,
        parsed.tenNCC,
        parsed.chiNhanh,
        parsed.tongTien,
        parsed.daTra,
        parsed.conNo,
        parsed.trangThai,
        parsed.ghiChu,
        JSON.stringify(parsed.chiTietSanPham)
      ]);
    }

    if (needUpdateSheet && updatedRowsData.length > 0) {
      try {
        sheet.getRange(1, 1, 1, STANDARD_HEADERS_NHAPHANG.length).setValues([STANDARD_HEADERS_NHAPHANG]);
        sheet.getRange(2, 1, updatedRowsData.length, STANDARD_HEADERS_NHAPHANG.length).setValues(updatedRowsData);
        SpreadsheetApp.flush();
      } catch(eFixSheet) {
        Logger.log("Lỗi tự động chữa lành sheet NhapHang: " + eFixSheet.message);
      }
    }

    list.reverse();
    return { success: true, data: list };
  } catch(err) {
    Logger.log("Lỗi apiGetDanhSachNhapHang: " + err.message);
    return { success: false, error: err.message, data: [] };
  }
}

function apiLuuPhieuNhapHang(payload) {
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet() || SpreadsheetApp.openById("1MZyIP9j7AQbUOgeGPmbA9EsWyhc0C1vXG9t1FWw_uFU");
    let sheet = getSheetNhapHang(ss);

    const maPhieu = payload.maPhieu || ("PNH" + Date.now().toString().slice(-6));
    const ngayNhap = payload.ngayNhap || Utilities.formatDate(new Date(), Session.getScriptTimeZone() || "GMT+7", "yyyy-MM-dd HH:mm:ss");
    const tongTien = Number(payload.tongTien) || 0;
    const daTra = Number(payload.daTra) || 0;
    const conNo = Math.max(0, tongTien - daTra);
    const chiNhanh = payload.chiNhanh || "CN01: Trụ sở chính Thanh Miện";
    const chiTiet = Array.isArray(payload.chiTietSanPham) ? payload.chiTietSanPham : (Array.isArray(payload.chiTiet) ? payload.chiTiet : []);
    const isEdit = Boolean(payload.isEdit);
    const maNCC = payload.maNCC || "NCC_LE";
    const tenNCC = payload.tenNCC || "Nhà cung cấp";
    const trangThai = payload.trangThai || (conNo > 0 ? (daTra > 0 ? "Một phần" : "Còn nợ") : "Hoàn thành");
    const ghiChu = payload.ghiChu || "";

    const rows = sheet.getDataRange().getValues();
    let existingRowIndex = -1;
    let oldChiTiet = [];

    if (isEdit || payload.maPhieu) {
      for (let i = 1; i < rows.length; i++) {
        let r = rows[i];
        let found = false;
        if (String(r[0] || '').trim().toUpperCase() === String(maPhieu).trim().toUpperCase()) {
          found = true;
        } else {
          for (let j = 0; j < r.length; j++) {
            if (String(r[j] || '').trim().toUpperCase() === String(maPhieu).trim().toUpperCase()) {
              found = true; break;
            }
          }
        }
        if (found) {
          existingRowIndex = i + 1;
          try {
            let jsonStr = r[10] || "";
            if (!jsonStr) {
              for (let k = 0; k < r.length; k++) {
                if (String(r[k] || '').startsWith("[")) { jsonStr = r[k]; break; }
              }
            }
            oldChiTiet = JSON.parse(jsonStr);
          } catch(e) {}
          break;
        }
      }
    }

    const rowData = [
      maPhieu,
      ngayNhap,
      maNCC,
      tenNCC,
      chiNhanh,
      tongTien,
      daTra,
      conNo,
      trangThai,
      ghiChu,
      JSON.stringify(chiTiet)
    ];

    if (existingRowIndex > 0) {
      sheet.getRange(existingRowIndex, 1, 1, STANDARD_HEADERS_NHAPHANG.length).setValues([rowData]);
    } else {
      sheet.appendRow(rowData);
    }

    // 1. Quản lý tồn kho trong DM_HangHoa & IMEI trong Kho_IMEI
    const sheetHang = ss.getSheetByName("DM_HangHoa");
    let sheetIMEI = ss.getSheetByName("Kho_IMEI");
    if (!sheetIMEI) {
      sheetIMEI = ss.insertSheet("Kho_IMEI");
      sheetIMEI.appendRow(["ChiNhanh", "IMEI", "MaHang", "TrangThai", "MaPhieuNhap", "NgayCapNhat"]);
    }

    let rowsIMEI = sheetIMEI.getDataRange().getValues();
    let headersIMEI = rowsIMEI.length > 0 ? rowsIMEI[0].map(h => String(h || "").trim().toLowerCase().replace(/[\s_]+/g, '')) : [];
    if (headersIMEI.length === 0) {
      headersIMEI = ["chinhanh", "imei", "mahang", "trangthai", "maphieunhap", "ngaycapnhat"];
      sheetIMEI.appendRow(["ChiNhanh", "IMEI", "MaHang", "TrangThai", "MaPhieuNhap", "NgayCapNhat"]);
      rowsIMEI = sheetIMEI.getDataRange().getValues();
    }
    let colCN_IMEI = headersIMEI.indexOf("chinhanh");
    let colCode_IMEI = headersIMEI.indexOf("imei") > -1 ? headersIMEI.indexOf("imei") : headersIMEI.indexOf("serial");
    let colMa_IMEI = headersIMEI.indexOf("mahang");
    let colTT_IMEI = headersIMEI.indexOf("trangthai");
    let colPhieu_IMEI = headersIMEI.indexOf("maphieu") > -1 ? headersIMEI.indexOf("maphieu") : headersIMEI.indexOf("maphieunhap");
    let colNgay_IMEI = headersIMEI.indexOf("ngaycapnhat") > -1 ? headersIMEI.indexOf("ngaycapnhat") : headersIMEI.indexOf("ngaynhap");

    let mapImeiRow = {};
    for (let r = 1; r < rowsIMEI.length; r++) {
      let existingCode = String(rowsIMEI[r][colCode_IMEI > -1 ? colCode_IMEI : 1] || "").trim().toUpperCase();
      if (existingCode) mapImeiRow[existingCode] = r + 1;
    }

    if (sheetHang) {
      const rHang = sheetHang.getDataRange().getValues();
      const hHang = rHang[0].map(x => String(x || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
      let idxMa = hHang.indexOf("mahang") > -1 ? hHang.indexOf("mahang") : 0;
      let idxTon = hHang.indexOf("tonkho") > -1 ? hHang.indexOf("tonkho") : 7;
      let idxCoIMEI = hHang.indexOf("coquanlyimei") > -1 ? hHang.indexOf("coquanlyimei") : (hHang.indexOf("quanlyimei") > -1 ? hHang.indexOf("quanlyimei") : -1);

      if (isEdit && Array.isArray(oldChiTiet) && oldChiTiet.length > 0) {
        oldChiTiet.forEach(oldItem => {
          let mH = String(oldItem.maHang || "").trim().toUpperCase();
          let sl = Number(oldItem.soLuong) || 0;
          for (let i = 1; i < rHang.length; i++) {
            if (String(rHang[i][idxMa] || "").trim().toUpperCase() === mH) {
              let curTon = Number(rHang[i][idxTon]) || 0;
              let tonMoi = Math.max(0, curTon - sl);
              sheetHang.getRange(i + 1, idxTon + 1).setValue(tonMoi);
              rHang[i][idxTon] = tonMoi;
              break;
            }
          }
        });
      }

      if (chiTiet.length > 0) {
        chiTiet.forEach(item => {
          let mH = String(item.maHang || "").trim().toUpperCase();
          let sl = Number(item.soLuong) || 0;
          let imeis = item.imeiStr ? String(item.imeiStr).split(/[\n,;\r\t]+/).map(s => s.trim().toUpperCase()).filter(Boolean) : [];

          for (let i = 1; i < rHang.length; i++) {
            if (String(rHang[i][idxMa] || "").trim().toUpperCase() === mH) {
              let curTon = Number(rHang[i][idxTon]) || 0;
              let tonMoi = curTon + sl;
              sheetHang.getRange(i + 1, idxTon + 1).setValue(tonMoi);
              rHang[i][idxTon] = tonMoi;
              if (imeis.length > 0 && idxCoIMEI > -1) {
                sheetHang.getRange(i + 1, idxCoIMEI + 1).setValue("Có");
                rHang[i][idxCoIMEI] = "Có";
              }
              break;
            }
          }

          if (sheetIMEI && imeis.length > 0) {
            imeis.forEach(im => {
              if (mapImeiRow[im]) {
                let rowNum = mapImeiRow[im];
                if (colTT_IMEI > -1) sheetIMEI.getRange(rowNum, colTT_IMEI + 1).setValue("TrongKho");
                if (colMa_IMEI > -1) sheetIMEI.getRange(rowNum, colMa_IMEI + 1).setValue(mH);
                if (colCN_IMEI > -1) sheetIMEI.getRange(rowNum, colCN_IMEI + 1).setValue(chiNhanh);
                if (colPhieu_IMEI > -1) sheetIMEI.getRange(rowNum, colPhieu_IMEI + 1).setValue(maPhieu);
                if (colNgay_IMEI > -1) sheetIMEI.getRange(rowNum, colNgay_IMEI + 1).setValue(new Date());
              } else {
                let newRow = new Array(Math.max(headersIMEI.length, 6)).fill("");
                if (colCN_IMEI > -1) newRow[colCN_IMEI] = chiNhanh; else newRow[0] = chiNhanh;
                if (colCode_IMEI > -1) newRow[colCode_IMEI] = im; else newRow[1] = im;
                if (colMa_IMEI > -1) newRow[colMa_IMEI] = mH; else newRow[2] = mH;
                if (colTT_IMEI > -1) newRow[colTT_IMEI] = "TrongKho"; else newRow[3] = "TrongKho";
                if (colPhieu_IMEI > -1) newRow[colPhieu_IMEI] = maPhieu; else newRow[4] = maPhieu;
                if (colNgay_IMEI > -1) newRow[colNgay_IMEI] = new Date(); else newRow[5] = new Date();
                sheetIMEI.appendRow(newRow);
                mapImeiRow[im] = sheetIMEI.getLastRow();
              }
            });
          }
        });
      }
    }

    // 2. Ghi Sổ Quỹ nếu có thanh toán tiền (daTra > 0) và không phải chế độ sửa
    if (daTra > 0 && !isEdit) {
      let sheetQuy = ss.getSheetByName("SoQuy");
      if (!sheetQuy) {
        sheetQuy = ss.insertSheet("SoQuy");
        sheetQuy.appendRow(["ChiNhanh", "MaPhieu", "LoaiPhieu", "LoaiQuy", "NgayGD", "SoTien", "DoiTuong", "MaDoiTuong", "MaChungTu", "TrangThai", "GhiChu"]);
      }
      let maPC = "PC" + Date.now().toString().slice(-6);
      let loaiQuyChi = payload.loaiQuy || payload.hinhThucTT || "TIEN_MAT";
      sheetQuy.appendRow([
        chiNhanh,
        maPC,
        "CHI",
        loaiQuyChi,
        ngayNhap,
        daTra,
        "Nhà cung cấp",
        maNCC,
        maPhieu,
        "DaThanhToan",
        `Chi tiền nhập hàng ${maPhieu} - NCC ${tenNCC}`
      ]);
    }

    // 3. Tăng công nợ NCC nếu còn nợ (conNo > 0) và không phải chế độ sửa
    if (conNo > 0 && maNCC && !isEdit) {
      const sheetDT = ss.getSheetByName("DM_DoiTac");
      if (sheetDT) {
        const rDT = sheetDT.getDataRange().getValues();
        const hDT = rDT[0].map(x => String(x || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
        let idxMa = hDT.indexOf("madoitac") > -1 ? hDT.indexOf("madoitac") : 0;
        let idxCongNo = hDT.indexOf("congno") > -1 ? hDT.indexOf("congno") : (hDT.indexOf("congnoncc") > -1 ? hDT.indexOf("congnoncc") : (hDT.indexOf("no") > -1 ? hDT.indexOf("no") : 7));
        for (let i = 1; i < rDT.length; i++) {
          if (String(rDT[i][idxMa] || "").trim().toUpperCase() === String(maNCC).trim().toUpperCase()) {
            let curCN = Number(rDT[i][idxCongNo]) || 0;
            sheetDT.getRange(i + 1, idxCongNo + 1).setValue(curCN + conNo);
            break;
          }
        }
      }
    }

    SpreadsheetApp.flush();
    return { success: true, maPhieu: maPhieu };
  } catch(err) {
    Logger.log("Lỗi apiLuuPhieuNhapHang: " + err.message);
    return { success: false, error: err.message };
  }
}

// Hủy đơn nhập hàng (Hoàn tồn kho, hủy IMEI, hoàn tiền sổ quỹ & trừ nợ NCC)
function apiHuyDonNhapHang(payload) {
  try {
    const maPhieu = typeof payload === 'object' ? payload.maPhieu : payload;
    const lyDo = (typeof payload === 'object' && payload.lyDo) ? payload.lyDo : "Hủy đơn nhập theo yêu cầu người dùng";
    if (!maPhieu) return { success: false, error: "Thiếu mã phiếu nhập hàng!" };

    const ss = SpreadsheetApp.getActiveSpreadsheet() || SpreadsheetApp.openById("1MZyIP9j7AQbUOgeGPmbA9EsWyhc0C1vXG9t1FWw_uFU");
    let sheet = getSheetNhapHang(ss);
    if (!sheet) return { success: false, error: "Không tìm thấy sheet NhapHang!" };

    const rows = sheet.getDataRange().getValues();
    if (rows.length < 2) return { success: false, error: "Danh sách nhập hàng trống!" };

    let targetRowIndex = -1;
    let targetRow = null;

    for (let i = 1; i < rows.length; i++) {
      let r = rows[i];
      let match = false;
      if (String(r[0] || '').trim().toUpperCase() === String(maPhieu).trim().toUpperCase()) {
        match = true;
      } else {
        for (let j = 0; j < r.length; j++) {
          if (String(r[j] || '').trim().toUpperCase() === String(maPhieu).trim().toUpperCase()) {
            match = true; break;
          }
        }
      }
      if (match) {
        targetRowIndex = i + 1;
        targetRow = rows[i];
        break;
      }
    }

    if (targetRowIndex === -1) {
      return { success: false, error: "Không tìm thấy phiếu nhập " + maPhieu };
    }

    let mapDoiTac = getMapDoiTac(ss);
    let parsed = parseAndNormalizeDonNhapRow(targetRow, mapDoiTac);

    if (parsed.trangThai === "Đã hủy") {
      return { success: false, error: "Đơn nhập hàng " + maPhieu + " đã bị hủy trước đó rồi!" };
    }

    // 1. Phân tích chi tiết sản phẩm để hoàn tồn kho & đổi trạng thái IMEI
    let chiTiet = parsed.chiTietSanPham;
    const sheetHang = ss.getSheetByName("DM_HangHoa");
    if (sheetHang && Array.isArray(chiTiet) && chiTiet.length > 0) {
      const rHang = sheetHang.getDataRange().getValues();
      const hHang = rHang[0].map(x => String(x || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
      let idxMaH = hHang.indexOf("mahang") > -1 ? hHang.indexOf("mahang") : 0;
      let idxTonH = hHang.indexOf("tonkho") > -1 ? hHang.indexOf("tonkho") : 7;

      chiTiet.forEach(item => {
        let mH = String(item.maHang || '').trim().toUpperCase();
        let sl = Number(item.soLuong) || 0;
        if (mH && sl > 0) {
          for (let k = 1; k < rHang.length; k++) {
            if (String(rHang[k][idxMaH] || '').trim().toUpperCase() === mH) {
              let curTon = Number(rHang[k][idxTonH]) || 0;
              let tonMoi = Math.max(0, curTon - sl);
              sheetHang.getRange(k + 1, idxTonH + 1).setValue(tonMoi);
              rHang[k][idxTonH] = tonMoi;
              break;
            }
          }
        }
      });
    }

    // Đánh dấu hủy IMEI trong Kho_IMEI
    const sheetIMEI = ss.getSheetByName("Kho_IMEI");
    if (sheetIMEI && Array.isArray(chiTiet) && chiTiet.length > 0) {
      let allIMEIs = [];
      chiTiet.forEach(item => {
        if (item.imeiStr) {
          let arr = String(item.imeiStr).split(/[\n,;\r\t]+/).map(s => s.trim().toUpperCase()).filter(Boolean);
          allIMEIs = allIMEIs.concat(arr);
        }
      });
      if (allIMEIs.length > 0) {
        const rIMEI = sheetIMEI.getDataRange().getValues();
        let idxIMEICode = 1;
        let idxIMEIStatus = 3;
        for (let k = 1; k < rIMEI.length; k++) {
          let code = String(rIMEI[k][idxIMEICode] || '').trim().toUpperCase();
          if (allIMEIs.includes(code)) {
            sheetIMEI.getRange(k + 1, idxIMEIStatus + 1).setValue("HuyNhapKho");
          }
        }
      }
    }

    // 2. Hoàn trả tiền vào Sổ Quỹ (Ghi phiếu THU hoàn tiền nhập) nếu đơn đã thanh toán (daTra > 0)
    let daTra = parsed.daTra;
    if (daTra > 0) {
      let sheetQuy = ss.getSheetByName("SoQuy");
      if (!sheetQuy) {
        sheetQuy = ss.insertSheet("SoQuy");
        sheetQuy.appendRow(["ChiNhanh", "MaPhieu", "LoaiPhieu", "LoaiQuy", "NgayGD", "SoTien", "DoiTuong", "MaDoiTuong", "MaChungTu", "TrangThai", "GhiChu"]);
      }
      let maPT = "PT" + Date.now().toString().slice(-6);
      let nowStr = Utilities.formatDate(new Date(), "GMT+7", "yyyy-MM-dd HH:mm:ss");
      sheetQuy.appendRow([
        parsed.chiNhanh,
        maPT,
        "THU",
        "TIEN_MAT",
        nowStr,
        daTra,
        "Nhà cung cấp",
        parsed.maNCC,
        maPhieu,
        "DaThanhToan",
        `Thu hoàn tiền do hủy đơn nhập ${maPhieu} (NCC: ${parsed.tenNCC})`
      ]);
    }

    // 3. Giảm công nợ NCC nếu đơn có ghi nợ (conNo > 0)
    let conNo = parsed.conNo;
    if (conNo > 0 && parsed.maNCC) {
      const sheetDT = ss.getSheetByName("DM_DoiTac");
      if (sheetDT) {
        const rDT = sheetDT.getDataRange().getValues();
        const hDT = rDT[0].map(x => String(x || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
        let idxMaDT = hDT.indexOf("madoitac") > -1 ? hDT.indexOf("madoitac") : 0;
        let idxCongNo = hDT.indexOf("congno") > -1 ? hDT.indexOf("congno") : 7;
        for (let k = 1; k < rDT.length; k++) {
          if (String(rDT[k][idxMaDT] || '').trim().toUpperCase() === parsed.maNCC.toUpperCase()) {
            let curCN = Number(rDT[k][idxCongNo]) || 0;
            let cnMoi = Math.max(0, curCN - conNo);
            sheetDT.getRange(k + 1, idxCongNo + 1).setValue(cnMoi);
            break;
          }
        }
      }
    }

    // 4. Đánh dấu Đã hủy trong sheet NhapHang (Cột 9 - TrangThai)
    sheet.getRange(targetRowIndex, 9).setValue("Đã hủy");
    let curGC = parsed.ghiChu;
    sheet.getRange(targetRowIndex, 10).setValue(curGC ? (curGC + " | [ĐÃ HỦY: " + lyDo + "]") : ("[ĐÃ HỦY: " + lyDo + "]"));

    SpreadsheetApp.flush();
    return { success: true, message: `Đã hủy thành công đơn nhập hàng ${maPhieu}!` };
  } catch(err) {
    Logger.log("Lỗi apiHuyDonNhapHang: " + err.message);
    return { success: false, error: err.message };
  }
}

// Cập nhật đơn nhập hàng (Sửa NCC, Ghi chú, Trả thêm nợ)
function apiCapNhatDonNhapHang(payload) {
  try {
    const maPhieu = payload.maPhieu;
    if (!maPhieu) return { success: false, error: "Thiếu mã phiếu nhập hàng!" };

    const ss = SpreadsheetApp.getActiveSpreadsheet() || SpreadsheetApp.openById("1MZyIP9j7AQbUOgeGPmbA9EsWyhc0C1vXG9t1FWw_uFU");
    let sheet = getSheetNhapHang(ss);
    if (!sheet) return { success: false, error: "Không tìm thấy sheet NhapHang!" };

    const rows = sheet.getDataRange().getValues();
    if (rows.length < 2) return { success: false, error: "Danh sách nhập hàng trống!" };

    let targetRowIndex = -1;
    let targetRow = null;

    for (let i = 1; i < rows.length; i++) {
      let r = rows[i];
      let match = false;
      if (String(r[0] || '').trim().toUpperCase() === String(maPhieu).trim().toUpperCase()) {
        match = true;
      } else {
        for (let j = 0; j < r.length; j++) {
          if (String(r[j] || '').trim().toUpperCase() === String(maPhieu).trim().toUpperCase()) {
            match = true; break;
          }
        }
      }
      if (match) {
        targetRowIndex = i + 1;
        targetRow = rows[i];
        break;
      }
    }

    if (targetRowIndex === -1) {
      return { success: false, error: "Không tìm thấy phiếu nhập " + maPhieu };
    }

    let mapDoiTac = getMapDoiTac(ss);
    let parsed = parseAndNormalizeDonNhapRow(targetRow, mapDoiTac);

    if (parsed.trangThai === "Đã hủy") {
      return { success: false, error: "Đơn hàng này đã bị hủy, không thể chỉnh sửa!" };
    }

    // 1. Cập nhật NCC nếu có thay đổi
    let newTenNCC = payload.tenNCC || parsed.tenNCC;
    let newMaNCC = payload.maNCC || parsed.maNCC;
    sheet.getRange(targetRowIndex, 3).setValue(newMaNCC);
    sheet.getRange(targetRowIndex, 4).setValue(newTenNCC);

    // 2. Cập nhật Ghi chú
    if (typeof payload.ghiChu !== 'undefined') {
      sheet.getRange(targetRowIndex, 10).setValue(payload.ghiChu);
    }

    // 3. Trả thêm tiền nợ (nếu soTienTraThem > 0)
    let soTienTraThem = Number(payload.soTienTraThem) || 0;
    if (soTienTraThem > 0) {
      let tongTien = parsed.tongTien;
      let daTraCu = parsed.daTra;
      let daTraMoi = Math.min(tongTien, daTraCu + soTienTraThem);
      let conNoMoi = Math.max(0, tongTien - daTraMoi);
      let ttMoi = conNoMoi > 0 ? (daTraMoi > 0 ? "Một phần" : "Còn nợ") : "Hoàn thành";

      sheet.getRange(targetRowIndex, 7).setValue(daTraMoi);
      sheet.getRange(targetRowIndex, 8).setValue(conNoMoi);
      sheet.getRange(targetRowIndex, 9).setValue(ttMoi);

      // Ghi phiếu CHI vào SoQuy
      let sheetQuy = ss.getSheetByName("SoQuy");
      if (!sheetQuy) {
        sheetQuy = ss.insertSheet("SoQuy");
        sheetQuy.appendRow(["ChiNhanh", "MaPhieu", "LoaiPhieu", "LoaiQuy", "NgayGD", "SoTien", "DoiTuong", "MaDoiTuong", "MaChungTu", "TrangThai", "GhiChu"]);
      }
      let maPC = "PC" + Date.now().toString().slice(-6);
      let nowStr = Utilities.formatDate(new Date(), "GMT+7", "yyyy-MM-dd HH:mm:ss");
      sheetQuy.appendRow([
        parsed.chiNhanh,
        maPC,
        "CHI",
        payload.hinhThucTraThem || "TIEN_MAT",
        nowStr,
        soTienTraThem,
        "Nhà cung cấp",
        newMaNCC,
        maPhieu,
        "DaThanhToan",
        `Thanh toán thêm công nợ đơn nhập ${maPhieu} - NCC ${newTenNCC}`
      ]);

      // Giảm nợ NCC trong DM_DoiTac
      if (newMaNCC) {
        const sheetDT = ss.getSheetByName("DM_DoiTac");
        if (sheetDT) {
          const rDT = sheetDT.getDataRange().getValues();
          const hDT = rDT[0].map(x => String(x || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
          let idxMaDT = hDT.indexOf("madoitac") > -1 ? hDT.indexOf("madoitac") : 0;
          let idxCongNo = hDT.indexOf("congno") > -1 ? hDT.indexOf("congno") : 7;
          for (let k = 1; k < rDT.length; k++) {
            if (String(rDT[k][idxMaDT] || '').trim().toUpperCase() === newMaNCC.toUpperCase()) {
              let curCN = Number(rDT[k][idxCongNo]) || 0;
              let cnMoi = Math.max(0, curCN - soTienTraThem);
              sheetDT.getRange(k + 1, idxCongNo + 1).setValue(cnMoi);
              break;
            }
          }
        }
      }
    }

    // 4. Cập nhật Ngày nhập & Người nhập nếu có
    let headersNH = rows[0].map(h => String(h || '').trim().toLowerCase().replace(/[\s_]+/g, ''));
    let colNgayNH = headersNH.indexOf('ngaynhap') > -1 ? headersNH.indexOf('ngaynhap') : headersNH.indexOf('ngay');
    if (colNgayNH === -1) colNgayNH = 1;
    if (payload.ngayNhap) {
      sheet.getRange(targetRowIndex, colNgayNH + 1).setValue(payload.ngayNhap);
    }
    let newNguoiNhap = payload.nguoiNhap || payload.nhanVien;
    if (newNguoiNhap) {
      let colNV = headersNH.indexOf('nhanvien') > -1 ? headersNH.indexOf('nhanvien') : headersNH.indexOf('nguoinhap');
      if (colNV === -1) colNV = 11;
      sheet.getRange(targetRowIndex, colNV + 1).setValue(newNguoiNhap);
    }

    // 5. Cập nhật ngày giờ phiếu chi trong SoQuy nếu có
    if (payload.ngayNhap) {
      let sheetQuy = ss.getSheetByName("SoQuy");
      if (sheetQuy) {
        let qRows = sheetQuy.getDataRange().getValues();
        let qHeaders = qRows[0].map(h => String(h || '').toLowerCase().replace(/[\s_]+/g, ''));
        let colChungTu = qHeaders.indexOf("machungtu");
        let colNgayGD = qHeaders.indexOf("ngaygd") > -1 ? qHeaders.indexOf("ngaygd") : qHeaders.indexOf("ngay");
        if (colChungTu > -1 && colNgayGD > -1) {
          for (let k = 1; k < qRows.length; k++) {
            if (String(qRows[k][colChungTu] || '').trim().toUpperCase() === String(maPhieu).trim().toUpperCase()) {
              sheetQuy.getRange(k + 1, colNgayGD + 1).setValue(payload.ngayNhap);
              break;
            }
          }
        }
      }
    }

    // 6. Đồng bộ sang Supabase
    try {
      let sbDate = payload.ngayNhapISO || payload.ngayNhap;
      if (!payload.ngayNhapISO) {
        try {
          let dDate = new Date(payload.ngayNhap);
          if (!isNaN(dDate.getTime())) sbDate = dDate.toISOString();
        } catch(eD) {}
      }
      let sbPayload = {};
      if (sbDate) sbPayload.ngay_ban = sbDate;
      if (newNguoiNhap) sbPayload.nhan_vien = newNguoiNhap;
      if (newMaNCC) sbPayload.ma_kh = newMaNCC;
      if (newTenNCC) sbPayload.ten_kh = newTenNCC;
      if (typeof patchSupabaseServer === 'function') {
        patchSupabaseServer("don_hang", "ma_don_hang=eq." + encodeURIComponent(maPhieu), sbPayload);
        if (sbDate) {
          patchSupabaseServer("so_quy", "ma_chung_tu=eq." + encodeURIComponent(maPhieu), { ngay_gd: sbDate });
        }
      }
    } catch(eSb) {}

    SpreadsheetApp.flush();
    return { success: true, message: "Cập nhật đơn nhập hàng " + maPhieu + " thành công!" };
  } catch(err) {
    Logger.log("Lỗi apiCapNhatDonNhapHang: " + err.message);
    return { success: false, error: err.message };
  }
}


// 4. Quản lý Đơn Trả Hàng Nhà Cung Cấp (3.3)
function apiGetDanhSachTraHangNCC() {
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    let sheet = ss.getSheetByName("TraHangNCC") || ss.getSheetByName("GiaoDich_TraNCC");
    if (!sheet) return { success: true, data: [] };

    const rows = sheet.getDataRange().getValues();
    if (rows.length < 2) return { success: true, data: [] };

    const h = rows[0].map(x => String(x || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
    let idxMa = h.indexOf("maphieu") > -1 ? h.indexOf("maphieu") : 0;
    let idxNgay = h.indexOf("ngaytra") > -1 ? h.indexOf("ngaytra") : 1;
    let idxMaNCC = h.indexOf("mancc") > -1 ? h.indexOf("mancc") : 2;
    let idxTenNCC = h.indexOf("tenncc") > -1 ? h.indexOf("tenncc") : 3;
    let idxTong = h.indexOf("tongtien") > -1 ? h.indexOf("tongtien") : 4;
    let idxHinhThuc = h.indexOf("hinhthuc") > -1 ? h.indexOf("hinhthuc") : 5;
    let idxTT = h.indexOf("trangthai") > -1 ? h.indexOf("trangthai") : 6;
    let idxCT = h.indexOf("chitietsanpham") > -1 ? h.indexOf("chitietsanpham") : (h.indexOf("chitiet") > -1 ? h.indexOf("chitiet") : -1);
    let idxGhiChu = h.indexOf("ghichu") > -1 ? h.indexOf("ghichu") : -1;
    let idxCN = h.indexOf("chinhanh") > -1 ? h.indexOf("chinhanh") : -1;

    let list = [];
    for (let i = 1; i < rows.length; i++) {
      let r = rows[i];
      let maP = String(r[idxMa] || "").trim();
      if (!maP) continue;

      let ngayStr = r[idxNgay];
      if (ngayStr instanceof Date) ngayStr = Utilities.formatDate(ngayStr, "GMT+7", "yyyy-MM-dd HH:mm:ss");

      let chiTiet = [];
      if (idxCT > -1 && r[idxCT]) {
        try { chiTiet = typeof r[idxCT] === 'string' ? JSON.parse(r[idxCT]) : r[idxCT]; } catch(e) {}
      }

      list.push({
        maPhieu: maP,
        ngayTra: String(ngayStr || ""),
        maNCC: idxMaNCC > -1 ? String(r[idxMaNCC] || "") : "",
        tenNCC: idxTenNCC > -1 ? String(r[idxTenNCC] || "") : "",
        chiNhanh: idxCN > -1 ? String(r[idxCN] || "CN01: Trụ sở chính") : "CN01: Trụ sở chính",
        tongTien: Number(r[idxTong]) || 0,
        hinhThuc: idxHinhThuc > -1 ? String(r[idxHinhThuc] || "CONG_NO") : "CONG_NO",
        trangThai: String(r[idxTT] || "Đã trả hàng"),
        ghiChu: idxGhiChu > -1 ? String(r[idxGhiChu] || "") : "",
        chiTietSanPham: chiTiet
      });
    }

    list.reverse();
    return { success: true, data: list };
  } catch(err) {
    Logger.log("Lỗi apiGetDanhSachTraHangNCC: " + err.message);
    return { success: false, error: err.message, data: [] };
  }
}

function apiLuuPhieuTraHangNCC(payload) {
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    let sheet = ss.getSheetByName("TraHangNCC");
    if (!sheet) {
      sheet = ss.insertSheet("TraHangNCC");
      sheet.appendRow(["MaPhieu", "NgayTra", "MaNCC", "TenNCC", "TongTien", "HinhThuc", "TrangThai", "ChiTietSanPham", "GhiChu", "ChiNhanh"]);
    }

    const maPhieu = payload.maPhieu || ("PTN" + Date.now().toString().slice(-6));
    const ngayTra = payload.ngayTra || Utilities.formatDate(new Date(), Session.getScriptTimeZone() || "GMT+7", "yyyy-MM-dd HH:mm:ss");
    const tongTien = Number(payload.tongTien) || 0;
    const chiNhanh = payload.chiNhanh || "CN01: Trụ sở chính";
    const chiTiet = Array.isArray(payload.chiTietSanPham) ? payload.chiTietSanPham : [];
    const hinhThuc = payload.hinhThuc || "CONG_NO";

    sheet.appendRow([
      maPhieu,
      ngayTra,
      payload.maNCC || "",
      payload.tenNCC || "",
      tongTien,
      hinhThuc,
      "Đã trả hàng",
      JSON.stringify(chiTiet),
      payload.ghiChu || "",
      chiNhanh
    ]);

    // 1. Trừ tồn kho trong DM_HangHoa & chuyển trạng thái IMEI sang DaTraNCC
    const sheetHang = ss.getSheetByName("DM_HangHoa");
    const sheetIMEI = ss.getSheetByName("Kho_IMEI");

    if (sheetHang && chiTiet.length > 0) {
      const rHang = sheetHang.getDataRange().getValues();
      const hHang = rHang[0].map(x => String(x || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
      let idxMa = hHang.indexOf("mahang") > -1 ? hHang.indexOf("mahang") : 0;
      let idxTon = hHang.indexOf("tonkho") > -1 ? hHang.indexOf("tonkho") : 7;

      chiTiet.forEach(item => {
        let mH = String(item.maHang || "").trim().toUpperCase();
        let sl = Number(item.soLuong) || 0;
        for (let i = 1; i < rHang.length; i++) {
          if (String(rHang[i][idxMa] || "").trim().toUpperCase() === mH) {
            let curTon = Number(rHang[i][idxTon]) || 0;
            sheetHang.getRange(i + 1, idxTon + 1).setValue(Math.max(0, curTon - sl));
            rHang[i][idxTon] = Math.max(0, curTon - sl);
            break;
          }
        }

        // Cập nhật IMEI nếu có
        if (sheetIMEI && item.imeiStr) {
          let imeis = String(item.imeiStr).split(/[\n,;\r\t]+/).map(s => s.trim().toUpperCase()).filter(Boolean);
          const rIMEI = sheetIMEI.getDataRange().getValues();
          if (rIMEI.length > 1) {
            const hIMEI = rIMEI[0].map(x => String(x || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
            let colIMEI = hIMEI.indexOf("imei") > -1 ? hIMEI.indexOf("imei") : 1;
            let colTT = hIMEI.indexOf("trangthai") > -1 ? hIMEI.indexOf("trangthai") : 3;
            for (let j = 1; j < rIMEI.length; j++) {
              let imVal = String(rIMEI[j][colIMEI] || "").trim().toUpperCase();
              if (imeis.includes(imVal)) {
                sheetIMEI.getRange(j + 1, colTT + 1).setValue("DaTraNCC");
              }
            }
          }
        }
      });
    }

    // 2. Xử lý tài chính: Cấn trừ công nợ hoặc Thu tiền vào Sổ Quỹ
    if (hinhThuc === "CONG_NO" && payload.maNCC) {
      const sheetDT = ss.getSheetByName("DM_DoiTac");
      if (sheetDT) {
        const rDT = sheetDT.getDataRange().getValues();
        const hDT = rDT[0].map(x => String(x || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
        let idxMa = hDT.indexOf("madoitac") > -1 ? hDT.indexOf("madoitac") : 0;
        let idxCongNo = hDT.indexOf("congno") > -1 ? hDT.indexOf("congno") : 7;
        for (let i = 1; i < rDT.length; i++) {
          if (String(rDT[i][idxMa] || "").trim().toUpperCase() === String(payload.maNCC).trim().toUpperCase()) {
            let curCN = Number(rDT[i][idxCongNo]) || 0;
            sheetDT.getRange(i + 1, idxCongNo + 1).setValue(Math.max(0, curCN - tongTien));
            break;
          }
        }
      }
    } else if (tongTien > 0) {
      // Thu tiền mặt hoặc Chuyển khoản từ NCC
      let sheetQuy = ss.getSheetByName("SoQuy");
      if (!sheetQuy) {
        sheetQuy = ss.insertSheet("SoQuy");
        sheetQuy.appendRow(["ChiNhanh", "MaPhieu", "LoaiPhieu", "LoaiQuy", "NgayGD", "SoTien", "DoiTuong", "MaDoiTuong", "MaChungTu", "TrangThai", "GhiChu"]);
      }
      let maPT = "PT" + Date.now().toString().slice(-6);
      let loaiQuyThu = (hinhThuc === "TIEN_MAT" || hinhThuc === "TAI_KHOAN") ? hinhThuc : "TIEN_MAT";
      sheetQuy.appendRow([
        chiNhanh,
        maPT,
        "THU",
        loaiQuyThu,
        ngayTra,
        tongTien,
        "Nhà cung cấp",
        payload.maNCC || "",
        maPhieu,
        "DaThanhToan",
        `Thu tiền hoàn từ trả hàng NCC ${maPhieu} - NCC ${payload.tenNCC || payload.maNCC}`
      ]);
    }

    return { success: true, maPhieu: maPhieu };
  } catch(err) {
    Logger.log("Lỗi apiLuuPhieuTraHangNCC: " + err.message);
    return { success: false, error: err.message };
  }
}

// 5. Quản lý Đơn Đặt Hàng (4.1)
function apiGetDanhSachDonDatHang() {
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    if (typeof dongBoTienCocDonDatHang === 'function') {
      dongBoTienCocDonDatHang(ss);
    }
    let sheet = ss.getSheetByName("DonDatHang");
    if (!sheet) return { success: true, data: [] };

    const rows = sheet.getDataRange().getValues();
    if (rows.length < 2) return { success: true, data: [] };

    const h = rows[0].map(x => String(x || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
    let idxMa = h.indexOf("madondat") > -1 ? h.indexOf("madondat") : 0;
    let idxNgay = h.indexOf("ngaydat") > -1 ? h.indexOf("ngaydat") : 1;
    let idxMaKH = h.indexOf("makh") > -1 ? h.indexOf("makh") : 2;
    let idxTenKH = h.indexOf("tenkh") > -1 ? h.indexOf("tenkh") : 3;
    let idxSDT = h.indexOf("sodienthoai") > -1 ? h.indexOf("sodienthoai") : 4;
    let idxTong = h.indexOf("tongtien") > -1 ? h.indexOf("tongtien") : 5;
    let idxCoc = h.indexOf("tiencoc") > -1 ? h.indexOf("tiencoc") : 6;
    let idxTT = h.indexOf("trangthai") > -1 ? h.indexOf("trangthai") : 7;
    let idxCT = h.indexOf("chitietsanpham") > -1 ? h.indexOf("chitietsanpham") : (h.indexOf("chitiet") > -1 ? h.indexOf("chitiet") : -1);
    let idxGhiChu = h.indexOf("ghichu") > -1 ? h.indexOf("ghichu") : -1;
    let idxCN = h.indexOf("chinhanh") > -1 ? h.indexOf("chinhanh") : -1;

    let list = [];
    for (let i = 1; i < rows.length; i++) {
      let r = rows[i];
      let maD = String(r[idxMa] || "").trim();
      if (!maD) continue;

      let ngayStr = r[idxNgay];
      if (ngayStr instanceof Date) ngayStr = Utilities.formatDate(ngayStr, "GMT+7", "yyyy-MM-dd HH:mm:ss");

      let chiTiet = [];
      if (idxCT > -1 && r[idxCT]) {
        try { chiTiet = typeof r[idxCT] === 'string' ? JSON.parse(r[idxCT]) : r[idxCT]; } catch(e) {}
      }

      list.push({
        maDonDat: maD,
        maDon: maD,
        ngayDat: String(ngayStr || ""),
        maKH: idxMaKH > -1 ? String(r[idxMaKH] || "KL") : "KL",
        tenKH: idxTenKH > -1 ? String(r[idxTenKH] || "Khách lẻ") : "Khách lẻ",
        soDienThoai: idxSDT > -1 ? String(r[idxSDT] || "") : "",
        sdt: idxSDT > -1 ? String(r[idxSDT] || "") : "",
        chiNhanh: idxCN > -1 ? String(r[idxCN] || "CN01: Trụ sở chính") : "CN01: Trụ sở chính",
        tongTien: Number(r[idxTong]) || 0,
        tienCoc: Number(r[idxCoc]) || 0,
        trangThai: String(r[idxTT] || "Chờ xử lý"),
        ghiChu: idxGhiChu > -1 ? String(r[idxGhiChu] || "") : "",
        chiTietSanPham: chiTiet,
        chiTiet: chiTiet
      });
    }

    list.reverse();
    return { success: true, data: list };
  } catch(err) {
    Logger.log("Lỗi apiGetDanhSachDonDatHang: " + err.message);
    return { success: false, error: err.message, data: [] };
  }
}

function apiLuuDonDatHang(payload) {
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    let sheet = ss.getSheetByName("DonDatHang");
    if (!sheet) {
      sheet = ss.insertSheet("DonDatHang");
      sheet.appendRow(["MaDonDat", "NgayDat", "MaKH", "TenKH", "SoDienThoai", "TongTien", "TienCoc", "TrangThai", "ChiTietSanPham", "GhiChu", "ChiNhanh"]);
    }

    const maDonDat = payload.maDonDat || payload.maDon || ("DDH" + Date.now().toString().slice(-6));
    const ngayDat = payload.ngayDat || Utilities.formatDate(new Date(), Session.getScriptTimeZone() || "GMT+7", "yyyy-MM-dd HH:mm:ss");
    const tongTien = Number(payload.tongTien) || 0;
    const tienCoc = Number(payload.tienCoc) || 0;
    const chiNhanh = payload.chiNhanh || "CN01: Trụ sở chính";
    const soDienThoai = payload.soDienThoai || payload.sdt || "";
    const chiTiet = Array.isArray(payload.chiTietSanPham) ? payload.chiTietSanPham : (Array.isArray(payload.chiTiet) ? payload.chiTiet : []);
    const maKH = payload.maKH || "KL";
    const tenKH = payload.tenKH || "Khách lẻ";

    // Kiểm tra xem đơn đã tồn tại chưa để update hay thêm mới
    const rows = sheet.getDataRange().getValues();
    let foundRow = -1;
    for (let i = 1; i < rows.length; i++) {
      if (String(rows[i][0] || "").trim().toUpperCase() === maDonDat.toUpperCase()) {
        foundRow = i + 1;
        break;
      }
    }

    if (foundRow > -1) {
      if (maKH && maKH !== "KL") sheet.getRange(foundRow, 3).setValue(maKH);
      sheet.getRange(foundRow, 4).setValue(tenKH);
      sheet.getRange(foundRow, 5).setValue(soDienThoai);
      sheet.getRange(foundRow, 6).setValue(tongTien);
      sheet.getRange(foundRow, 7).setValue(tienCoc);
      sheet.getRange(foundRow, 8).setValue(payload.trangThai || "Chờ xử lý");
      sheet.getRange(foundRow, 9).setValue(JSON.stringify(chiTiet));
      sheet.getRange(foundRow, 10).setValue(payload.ghiChu || "");
      if (chiNhanh) sheet.getRange(foundRow, 11).setValue(chiNhanh);
    } else {
      sheet.appendRow([
        maDonDat,
        ngayDat,
        maKH,
        tenKH,
        soDienThoai,
        tongTien,
        tienCoc,
        payload.trangThai || "Chờ xử lý",
        JSON.stringify(chiTiet),
        payload.ghiChu || "",
        chiNhanh
      ]);
    }

    // Tự động đối soát tiền cọc, tạo phiếu thu và cập nhật công nợ
    if (typeof dongBoTienCocDonDatHang === 'function') {
      dongBoTienCocDonDatHang(ss);
    }

    return { success: true, maDonDat: maDonDat, maDon: maDonDat };
  } catch(err) {
    Logger.log("Lỗi apiLuuDonDatHang: " + err.message);
    return { success: false, error: err.message };
  }
}

function apiCapNhatTrangThaiDonDatHang(maDonDat, trangThaiMoi) {
  try {
    const ss = SpreadsheetApp.getActiveSpreadsheet();
    let sheet = ss.getSheetByName("DonDatHang");
    if (!sheet) return { success: false, error: "Không tìm thấy sheet DonDatHang" };

    const rows = sheet.getDataRange().getValues();
    let foundRow = -1;
    let donData = null;
    for (let i = 1; i < rows.length; i++) {
      if (String(rows[i][0] || "").trim().toUpperCase() === String(maDonDat).trim().toUpperCase()) {
        foundRow = i + 1;
        donData = rows[i];
        break;
      }
    }

    if (foundRow === -1) {
      return { success: false, error: "Không tìm thấy mã đơn đặt hàng" };
    }

    sheet.getRange(foundRow, 8).setValue(trangThaiMoi);

    // Nếu hủy đơn đặt hàng và đơn có tiền cọc > 0: giảm công nợ đã cộng trước đó
    if (trangThaiMoi === 'Đã hủy' && donData) {
      let tienCoc = Number(donData[6]) || 0;
      let maKH = String(donData[2] || "").trim().toUpperCase();
      if (tienCoc > 0 && maKH && maKH !== "KL") {
        try {
          let sheetDT = ss.getSheetByName("DM_DoiTac");
          if (sheetDT) {
            let rowsDT = sheetDT.getDataRange().getValues();
            let headersDT = rowsDT.length > 0 ? rowsDT[0].map(h => String(h || "").trim().toLowerCase().replace(/[\s_]+/g, '')) : [];
            let idxMaDT = headersDT.indexOf("madoitac") > -1 ? headersDT.indexOf("madoitac") : 0;
            let idxCongNoDT = headersDT.indexOf("congno") > -1 ? headersDT.indexOf("congno") : 7;
            for (let k = 1; k < rowsDT.length; k++) {
              if (String(rowsDT[k][idxMaDT] || "").trim().toUpperCase() === maKH) {
                let currDebt = Number(rowsDT[k][idxCongNoDT]) || 0;
                sheetDT.getRange(k + 1, idxCongNoDT + 1).setValue(Math.max(0, currDebt - tienCoc));
                break;
              }
            }
          }
        } catch(eHuy) {
          Logger.log("Lỗi hoàn công nợ khi hủy đơn đặt: " + eHuy.message);
        }
      }
    }

    return { success: true };
  } catch(err) {
    Logger.log("Lỗi apiCapNhatTrangThaiDonDatHang: " + err.message);
    return { success: false, error: err.message };
  }
}

// Cập nhật số lượng tồn kho chính xác cho một sản phẩm trong DM_HangHoa
function apiCapNhatTonKhoHangHoa(maHang, tonMoi) {
  try {
    if (!maHang) return { success: false, error: "Thiếu mã hàng" };
    const ss = SpreadsheetApp.getActiveSpreadsheet() || SpreadsheetApp.openById("1MZyIP9j7AQbUOgeGPmbA9EsWyhc0C1vXG9t1FWw_uFU");
    const sheetHang = ss.getSheetByName("DM_HangHoa");
    if (!sheetHang) return { success: false, error: "Không tìm thấy sheet DM_HangHoa" };
    const rows = sheetHang.getDataRange().getValues();
    if (rows.length < 2) return { success: false, error: "Bảng hàng hóa trống" };
    const headers = rows[0].map(h => String(h || "").trim().toLowerCase().replace(/[\s_]+/g, ''));
    let idxMa = headers.indexOf("mahang");
    let idxTon = headers.indexOf("tonkho");
    if (idxMa === -1) idxMa = 0;
    if (idxTon === -1) idxTon = 7;
    const targetMa = String(maHang).trim().toUpperCase();
    for (let i = 1; i < rows.length; i++) {
      if (String(rows[i][idxMa] || "").trim().toUpperCase() === targetMa) {
        sheetHang.getRange(i + 1, idxTon + 1).setValue(Number(tonMoi) || 0);
        return { success: true, maHang: targetMa, tonMoi: Number(tonMoi) || 0 };
      }
    }
    return { success: false, error: "Không tìm thấy sản phẩm " + targetMa };
  } catch(e) {
    return { success: false, error: e.message };
  }
}


// Alias cho apiLuuDonHangPOS
function apiLuuDonHang(order) {
  return apiLuuDonHangPOS(order);
}
