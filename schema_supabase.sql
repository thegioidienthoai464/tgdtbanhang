-- ====================================================================
-- HỆ THỐNG QUẢN LÝ BÁN HÀNG & KHO - SUPABASE POSTGRESQL SCHEMA
-- Tối ưu chỉ mục (Indexes) tìm kiếm siêu tốc < 50ms
-- ====================================================================

-- [TÙY CHỌN]: Nếu bạn đã tạo database trước đó, hãy chạy các lệnh sau trong Supabase SQL Editor để mở rộng độ dài các cột:
-- ALTER TABLE dm_hanghoa ALTER COLUMN ma_nhom TYPE TEXT;
-- ALTER TABLE dm_hanghoa ALTER COLUMN don_vi_tinh TYPE TEXT;
-- ALTER TABLE dm_hanghoa ALTER COLUMN trang_thai TYPE TEXT;
-- ALTER TABLE dm_hanghoa ALTER COLUMN ma_hang TYPE VARCHAR(100);
-- ALTER TABLE dm_hanghoa ALTER COLUMN ten_hang TYPE TEXT;
-- ALTER TABLE kho_imei ALTER COLUMN imei TYPE VARCHAR(100);
-- ALTER TABLE kho_imei ALTER COLUMN ma_hang TYPE VARCHAR(100);
-- ALTER TABLE kho_imei ALTER COLUMN trang_thai TYPE TEXT;
-- ALTER TABLE dm_doitac ALTER COLUMN ma_doi_tac TYPE VARCHAR(100);
-- ALTER TABLE dm_doitac ALTER COLUMN ten_doi_tac TYPE TEXT;
-- ALTER TABLE dm_doitac ALTER COLUMN trang_thai TYPE TEXT;
-- ALTER TABLE don_hang ALTER COLUMN ma_don_hang TYPE VARCHAR(100);
-- ALTER TABLE don_hang ALTER COLUMN ten_kh TYPE TEXT;
-- ALTER TABLE don_hang ALTER COLUMN trang_thai TYPE TEXT;
-- ALTER TABLE so_quy ALTER COLUMN ma_phieu TYPE VARCHAR(100);
-- ALTER TABLE so_quy ALTER COLUMN trang_thai TYPE TEXT;

-- 1. BẢNG CHI NHÁNH
CREATE TABLE IF NOT EXISTS dm_chinhanh (
    ma_cn VARCHAR(50) PRIMARY KEY,
    ten_cn VARCHAR(255) NOT NULL,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 2. BẢNG NHÓM HÀNG
CREATE TABLE IF NOT EXISTS dm_nhomhang (
    ma_nhom VARCHAR(50) PRIMARY KEY,
    ten_nhom VARCHAR(255) NOT NULL,
    ma_nhom_cha VARCHAR(50),
    ghi_chu TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 3. BẢNG DANH MỤC HÀNG HÓA
CREATE TABLE IF NOT EXISTS dm_hanghoa (
    id BIGSERIAL PRIMARY KEY,
    chi_nhanh VARCHAR(100) DEFAULT 'CN01: Trụ sở chính Thanh Miện',
    ma_hang VARCHAR(50) NOT NULL UNIQUE,
    ten_hang VARCHAR(255) NOT NULL,
    ma_nhom VARCHAR(50),
    don_vi_tinh VARCHAR(50) DEFAULT 'Cái',
    gia_von NUMERIC(15, 2) DEFAULT 0,
    gia_ban NUMERIC(15, 2) DEFAULT 0,
    co_quan_ly_imei BOOLEAN DEFAULT FALSE,
    ton_kho NUMERIC(15, 2) DEFAULT 0,
    trang_thai VARCHAR(50) DEFAULT 'Kinh doanh',
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_hanghoa_ma ON dm_hanghoa(ma_hang);
CREATE INDEX IF NOT EXISTS idx_hanghoa_ten ON dm_hanghoa(ten_hang);
CREATE INDEX IF NOT EXISTS idx_hanghoa_nhom ON dm_hanghoa(ma_nhom);

-- 4. BẢNG KHO SERIAL / IMEI
CREATE TABLE IF NOT EXISTS kho_imei (
    id BIGSERIAL PRIMARY KEY,
    chi_nhanh VARCHAR(100) DEFAULT 'CN01: Trụ sở chính Thanh Miện',
    imei VARCHAR(100) NOT NULL UNIQUE,
    ma_hang VARCHAR(50) NOT NULL,
    trang_thai VARCHAR(50) DEFAULT 'TrongKho', -- TrongKho, DaBan, DaXuatHuy, DaTraNCC
    ma_phieu_nhap VARCHAR(50),
    ma_don_ban VARCHAR(50),
    ngay_cap_nhat TIMESTAMPTZ DEFAULT NOW(),
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_imei_code ON kho_imei(imei);
CREATE INDEX IF NOT EXISTS idx_imei_ma_hang ON kho_imei(ma_hang);
CREATE INDEX IF NOT EXISTS idx_imei_trang_thai ON kho_imei(trang_thai);

-- 5. BẢNG ĐỐI TÁC (KHÁCH HÀNG & NHÀ CUNG CẤP)
CREATE TABLE IF NOT EXISTS dm_doitac (
    ma_doi_tac VARCHAR(50) PRIMARY KEY,
    loai_doi_tac VARCHAR(20) DEFAULT 'KH', -- KH hoặc NCC
    ten_doi_tac VARCHAR(255) NOT NULL,
    so_dien_thoai VARCHAR(50),
    dia_chi TEXT,
    gioi_tinh VARCHAR(20),
    ngay_sinh DATE,
    cong_no NUMERIC(15, 2) DEFAULT 0,
    trang_thai VARCHAR(50) DEFAULT 'HoatDong',
    ghi_chu TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_doitac_sdt ON dm_doitac(so_dien_thoai);
CREATE INDEX IF NOT EXISTS idx_doitac_loai ON dm_doitac(loai_doi_tac);

-- 6. BẢNG ĐƠN HÀNG ĐÃ BÁN (POS / BÁN LẺ)
CREATE TABLE IF NOT EXISTS don_hang (
    ma_don_hang VARCHAR(50) PRIMARY KEY,
    ngay_ban TIMESTAMPTZ DEFAULT NOW(),
    ma_kh VARCHAR(50) DEFAULT 'KL',
    ten_kh VARCHAR(255) DEFAULT 'Khách lẻ',
    so_dien_thoai VARCHAR(50),
    chi_nhanh VARCHAR(100) DEFAULT 'CN01: Trụ sở chính Thanh Miện',
    tong_tien NUMERIC(15, 2) DEFAULT 0,
    giam_gia NUMERIC(15, 2) DEFAULT 0,
    khach_phai_tra NUMERIC(15, 2) DEFAULT 0,
    khach_tra NUMERIC(15, 2) DEFAULT 0,
    hinh_thuc_tt VARCHAR(50) DEFAULT 'TIEN_MAT',
    ngan_hang_nhan VARCHAR(255),
    chi_tiet_san_pham JSONB DEFAULT '[]'::jsonb, -- Lưu mảng item [ {maHang, tenHang, soLuong, donGia, thanhTien, imeiStr} ]
    trang_thai VARCHAR(50) DEFAULT 'Hoàn thành',
    nhan_vien VARCHAR(100) DEFAULT 'Quản trị viên',
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_donhang_ngay ON don_hang(ngay_ban DESC);
CREATE INDEX IF NOT EXISTS idx_donhang_makh ON don_hang(ma_kh);
CREATE INDEX IF NOT EXISTS idx_donhang_sdt ON don_hang(so_dien_thoai);

-- 7. BẢNG PHIẾU KHÁCH TRẢ HÀNG
CREATE TABLE IF NOT EXISTS phieu_tra_hang (
    ma_phieu_tra VARCHAR(50) PRIMARY KEY,
    ma_don_goc VARCHAR(50) NOT NULL,
    ngay_tra TIMESTAMPTZ DEFAULT NOW(),
    ma_kh VARCHAR(50),
    ten_kh VARCHAR(255),
    so_dien_thoai VARCHAR(50),
    chi_nhanh VARCHAR(100) DEFAULT 'CN01: Trụ sở chính Thanh Miện',
    danh_sach_tra JSONB DEFAULT '[]'::jsonb,
    tong_tien_hoan NUMERIC(15, 2) DEFAULT 0,
    phi_khau_tru NUMERIC(15, 2) DEFAULT 0,
    hinh_thuc_tt VARCHAR(50) DEFAULT 'TIEN_MAT',
    ngan_hang_chi VARCHAR(255),
    ly_do_tra TEXT,
    nhan_vien VARCHAR(100) DEFAULT 'Quản trị viên',
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_phieutra_madon ON phieu_tra_hang(ma_don_goc);
CREATE INDEX IF NOT EXISTS idx_phieutra_ngay ON phieu_tra_hang(ngay_tra DESC);

-- 8. BẢNG SỔ QUỸ DÒNG TIỀN (THU / CHI)
CREATE TABLE IF NOT EXISTS so_quy (
    ma_phieu VARCHAR(50) PRIMARY KEY,
    chi_nhanh VARCHAR(100) DEFAULT 'CN01: Trụ sở chính Thanh Miện',
    loai_phieu VARCHAR(20) NOT NULL, -- THU hoặc CHI
    loai_quy VARCHAR(100) DEFAULT 'TIEN_MAT', -- TIEN_MAT hoặc Tên Ngân Hàng
    ngay_gd TIMESTAMPTZ DEFAULT NOW(),
    so_tien NUMERIC(15, 2) NOT NULL DEFAULT 0,
    doi_tuong VARCHAR(100) DEFAULT 'Khách hàng',
    ma_doi_tuong VARCHAR(50),
    ma_chung_tu VARCHAR(50),
    trang_thai VARCHAR(50) DEFAULT 'DaThanhToan',
    ghi_chu TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_soquy_ngay ON so_quy(ngay_gd DESC);
CREATE INDEX IF NOT EXISTS idx_soquy_loai ON so_quy(loai_phieu);
CREATE INDEX IF NOT EXISTS idx_soquy_quy ON so_quy(loai_quy);

-- 9. BẢNG TÀI KHOẢN NGÂN HÀNG
CREATE TABLE IF NOT EXISTS dm_nganhang (
    ma_nh VARCHAR(50) PRIMARY KEY,
    ten_nh VARCHAR(255) NOT NULL,
    so_tk VARCHAR(50) NOT NULL,
    chu_tk VARCHAR(255) NOT NULL,
    ghi_chu TEXT,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10. BẢNG NGƯỜI DÙNG & PHÂN QUYỀN
CREATE TABLE IF NOT EXISTS nguoi_dung (
    ma_nv VARCHAR(50) PRIMARY KEY,
    username VARCHAR(100) NOT NULL UNIQUE,
    ho_ten VARCHAR(255) NOT NULL,
    password VARCHAR(255) DEFAULT '123456',
    vai_tro VARCHAR(50) DEFAULT 'Thu ngân',
    sdt VARCHAR(50),
    email VARCHAR(100),
    trang_thai VARCHAR(50) DEFAULT 'HoatDong',
    quyen_han JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

-- 11. BẢNG BẢNG GIÁ SẢN PHẨM (PRICE BOOKS)
CREATE TABLE IF NOT EXISTS dm_banggia (
    id BIGSERIAL PRIMARY KEY,
    ma_bang_gia VARCHAR(50),
    ten_bang_gia VARCHAR(255) NOT NULL,
    ma_hang VARCHAR(50) NOT NULL,
    gia_ban NUMERIC(15, 2) NOT NULL DEFAULT 0,
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);
CREATE INDEX IF NOT EXISTS idx_banggia_ten ON dm_banggia(ten_bang_gia);
CREATE INDEX IF NOT EXISTS idx_banggia_mahang ON dm_banggia(ma_hang);

-- ====================================================================
-- BẬT ROW LEVEL SECURITY (RLS) & CHO PHÉP WEB APP TRUY VẤN
-- ====================================================================
ALTER TABLE dm_chinhanh ENABLE ROW LEVEL SECURITY;
ALTER TABLE dm_nhomhang ENABLE ROW LEVEL SECURITY;
ALTER TABLE dm_hanghoa ENABLE ROW LEVEL SECURITY;
ALTER TABLE kho_imei ENABLE ROW LEVEL SECURITY;
ALTER TABLE dm_doitac ENABLE ROW LEVEL SECURITY;
ALTER TABLE don_hang ENABLE ROW LEVEL SECURITY;
ALTER TABLE phieu_tra_hang ENABLE ROW LEVEL SECURITY;
ALTER TABLE so_quy ENABLE ROW LEVEL SECURITY;
ALTER TABLE dm_nganhang ENABLE ROW LEVEL SECURITY;
ALTER TABLE nguoi_dung ENABLE ROW LEVEL SECURITY;
ALTER TABLE dm_banggia ENABLE ROW LEVEL SECURITY;

-- Cho phép đọc/ghi qua Anon Key của Supabase
CREATE POLICY "Public Read All" ON dm_chinhanh FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Public Read All" ON dm_nhomhang FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Public Read All" ON dm_hanghoa FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Public Read All" ON kho_imei FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Public Read All" ON dm_doitac FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Public Read All" ON don_hang FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Public Read All" ON phieu_tra_hang FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Public Read All" ON so_quy FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Public Read All" ON dm_nganhang FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Public Read All" ON nguoi_dung FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "Public Read All" ON dm_banggia FOR ALL USING (true) WITH CHECK (true);

-- ====================================================================
-- DỮ LIỆU MẶC ĐỊNH BAN ĐẦU
-- ====================================================================
INSERT INTO dm_chinhanh (ma_cn, ten_cn) VALUES 
('CN01', 'Trụ sở chính Thanh Miện'),
('CN02', 'Chi nhánh TP. Hải Dương'),
('CN03', 'Chi nhánh Hà Nội')
ON CONFLICT (ma_cn) DO NOTHING;

INSERT INTO nguoi_dung (ma_nv, username, ho_ten, password, vai_tro, trang_thai) VALUES 
('NV001', 'admin', 'Quản trị viên hệ thống', '123456', 'Admin', 'HoatDong')
ON CONFLICT (username) DO NOTHING;


-- ====================================================================
-- BẢNG 12: YÊU CẦU SỬA CHỮA & BẢO HÀNH (CHUẨN KIOTVIET)
-- ====================================================================
CREATE TABLE IF NOT EXISTS yeu_cau_sua_chua (
    id BIGINT GENERATED BY DEFAULT AS IDENTITY PRIMARY KEY,
    ma_yeu_cau VARCHAR(50) UNIQUE NOT NULL,
    ngay_tiep_nhan TIMESTAMPTZ DEFAULT NOW(),
    ngay_cap_nhat TIMESTAMPTZ DEFAULT NOW(),
    ngay_hen_tra TIMESTAMPTZ,
    ngay_hoan_thanh TIMESTAMPTZ,
    chi_nhanh VARCHAR(100) DEFAULT 'Thanh Giang',
    noi_tiep_nhan VARCHAR(100) DEFAULT 'Tại cửa hàng',
    bang_gia VARCHAR(100) DEFAULT 'Bảng giá chung',
    nguoi_nhan VARCHAR(100),
    ky_thuat_vien VARCHAR(100),
    loai_yeu_cau VARCHAR(50) DEFAULT 'SUA_CHUA',
    ma_kh VARCHAR(50),
    ten_kh VARCHAR(255),
    so_dien_thoai VARCHAR(50),
    dia_chi TEXT,
    ma_hang VARCHAR(50),
    ten_thiet_bi VARCHAR(255),
    imei VARCHAR(100),
    mat_khau_may VARCHAR(100),
    phu_kien TEXT,
    tinh_trang_loi TEXT,
    ghi_chu TEXT,
    trang_thai VARCHAR(50) DEFAULT 'TiepNhan',
    danh_sach_dich_vu JSONB DEFAULT '[]'::jsonb,
    tong_tien_hang NUMERIC(15, 2) DEFAULT 0,
    giam_gia NUMERIC(15, 2) DEFAULT 0,
    khach_can_tra NUMERIC(15, 2) DEFAULT 0,
    khach_da_tra NUMERIC(15, 2) DEFAULT 0,
    con_can_tra NUMERIC(15, 2) DEFAULT 0,
    lich_su_thanh_toan JSONB DEFAULT '[]'::jsonb,
    ma_hoa_don_lien_ket VARCHAR(50),
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX IF NOT EXISTS idx_ycsc_ma ON yeu_cau_sua_chua(ma_yeu_cau);
CREATE INDEX IF NOT EXISTS idx_ycsc_sdt ON yeu_cau_sua_chua(so_dien_thoai);
CREATE INDEX IF NOT EXISTS idx_ycsc_imei ON yeu_cau_sua_chua(imei);
CREATE INDEX IF NOT EXISTS idx_ycsc_trang_thai ON yeu_cau_sua_chua(trang_thai);
