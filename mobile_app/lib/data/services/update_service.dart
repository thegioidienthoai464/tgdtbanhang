import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../../ui/core/app_theme.dart';

class UpdateInfo {
  final String version;
  final int buildNumber;
  final String releaseNotes;
  final String downloadUrl;
  final bool forceUpdate;

  UpdateInfo({
    required this.version,
    required this.buildNumber,
    required this.releaseNotes,
    required this.downloadUrl,
    this.forceUpdate = false,
  });

  factory UpdateInfo.fromJson(Map<String, dynamic> json) {
    return UpdateInfo(
      version: json['version'] ?? '1.0.8',
      buildNumber: json['build_number'] ?? 9,
      releaseNotes: json['release_notes'] ?? 'Bản cập nhật tối ưu hệ thống.',
      downloadUrl: json['download_url'] ?? 'https://tgdtbanhang.netlify.app/download.html',
      forceUpdate: json['force_update'] == true,
    );
  }
}

class UpdateService {
  // Phiên bản hiện tại của App
  static const String currentVersion = '1.1.3';
  static const int currentBuildNumber = 14;


  // Cờ ghi nhớ người dùng đã từ chối cập nhật trong phiên hiện tại (tránh pop-up lặp lại liên tục)
  static bool _dismissedInThisSession = false;

  // Danh sách nguồn kiểm tra phiên bản (Ưu tiên GitHub Raw và GitHub Pages luôn cập nhật mới nhất)
  static const List<String> versionCheckUrls = [
    'https://raw.githubusercontent.com/thegioidienthoai464/tgdtbanhang/main/version.json',
    'https://thegioidienthoai464.github.io/tgdtbanhang/version.json',
  ];

  // Kiểm tra xem có bản cập nhật mới không
  static Future<UpdateInfo?> checkForUpdate({bool isManualCheck = false}) async {
    if (!isManualCheck && _dismissedInThisSession) {
      return null;
    }

    final timestamp = DateTime.now().millisecondsSinceEpoch;
    
    for (final baseUrl in versionCheckUrls) {
      try {
        final urlWithCacheBuster = Uri.parse('$baseUrl?t=$timestamp');
        final response = await http.get(
          urlWithCacheBuster,
          headers: {'Cache-Control': 'no-cache', 'Pragma': 'no-cache'},
        ).timeout(const Duration(seconds: 4));

        if (response.statusCode == 200) {
          final data = json.decode(utf8.decode(response.bodyBytes));
          final update = UpdateInfo.fromJson(data);

          // Nếu số build trên máy chủ lớn hơn mã build hiện tại của app
          if (update.buildNumber > currentBuildNumber) {
            return update;
          }
          return null; // Đã kiểm tra thành công và app đang ở bản mới nhất
        }
      } catch (e) {
        debugPrint("Lỗi kiểm tra cập nhật từ $baseUrl: $e");
      }
    }
    return null;
  }

  // Hiển thị hộp thoại thông báo cập nhật cho người dùng
  static void showUpdateDialog(BuildContext context, UpdateInfo update, {bool isManualCheck = false}) {
    showDialog(
      context: context,
      barrierDismissible: !update.forceUpdate,
      builder: (dialogCtx) {
        return AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppTheme.primaryBlue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.system_update_rounded, color: AppTheme.primaryBlue),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bản cập nhật mới!',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    Text(
                      'Phiên bản v${update.version}',
                      style: const TextStyle(fontSize: 13, color: AppTheme.primaryBlue, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              ),
              if (!update.forceUpdate)
                IconButton(
                  icon: const Icon(Icons.close, size: 20, color: AppTheme.textMuted),
                  onPressed: () {
                    _dismissedInThisSession = true;
                    Navigator.pop(dialogCtx);
                  },
                  tooltip: 'Đóng',
                ),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Tính năng mới & Nâng cấp:',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: AppTheme.borderSubtle),
                ),
                child: Text(
                  update.releaseNotes,
                  style: const TextStyle(fontSize: 13, height: 1.4),
                ),
              ),
            ],
          ),
          actionsAlignment: MainAxisAlignment.spaceBetween,
          actions: [
            TextButton.icon(
              icon: const Icon(Icons.copy_rounded, size: 16),
              label: const Text('Sao chép link tải'),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: update.downloadUrl));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Đã sao chép link tải! Bạn có thể dán vào trình duyệt để tải file APK.'),
                    duration: Duration(seconds: 4),
                  ),
                );
              },
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (!update.forceUpdate)
                  TextButton(
                    onPressed: () {
                      _dismissedInThisSession = true;
                      Navigator.pop(dialogCtx);
                    },
                    child: const Text('Để sau', style: TextStyle(color: AppTheme.textMuted)),
                  ),
                const SizedBox(width: 6),
                ElevatedButton.icon(
                  icon: const Icon(Icons.download_rounded, size: 18),
                  label: const Text('CẬP NHẬT NGAY'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () async {
                    if (!update.forceUpdate) {
                      Navigator.pop(dialogCtx);
                    }
                    final uri = Uri.parse(update.downloadUrl);
                    bool success = false;
                    try {
                      success = await launchUrl(uri, mode: LaunchMode.externalApplication);
                    } catch (_) {}

                    if (!success) {
                      try {
                        success = await launchUrl(uri, mode: LaunchMode.platformDefault);
                      } catch (_) {}
                    }

                    if (!success) {
                      try {
                        success = await launchUrl(uri);
                      } catch (_) {}
                    }

                    if (!success && context.mounted) {
                      Clipboard.setData(ClipboardData(text: update.downloadUrl));
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          duration: const Duration(seconds: 8),
                          content: Text('Đã sao chép link! Vui lòng dán vào trình duyệt: ${update.downloadUrl}'),
                          action: SnackBarAction(
                            label: 'Đóng',
                            onPressed: () {},
                          ),
                        ),
                      );
                    }
                  },
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
