const SS = SpreadsheetApp.getActiveSpreadsheet();

// ====================================================================
// HỆ THỐNG TỰ ĐỘNG KHỞI TẠO BẢNG TÍNH & DỮ LIỆU MẪU ĐẦY ĐỦ
// ====================================================================
function ensureSheet(sheetName, headers) {
  var sheet = SS.getSheetByName(sheetName);
  if (!sheet) {
    sheet = SS.insertSheet(sheetName);
    sheet.appendRow(headers);
    sheet.getRange(1, 1, 1, headers.length).setFontWeight("bold").setBackground("#f1f5f9");
  }
  return sheet;
}

function initAllSheets() {
  var sNhom = ensureSheet("DM_NhomHang", ["MaNhom", "TenNhom", "MaNhomCha", "GhiChu"]);
  var sHang = ensureSheet("DM_HangHoa", ["MaHang", "TenHang", "MaNhom", "DonViTinh", "GiaVon", "GiaBan", "CoQuanLyIMEI", "TonKho", "TrangThai"]);
  var sIMEI = ensureSheet("Kho_IMEI", ["IMEI", "MaHang", "TrangThai", "MaPhieuNhap", "MaDonBan", "NgayCapNhat"]);
  var sBangGia = ensureSheet("DM_BangGia", ["MaBangGia", "TenBangGia", "MaHang", "GiaBan"]);
  var sDoiTac = ensureSheet("DM_DoiTac", ["MaDoiTac", "LoaiDoiTac", "TenDoiTac", "SoDienThoai", "DiaChi", "CongNo", "TrangThai", "GhiChu"]);
  var sDon = ensureSheet("GiaoDich_DonHang", ["MaDon", "LoaiDon", "NgayTao", "MaKH", "NhanVien", "TongTien", "GiamGia", "KhachTra", "HinhThucTT", "TrangThai", "GhiChu"]);
  var sCTDon = ensureSheet("ChiTiet_DonHang", ["MaChiTiet", "MaDon", "MaHang", "SoLuong", "DonGia", "GiaVon", "DanhSachIMEI"]);
  var sNhap = ensureSheet("GiaoDich_NhapHang", ["MaNhap", "LoaiDon", "NgayTao", "MaNCC", "TongTien", "DaTraNCC", "HinhThucTT", "TrangThai"]);
  var sCTNhap = ensureSheet("ChiTiet_NhapHang", ["MaChiTiet", "MaNhap", "MaHang", "SoLuong", "DonGiaNhap", "DanhSachIMEI"]);
  var sKhoKhac = ensureSheet("GiaoDich_KhoKhac", ["MaChungTu", "Loai", "NgayTao", "MaHang", "SL_SoSach", "SL_ThucTe", "ChenhLech", "DanhSachIMEI", "TrangThai", "GhiChu"]);
  var sSoQuy = ensureSheet("SoQuy", ["ChiNhanh", "MaPhieu", "LoaiPhieu", "LoaiQuy", "NgayGD", "SoTien", "DoiTuong", "MaDoiTuong", "MaChungTu", "TrangThai", "GhiChu"]);
  var sSuaChua = ensureSheet("YeuCau_SuaChua", [
    "MaYeuCau", "NgayTiepNhan", "ChiNhanh", "MaKH", "TenKH", "SoDienThoai", 
    "TenThietBi", "IMEI", "MatKhau", "PhuKien", "TinhTrangLoi", "TongTienHang", 
    "GiamGia", "KhachCanTra", "KhachDaTra", "TrangThai", "NguoiNhan", "MaHoaDonLienKet", "GhiChu"
  ]);

  // TỰ ĐỘNG BƠM DỮ LIỆU MẪU NẾU SHEET ĐANG TRỐNG ĐỂ HỆ THỐNG HOẠT ĐỘNG NGAY
  if (sHang.getLastRow() <= 1) {
    sNhom.appendRow(["NH001", "Điện Thoại Di Động", "", "Nhóm máy chính"]);
    sNhom.appendRow(["NH002", "Phụ Kiện Điện Tử", "", "Phụ kiện cao cấp"]);

    sHang.appendRow(["SP001", "iPhone 15 Pro Max 256GB", "NH001", "Cái", 26000000, 29500000, true, 12, "Kinh doanh"]);
    sHang.appendRow(["SP002", "Samsung Galaxy S24 Ultra 512GB", "NH001", "Cái", 24000000, 27900000, true, 8, "Kinh doanh"]);
    sHang.appendRow(["SP003", "Củ sạc nhanh 20W Type-C Anker", "NH002", "Cái", 150000, 350000, false, 45, "Kinh doanh"]);
    sHang.appendRow(["SP004", "Tai nghe AirPods Pro 2", "NH002", "Cái", 4200000, 5390000, true, 15, "Kinh doanh"]);

    sBangGia.appendRow(["BG01", "Bảng giá khách VIP", "SP001", 28500000]);
    sBangGia.appendRow(["BG02", "Bảng giá đại lý", "SP001", 27500000]);

    sDoiTac.appendRow(["NCC0001", "NCC", "Công ty Synnex FPT", "02473008888", "Hà Nội", 0, "HoatDong", ""]);
    sDoiTac.appendRow(["NCC0002", "NCC", "Công ty Cổ phần Thế Giới Số DGW", "02839290059", "TP.HCM", 0, "HoatDong", ""]);
    sDoiTac.appendRow(["KH0001", "KH", "Nguyễn Văn An", "0912345678", "Hà Nội", 0, "HoatDong", ""]);
    sDoiTac.appendRow(["KH0002", "KH", "Trần Thị Mai", "0987654321", "Đà Nẵng", 0, "HoatDong", ""]);
  }
}

function getTableData(sheetName) {
  initAllSheets();
  var sheet = SS.getSheetByName(sheetName);
  var values = sheet.getDataRange().getValues();
  if (values.length <= 1) return [];
  var headers = values[0];
  var rows = [];
  for (var i = 1; i < values.length; i++) {
    var obj = {};
    for (var j = 0; j < headers.length; j++) {
      obj[headers[j]] = values[i][j];
    }
    rows.push(obj);
  }
  return rows;
}

// ====================================================================
// MODULE 1: DASHBOARD
// ====================================================================
function getDashboardData(timeRange) {
  initAllSheets();
  var donHangList = getTableData("GiaoDich_DonHang");
  var chiTietList = getTableData("ChiTiet_DonHang");
  var now = new Date();
  var todayStr = Utilities.formatDate(now, "GMT+7", "yyyy-MM-dd");

  var doanhThuHomNay = 0, soDonHomNay = 0, traHangHomNay = 0, soDonTraHomNay = 0;
  var topHang = {}, topNhanVien = {};

  donHangList.forEach(function(don) {
    var ngayDon = don.NgayTao ? Utilities.formatDate(new Date(don.NgayTao), "GMT+7", "yyyy-MM-dd") : "";
    if (ngayDon === todayStr) {
      if (don.LoaiDon === 'HOA_DON') {
        doanhThuHomNay += (Number(don.KhachTra) || 0);
        soDonHomNay++;
      } else if (don.LoaiDon === 'TRA_HANG') {
        traHangHomNay += (Number(don.TongTien) || 0);
        soDonTraHomNay++;
      }
    }
    if (don.LoaiDon === 'HOA_DON') {
      var nv = don.NhanVien || "Admin";
      topNhanVien[nv] = (topNhanVien[nv] || 0) + (Number(don.KhachTra) || 0);
    }
  });

  chiTietList.forEach(function(ct) {
    topHang[ct.MaHang] = (topHang[ct.MaHang] || 0) + (Number(ct.SoLuong) || 0);
  });

  var dtThuanHomNay = doanhThuHomNay - traHangHomNay;

  return {
    kpi: {
      doanhThuHomNay: doanhThuHomNay,
      soDonHomNay: soDonHomNay,
      traHangHomNay: traHangHomNay,
      soDonTraHomNay: soDonTraHomNay,
      dtThuanHomNay: dtThuanHomNay,
      tangTruongHomQua: 0
    },
    topHang: topHang,
    topNhanVien: topNhanVien
  };
}

// ====================================================================
// MODULE 2: HÀNG HÓA, NHÓM HÀNG, BẢNG GIÁ, KIỂM KHO, XUẤT HỦY
// ====================================================================
function apiGetNhomHang() {
  return getTableData("DM_NhomHang");
}

function apiLuuChiTietNhomHang(data) {
  var sheet = SS.getSheetByName("DM_NhomHang");
  var values = sheet.getDataRange().getValues();
  var maNhom = String(data.maNhom || data.MaNhom || "").trim();
  var tenNhom = String(data.tenNhom || data.TenNhom || "").trim();
  var maNhomCha = String(data.maNhomCha || data.MaNhomCha || "").trim();
  var ghiChu = String(data.ghiChu || data.GhiChu || "").trim();

  var foundRow = -1;
  if (maNhom) {
    for (var i = 1; i < values.length; i++) {
      if (String(values[i][0]).toUpperCase() === maNhom.toUpperCase()) {
        foundRow = i + 1;
        break;
      }
    }
  }

  if (foundRow > 0) {
    sheet.getRange(foundRow, 2).setValue(tenNhom);
    sheet.getRange(foundRow, 3).setValue(maNhomCha);
    sheet.getRange(foundRow, 4).setValue(ghiChu);
    return { success: true, maNhom: maNhom, tenNhom: tenNhom, isUpdate: true };
  } else {
    var newCode = maNhom || ("NH" + ("000" + values.length).slice(-3));
    sheet.appendRow([newCode, tenNhom, maNhomCha, ghiChu]);
    return { success: true, maNhom: newCode, tenNhom: tenNhom, isUpdate: false };
  }
}

function apiLuuNhomHang(data) {
  return apiLuuChiTietNhomHang(data);
}

function apiXoaNhomHang(maNhom) {
  var sheet = SS.getSheetByName("DM_NhomHang");
  var values = sheet.getDataRange().getValues();
  for (var i = values.length - 1; i >= 1; i--) {
    if (String(values[i][0]) === String(maNhom)) {
      sheet.deleteRow(i + 1);
      return { success: true };
    }
  }
  return { success: false, error: "Không tìm thấy nhóm hàng" };
}

// apiGetDanhSachHangHoa được định nghĩa chính xác và hỗ trợ quét IMEI tại Code.js

function apiLuuHangHoa(data) {
  var sheetHang = SS.getSheetByName("DM_HangHoa");
  var hangValues = sheetHang.getDataRange().getValues();
  var maHang = String(data.maHang).trim();
  var rowIndex = -1;
  for (var i = 1; i < hangValues.length; i++) {
    if (String(hangValues[i][0]) === maHang) { rowIndex = i + 1; break; }
  }

  if (rowIndex > -1) {
    sheetHang.getRange(rowIndex, 2, 1, 8).setValues([[
      data.tenHang, data.maNhom, data.donViTinh || "Cái", Number(data.giaVon) || 0, Number(data.giaBan) || 0, data.coQuanLyIMEI, Number(data.tonKho) || 0, data.trangThai || "Kinh doanh"
    ]]);
  } else {
    sheetHang.appendRow([
      maHang, data.tenHang, data.maNhom, data.donViTinh || "Cái",
      Number(data.giaVon) || 0, Number(data.giaBan) || 0,
      data.coQuanLyIMEI, Number(data.tonKho) || 0, data.trangThai || "Kinh doanh"
    ]);
  }
  return { success: true, maHang: maHang };
}

// BẢNG GIÁ
function apiGetBangGiaData() {
  initAllSheets();
  var sheet = SS.getSheetByName("DM_BangGia");
  var values = sheet.getDataRange().getValues();
  var bangGiaSet = new Set(["Bảng giá bán lẻ chuẩn"]);
  var chiTiet = [];

  for (var i = 1; i < values.length; i++) {
    if (values[i][1]) bangGiaSet.add(String(values[i][1]).trim());
    chiTiet.push({
      maBangGia: values[i][0],
      tenBangGia: values[i][1],
      maHang: values[i][2],
      giaBan: Number(values[i][3]) || 0
    });
  }

  return { danhSachBangGia: Array.from(bangGiaSet), chiTietGia: chiTiet };
}

function apiLuuBangGia(payload) {
  var sheet = SS.getSheetByName("DM_BangGia");
  var values = sheet.getDataRange().getValues();
  var tenBangGia = payload.tenBangGia.trim();
  var maBangGia = "BG" + new Date().getTime();

  for (var i = values.length - 1; i >= 1; i--) {
    if (String(values[i][1]).trim() === tenBangGia) {
      sheet.deleteRow(i + 1);
    }
  }

  var newRows = [];
  payload.danhSachGia.forEach(function(item) {
    newRows.push([maBangGia, tenBangGia, item.maHang, Number(item.giaBan) || 0]);
  });
  if (newRows.length > 0) {
    sheet.getRange(sheet.getLastRow() + 1, 1, newRows.length, 4).setValues(newRows);
  }
  return { success: true };
}

function apiXoaBangGia(tenBangGia) {
  initAllSheets();
  var sheet = SS.getSheetByName("DM_BangGia");
  var values = sheet.getDataRange().getValues();
  var ten = String(tenBangGia || "").trim();
  if (!ten || ten === "Bảng giá bán lẻ chuẩn") {
    return { success: false, message: "Không thể xóa bảng giá này" };
  }

  for (var i = values.length - 1; i >= 1; i--) {
    if (String(values[i][1]).trim() === ten) {
      sheet.deleteRow(i + 1);
    }
  }
  return { success: true };
}

// ====================================================================
// KIỂM KHO & XUẤT HỦY
// (Đã được định nghĩa và tối ưu hóa chuyên nghiệp, đa chi nhánh, IMEI và Supabase trong Code.js)
// ====================================================================

// ====================================================================
// MODULE 3 & 4: ĐỐI TÁC, NHẬP HÀNG, ĐƠN HÀNG, TRẢ HÀNG
// ====================================================================
// apiGetDanhSachDoiTac, apiLuuDoiTac, apiLuuPhieuNhapHang, apiGetDanhSachTraHangNCC, apiLuuPhieuTraHangNCC
// đã được định nghĩa và tối ưu khớp cột chuẩn trong Code.js




function apiTaoHoaDon(payload) {
  var sheetDon = SS.getSheetByName("GiaoDich_DonHang");
  var sheetCT = SS.getSheetByName("ChiTiet_DonHang");
  var sheetHang = SS.getSheetByName("DM_HangHoa");
  var sheetSoQuy = SS.getSheetByName("SoQuy");

  var maDon = (payload.loaiDon === 'DAT_HANG' ? "DH" : (payload.loaiDon === 'TRA_HANG' ? "TH" : "HD")) + new Date().getTime();
  var ngayTao = Utilities.formatDate(new Date(), "GMT+7", "yyyy-MM-dd HH:mm:ss");

  sheetDon.appendRow([
    maDon, payload.loaiDon, ngayTao, payload.maKH, "Admin",
    Number(payload.tongTien) || 0, Number(payload.giamGia) || 0, Number(payload.khachTra) || 0,
    payload.hinhThucTT || "TIEN_MAT", "HoanThanh", ""
  ]);

  var hangValues = sheetHang.getDataRange().getValues();
  payload.chiTiet.forEach(function(item) {
    sheetCT.appendRow(["CT_" + Math.random(), maDon, item.maHang, Number(item.soLuong), Number(item.donGia), Number(item.donGia), ""]);
    for (var r = 1; r < hangValues.length; r++) {
      if (String(hangValues[r][0]) === String(item.maHang)) {
        var ton = Number(hangValues[r][7]) || 0;
        if (payload.loaiDon === 'TRA_HANG') {
          sheetHang.getRange(r + 1, 8).setValue(ton + Number(item.soLuong));
        } else if (payload.loaiDon === 'HOA_DON') {
          sheetHang.getRange(r + 1, 8).setValue(Math.max(0, ton - Number(item.soLuong)));
        }
        break;
      }
    }
  });

  if (payload.loaiDon === 'HOA_DON' && Number(payload.khachTra) > 0) {
    sheetSoQuy.appendRow(["CN01: Trụ sở chính", "PT" + new Date().getTime(), "THU", payload.hinhThucTT || "TIEN_MAT", ngayTao, Number(payload.khachTra), "Khách hàng", payload.maKH, maDon, "DaThanhToan", "Thu tiền bán hàng hóa đơn " + maDon]);
  } else if (payload.loaiDon === 'TRA_HANG' && Number(payload.khachTra) > 0) {
    sheetSoQuy.appendRow(["CN01: Trụ sở chính", "PC" + new Date().getTime(), "CHI", payload.hinhThucTT || "TIEN_MAT", ngayTao, Number(payload.khachTra), "Khách hàng", payload.maKH, maDon, "DaThanhToan", "Chi hoàn tiền trả hàng đơn " + maDon]);
  }

  return { success: true, maDon: maDon };
}

// ====================================================================
// MODULE 5: SỔ QUỸ (Được quản lý chính bởi apiGetChiTietSoQuy trong Code.js)
// ====================================================================

function apiTaoPhieuSoQuy(payload) {
  var sheet = SS.getSheetByName("SoQuy");
  if (!sheet) {
    initAllSheets();
    sheet = SS.getSheetByName("SoQuy");
  }
  var maPhieu = (payload.loaiPhieu === "THU" ? "PT" : "PC") + new Date().getTime();
  var ngayGD = Utilities.formatDate(new Date(), "GMT+7", "yyyy-MM-dd HH:mm:ss");

  sheet.appendRow([
    payload.chiNhanh || "CN01: Trụ sở chính",
    maPhieu,
    payload.loaiPhieu || "THU",
    payload.loaiQuy || payload.hinhThucTT || "TIEN_MAT",
    ngayGD,
    Number(payload.soTien) || 0,
    payload.doiTuong || "Khác",
    payload.maDoiTuong || "",
    payload.maChungTu || "THU_CONG",
    "DaThanhToan",
    payload.ghiChu || ""
  ]);
  return { success: true, maPhieu: maPhieu };
}

function apiHuyPhieuSoQuy(maPhieu) {
  var sheet = SS.getSheetByName("SoQuy");
  if (!sheet) return { success: false, error: "Không tìm thấy sheet SoQuy" };
  var values = sheet.getDataRange().getValues();
  if (values.length <= 1) return { success: false, error: "Không có dữ liệu" };

  var headers = values[0].map(function(h) { return String(h || "").trim().toLowerCase(); });
  var colMaPhieu = -1, colTrangThai = -1;
  for (var c = 0; c < headers.length; c++) {
    if (headers[c].indexOf("maphieu") > -1) colMaPhieu = c;
    if (headers[c].indexOf("trangthai") > -1) colTrangThai = c;
  }
  if (colMaPhieu === -1) colMaPhieu = (values[1] && String(values[1][0]).startsWith("CN")) ? 1 : 0;
  if (colTrangThai === -1) colTrangThai = headers.length >= 11 ? 9 : 8;

  for (var i = 1; i < values.length; i++) {
    if (String(values[i][colMaPhieu]) === String(maPhieu)) {
      sheet.getRange(i + 1, colTrangThai + 1).setValue("DaHuy");
      return { success: true };
    }
  }
  return { success: false, error: "Không tìm thấy phiếu " + maPhieu };
}



// ====================================================================
// MODULE 7: QUẢN LÝ NGƯỜI DÙNG & PHÂN QUYỀN (LƯU VĨNH VIỄN TRÊN GOOGLE SHEETS)
// ====================================================================

function apiGetDanhSachNguoiDung() {
  var sheet = SS.getSheetByName("DM_NguoiDung");
  if (!sheet) {
    // Tự động tạo sheet và tiêu đề nếu lỡ quên
    sheet = SS.insertSheet("DM_NguoiDung");
    sheet.appendRow(["MaNV", "Username", "Password", "HoTen", "VaiTro", "SoDienThoai", "Email", "TrangThai", "Permissions"]);
    sheet.getRange(1, 1, 1, 9).setFontWeight("bold").setBackground("#f1f5f9");
    
    // Bơm 4 tài khoản mẫu mặc định ban đầu
    sheet.appendRow(["NV001", "admin", "123456", "Quản Trị Viên Hệ Thống", "Admin", "0901111222", "admin@erp.local", "HoatDong", "ALL"]);
    sheet.appendRow(["NV002", "thukho", "123456", "Lê Văn Kho", "Quản lý kho", "0912222333", "kho@erp.local", "HoatDong", "HANG_HOA,KIEM_KHO,XUAT_HUY,MUA_HANG"]);
    sheet.appendRow(["NV003", "thungan01", "123456", "Trần Thị Mai Thu", "Thu ngân", "0983333444", "thungan@erp.local", "HoatDong", "DASHBOARD,DON_HANG,KHACH_HANG"]);
    sheet.appendRow(["NV004", "ketoan", "123456", "Phạm Hoàng Yến", "Kế toán", "0934444555", "ketoan@erp.local", "HoatDong", "SO_QUY,BAO_CAO,CONG_NO"]);
  }

  var values = sheet.getDataRange().getValues();
  if (values.length <= 1) return [];

  var result = [];
  for (var i = 1; i < values.length; i++) {
    var r = values[i];
    var permsStr = String(r[8] || "ALL").trim();
    var permsArr = permsStr ? permsStr.split(',').map(function(s) { return s.trim(); }) : ["ALL"];
    
    result.push({
      maNV: String(r[0] || ""),
      username: String(r[1] || ""),
      password: String(r[2] || "123456"),
      hoTen: String(r[3] || ""),
      vaiTro: String(r[4] || "Thu ngân"),
      soDienThoai: String(r[5] || ""),
      email: String(r[6] || ""),
      trangThai: String(r[7] || "HoatDong"),
      permissions: permsArr
    });
  }
  return result;
}

function apiLuuNguoiDung(payload) {
  var lock = LockService.getScriptLock();
  lock.waitLock(15000);
  try {
    var sheet = SS.getSheetByName("DM_NguoiDung");
    if (!sheet) throw new Error("Không tìm thấy trang tính DM_NguoiDung!");

    var values = sheet.getDataRange().getValues();
    var maNV = String(payload.maNV || "").trim().toUpperCase();
    var username = String(payload.username || "").trim().toLowerCase();

    var rowIndex = -1;
    for (var i = 1; i < values.length; i++) {
      if (String(values[i][0]).toUpperCase() === maNV || String(values[i][1]).toLowerCase() === username) {
        rowIndex = i + 1;
        break;
      }
    }

    var permsJoined = Array.isArray(payload.permissions) ? payload.permissions.join(',') : (payload.permissions || "ALL");

    if (rowIndex > -1) {
      // Cập nhật thông tin nhân viên đã có
      sheet.getRange(rowIndex, 4, 1, 5).setValues([[
        payload.hoTen,
        payload.vaiTro,
        "'" + (payload.soDienThoai || ""),
        payload.email || "",
        payload.trangThai || "HoatDong"
      ]]);
      if (payload.password) {
        sheet.getRange(rowIndex, 3).setValue(payload.password);
      }
      if (payload.permissions) {
        sheet.getRange(rowIndex, 9).setValue(permsJoined);
      }
    } else {
      // Thêm mới nhân viên
      sheet.appendRow([
        maNV,
        username,
        payload.password || "123456",
        payload.hoTen,
        payload.vaiTro,
        "'" + (payload.soDienThoai || ""),
        payload.email || "",
        payload.trangThai || "HoatDong",
        permsJoined
      ]);
    }

    return { success: true, message: "Đã lưu người dùng thành công!" };
  } catch (err) {
    return { success: false, error: err.message };
  } finally {
    lock.releaseLock();
  }
}

function apiCapNhatTrangThaiVaQuyenNguoiDung(payload) {
  var lock = LockService.getScriptLock();
  lock.waitLock(15000);
  try {
    var sheet = SS.getSheetByName("DM_NguoiDung");
    var values = sheet.getDataRange().getValues();
    var maNV = String(payload.maNV || "").trim().toUpperCase();

    for (var i = 1; i < values.length; i++) {
      if (String(values[i][0]).toUpperCase() === maNV) {
        if (payload.trangThai) {
          sheet.getRange(i + 1, 8).setValue(payload.trangThai);
        }
        if (payload.permissions) {
          var joined = Array.isArray(payload.permissions) ? payload.permissions.join(',') : payload.permissions;
          sheet.getRange(i + 1, 9).setValue(joined);
        }
        return { success: true, message: "Cập nhật thành công!" };
      }
    }
    return { success: false, error: "Không tìm thấy nhân viên mã: " + maNV };
  } catch (err) {
    return { success: false, error: err.message };
  } finally {
    lock.releaseLock();
  }
}

// ====================================================================
// HỆ THỐNG XÁC THỰC ĐĂNG NHẬP
// ====================================================================
function apiKiemTraDangNhap(username, password) {
  var sheet = SS.getSheetByName("DM_NguoiDung");
  if (!sheet) return { success: false, error: "Hệ thống chưa khởi tạo bảng dữ liệu người dùng!" };
  
  var values = sheet.getDataRange().getValues();
  var uClean = String(username || "").trim().toLowerCase();
  var pClean = String(password || "").trim();

  for (var i = 1; i < values.length; i++) {
    var r = values[i];
    var dbUser = String(r[1] || "").trim().toLowerCase();
    var dbPass = String(r[2] || "").trim();
    var trangThai = String(r[7] || "HoatDong").trim();

    if (dbUser === uClean) {
      if (trangThai === "TamKhoa") {
        return { success: false, error: "Tài khoản của bạn đã bị tạm khóa bởi quản trị viên!" };
      }
      if (dbPass === pClean) {
        var permsStr = String(r[8] || "ALL").trim();
        var permsArr = permsStr ? permsStr.split(',').map(function(s) { return s.trim(); }) : ["ALL"];
        
        return {
          success: true,
          user: {
            maNV: String(r[0] || ""),
            username: dbUser,
            hoTen: String(r[3] || ""),
            vaiTro: String(r[4] || "Thu ngân"),
            soDienThoai: String(r[5] || ""),
            email: String(r[6] || ""),
            permissions: permsArr
          }
        };
      } else {
        return { success: false, error: "Mật khẩu không chính xác!" };
      }
    }
  }
  return { success: false, error: "Tên đăng nhập không tồn tại trong hệ thống!" };
}
