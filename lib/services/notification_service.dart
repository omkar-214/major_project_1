import 'dart:math';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:intl/intl.dart';
import 'package:timezone/data/latest_all.dart' as tzdata;
import 'package:timezone/timezone.dart' as tz;
import 'package:vaultly/pages/transaction_detail_page.dart';
import 'package:vaultly/providers/app_provider.dart';
import 'package:vaultly/services/interest_service.dart';
import 'package:vaultly/utils/format.dart';

class ReminderSettings {
  final Set<int> days;
  final bool monthlySummary;

  const ReminderSettings({
    required this.days,
    required this.monthlySummary,
  });
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();
  static final GlobalKey<NavigatorState> navKey = GlobalKey<NavigatorState>();

  final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  bool _ready = false;
  bool _running = false;
  bool _pending = false;

  static const NotificationDetails _details = NotificationDetails(
    android: AndroidNotificationDetails(
      "vaultly_reminders",
      "Reminders",
      channelDescription: "Due date reminders and monthly summaries",
      importance: Importance.high,
      priority: Priority.high,
    ),
  );

  bool get supported {
    return !kIsWeb && defaultTargetPlatform == TargetPlatform.android;
  }

  Future<void> init() async {
    if (!supported || _ready) return;

    tzdata.initializeTimeZones();
    await _plugin.initialize(
      settings: const InitializationSettings(
        android: AndroidInitializationSettings("@mipmap/ic_launcher"),
      ),
      onDidReceiveNotificationResponse: _onTap,
    );
    _ready = true;
  }

  void _onTap(NotificationResponse response) {
    int? id = int.tryParse(response.payload ?? "");
    if (id == null) return;

    navKey.currentState?.push(
      MaterialPageRoute(builder: (context) => TransactionDetailPage(txId: id)),
    );
  }

  Future<bool> requestPermission() async {
    if (!_ready) return false;

    final android = _plugin.resolvePlatformSpecificImplementation<
        AndroidFlutterLocalNotificationsPlugin>();
    if (android == null) return false;

    bool? granted = await android.requestNotificationsPermission();
    return granted ?? false;
  }

  Future<ReminderSettings> loadSettings() async {
    String? daysValue = await _storage.read(key: "reminder_days");
    String? monthlyValue = await _storage.read(key: "monthly_summary");

    Set<int> days;
    if (daysValue == null) {
      days = {1};
    } else {
      days = {};
      for (final part in daysValue.split(",")) {
        if (part.isNotEmpty) {
          days.add(int.parse(part));
        }
      }
    }

    return ReminderSettings(
      days: days,
      monthlySummary: monthlyValue != "false",
    );
  }

  Future<void> saveSettings(ReminderSettings settings) async {
    List<int> list = settings.days.toList();
    list.sort();
    await _storage.write(key: "reminder_days", value: list.join(","));
    await _storage.write(
      key: "monthly_summary",
      value: settings.monthlySummary.toString(),
    );
  }

  Future<void> showTest() async {
    if (!_ready) return;

    await _plugin.show(
      id: 999999,
      title: "Vaultly",
      body: "Notifications are working",
      notificationDetails: _details,
    );
  }

  Future<void> cancelAll() async {
    if (!_ready) return;

    await _plugin.cancelAll();
  }

  Future<void> _schedule(
      int id,
      DateTime when,
      String title,
      String body,
      String payload,
      ) async {
    DateTime now = DateTime.now();
    if (!when.isAfter(now)) return;

    final scheduled = tz.TZDateTime.now(tz.local).add(when.difference(now));
    await _plugin.zonedSchedule(
      id: id,
      title: title,
      body: body,
      scheduledDate: scheduled,
      notificationDetails: _details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      payload: payload,
    );
  }

  Future<void> sync(AppProvider app) async {
    if (!_ready) return;

    if (_running) {
      _pending = true;
      return;
    }
    _running = true;
    try {
      do {
        _pending = false;
        await _apply(app);
      } while (_pending);
    } catch (e) {
      debugPrint("Notification sync error: $e");
    } finally {
      _running = false;
    }
  }

  double _sum(AppProvider app, bool given, DateTime from, DateTime to) {
    double total = 0;
    for (final tx in app.txs) {
      if (tx.given != given) continue;
      total += InterestService.between(tx, from, to, asOf: to);
    }
    return total;
  }

  Future<void> _apply(AppProvider app) async {
    await _plugin.cancelAll();
    if (app.uid == null) return;

    ReminderSettings settings = await loadSettings();

    for (final tx in app.txs) {
      if (tx.settledAt != null || tx.dueDate == null) continue;

      final contact = app.contactById(tx.contactId);
      String name = contact?.name ?? "contact";
      double projected = tx.amount + InterestService.tillDue(tx) - app.paidFor(tx.id!);
      String amount = money(max(0.0, projected));
      DateTime due = tx.dueDate!;
      DateTime at9 = DateTime(due.year, due.month, due.day, 9);
      String payload = "${tx.id}";
      int base = tx.id! * 100;

      String line;
      if (tx.given) {
        line = "$amount to receive from $name";
      } else {
        line = "$amount to pay to $name";
      }

      for (final daysBefore in settings.days) {
        String titleDays = daysBefore == 1 ? "1 day" : "$daysBefore days";
        await _schedule(
          base + daysBefore,
          at9.subtract(Duration(days: daysBefore)),
          "Payment due in $titleDays",
          line,
          payload,
        );
      }

      await _schedule(base, at9, "Payment due today", line, payload);
      await _schedule(
        base + 50,
        at9.add(const Duration(days: 1)),
        "Payment overdue",
        line,
        payload,
      );
    }

    if (settings.monthlySummary) {
      DateTime now = DateTime.now();
      DateTime start = DateTime(now.year, now.month);
      DateTime end = DateTime(now.year, now.month + 1);
      double earned = _sum(app, true, start, end);
      double paid = _sum(app, false, start, end);
      await _schedule(
        999001,
        DateTime(end.year, end.month, end.day, 9),
        "Monthly summary",
        "${DateFormat("MMMM").format(start)}: interest earned ${money(earned)}, paid ${money(paid)}",
        "",
      );
    }
  }
}