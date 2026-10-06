# SMART ERP BÁN HÀNG & KHO - ỨNG DỤNG NATIVE DI ĐỘNG (ANDROID & iOS)

Ứng dụng di động Native được phát triển bằng **Flutter 3**, kết nối trực tiếp với cùng cơ sở dữ liệu **Supabase Cloud** mà hệ thống Web (`https://tgdtbanhang.netlify.app`) đang sử dụng. Mọi dữ liệu bán hàng, đặt cọc, tồn kho và sổ quỹ đều được đồng bộ tức thì 2 chiều.

---

## 📱 CÁC TÍNH NĂNG ĐƯỢC THIẾT KẾ RIÊNG CHO DI ĐỘNG

1. **Thu ngân POS bán lẻ di động (`PosView`)**:
   - Giao diện tối ưu ngón tay chạm cảm ứng, tìm kiếm siêu nhanh.
   - Tích hợp nút quét mã vạch Barcode / QR / IMEI bằng Camera điện thoại.
   - Thêm bớt số lượng, chọn khách hàng, chọn hình thức thanh toán (Tiền mặt, Chuyển khoản, Ghi nợ).
   - Tự động trừ tồn kho, cập nhật công nợ và ghi phiếu thu vào Sổ Quỹ ngay khi thanh toán.

2. **Quản lý Đơn hàng đa năng (`OrdersView`)**:
   - **Tab 1: Đơn đặt hàng (4.1)**: Theo dõi đơn khách đặt trước, tiền cọc, trạng thái đơn.
   - **Tab 2: Bán hàng POS (4.5)**: Lịch sử các đơn hàng đã xuất bán.
   - **Tab 3: Đơn nhập hàng (3.2)**: Danh sách phiếu nhập hàng từ các Nhà cung cấp.

3. **Tra cứu Kho & IMEI (`InventoryView`)**:
   - Thẻ thống kê tổng số lượng tồn kho và tổng giá trị vốn hàng hóa.
   - Tra cứu theo mã máy, tên máy, xem giá vốn, giá bán.
   - Cảnh báo trạng thái hết hàng / còn hàng bằng màu sắc trực quan.

4. **Sổ Quỹ Thu Chi (`CashbookView`)**:
   - Thẻ hiển thị số dư tồn quỹ thực tế, tổng thu, tổng chi.
   - Lọc nhanh giữa Quỹ tiền mặt và Quỹ ngân hàng.
   - Nút **+ Lập phiếu**: Tạo phiếu thu / chi nhanh chỉ với 3 thao tác ngay trên điện thoại.

5. **Tổng quan KPIs (`DashboardView`)**:
   - Theo dõi doanh số bán hàng, số đơn đặt đang chờ giao, tồn kho máy.
   - Các phím tắt nhanh để bán hàng hoặc kiểm kho.

---

## 🛠️ CẤU TRÚC MÃ NGUỒN (KIẾN TRÚC MVVM CHUẨN FLUTTER)

```text
mobile_app/
├── lib/
│   ├── data/
│   │   ├── models/          # ProductModel, OrderModel, PartnerModel, CashbookModel
│   │   ├── services/        # SupabaseService (Kết nối Cloud trực tiếp)
│   │   └── repositories/    # ProductRepo, OrderRepo, PartnerRepo, CashbookRepo
│   ├── ui/
│   │   ├── core/            # AppTheme, Formatters tiền tệ VNĐ & ngày giờ
│   │   └── features/
│   │       ├── dashboard/   # Màn hình Tổng quan
│   │       ├── pos/         # Màn hình Thu ngân POS
│   │       ├── orders/      # Màn hình Quản lý đơn hàng
│   │       ├── inventory/   # Màn hình Kho hàng
│   │       └── cashbook/    # Màn hình Sổ quỹ
│   └── main.dart            # Điểm khởi chạy ứng dụng & Thanh điều hướng đáy
├── android/                 # Cấu hình Android (Camera, Bluetooth, Network)
├── ios/                     # Cấu hình iOS (Camera, Bluetooth)
├── .github/workflows/       # Tự động build file .APK trên đám mây qua GitHub
└── pubspec.yaml             # Thư viện Flutter
```

---

## 🚀 HƯỚNG DẪN XUẤT FILE CÀI ĐẶT (.APK) CHO ĐIỆN THOẠI ANDROID

### 👉 Cách 1: Tự động xuất APK miễn phí trên GitHub Actions (Khuyên dùng - Nhanh nhất & Không cần cài Flutter nặng máy)
1. Dự án đã được thiết lập sẵn file `.github/workflows/build_apk.yml`.
2. Khi đẩy (push) thư mục này lên kho mã nguồn GitHub của bạn:
   - GitHub sẽ tự động chạy máy chủ ảo Ubuntu, cài Flutter và đóng gói ứng dụng.
   - Sau khoảng 3-5 phút, bạn vào mục **Actions** trên GitHub -> Bấm vào lần chạy gần nhất -> Tải file **`SmartERP-Android-App.zip`** (bên trong có file `app-release.apk`).
3. Chép file `.apk` vào điện thoại Android và bấm Cài đặt là có thể sử dụng ngay!

### 👉 Cách 2: Chạy trực tiếp trên máy tính có cài Flutter SDK
Nếu máy tính của bạn đã có môi trường Flutter:
1. Mở terminal tại thư mục `mobile_app`:
   ```bash
   cd mobile_app
   flutter pub get
   ```
2. Chạy ứng dụng trên máy ảo hoặc điện thoại thật cắm cáp:
   ```bash
   flutter run
   ```
3. Đóng gói file APK Release:
   ```bash
   flutter build apk --release
   ```
   File APK sẽ được tạo tại: `build/app/outputs/flutter-apk/app-release.apk`.
