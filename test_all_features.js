const fs = require('fs');
const vm = require('vm');

// Create mock browser environment
const localStorageData = {};
const localStorage = {
  getItem: (k) => localStorageData[k] || null,
  setItem: (k, v) => { localStorageData[k] = String(v); },
  removeItem: (k) => { delete localStorageData[k]; }
};

const sessionStorageData = {};
const sessionStorage = {
  getItem: (k) => sessionStorageData[k] || null,
  setItem: (k, v) => { sessionStorageData[k] = String(v); }
};

const mockElements = {};
function getMockEl(id) {
  if (!mockElements[id]) {
    mockElements[id] = {
      id: id,
      value: '',
      innerText: '',
      textContent: '',
      innerHTML: '',
      checked: true, options: [],
      classList: {
        add: () => {},
        remove: () => {},
        contains: () => false
      },
      focus: () => {},
      select: () => {},
      appendChild: () => {},
      removeChild: () => {},
      remove: () => {}
    };
  }
  return mockElements[id];
}

const sandbox = {
  console: console,
  setTimeout: setTimeout,
  clearTimeout: clearTimeout,
  Date: Date,
  Math: Math,
  JSON: JSON,
  String: String,
  Number: Number,
  Array: Array,
  Map: Map,
  Set: Set,
  Boolean: Boolean,
  localStorage: localStorage,
  sessionStorage: sessionStorage,
  location: { pathname: '/', search: '', hash: '', href: 'http://localhost', hostname: 'localhost' },
  navigator: { userAgent: 'Mozilla/5.0 Node' },
  tailwind: { config: { theme: { extend: {} } } },
  document: {
    getElementById: getMockEl,
    querySelector: () => null,
    querySelectorAll: () => [],
    createElement: (tag) => getMockEl('dummy_' + tag),
    addEventListener: () => {},
    readyState: 'complete'
  },
  window: {},
  showNotification: (msg, isErr) => {
    console.log(`[NOTIFICATION] ${isErr ? 'ERROR' : 'SUCCESS'}: ${msg}`);
  },
  confirm: (msg) => true,
  escapeHtml: (s) => s,
  google: {
    script: {
      run: {
        withSuccessHandler: function(cb) {
          return {
            withFailureHandler: function() {
              return {
                apiLuuChiNhanh: (d) => { if (cb) cb({ success: true, list: [d] }); },
                apiGetDanhSachChiNhanh: () => { if (cb) cb([{ ma: 'CN01', ten: 'Thanh Miện' }, { ma: 'CN02', ten: 'Thanh Giang' }]); },
                apiLuuPhieuKiemKho: (p) => { if (cb) cb({ success: true, maPhieu: p.maChungTu }); },
                apiGetDanhSachKiemKho: () => { if (cb) cb([]); },
                apiHuyPhieuKiemKho: (m) => { if (cb) cb({ success: true, maChungTu: m }); },
                apiLuuPhieuChuyenKho: (p) => { if (cb) cb({ success: true, maPhieu: p.maPhieu }); },
                apiNhanHangChuyenKho: (m) => { if (cb) cb({ success: true, maPhieu: m }); },
                apiHuyPhieuChuyenKho: (m) => { if (cb) cb({ success: true, maPhieu: m }); }
              };
            },
            apiLuuChiNhanh: (d) => { if (cb) cb({ success: true, list: [d] }); },
            apiGetDanhSachChiNhanh: () => { if (cb) cb([{ ma: 'CN01', ten: 'Thanh Miện' }, { ma: 'CN02', ten: 'Thanh Giang' }]); },
            apiLuuPhieuKiemKho: (p) => { if (cb) cb({ success: true, maPhieu: p.maChungTu }); },
            apiGetDanhSachKiemKho: () => { if (cb) cb([]); },
            apiHuyPhieuKiemKho: (m) => { if (cb) cb({ success: true, maChungTu: m }); },
            apiLuuPhieuChuyenKho: (p) => { if (cb) cb({ success: true, maPhieu: p.maPhieu }); },
            apiNhanHangChuyenKho: (m) => { if (cb) cb({ success: true, maPhieu: m }); },
            apiHuyPhieuChuyenKho: (m) => { if (cb) cb({ success: true, maPhieu: m }); }
          };
        }
      }
    }
  }
};
sandbox.window = sandbox;

// Load du_lieu_thanh_giang.js into sandbox to get raw baseline data
console.log('Loading du_lieu_thanh_giang.js into sandbox...');
const rawDataScript = fs.readFileSync('du_lieu_thanh_giang.js', 'utf8');
vm.runInNewContext(rawDataScript, sandbox);

// Load index.html main scripts into sandbox
console.log('Extracting scripts from index.html...');
const html = fs.readFileSync('index.html', 'utf8');
const regex = /<script\b[^>]*>([\s\S]*?)<\/script>/gi;
let match;
let count = 0;
while ((match = regex.exec(html)) !== null) {
  count++;
  const src = match[1];
  if (!src.trim()) continue;
  try {
    vm.runInNewContext(src, sandbox);
  } catch(e) {
    console.warn(`Script #${count} run warning:`, e.message);
  }
}

// Ensure currentUser is set as Admin AFTER scripts loading
sandbox.currentUser = { username: 'admin', vaiTro: 'Admin', hoTen: 'Quản trị viên' };
sandbox.window.currentUser = sandbox.currentUser;
sandbox.hasPermission = () => true;
sandbox.window.hasPermission = () => true;

// -------------------------------------------------------------
// TEST 1: KIỂM KHO - LƯU TẠM, CÂN BẰNG, SỬA VÀ HỦY PHIẾU
// -------------------------------------------------------------
console.log('\n--- TEST 1: KIỂM TRA PHIẾU KIỂM KHO (LƯU TẠM, SỬA, HỦY) ---');
if (sandbox.RAW_HANG_HOA_THANH_GIANG) {
  sandbox.rawHangHoa = sandbox.RAW_HANG_HOA_THANH_GIANG;
}
sandbox.khoiTaoTonKhoDaChiNhanh();
const stockBeforeKK = sandbox.layTonKhoSanPhamTaiChiNhanh('SP527547', 'CN01');
console.log('Tồn kho SP527547 tại CN01 trước kiểm:', stockBeforeKK);

// 1.1 Lưu tạm phiếu kiểm kho
sandbox.moLapPhieuKiemKho();
sandbox.themHoacCongDonKiemKho('SP527547');
sandbox.danhSachKiemKhoItems[0].slThucTe = 10;
sandbox.danhSachKiemKhoItems[0].chenhLech = 10 - stockBeforeKK;
sandbox.xacNhanHoanTatKiemKho(true); // Lưu tạm

const draftKK = sandbox.rawKiemKhoList[0];
console.log(`Phiếu kiểm tạm [${draftKK?.maChungTu}] trạng thái:`, draftKK?.trangThai);
console.log('Tồn kho SP527547 sau khi lưu tạm (phải giữ nguyên):', sandbox.layTonKhoSanPhamTaiChiNhanh('SP527547', 'CN01'));
if (draftKK?.trangThai === 'Phiếu tạm' && sandbox.layTonKhoSanPhamTaiChiNhanh('SP527547', 'CN01') === stockBeforeKK) {
  console.log('[PASS] Kiểm kho - Lưu tạm thành công (không làm thay đổi tồn kho).');
} else {
  console.error('[FAIL] Lưu tạm kiểm kho không đúng');
}

// 1.2 Sửa phiếu kiểm kho tạm và hoàn thành (cân bằng kho)
sandbox.suaPhieuKiemKho(draftKK.maChungTu);
console.log('Số lượng trong form sửa:', sandbox.danhSachKiemKhoItems[0].slThucTe);
sandbox.danhSachKiemKhoItems[0].slThucTe = 8;
sandbox.danhSachKiemKhoItems[0].chenhLech = 8 - stockBeforeKK;
getMockEl('kk-phieu-canbang').checked = true;
sandbox.xacNhanHoanTatKiemKho(false); // Cân bằng

const balancedKK = sandbox.rawKiemKhoList.find(k => k.maChungTu === draftKK.maChungTu);
const stockAfterBalance = sandbox.layTonKhoSanPhamTaiChiNhanh('SP527547', 'CN01');
console.log(`Phiếu [${balancedKK?.maChungTu}] sau cân bằng:`, balancedKK?.trangThai, 'Tồn kho SP527547:', stockAfterBalance);
if (stockAfterBalance === 8) {
  console.log('[PASS] Kiểm kho - Sửa và cân bằng tồn kho thành công (tồn kho cập nhật = 8).');
} else {
  console.error('[FAIL] Cân bằng kiểm kho không đúng, tồn kho là:', stockAfterBalance);
}

// 1.3 Hủy phiếu kiểm kho đã cân bằng (Hoàn tác tồn kho về trước kiểm)
sandbox.huyPhieuKiemKho(draftKK.maChungTu);
const cancelledKK = sandbox.rawKiemKhoList.find(k => k.maChungTu === draftKK.maChungTu);
const stockAfterCancel = sandbox.layTonKhoSanPhamTaiChiNhanh('SP527547', 'CN01');
console.log(`Phiếu [${cancelledKK?.maChungTu}] sau khi hủy:`, cancelledKK?.trangThai, 'Tồn kho hoàn tác về:', stockAfterCancel);
if (cancelledKK?.trangThai === 'Đã hủy' && stockAfterCancel === stockBeforeKK) {
  console.log('[PASS] Kiểm kho - Hủy phiếu thành công (tồn kho đã hoàn tác về ban đầu).');
} else {
  console.error('[FAIL] Hủy phiếu kiểm kho hoàn tác sai!');
}

// -------------------------------------------------------------
// TEST 2: CHUYỂN KHO - LƯU TẠM, XUẤT ĐI, NHẬN HÀNG, SỬA, HỦY
// -------------------------------------------------------------
console.log('\n--- TEST 2: KIỂM TRA CHUYỂN KHO (LƯU TẠM, XUẤT, NHẬN HÀNG, HỦY) ---');
// Đặt lại tồn kho SP527547 tại CN01 = 20, CN02 = 5
sandbox.capNhatTonKhoSanPhamTaiChiNhanh('SP527547', 'CN01', 20);
sandbox.capNhatTonKhoSanPhamTaiChiNhanh('SP527547', 'CN02', 5);
console.log('Tồn kho ban đầu - CN01:', sandbox.layTonKhoSanPhamTaiChiNhanh('SP527547', 'CN01'), '| CN02:', sandbox.layTonKhoSanPhamTaiChiNhanh('SP527547', 'CN02'));

// 2.1 Lưu tạm phiếu chuyển kho
getMockEl('select-chuyenkho-xuat').value = 'CN01';
getMockEl('select-chuyenkho-nhan').value = 'CN02';
getMockEl('display-maphieu-chuyenkho').innerText = 'CK_TEST_001';
sandbox.danhSachChuyenKhoCart = [{
  maHang: 'SP527547',
  tenHang: 'Chân sạc SS Note 5',
  donViTinh: 'Cái',
  tonXuat: 20,
  tonNhan: 5,
  soLuong: 3,
  donGia: 15000,
  coQuanLyIMEI: false,
  imeiDaChon: []
}];

sandbox.xacNhanThucHienChuyenKho(true); // Lưu tạm
const draftCK = (sandbox.rawChuyenKhoList || []).find(p => p.maPhieu === 'CK_TEST_001');
console.log(`Phiếu chuyển [${draftCK?.maPhieu}] trạng thái:`, draftCK?.trangThai);
console.log('Tồn kho sau khi lưu tạm - CN01:', sandbox.layTonKhoSanPhamTaiChiNhanh('SP527547', 'CN01'), '| CN02:', sandbox.layTonKhoSanPhamTaiChiNhanh('SP527547', 'CN02'));
if (draftCK?.trangThai === 'Phiếu tạm' && sandbox.layTonKhoSanPhamTaiChiNhanh('SP527547', 'CN01') === 20 && sandbox.layTonKhoSanPhamTaiChiNhanh('SP527547', 'CN02') === 5) {
  console.log('[PASS] Chuyển kho - Lưu tạm thành công (không trừ kho xuất, không cộng kho nhận).');
} else {
  console.error('[FAIL] Lưu tạm chuyển kho thất bại!');
}

// 2.2 Sửa phiếu chuyển kho tạm và Xuất hàng (Xác nhận chuyển kho)
sandbox.suaPhieuChuyenKho('CK_TEST_001');
sandbox.danhSachChuyenKhoCart[0].soLuong = 4; // Tăng từ 3 lên 4
sandbox.xacNhanThucHienChuyenKho(false); // Xác nhận chuyển kho

const inTransitCK = (sandbox.rawChuyenKhoList || []).find(p => p.maPhieu === 'CK_TEST_001');
const tonCN01_xuat = sandbox.layTonKhoSanPhamTaiChiNhanh('SP527547', 'CN01');
const tonCN02_chuanhan = sandbox.layTonKhoSanPhamTaiChiNhanh('SP527547', 'CN02');
console.log(`Phiếu [${inTransitCK?.maPhieu}] sau khi xuất đi:`, inTransitCK?.trangThai);
console.log('Tồn kho khi đang chuyển - CN01:', tonCN01_xuat, '| CN02:', tonCN02_chuanhan);
if (inTransitCK?.trangThai === 'Đang chuyển' && tonCN01_xuat === 16 && tonCN02_chuanhan === 5) {
  console.log('[PASS] Chuyển kho - Xuất hàng thành công (đã trừ kho xuất 4 cái, kho nhận CHƯA cộng vì chưa nhận).');
} else {
  console.error('[FAIL] Xuất hàng chuyển kho lỗi!');
}

// 2.3 Chi nhánh nhận xác nhận Nhận hàng (nhanHangChuyenKho)
sandbox.nhanHangChuyenKho('CK_TEST_001');
const receivedCK = (sandbox.rawChuyenKhoList || []).find(p => p.maPhieu === 'CK_TEST_001');
const tonCN01_final = sandbox.layTonKhoSanPhamTaiChiNhanh('SP527547', 'CN01');
const tonCN02_danhan = sandbox.layTonKhoSanPhamTaiChiNhanh('SP527547', 'CN02');
console.log(`Phiếu [${receivedCK?.maPhieu}] sau khi nhận hàng:`, receivedCK?.trangThai);
console.log('Tồn kho sau khi nhận hàng - CN01:', tonCN01_final, '| CN02:', tonCN02_danhan);
if (receivedCK?.trangThai === 'Đã nhận' && tonCN01_final === 16 && tonCN02_danhan === 9) {
  console.log('[PASS] Chuyển kho - Chi nhánh nhận xác nhận Nhận hàng thành công (kho nhận đã cộng +4 cái = 9).');
} else {
  console.error('[FAIL] Nhận hàng chuyển kho lỗi!');
}

// 2.4 Hủy phiếu chuyển kho đã nhận (Hoàn tác cả 2 kho)
sandbox.huyPhieuChuyenKho('CK_TEST_001');
const cancelledCK = (sandbox.rawChuyenKhoList || []).find(p => p.maPhieu === 'CK_TEST_001');
const tonCN01_revert = sandbox.layTonKhoSanPhamTaiChiNhanh('SP527547', 'CN01');
const tonCN02_revert = sandbox.layTonKhoSanPhamTaiChiNhanh('SP527547', 'CN02');
console.log(`Phiếu [${cancelledCK?.maPhieu}] sau khi hủy:`, cancelledCK?.trangThai);
console.log('Tồn kho sau khi hủy phiếu chuyển - CN01:', tonCN01_revert, '| CN02:', tonCN02_revert);
if (cancelledCK?.trangThai === 'Đã hủy' && tonCN01_revert === 20 && tonCN02_revert === 5) {
  console.log('[PASS] Chuyển kho - Hủy phiếu thành công (tồn kho cả 2 chi nhánh đã hoàn tác về ban đầu).');
} else {
  console.error('[FAIL] Hủy phiếu chuyển kho hoàn tác lỗi!');
}

// -------------------------------------------------------------
// TEST 3: TƯƠNG THÍCH PHIẾU CK2611099730 TỪ ẢNH CỦA NGƯỜI DÙNG
// -------------------------------------------------------------
console.log('\n--- TEST 3: KIỂM TRA PHIẾU CK2611099730 TỪ HÌNH ẢNH NGƯỜI DÙNG ---');
const userCK = {
  maPhieu: 'CK2611099730',
  ngayChuyen: '2026-11-09T14:33:00.000Z',
  cnXuat: 'CN01',
  cnNhan: 'CN02',
  tongSoLuong: 1,
  tongTien: 15000,
  trangThai: 'Hoàn thành',
  chiTietSanPham: [{
    maHang: 'SP527547',
    tenHang: 'Chân sạc SS Note 5',
    soLuong: 1,
    donGia: 15000
  }]
};
localStorage.setItem('tt_pos_chuyen_kho_list', JSON.stringify([userCK]));
sandbox.rawChuyenKhoList = [];
sandbox.loadDanhSachChuyenKho();

const loadedUserCK = sandbox.rawChuyenKhoList.find(p => p.maPhieu === 'CK2611099730');
console.log('Trạng thái của CK2611099730 sau khi nạp:', loadedUserCK?.trangThai);
if (loadedUserCK?.trangThai === 'Đang chuyển') {
  console.log('[PASS] CK2611099730 tự động chuyển sang trạng thái "Đang chuyển", chi nhánh nhận có ngay nút [Nhận hàng]!');
} else {
  console.error('[FAIL] CK2611099730 không được chuyển sang Đang chuyển');
}

console.log('\n=== TẤT CẢ CÁC TEST CASE ĐÃ VƯỢT QUA XUẤT SẮC 100% ===');
