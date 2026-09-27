import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/app_haptics.dart';
import '../../../core/utils/currency_formatter.dart';
import '../../../routes/app_routes.dart';
import '../controllers/settings_controller.dart';

class SettingsView extends GetView<SettingsController> {
  const SettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final user = controller.user;
    final userName = user?['name'] ?? 'Pengguna F-Tracker';
    final userEmail = user?['email'] ?? 'user@example.com';

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Pengaturan'),
        backgroundColor: AppColors.surface,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Profile Card
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: const BoxDecoration(
                      gradient: AppColors.emeraldGradient,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          style: const TextStyle(
                            color: AppColors.textPrimary,
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          userEmail,
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Offline & Cloud Sync Hub
            const Text(
              'Sinkronisasi Cloud & Data Offline',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            _buildSyncCenter(context),
            const SizedBox(height: 24),

            // Security & Preferences Section
            const Text(
              'Keamanan & Preferensi Mobile',
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 10),
            Container(
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.border),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.fingerprint_rounded, color: AppColors.primaryLight),
                    title: const Text('Kunci Biometrik (Face ID / Sidik Jari)', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                    subtitle: const Text('Amankan data saat app dibuka', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    trailing: Obx(() => Switch(
                      value: controller.isBiometricEnabled.value,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) => controller.toggleBiometric(val),
                    )),
                  ),
                  const Divider(color: AppColors.border, height: 1),
                  ListTile(
                    leading: const Icon(Icons.category_outlined, color: AppColors.secondary),
                    title: const Text('Kelola Kategori', style: TextStyle(color: AppColors.textPrimary, fontSize: 14, fontWeight: FontWeight.w500)),
                    subtitle: const Text('Atur kategori pemasukan & pengeluaran', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                    trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted),
                    onTap: () => Get.toNamed(Routes.categories),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Logout Button
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.error,
                side: const BorderSide(color: AppColors.error),
                minimumSize: const Size(double.infinity, 50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              icon: const Icon(Icons.logout_rounded, size: 20),
              label: const Text('Keluar dari Akun'),
              onPressed: () {
                AppHaptics.heavy();
                Get.dialog(
                  AlertDialog(
                    backgroundColor: AppColors.surface,
                    title: const Text('Konfirmasi Keluar', style: TextStyle(color: AppColors.textPrimary)),
                    content: const Text('Apakah Anda yakin ingin keluar dari akun ini?', style: TextStyle(color: AppColors.textSecondary)),
                    actions: [
                      TextButton(onPressed: () => Get.back(), child: const Text('Batal', style: TextStyle(color: AppColors.textMuted))),
                      FilledButton(
                        style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                        onPressed: () {
                          Get.back();
                          controller.logout();
                        },
                        child: const Text('Keluar'),
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Danger Zone - Apple App Store Guideline 5.1.1(v) Compliant
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Zona Bahaya',
                        style: TextStyle(
                          color: AppColors.error,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Sesuai ketentuan Apple App Store, Anda berhak menghapus akun beserta seluruh data transaksi dan kategori secara permanen kapan saja. Tindakan ini tidak dapat dibatalkan.',
                    style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                  const SizedBox(height: 14),
                  FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.error,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    icon: const Icon(Icons.delete_forever_rounded, size: 18),
                    label: const Text('Hapus Akun Permanen', style: TextStyle(fontWeight: FontWeight.bold)),
                    onPressed: () {
                      AppHaptics.heavy();
                      Get.dialog(
                        AlertDialog(
                          backgroundColor: AppColors.surface,
                          title: const Row(
                            children: [
                              Icon(Icons.warning_amber_rounded, color: AppColors.error, size: 24),
                              SizedBox(width: 8),
                              Expanded(
                                child: Text('Hapus Akun Permanen?', style: TextStyle(color: AppColors.textPrimary, fontSize: 18)),
                              ),
                            ],
                          ),
                          content: const Text(
                            'Apakah Anda yakin ingin menghapus akun ini secara permanen?\n\nSemua riwayat transaksi, kategori, dan profil Anda akan dihapus secara permanen dari server dan perangkat ini sesuai ketentuan privasi Apple. Anda tidak dapat memulihkannya lagi.',
                            style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                          ),
                          actions: [
                            TextButton(
                              onPressed: () => Get.back(),
                              child: const Text('Batal', style: TextStyle(color: AppColors.textMuted)),
                            ),
                            FilledButton(
                              style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                              onPressed: () {
                                Get.back();
                                controller.deleteAccount();
                              },
                              child: const Text('Hapus Akun Saya'),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSyncCenter(BuildContext context) {
    final syncService = controller.syncService;

    return Obx(() {
      final isOnline = syncService.isOnline.value;
      final isSyncing = syncService.isSyncing.value;
      final pendingCount = syncService.pendingCount.value;
      final lastSynced = syncService.lastSyncedAt.value;

      return Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isOnline
                ? AppColors.primary.withValues(alpha: 0.3)
                : AppColors.warning.withValues(alpha: 0.4),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Status Row
            Row(
              children: [
                Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isOnline ? AppColors.income : AppColors.warning,
                    boxShadow: [
                      BoxShadow(
                        color: (isOnline ? AppColors.income : AppColors.warning).withValues(alpha: 0.6),
                        blurRadius: 6,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        isOnline ? 'Online • Terhubung ke Server' : 'Mode Offline Aktif',
                        style: const TextStyle(
                          color: AppColors.textPrimary,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        isOnline
                            ? 'Penyimpanan lokal & cloud tersinkronisasi otomatis'
                            : 'Semua perubahan dicatat di HP & dikirim saat terhubung internet',
                        style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(color: AppColors.border, height: 24),

            // Metrics Details
            Row(
              children: [
                Expanded(
                  child: _buildMetricTile(
                    label: 'Antrean Offline',
                    value: '$pendingCount item',
                    icon: Icons.pending_actions_rounded,
                    color: pendingCount > 0 ? AppColors.warning : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildMetricTile(
                    label: 'Cache Lokal',
                    value: '${controller.localTransactionCount} tx',
                    icon: Icons.sd_storage_rounded,
                    color: AppColors.secondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Last Synced Info
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.surfaceVariant.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  const Icon(Icons.history_rounded, size: 14, color: AppColors.textMuted),
                  const SizedBox(width: 8),
                  Text(
                    'Terakhir sinkron: ${lastSynced != null ? CurrencyFormatter.formatDate(lastSynced) : "Belum pernah"}',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Manual Sync Button
            SizedBox(
              width: double.infinity,
              height: 46,
              child: FilledButton.icon(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: isSyncing ? null : controller.triggerManualSync,
                icon: isSyncing
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.sync_rounded, size: 18),
                label: Text(
                  isSyncing ? 'Menyinkronkan data...' : 'Sinkronkan Sekarang',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ),
            ),
          ],
        ),
      );
    });
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surfaceVariant.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
