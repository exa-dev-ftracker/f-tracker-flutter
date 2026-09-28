import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';
import '../theme/app_colors.dart';
import '../utils/app_haptics.dart';
import 'logger_service.dart';
import 'permission_service.dart';
import 'snackbar_service.dart';

class ScannedReceiptResult {
  final double? estimatedAmount;
  final String? merchantName;
  final DateTime? date;
  final String imagePath;
  final String? rawText;

  const ScannedReceiptResult({
    this.estimatedAmount,
    this.merchantName,
    this.date,
    required this.imagePath,
    this.rawText,
  });
}

class ReceiptScannerService {
  ReceiptScannerService._();

  static final ImagePicker _picker = ImagePicker();

  /// Menampilkan opsi Scan via Kamera atau Galeri, lalu memproses struk dengan ML Kit On-Device (100% Gratis & Offline)
  static Future<ScannedReceiptResult?> showScannerModal() async {
    final source = await Get.bottomSheet<ImageSource>(
      Material(
        color: AppColors.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        clipBehavior: Clip.antiAlias,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Wrap(
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const Text(
                'Scan Receipt (Free OCR)',
                style: TextStyle(
                  color: AppColors.textPrimary,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'Processed on-device with Google ML Kit with zero server quota or credit card required.',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12),
              ),
              const SizedBox(height: 20),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary),
                ),
                title: const Text('Take Photo with Camera', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                subtitle: const Text('Point camera at receipt or bill', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                onTap: () {
                  AppHaptics.selection();
                  Get.back(result: ImageSource.camera);
                },
              ),
              const Divider(color: AppColors.border, height: 1),
              ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.secondary.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.photo_library_rounded, color: AppColors.secondary),
                ),
                title: const Text('Choose from Photo Gallery', style: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600)),
                subtitle: const Text('Use an existing receipt photo', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                onTap: () {
                  AppHaptics.selection();
                  Get.back(result: ImageSource.gallery);
                },
              ),
              const SizedBox(height: 10),
            ],
          ),
        ),
      ),
    );

    if (source == null) return null;

    if (source == ImageSource.camera) {
      return scanFromCamera();
    } else {
      return pickFromGallery();
    }
  }

  static Future<ScannedReceiptResult?> scanFromCamera() async {
    final granted = await PermissionService.requestCamera(reason: 'automatically scanning receipts');
    if (!granted) return null;

    try {
      final image = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 90,
      );
      if (image == null) return null;

      return await _processReceiptImage(image.path);
    } catch (e) {
      LoggerService.e('Camera pick failed: $e', tag: 'ReceiptScanner');
      SnackbarService.error('Failed to open camera: $e');
      return null;
    }
  }

  static Future<ScannedReceiptResult?> pickFromGallery() async {
    try {
      final image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 90,
      );
      if (image == null) return null;

      return await _processReceiptImage(image.path);
    } catch (e) {
      LoggerService.e('Gallery pick failed: $e', tag: 'ReceiptScanner');
      SnackbarService.error('Failed to select photo from gallery: $e');
      return null;
    }
  }

  static Future<ScannedReceiptResult> _processReceiptImage(String path) async {
    LoggerService.i('Processing receipt with On-Device Google ML Kit: $path', tag: 'ReceiptScanner');

    final inputImage = InputImage.fromFilePath(path);
    final textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

    try {
      final recognizedText = await textRecognizer.processImage(inputImage);
      final rawText = recognizedText.text;

      final lines = <String>[];
      for (final block in recognizedText.blocks) {
        for (final line in block.lines) {
          final trimmed = line.text.trim();
          if (trimmed.isNotEmpty) lines.add(trimmed);
        }
      }

      final merchantName = _extractMerchantName(lines);
      final amount = _extractTotalAmount(lines);
      final date = _extractDate(lines);

      LoggerService.i(
        'ML Kit OCR Result -> Merchant: "$merchantName", Amount: $amount, Date: $date',
        tag: 'ReceiptScanner',
      );

      return ScannedReceiptResult(
        estimatedAmount: amount,
        merchantName: merchantName,
        date: date ?? DateTime.now(),
        imagePath: path,
        rawText: rawText,
      );
    } catch (e) {
      LoggerService.e('On-device OCR parsing failed: $e', tag: 'ReceiptScanner');
      return ScannedReceiptResult(
        estimatedAmount: null,
        merchantName: null,
        date: DateTime.now(),
        imagePath: path,
      );
    } finally {
      await textRecognizer.close();
    }
  }

  /// Ekstraksi nama merchant dari baris-baris atas struk
  static String? _extractMerchantName(List<String> lines) {
    if (lines.isEmpty) return null;

    final skipKeywords = [
      'jl.', 'jalan', 'telp', 'phone', 'npwp', 'receipt', 'struk', 'no.',
      'nota', 'kasir', 'waktu', 'tanggal', 'order', 'table', 'meja', 'shift',
      'welcome', 'selamat datang', 'terima kasih'
    ];

    for (int i = 0; i < lines.length && i < 6; i++) {
      final line = lines[i].trim();
      final lower = line.toLowerCase();

      // Lewati baris berisi kata kunci alamat/header
      if (skipKeywords.any((kw) => lower.contains(kw))) continue;

      // Lewati baris yang cuma angka atau simbol
      final digitsOnly = line.replaceAll(RegExp(r'[^0-9]'), '');
      if (digitsOnly.length > 5 && digitsOnly.length == line.replaceAll(RegExp(r'\s'), '').length) {
        continue;
      }

      if (line.length >= 3 && line.length <= 40) {
        return line;
      }
    }

    return lines.firstOrNull;
  }

  /// Ekstraksi total nominal dari keyword seperti TOTAL, GRAND TOTAL, JUMLAH, BAYAR
  static double? _extractTotalAmount(List<String> lines) {
    final priorityKeywords = [
      'grand total',
      'total bayar',
      'total akhir',
      'total belanja',
      'total tagihan',
      'total',
      'jumlah',
      'bayar',
      'tunai',
      'netto',
      'subtotal',
    ];

    for (final kw in priorityKeywords) {
      for (int i = 0; i < lines.length; i++) {
        final line = lines[i];
        final lower = line.toLowerCase();

        if (lower.contains(kw)) {
          // 1. Cek nominal di baris yang sama
          final sameLineAmount = _parseAmountFromText(line);
          if (sameLineAmount != null && sameLineAmount > 0) {
            return sameLineAmount;
          }

          // 2. Cek nominal di baris tepat setelah keyword (format umum kasir: TOTAL \n Rp 50.000)
          if (i + 1 < lines.length) {
            final nextLineAmount = _parseAmountFromText(lines[i + 1]);
            if (nextLineAmount != null && nextLineAmount > 0) {
              return nextLineAmount;
            }
          }
        }
      }
    }

    // 3. Fallback: Kumpulkan semua angka bertipe nominal dan ambil nominal tertinggi yang masuk akal
    final candidates = <double>[];
    for (final line in lines) {
      final amt = _parseAmountFromText(line);
      if (amt != null && amt >= 100 && amt <= 100000000) {
        candidates.add(amt);
      }
    }

    if (candidates.isNotEmpty) {
      candidates.sort((a, b) => b.compareTo(a));
      return candidates.first;
    }

    return null;
  }

  /// Parsing angka mata uang Indonesia (Rp 50.000, 50.000,00, 150000)
  static double? _parseAmountFromText(String text) {
    final regex = RegExp(r'(?:Rp\.?\s*)?([0-9]{1,3}(?:[\.,][0-9]{3})*(?:[\.,][0-9]{2})?|[0-9]+)');
    final matches = regex.allMatches(text);

    for (final match in matches) {
      String raw = match.group(1) ?? '';
      if (raw.isEmpty) continue;

      if (raw.contains('.') && raw.contains(',')) {
        if (raw.lastIndexOf(',') > raw.lastIndexOf('.')) {
          // Format IDR desimal: 50.000,00
          raw = raw.replaceAll('.', '').replaceAll(',', '.');
        } else {
          // Format US desimal: 50,000.00
          raw = raw.replaceAll(',', '');
        }
      } else if (raw.contains('.')) {
        final parts = raw.split('.');
        if (parts.last.length == 3 || parts.length > 2) {
          raw = raw.replaceAll('.', '');
        }
      } else if (raw.contains(',')) {
        final parts = raw.split(',');
        if (parts.last.length == 3 || parts.length > 2) {
          raw = raw.replaceAll(',', '');
        } else {
          raw = raw.replaceAll(',', '.');
        }
      }

      final parsed = double.tryParse(raw);
      if (parsed != null && parsed >= 100 && parsed < 1000000000) {
        return parsed;
      }
    }
    return null;
  }

  /// Ekstraksi tanggal struk (DD/MM/YYYY atau DD-MM-YYYY)
  static DateTime? _extractDate(List<String> lines) {
    final dateRegex = RegExp(r'\b(\d{1,2})[\/\-\.](\d{1,2})[\/\-\.](\d{2,4})\b');

    for (final line in lines) {
      final match = dateRegex.firstMatch(line);
      if (match != null) {
        final d = int.tryParse(match.group(1)!) ?? 1;
        final m = int.tryParse(match.group(2)!) ?? 1;
        var y = int.tryParse(match.group(3)!) ?? DateTime.now().year;
        if (y < 100) y += 2000;

        if (m >= 1 && m <= 12 && d >= 1 && d <= 31 && y >= 2020 && y <= 2030) {
          try {
            return DateTime(y, m, d);
          } catch (_) {}
        }
      }
    }
    return null;
  }
}
