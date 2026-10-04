import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vaultly/providers/app_provider.dart';
import 'package:vaultly/services/backup_service.dart';
import 'package:vaultly/theme/app_colors.dart';
import 'package:vaultly/widgets/common.dart';

class BackupPage extends StatefulWidget {
  const BackupPage({super.key});

  @override
  State<BackupPage> createState() => _BackupPageState();
}

class _BackupPageState extends State<BackupPage> {
  bool _busy = false;
  String _status = "";

  Future<void> _run(Future<String> Function() action) async {
    setState(() {
      _busy = true;
      _status = "";
    });
    try {
      String result = await action();
      if (mounted) {
        setState(() {
          _status = result;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _status = "Failed: $e";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _busy = false;
        });
      }
    }
  }

  Future<void> _restore(Future<bool> Function(AppProvider) fn) async {
    bool ok = await confirmDialog(
      context,
      "Restore backup",
      "Your current data will be replaced with the backup.",
    );
    if (!ok || !mounted) return;

    AppProvider app = context.read<AppProvider>();
    await _run(() async {
      bool done = await fn(app);
      if (done) {
        return "Backup restored";
      }
      return "No backup found";
    });
  }

  Widget _tile(IconData icon, String title, String subtitle, VoidCallback onTap) {
    return AppCard(
      onTap: _busy ? null : onTap,
      child: Row(
        children: [
          Icon(icon, color: AppColors.accent),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: const TextStyle(color: AppColors.text, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    AppProvider app = context.read<AppProvider>();

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: pageBar("Export & Backup"),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            const SectionHeader(title: "Export"),
            const SizedBox(height: 10),
            _tile(
              Icons.table_chart_outlined,
              "Export to CSV",
              "Saves the file and opens the share sheet",
                  () {
                _run(() async {
                  final file = await BackupService.exportCsv(app);
                  await BackupService.shareFile(file, "Vaultly transactions");
                  return "CSV saved:\n${file.path}";
                });
              },
            ),
            const SizedBox(height: 18),
            const SectionHeader(title: "Local backup"),
            const SizedBox(height: 10),
            _tile(
              Icons.save_alt,
              "Backup to device",
              "Saves all data as a JSON file on this device",
                  () {
                _run(() async {
                  final file = await BackupService.localBackup(app);
                  return "Backup saved:\n${file.path}";
                });
              },
            ),
            _tile(
              Icons.restore,
              "Restore from device",
              "Replaces current data with the saved JSON file",
                  () {
                _restore(BackupService.localRestore);
              },
            ),
            _tile(
              Icons.share_outlined,
              "Share backup file",
              "Creates a backup and shares it with any app",
                  () {
                _run(() async {
                  final file = await BackupService.localBackup(app);
                  await BackupService.shareFile(file, "Vaultly backup");
                  return "Backup shared:\n${file.path}";
                });
              },
            ),
            const SizedBox(height: 18),
            const SectionHeader(title: "Cloud backup"),
            const SizedBox(height: 10),
            _tile(
              Icons.cloud_upload_outlined,
              "Backup to cloud",
              "Stores your data securely in your Firebase account",
                  () {
                _run(() async {
                  await BackupService.cloudBackup(app);
                  return "Cloud backup completed";
                });
              },
            ),
            _tile(
              Icons.cloud_download_outlined,
              "Restore from cloud",
              "Replaces current data with your latest cloud backup",
                  () {
                _restore(BackupService.cloudRestore);
              },
            ),
            const SizedBox(height: 16),
            if (_busy) const Center(child: CircularProgressIndicator()),
            if (_status.isNotEmpty)
              Text(
                _status,
                style: const TextStyle(color: AppColors.text, fontSize: 13),
              ),
          ],
        ),
      ),
    );
  }
}