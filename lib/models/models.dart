class Contact {
  final int? id;
  final String uid;
  final String name;
  final String phone;
  final String email;
  final String type;

  const Contact({
    this.id,
    required this.uid,
    required this.name,
    required this.phone,
    this.email = '',
    required this.type,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'uid': uid,
      'name': name,
      'phone': phone,
      'email': email,
      'type': type,
    };
  }

  factory Contact.fromMap(Map<String, Object?> map) {
    return Contact(
      id: map['id'] as int?,
      uid: map['uid'] as String,
      name: map['name'] as String,
      phone: (map['phone'] as String?) ?? '',
      email: (map['email'] as String?) ?? '',
      type: (map['type'] as String?) ?? 'borrower',
    );
  }
}

class TxModel {
  final int? id;
  final String uid;
  final int contactId;
  final double amount;
  final bool given;
  final double rate;
  final String rateType;
  final DateTime startDate;
  final DateTime? dueDate;
  final String notes;
  final DateTime? settledAt;

  const TxModel({
    this.id,
    required this.uid,
    required this.contactId,
    required this.amount,
    required this.given,
    required this.rate,
    required this.rateType,
    required this.startDate,
    this.dueDate,
    this.notes = '',
    this.settledAt,
  });

  String get rateLabel {
    final decimals = rate % 1 == 0 ? 0 : 2;
    final rateText = rate.toStringAsFixed(decimals);
    final period = rateType == 'monthly' ? 'month' : 'year';
    return '$rateText% per $period';
  }

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'uid': uid,
      'contact_id': contactId,
      'amount': amount,
      'given': given ? 1 : 0,
      'rate': rate,
      'rate_type': rateType,
      'start_date': startDate.millisecondsSinceEpoch,
      'due_date': dueDate?.millisecondsSinceEpoch,
      'notes': notes,
      'settled_at': settledAt?.millisecondsSinceEpoch,
    };
  }

  factory TxModel.fromMap(Map<String, Object?> map) {
    DateTime? due;
    if (map['due_date'] != null) {
      due = DateTime.fromMillisecondsSinceEpoch(map['due_date'] as int);
    }

    DateTime? settled;
    if (map['settled_at'] != null) {
      settled = DateTime.fromMillisecondsSinceEpoch(map['settled_at'] as int);
    }

    return TxModel(
      id: map['id'] as int?,
      uid: map['uid'] as String,
      contactId: map['contact_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      given: map['given'] == 1,
      rate: (map['rate'] as num).toDouble(),
      rateType: (map['rate_type'] as String?) ?? 'monthly',
      startDate: DateTime.fromMillisecondsSinceEpoch(map['start_date'] as int),
      dueDate: due,
      notes: (map['notes'] as String?) ?? '',
      settledAt: settled,
    );
  }
}

class Payment {
  final int? id;
  final int txId;
  final double amount;
  final DateTime date;
  final String mode;
  final String note;
  final String? proofPath;

  const Payment({
    this.id,
    required this.txId,
    required this.amount,
    required this.date,
    required this.mode,
    this.note = '',
    this.proofPath,
  });

  Map<String, Object?> toMap() {
    return {
      'id': id,
      'transaction_id': txId,
      'amount': amount,
      'date': date.millisecondsSinceEpoch,
      'mode': mode,
      'note': note,
      'proof_path': proofPath,
    };
  }

  factory Payment.fromMap(Map<String, Object?> map) {
    return Payment(
      id: map['id'] as int?,
      txId: map['transaction_id'] as int,
      amount: (map['amount'] as num).toDouble(),
      date: DateTime.fromMillisecondsSinceEpoch(map['date'] as int),
      mode: (map['mode'] as String?) ?? 'Cash',
      note: (map['note'] as String?) ?? '',
      proofPath: map['proof_path'] as String?,
    );
  }
}
