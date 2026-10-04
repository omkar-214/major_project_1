import 'dart:convert';
import 'dart:io';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'package:vaultly/providers/app_provider.dart';
import 'package:vaultly/utils/format.dart';

class BackupService {
  static Future<Directory> _backupDir() async {
    if (Platform.isAndroid) {
      Directory? external = await getExternalStorageDirectory();
      if (external != null) {
        return external;
      }
    }
    return getApplicationDocumentsDirectory();
  }

  static String _csvCell(Object? value) {
    String text = (value ?? "").toString();
    return '"${text.replaceAll('"', '""')}"';
  }

  static Future<File> exportCsv(AppProvider app) async {
    List<List<Object?>> rows = [
      [
        "Contact",
        "Phone",
        "Contact Type",
        "Direction",
        "Principal",
        "Rate",
        "Rate Type",
        "Start Date",
        "Due Date",
        "Interest",
        "Paid",
        "Outstanding",
        "Status",
        "Notes",
      ],
    ];

    for (final tx in app.txs) {
      final contact = app.contactById(tx.contactId);
      rows.add([
        contact?.name ?? "",
        contact?.phone ?? "",
        contact?.type ?? "",
        tx.given ? "Given" : "Taken",
        tx.amount.toStringAsFixed(2),
        tx.rate,
        tx.rateType,
        fmtDate(tx.startDate),
        tx.dueDate == null ? "" : fmtDate(tx.dueDate!),
        app.interestOf(tx).toStringAsFixed(2),
        app.paidFor(tx.id!).toStringAsFixed(2),
        app.outstandingOf(tx).toStringAsFixed(2),
        app.statusOf(tx),
        tx.notes,
      ]);
    }

    String csv = rows.map((row) => row.map(_csvCell).join(",")).join("\n");
    Directory dir = await _backupDir();
    File file = File("${dir.path}/vaultly_transactions.csv");
    return file.writeAsString(csv);
  }

  static String _toJson(AppProvider app) {
    return jsonEncode({
      "version": 1,
      "createdAt": DateTime.now().toIso8601String(),
      "contacts": app.contacts.map((e) => e.toMap()).toList(),
      "transactions": app.txs.map((e) => e.toMap()).toList(),
      "payments": app.payments.map((e) => e.toMap()).toList(),
    });
  }

  static List<Map<String, Object?>> _mapsFromJson(Map<String, dynamic> json, String key) {
    List list = json[key] as List;
    List<Map<String, Object?>> result = [];
    for (final item in list) {
      result.add(Map<String, Object?>.from(item as Map));
    }
    return result;
  }

  static Future<void> _applyBackup(AppProvider app, String jsonText) async {
    Map<String, dynamic> json = jsonDecode(jsonText) as Map<String, dynamic>;
    await app.replaceAll(
      _mapsFromJson(json, "contacts"),
      _mapsFromJson(json, "transactions"),
      _mapsFromJson(json, "payments"),
    );
  }

  static Future<void> shareFile(File file, String text) async {
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path)], text: text),
    );
  }

  static Future<File> localBackup(AppProvider app) async {
    Directory dir = await _backupDir();
    File file = File("${dir.path}/vaultly_backup.json");
    return file.writeAsString(_toJson(app));
  }

  static Future<bool> localRestore(AppProvider app) async {
    Directory dir = await _backupDir();
    File file = File("${dir.path}/vaultly_backup.json");
    if (!await file.exists()) {
      return false;
    }
    await _applyBackup(app, await file.readAsString());
    return true;
  }

  static DocumentReference<Map<String, dynamic>> _cloudDoc() {
    User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception("Not signed in");
    }
    return FirebaseFirestore.instance
        .collection("users")
        .doc(user.uid)
        .collection("backups")
        .doc("latest");
  }

  static Future<void> cloudBackup(AppProvider app) async {
    await _cloudDoc().set({
      "data": _toJson(app),
      "updatedAt": FieldValue.serverTimestamp(),
    });
  }

  static Future<bool> cloudRestore(AppProvider app) async {
    final snap = await _cloudDoc().get();
    if (!snap.exists) {
      return false;
    }
    String? data = snap.data()?["data"] as String?;
    if (data == null) {
      return false;
    }
    await _applyBackup(app, data);
    return true;
  }
}