import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:vaultly/db/app_database.dart';
import 'package:vaultly/models/models.dart';
import 'package:vaultly/services/interest_service.dart';
import 'package:vaultly/services/notification_service.dart';
import 'package:vaultly/services/proof_service.dart';
import 'package:vaultly/utils/format.dart';

class AppProvider extends ChangeNotifier {
  List<Contact> contacts = [];
  List<TxModel> txs = [];
  List<Payment> payments = [];
  bool loading = false;

  String? get uid => FirebaseAuth.instance.currentUser?.uid;

  Future<void> load() async {
    loading = true;
    notifyListeners();
    await _reload();
    loading = false;
    notifyListeners();
  }

  Future<void> _reload() async {
    String? userId = uid;
    if (userId == null) {
      contacts = [];
      txs = [];
      payments = [];
      notifyListeners();
      return;
    }

    final db = await AppDatabase.instance.db;
    final contactRows = await db.query(
      "contacts",
      where: "uid = ?",
      whereArgs: [userId],
      orderBy: "name COLLATE NOCASE ASC",
    );
    final txRows = await db.query(
      "transactions",
      where: "uid = ?",
      whereArgs: [userId],
      orderBy: "start_date DESC, id DESC",
    );
    final paymentRows = await db.rawQuery(
      "SELECT p.* FROM payments p INNER JOIN transactions t ON t.id = p.transaction_id WHERE t.uid = ? ORDER BY p.date DESC, p.id DESC",
      [userId],
    );

    contacts = contactRows.map(Contact.fromMap).toList();
    txs = txRows.map(TxModel.fromMap).toList();
    payments = paymentRows.map(Payment.fromMap).toList();
    notifyListeners();
    NotificationService.instance.sync(this);
  }

  void clear() {
    contacts = [];
    txs = [];
    payments = [];
    notifyListeners();
    NotificationService.instance.cancelAll();
  }

  Contact? contactById(int id) {
    for (Contact contact in contacts) {
      if (contact.id == id) {
        return contact;
      }
    }
    return null;
  }

  TxModel? txById(int id) {
    for (TxModel tx in txs) {
      if (tx.id == id) {
        return tx;
      }
    }
    return null;
  }

  List<Payment> paymentsFor(int txId) {
    return payments.where((payment) => payment.txId == txId).toList();
  }

  List<TxModel> txsForContact(int contactId) {
    return txs.where((tx) => tx.contactId == contactId).toList();
  }

  double paidFor(int txId) {
    double total = 0;
    for (Payment payment in paymentsFor(txId)) {
      total += payment.amount;
    }
    return total;
  }

  double interestOf(TxModel tx) {
    return InterestService.tillToday(tx);
  }

  double outstandingOf(TxModel tx) {
    if (tx.settledAt != null) return 0;

    double value = tx.amount + interestOf(tx) - paidFor(tx.id!);
    if (value < 0) return 0;
    return value;
  }

  String statusOf(TxModel tx) {
    if (tx.settledAt != null) {
      return "Settled";
    }
    if (paidFor(tx.id!) > 0) {
      return "Partially paid";
    }
    return "Pending";
  }

  bool isOverdue(TxModel tx) {
    if (tx.settledAt != null) return false;
    if (tx.dueDate == null) return false;
    return dateOnly(tx.dueDate!).isBefore(dateOnly(DateTime.now()));
  }

  List<TxModel> get dues {
    List<TxModel> list = [];
    for (TxModel tx in txs) {
      if (tx.settledAt == null && tx.dueDate != null) {
        list.add(tx);
      }
    }
    list.sort((a, b) => a.dueDate!.compareTo(b.dueDate!));
    return list;
  }

  double interestSum(bool given, {DateTime? from, DateTime? to, int? contactId}) {
    DateTime start = from ?? DateTime(1970);
    DateTime end = to ?? DateTime(3000);
    double total = 0;
    for (TxModel tx in txs) {
      if (tx.given != given) continue;
      if (contactId != null && tx.contactId != contactId) continue;
      total += InterestService.between(tx, start, end);
    }
    return total;
  }

  double outstandingSum(bool given, {int? contactId}) {
    double total = 0;
    for (TxModel tx in txs) {
      if (tx.given != given) continue;
      if (contactId != null && tx.contactId != contactId) continue;
      total += outstandingOf(tx);
    }
    return total;
  }

  double principalSum(bool given, {DateTime? from, DateTime? to, int? contactId}) {
    double total = 0;
    for (TxModel tx in txs) {
      if (tx.given != given) continue;
      if (contactId != null && tx.contactId != contactId) continue;
      if (from != null && tx.startDate.isBefore(from)) continue;
      if (to != null && !tx.startDate.isBefore(to)) continue;
      total += tx.amount;
    }
    return total;
  }

  Future<void> _deleteProofs(List<Payment> list) async {
    for (Payment payment in list) {
      await ProofService.delete(payment.proofPath);
    }
  }

  Future<int> addContact({
    required String name,
    required String phone,
    required String email,
    required String type,
  }) async {
    final db = await AppDatabase.instance.db;
    Contact contact = Contact(
      uid: uid ?? "",
      name: name,
      phone: phone,
      email: email,
      type: type,
    );
    final data = contact.toMap();
    data.remove("id");
    int id = await db.insert("contacts", data);
    await _reload();
    return id;
  }

  Future<void> updateContact(Contact contact) async {
    final db = await AppDatabase.instance.db;
    final data = contact.toMap();
    data.remove("id");
    data.remove("uid");
    await db.update("contacts", data, where: "id = ?", whereArgs: [contact.id]);
    await _reload();
  }

  Future<void> deleteContact(int id) async {
    final db = await AppDatabase.instance.db;
    for (TxModel tx in txsForContact(id)) {
      await _deleteProofs(paymentsFor(tx.id!));
    }
    await db.delete("contacts", where: "id = ?", whereArgs: [id]);
    await _reload();
  }

  Future<void> addTransaction(TxModel tx) async {
    final db = await AppDatabase.instance.db;
    final data = tx.toMap();
    data.remove("id");
    data["uid"] = uid ?? "";
    await db.insert("transactions", data);
    await _reload();
  }

  Future<void> updateTransaction(TxModel tx) async {
    final db = await AppDatabase.instance.db;
    final data = tx.toMap();
    data.remove("id");
    data.remove("uid");
    data.remove("settled_at");
    await db.update("transactions", data, where: "id = ?", whereArgs: [tx.id]);
    await _reload();
  }

  Future<void> deleteTransaction(int id) async {
    final db = await AppDatabase.instance.db;
    await _deleteProofs(paymentsFor(id));
    await db.delete("transactions", where: "id = ?", whereArgs: [id]);
    await _reload();
  }

  Future<void> addPayment(Payment payment, {required bool settle}) async {
    final db = await AppDatabase.instance.db;
    final data = payment.toMap();
    data.remove("id");
    await db.insert("payments", data);
    if (settle) {
      await db.update(
        "transactions",
        {"settled_at": payment.date.millisecondsSinceEpoch},
        where: "id = ?",
        whereArgs: [payment.txId],
      );
    }
    await _reload();
  }

  Future<void> deletePayment(Payment payment) async {
    final db = await AppDatabase.instance.db;
    await ProofService.delete(payment.proofPath);
    await db.delete("payments", where: "id = ?", whereArgs: [payment.id]);
    await db.update(
      "transactions",
      {"settled_at": null},
      where: "id = ?",
      whereArgs: [payment.txId],
    );
    await _reload();
  }

  Future<void> reopenTransaction(int id) async {
    final db = await AppDatabase.instance.db;
    await db.update(
      "transactions",
      {"settled_at": null},
      where: "id = ?",
      whereArgs: [id],
    );
    await _reload();
  }

  Future<void> replaceAll(
      List<Map<String, Object?>> contactMaps,
      List<Map<String, Object?>> txMaps,
      List<Map<String, Object?>> paymentMaps,
      ) async {
    String? userId = uid;
    if (userId == null) {
      throw Exception("Not signed in");
    }

    final db = await AppDatabase.instance.db;
    await db.transaction((txn) async {
      await txn.delete("contacts", where: "uid = ?", whereArgs: [userId]);

      Map<int, int> contactIdMap = {};
      for (Map<String, Object?> contact in contactMaps) {
        int? oldId = contact["id"] as int?;
        Map<String, Object?> data = Map<String, Object?>.from(contact);
        data.remove("id");
        data["uid"] = userId;
        int newId = await txn.insert("contacts", data);
        if (oldId != null) {
          contactIdMap[oldId] = newId;
        }
      }

      Map<int, int> txIdMap = {};
      for (Map<String, Object?> tx in txMaps) {
        int? oldId = tx["id"] as int?;
        int? newContactId = contactIdMap[tx["contact_id"] as int];
        if (newContactId == null) continue;

        Map<String, Object?> data = Map<String, Object?>.from(tx);
        data.remove("id");
        data["uid"] = userId;
        data["contact_id"] = newContactId;
        int newId = await txn.insert("transactions", data);
        if (oldId != null) {
          txIdMap[oldId] = newId;
        }
      }

      for (Map<String, Object?> payment in paymentMaps) {
        int? newTxId = txIdMap[payment["transaction_id"] as int];
        if (newTxId == null) continue;

        Map<String, Object?> data = Map<String, Object?>.from(payment);
        data.remove("id");
        data["transaction_id"] = newTxId;
        await txn.insert("payments", data);
      }
    });

    await _reload();
  }
}