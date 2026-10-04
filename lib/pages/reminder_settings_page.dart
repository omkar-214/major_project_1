import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vaultly/providers/app_provider.dart';
import 'package:vaultly/services/notification_service.dart';
import 'package:vaultly/theme/app_colors.dart';
import 'package:vaultly/widgets/common.dart';

class ReminderSettingsPage extends StatefulWidget {
  const ReminderSettingsPage({super.key});

  @override
  State<ReminderSettingsPage> createState() => _ReminderSettingsPageState();
}

class _ReminderSettingsPageState extends State<ReminderSettingsPage> {
  Set<int> _days = {1};
  bool _monthly = true;
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final settings = await NotificationService.instance.loadSettings();

    if (!mounted) return;

    setState(() {
      _days = {...settings.days};
      _monthly = settings.monthlySummary;
      _loaded = true;
    });
  }

  Future<void> _save() async {
    await NotificationService.instance.saveSettings(
      ReminderSettings(days: _days, monthlySummary: _monthly),
    );

    if (!mounted) return;

    await NotificationService.instance.sync(context.read<AppProvider>());
  }

  void _toggleDay(int day) {
    setState(() {
      if (_days.contains(day)) {
        _days.remove(day);
      } else {
        _days.add(day);
      }
    });
    _save();
  }

  Future<void> _test() async {
    final service = NotificationService.instance;

    if (!service.supported) {
      showMsg(context, "Notifications work on Android devices only");
      return;
    }

    bool ok = await service.requestPermission();

    if (!mounted) return;

    if (!ok) {
      showMsg(context, "Notification permission is not granted");
      return;
    }
    await service.showTest();
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (!_loaded) {
      body = const Center(child: CircularProgressIndicator());
    } else {
      body = ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const SectionHeader(title: "Remind me before due date"),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            children: [1, 3, 7].map((day) {
              String label = day == 1 ? "1 day" : "$day days";
              return choiceChip(label, _days.contains(day), () {
                _toggleDay(day);
              });
            }).toList(),
          ),
          const SizedBox(height: 8),
          const Text(
            "You also get a reminder on the due date and a notification when a payment is overdue.",
            style: TextStyle(color: AppColors.text, fontSize: 12),
          ),
          const SizedBox(height: 24),
          AppCard(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              activeThumbColor: AppColors.accent,
              title: const Text(
                "Monthly summary",
                style: TextStyle(color: Colors.white),
              ),
              subtitle: const Text(
                "Interest earned and paid, on the 1st of every month",
                style: TextStyle(color: AppColors.text, fontSize: 12),
              ),
              value: _monthly,
              onChanged: (value) {
                setState(() {
                  _monthly = value;
                });
                _save();
              },
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
            onPressed: () {
              _test();
            },
            icon: const Icon(
              Icons.notifications_active_outlined,
              color: AppColors.accent,
            ),
            label: const Text(
              "Send test notification",
              style: TextStyle(color: AppColors.accent),
            ),
          ),
        ],
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: pageBar("Reminders"),
      body: SafeArea(child: body),
    );
  }
}