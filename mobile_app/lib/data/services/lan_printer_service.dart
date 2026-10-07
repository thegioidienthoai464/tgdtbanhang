import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/order_model.dart';
import '../models/cashbook_model.dart';
import '../../ui/core/formatters.dart';

class LanPrinterService {
  static const String _keyIp = 'printer_lan_ip';
  static const String _keyPort = 'printer_lan_port';
  static const String _keyAutoPrint = 'printer_auto_print';
  static const String _keyPaperSize = 'printer_paper_size'; // '80mm' or '58mm'
  static const String _keyStoreName = 'printer_store_name';
  static const String _keyStoreAddress = 'printer_store_address';
  static const String _keyStorePhone = 'printer_store_phone';

  // Lấy IP máy in đã lưu
  static Future<String> getPrinterIp() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyIp) ?? '192.168.1.200';
  }

  // Lấy Port máy in (mặc định 9100)
  static Future<int> getPrinterPort() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_keyPort) ?? 9100;
  }

  // Lấy trạng thái tự động in sau khi thanh toán
  static Future<bool> isAutoPrintEnabled() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_keyAutoPrint) ?? true;
  }

  // Lấy khổ giấy (80mm hoặc 58mm)
  static Future<String> getPaperSize() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_keyPaperSize) ?? '80mm';
  }

  // Lưu cấu hình máy in
  static Future<void> saveSettings({
    required String ip,
    required int port,
    required bool autoPrint,
    required String paperSize,
    String? storeName,
    String? storeAddress,
    String? storePhone,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyIp, ip.trim());
    await prefs.setInt(_keyPort, port);
    await prefs.setBool(_keyAutoPrint, autoPrint);
    await prefs.setString(_keyPaperSize, paperSize);
    if (storeName != null) await prefs.setString(_keyStoreName, storeName);
    if (storeAddress != null) await prefs.setString(_keyStoreAddress, storeAddress);
    if (storePhone != null) await prefs.setString(_keyStorePhone, storePhone);
  }

  // Chuyển tiếng Việt có dấu sang không dấu (đảm bảo 100% máy in bill không bị lỗi font)
  static String removeDiacritics(String str) {
    var withDia = 'àáạảãâầấậẩẫăằắặẳẵèéẹẻẽêềếệểễìíịỉĩòóọỏõôồốộổỗơờớợởỡùúụủũưừứựửữỳýỵỷỹđ'
        'ÀÁẠẢÃÂẦẤẬẨẪĂẰẮẶẲẴÈÉẸẺẼÊỀẾỆỂỄÌÍỊỈĨÒÓỌỎÕÔỒỐỘỔỖƠỜỚỢỞỠÙÚỤỦŨƯỪỨỰỬỮỲÝỴỶỸĐ';
    var withoutDia = 'aaaaaaaaaaaaaaaaaeeeeeeeeeeeiiiiiooooooooooooooooouuuuuuuuuuuyyyyyd'
        'AAAAAAAAAAAAAAAAAEEEEEEEEEEEIIIIIOOOOOOOOOOOOOOOOOUUUUUUUUUUUYYYYYD';

    for (int i = 0; i < withDia.length; i++) {
      str = str.replaceAll(withDia[i], withoutDia[i]);
    }
    return str;
  }

  // Hàm in thử nghiệm kết nối máy in LAN
  static Future<Map<String, dynamic>> testPrint({String? ip, int? port}) async {
    final targetIp = ip ?? await getPrinterIp();
    final targetPort = port ?? await getPrinterPort();

    try {
      final socket = await Socket.connect(
        targetIp,
        targetPort,
        timeout: const Duration(seconds: 4),
      );

      final bytes = <int>[];
      // Khởi tạo máy in
      bytes.addAll([0x1B, 0x40]); // ESC @

      // Căn giữa
      bytes.addAll([0x1B, 0x61, 0x01]); // ESC a 1
      bytes.addAll([0x1B, 0x45, 0x01]); // In đậm
      bytes.addAll([0x1D, 0x21, 0x11]); // Chữ to
      bytes.addAll(utf8.encode("THE GIOI DIEN THOAI 464\n"));

      bytes.addAll([0x1D, 0x21, 0x00]); // Chữ thường
      bytes.addAll([0x1B, 0x45, 0x00]); // Tắt in đậm
      bytes.addAll(utf8.encode("KIEM TRA KET NOI MAY IN LAN\n"));
      bytes.addAll(utf8.encode("--------------------------------\n"));
      
      // Căn trái
      bytes.addAll([0x1B, 0x61, 0x00]); // ESC a 0
      bytes.addAll(utf8.encode("Dia chi IP : $targetIp:$targetPort\n"));
      bytes.addAll(utf8.encode("Thoi gian  : ${Formatters.formatDateTime(DateTime.now())}\n"));
      bytes.addAll(utf8.encode("Trang thai : KET NOI THANH CONG 100%\n"));
      bytes.addAll(utf8.encode("--------------------------------\n"));

      // Căn giữa
      bytes.addAll([0x1B, 0x61, 0x01]);
      bytes.addAll(utf8.encode("May in san sang xuat hoa don!\n\n\n\n"));

      // Cắt giấy tự động
      bytes.addAll([0x1D, 0x56, 0x42, 0x00]); // GS V B 0

      socket.add(bytes);
      await socket.flush();
      await socket.close();

      return {'success': true, 'message': 'Kết nối và in thử thành công tới $targetIp:$targetPort!'};
    } catch (e) {
      debugPrint("Lỗi kết nối máy in LAN: $e");
      return {'success': false, 'message': 'Không thể kết nối máy in ($targetIp:$targetPort). Lỗi: $e'};
    }
  }

  // Hàm in hóa đơn bán hàng chính thức
  static Future<Map<String, dynamic>> printOrderReceipt(OrderModel order) async {
    final ip = await getPrinterIp();
    final port = await getPrinterPort();
    final paperSize = await getPaperSize();
    final is80mm = paperSize == '80mm';

    final prefs = await SharedPreferences.getInstance();
    final storeName = prefs.getString(_keyStoreName) ?? 'THE GIOI DIEN THOAI 464';
    final storeAddress = prefs.getString(_keyStoreAddress) ?? '464 Le Van Khuong, P. Thoi An, Q.12';
    final storePhone = prefs.getString(_keyStorePhone) ?? 'Hotline: 0989.xxx.xxx';

    final divider = is80mm 
        ? "------------------------------------------------\n" 
        : "--------------------------------\n";

    try {
      final socket = await Socket.connect(
        ip,
        port,
        timeout: const Duration(seconds: 4),
      );

      final bytes = <int>[];

      // 1. Khởi tạo máy in
      bytes.addAll([0x1B, 0x40]); // ESC @

      // 2. Tiêu đề cửa hàng (Căn giữa, Chữ to, In đậm)
      bytes.addAll([0x1B, 0x61, 0x01]); // Căn giữa
      bytes.addAll([0x1B, 0x45, 0x01]); // In đậm
      bytes.addAll([0x1D, 0x21, 0x11]); // Chữ to gấp đôi
      bytes.addAll(utf8.encode("${removeDiacritics(storeName)}\n"));

      // 3. Thông tin địa chỉ & hotline
      bytes.addAll([0x1D, 0x21, 0x00]); // Chữ chuẩn
      bytes.addAll([0x1B, 0x45, 0x00]); // Tắt in đậm
      bytes.addAll(utf8.encode("${removeDiacritics(storeAddress)}\n"));
      bytes.addAll(utf8.encode("$storePhone\n"));
      bytes.addAll(utf8.encode(divider));

      // 4. Tiêu đề Hóa Đơn
      bytes.addAll([0x1B, 0x45, 0x01]); // In đậm
      bytes.addAll([0x1D, 0x21, 0x01]); // Cao gấp đôi
      bytes.addAll(utf8.encode("HOA DON BAN HANG\n"));
      bytes.addAll([0x1D, 0x21, 0x00]); // Bình thường
      bytes.addAll([0x1B, 0x45, 0x00]);

      // 5. Thông tin đơn hàng (Căn trái)
      bytes.addAll([0x1B, 0x61, 0x00]); // Căn trái
      bytes.addAll(utf8.encode("Ma hoa don : ${order.maDonHang}\n"));
      bytes.addAll(utf8.encode("Ngay ban   : ${Formatters.formatDateTime(order.ngayBan)}\n"));
      bytes.addAll(utf8.encode("Khach hang : ${removeDiacritics(order.tenKH)}\n"));
      if (order.soDienThoai.isNotEmpty) {
        bytes.addAll(utf8.encode("Dien thoai : ${order.soDienThoai}\n"));
      }
      bytes.addAll(utf8.encode(divider));

      // 6. Tiêu đề cột sản phẩm
      bytes.addAll([0x1B, 0x45, 0x01]); // In đậm
      if (is80mm) {
        bytes.addAll(utf8.encode("TEN HANG               SL    DON GIA      THANH TIEN\n"));
      } else {
        bytes.addAll(utf8.encode("TEN HANG         SL     DON GIA   THANH TIEN\n"));
      }
      bytes.addAll([0x1B, 0x45, 0x00]); // Tắt in đậm
      bytes.addAll(utf8.encode(divider));

      // 7. Chi tiết từng mặt hàng
      for (final item in order.chiTietSanPham) {
        final ten = removeDiacritics(item.tenHang);
        final sl = item.soLuong.toString();
        final donGia = Formatters.formatCurrency(item.donGia);
        final thanhTien = Formatters.formatCurrency(item.thanhTien);

        // In tên sản phẩm trên 1 dòng
        bytes.addAll([0x1B, 0x45, 0x01]); // In đậm tên hàng
        bytes.addAll(utf8.encode("$ten\n"));
        bytes.addAll([0x1B, 0x45, 0x00]);

        // In số lượng, đơn giá, thành tiền
        if (is80mm) {
          final row = "  x$sl".padRight(22) + donGia.padRight(12) + thanhTien.padLeft(12) + "\n";
          bytes.addAll(utf8.encode(row));
        } else {
          final row = "  x$sl".padRight(14) + donGia.padRight(9) + thanhTien.padLeft(9) + "\n";
          bytes.addAll(utf8.encode(row));
        }

        // Nếu có IMEI
        if (item.imeiStr.isNotEmpty) {
          bytes.addAll(utf8.encode("  IMEI: ${item.imeiStr}\n"));
        }
      }
      bytes.addAll(utf8.encode(divider));

      // 8. Tổng kết thanh toán
      final tongTienStr = Formatters.formatCurrency(order.tongTien);
      final khachTraStr = Formatters.formatCurrency(order.khachTra);
      final conNoStr = Formatters.formatCurrency(order.conNo);
      final ptttStr = order.hinhThucTT == 'TIEN_MAT'
          ? 'Tien mat'
          : order.hinhThucTT == 'TAI_KHOAN'
              ? 'Chuyen khoan${order.nganHangNhan != null ? " (${removeDiacritics(order.nganHangNhan!)})" : ""}'
              : order.hinhThucTT == 'HON_HOP'
                  ? 'Hon hop (TM + CK)'
                  : 'Ghi no';

      bytes.addAll([0x1B, 0x45, 0x01]); // In đậm
      bytes.addAll(utf8.encode("TONG TIEN HANG  : $tongTienStr\n"));
      bytes.addAll([0x1B, 0x45, 0x00]);
      bytes.addAll(utf8.encode("Hinh thuc TT    : $ptttStr\n"));
      bytes.addAll(utf8.encode("Khach da tra    : $khachTraStr\n"));
      if (order.conNo > 0) {
        bytes.addAll([0x1B, 0x45, 0x01]);
        bytes.addAll(utf8.encode("CON NO          : $conNoStr\n"));
        bytes.addAll([0x1B, 0x45, 0x00]);
      }
      bytes.addAll(utf8.encode(divider));

      // 9. Lời cảm ơn và chân trang (Căn giữa)
      bytes.addAll([0x1B, 0x61, 0x01]); // Căn giữa
      bytes.addAll([0x1B, 0x45, 0x01]);
      bytes.addAll(utf8.encode("XIN CAM ON QUY KHACH!\n"));
      bytes.addAll([0x1B, 0x45, 0x00]);
      bytes.addAll(utf8.encode("Bao hanh theo tem & hoa don dien tu.\n"));
      bytes.addAll(utf8.encode("Hen gap lai quy khach lan sau!\n\n\n\n"));

      // 10. Lệnh cắt giấy
      bytes.addAll([0x1D, 0x56, 0x42, 0x00]); // GS V B 0

      socket.add(bytes);
      await socket.flush();
      await socket.close();

      return {'success': true, 'message': 'Đã in hóa đơn thành công ra máy in LAN ($ip:$port)!'};
    } catch (e) {
      debugPrint("Lỗi in bill: $e");
      return {'success': false, 'message': 'Không in được qua máy in LAN ($ip:$port). Lỗi: $e'};
    }
  }

  // Hàm in phiếu thu / chi sổ quỹ ra máy in LAN
  static Future<Map<String, dynamic>> printCashReceipt(CashbookModel tx) async {
    final ip = await getPrinterIp();
    final port = await getPrinterPort();
    final paperSize = await getPaperSize();
    final is80mm = paperSize == '80mm';

    final prefs = await SharedPreferences.getInstance();
    final storeName = prefs.getString(_keyStoreName) ?? 'THE GIOI DIEN THOAI 464';
    final storeAddress = prefs.getString(_keyStoreAddress) ?? '464 Le Van Khuong, P. Thoi An, Q.12';
    final storePhone = prefs.getString(_keyStorePhone) ?? 'Hotline: 0989.xxx.xxx';

    final divider = is80mm 
        ? "------------------------------------------------\n" 
        : "--------------------------------\n";

    final isThu = tx.isIncome;
    final title = isThu ? "PHIEU THU TIEN" : "PHIEU CHI TIEN";

    try {
      final socket = await Socket.connect(
        ip,
        port,
        timeout: const Duration(seconds: 4),
      );

      final bytes = <int>[];

      // 1. Khởi tạo máy in
      bytes.addAll([0x1B, 0x40]); // ESC @

      // 2. Tiêu đề cửa hàng
      bytes.addAll([0x1B, 0x61, 0x01]); // Căn giữa
      bytes.addAll([0x1B, 0x45, 0x01]); // In đậm
      bytes.addAll([0x1D, 0x21, 0x11]); // Chữ to
      bytes.addAll(utf8.encode("${removeDiacritics(storeName)}\n"));

      // 3. Thông tin địa chỉ & hotline
      bytes.addAll([0x1D, 0x21, 0x00]);
      bytes.addAll([0x1B, 0x45, 0x00]);
      bytes.addAll(utf8.encode("${removeDiacritics(storeAddress)}\n"));
      bytes.addAll(utf8.encode("$storePhone\n"));
      bytes.addAll(utf8.encode(divider));

      // 4. Tiêu đề Phiếu
      bytes.addAll([0x1B, 0x45, 0x01]);
      bytes.addAll([0x1D, 0x21, 0x01]); // Cao gấp đôi
      bytes.addAll(utf8.encode("$title\n"));
      bytes.addAll([0x1D, 0x21, 0x00]);
      bytes.addAll([0x1B, 0x45, 0x00]);

      // 5. Thông tin chi tiết phiếu
      bytes.addAll([0x1B, 0x61, 0x00]); // Căn trái
      bytes.addAll(utf8.encode("Ma phieu    : ${tx.maPhieu}\n"));
      bytes.addAll(utf8.encode("Ngay gio    : ${Formatters.formatDateTime(tx.ngayGD)}\n"));
      bytes.addAll(utf8.encode("Chi nhanh   : ${removeDiacritics(tx.chiNhanh)}\n"));
      if (tx.doiTuong.isNotEmpty) {
        bytes.addAll(utf8.encode("${isThu ? 'Nguoi nop' : 'Nguoi nhan'}: ${removeDiacritics(tx.doiTuong)}\n"));
      }
      bytes.addAll(utf8.encode("Hinh thuc   : ${removeDiacritics(tx.loaiQuy)}\n"));
      if (tx.maChungTu.isNotEmpty) {
        bytes.addAll(utf8.encode("Chung tu goc: ${tx.maChungTu}\n"));
      }
      if (tx.ghiChu.isNotEmpty) {
        bytes.addAll(utf8.encode("Ly do       : ${removeDiacritics(tx.ghiChu)}\n"));
      }
      bytes.addAll(utf8.encode(divider));

      // 6. Số tiền nổi bật
      final soTienStr = Formatters.formatCurrency(tx.soTien);
      bytes.addAll([0x1B, 0x45, 0x01]); // In đậm
      bytes.addAll([0x1D, 0x21, 0x11]); // Chữ to
      bytes.addAll([0x1B, 0x61, 0x01]); // Căn giữa
      bytes.addAll(utf8.encode("SO TIEN: $soTienStr\n"));
      bytes.addAll([0x1D, 0x21, 0x00]);
      bytes.addAll([0x1B, 0x45, 0x00]);
      bytes.addAll(utf8.encode(divider));

      // 7. Chữ ký 2 bên
      bytes.addAll([0x1B, 0x61, 0x00]); // Căn trái
      if (is80mm) {
        bytes.addAll(utf8.encode("      Nguoi nop/nhan                  Nguoi lap phieu\n"));
        bytes.addAll(utf8.encode("       (Ky & ghi ro ho ten)             (Ky & ghi ro ho ten)\n\n\n\n"));
      } else {
        bytes.addAll(utf8.encode("   Nguoi nop/nhan          Nguoi lap phieu\n"));
        bytes.addAll(utf8.encode("  (Ky & ghi ro ho ten)     (Ky & ghi ro ho ten)\n\n\n\n"));
      }

      // 8. Cắt giấy
      bytes.addAll([0x1D, 0x56, 0x42, 0x00]); // GS V B 0

      socket.add(bytes);
      await socket.flush();
      await socket.close();

      return {'success': true, 'message': 'Đã in phiếu thu chi thành công ra máy in LAN ($ip:$port)!'};
    } catch (e) {
      debugPrint("Lỗi in phiếu thu chi: $e");
      return {'success': false, 'message': 'Không in được phiếu qua máy in LAN ($ip:$port). Lỗi: $e'};
    }
  }
}
