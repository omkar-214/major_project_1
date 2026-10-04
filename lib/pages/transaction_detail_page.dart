import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:vaultly/models/models.dart';
import 'package:vaultly/pages/add_transaction_page.dart';
import 'package:vaultly/providers/app_provider.dart';
import 'package:vaultly/services/interest_service.dart';
import 'package:vaultly/services/proof_service.dart';
import 'package:vaultly/theme/app_colors.dart';
import 'package:vaultly/utils/format.dart';
import 'package:vaultly/widgets/common.dart';
import 'package:vaultly/widgets/customWidget.dart';

class TransactionDetailPage extends StatefulWidget {
  final int txId;

  const TransactionDetailPage({super.key, required this.txId});

  @override
  State<TransactionDetailPage> createState() => _TransactionDetailPageState();
}

class _TransactionDetailPageState extends State<TransactionDetailPage> {
  bool _tillDue = false;

  void _openPaymentSheet(TxModel tx, double outstanding) {
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => PaymentSheet(tx: tx, outstanding: outstanding),
    );
  }

  Future<void> _delete(TxModel tx) async {
    bool ok = await confirmDialog(
      context,
      "Delete transaction",
      "This will also delete its payments.",
    );
    if (!ok || !mounted) return;

    AppProvider app = context.read<AppProvider>();
    Navigator.pop(context);
    await app.deleteTransaction(tx.id!);
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final tx = app.txById(widget.txId);

    if (tx == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: pageBar("Transaction"),
      );
    }

    final contact = app.contactById(tx.contactId);
    bool useDue = _tillDue && tx.dueDate != null;
    double interest = useDue ? InterestService.tillDue(tx) : InterestService.tillToday(tx);
    double total = tx.amount + interest;
    double paid = app.paidFor(tx.id!);
    bool settled = tx.settledAt != null;

    double outstanding = 0;
    if (!settled) {
      outstanding = total - paid;
      if (outstanding < 0) {
        outstanding = 0;
      }
    }

    double todayOutstanding = app.outstandingOf(tx);
    Color color = tx.given ? AppColors.green : AppColors.red;
    final status = app.statusOf(tx);

    Color statusColor = AppColors.orange;
    if (settled) {
      statusColor = AppColors.green;
    } else if (app.isOverdue(tx)) {
      statusColor = AppColors.red;
    }

    final payments = app.paymentsFor(tx.id!);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: pageBar("Transaction", actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.white),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => AddTransactionPage(edit: tx)),
            );
          },
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.white),
          onPressed: () {
            _delete(tx);
          },
        ),
      ]),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            TxHeaderCard(
              tx: tx,
              contactName: contact?.name ?? "Unknown",
              phone: contact?.phone ?? "",
              contactType: contact?.type ?? "borrower",
              status: status,
              statusColor: statusColor,
              color: color,
            ),
            if (tx.dueDate != null && !settled)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Row(
                  children: [
                    choiceChip("Interest till today", !_tillDue, () {
                      setState(() {
                        _tillDue = false;
                      });
                    }),
                    const SizedBox(width: 8),
                    choiceChip("Till due date", _tillDue, () {
                      setState(() {
                        _tillDue = true;
                      });
                    }),
                  ],
                ),
              ),
            TxMoneyCard(
              tx: tx,
              interest: interest,
              total: total,
              paid: paid,
              outstanding: outstanding,
              color: color,
            ),
            if (settled)
              OutlinedButton.icon(
                onPressed: () => app.reopenTransaction(tx.id!),
                icon: const Icon(Icons.lock_open, color: AppColors.accent),
                label: const Text(
                  "Reopen transaction",
                  style: TextStyle(color: AppColors.accent),
                ),
              )
            else
              SizedBox(
                height: 48,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: () => _openPaymentSheet(tx, todayOutstanding),
                  icon: const Icon(Icons.payments_outlined, color: Colors.white),
                  label: const Text(
                    "Record payment",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            const SizedBox(height: 24),
            const SectionHeader(title: "Payment history"),
            const SizedBox(height: 10),
            if (payments.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "No payments recorded",
                  style: TextStyle(color: Colors.white54),
                ),
              )
            else
              ...payments.map((payment) => PaymentHistoryTile(payment: payment)),
          ],
        ),
      ),
    );
  }
}

class InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? color;
  final bool bold;

  const InfoRow({
    super.key,
    required this.label,
    required this.value,
    this.color,
    this.bold = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(color: AppColors.text, fontSize: 13),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.end,
              style: TextStyle(
                color: color ?? Colors.white,
                fontSize: 14,
                fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class TxHeaderCard extends StatelessWidget {
  final TxModel tx;
  final String contactName;
  final String phone;
  final String contactType;
  final String status;
  final Color statusColor;
  final Color color;

  const TxHeaderCard({
    super.key,
    required this.tx,
    required this.contactName,
    required this.phone,
    required this.contactType,
    required this.status,
    required this.statusColor,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          Row(
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: color.withValues(alpha: 0.15),
                child: Icon(
                  tx.given ? Icons.arrow_upward : Icons.arrow_downward,
                  color: color,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      contactName,
                      style: const TextStyle(color: Colors.white, fontSize: 17),
                    ),
                    if (phone.isNotEmpty)
                      Text(
                        phone,
                        style: const TextStyle(color: AppColors.text, fontSize: 12),
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  status,
                  style: TextStyle(color: statusColor, fontSize: 12),
                ),
              ),
            ],
          ),
          const Divider(color: Colors.white24, height: 24),
          InfoRow(
            label: "Type",
            value: tx.given ? "Given (you lent)" : "Taken (you borrowed)",
          ),
          InfoRow(
            label: "Tag",
            value: contactType == "lender" ? "Lender" : "Borrower",
          ),
          InfoRow(label: "Interest rate", value: tx.rateLabel),
          InfoRow(label: "Start date", value: fmtDate(tx.startDate)),
          InfoRow(
            label: "Due date",
            value: tx.dueDate == null ? "Not set" : fmtDate(tx.dueDate!),
          ),
          if (tx.settledAt != null)
            InfoRow(label: "Settled on", value: fmtDate(tx.settledAt!)),
          if (tx.notes.isNotEmpty) InfoRow(label: "Notes", value: tx.notes),
        ],
      ),
    );
  }
}

class TxMoneyCard extends StatelessWidget {
  final TxModel tx;
  final double interest;
  final double total;
  final double paid;
  final double outstanding;
  final Color color;

  const TxMoneyCard({
    super.key,
    required this.tx,
    required this.interest,
    required this.total,
    required this.paid,
    required this.outstanding,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return AppCard(
      margin: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          InfoRow(label: "Principal", value: money(tx.amount, decimals: true)),
          InfoRow(
            label: "Interest",
            value: money(interest, decimals: true),
            color: AppColors.orange,
          ),
          InfoRow(
            label: "Total ${tx.given ? "receivable" : "payable"}",
            value: money(total, decimals: true),
            bold: true,
          ),
          InfoRow(
            label: "Paid",
            value: money(paid, decimals: true),
            color: AppColors.green,
          ),
          const Divider(color: Colors.white24, height: 20),
          InfoRow(
            label: "Outstanding",
            value: money(outstanding, decimals: true),
            color: color,
            bold: true,
          ),
        ],
      ),
    );
  }
}

class PaymentHistoryTile extends StatelessWidget {
  final Payment payment;

  const PaymentHistoryTile({super.key, required this.payment});

  @override
  Widget build(BuildContext context) {
    AppProvider app = context.read<AppProvider>();
    String extra = "${fmtDate(payment.date)} • ${payment.mode}";
    if (payment.note.isNotEmpty) {
      extra += " • ${payment.note}";
    }

    return AppCard(
      child: Row(
        children: [
          ProofOrIcon(path: payment.proofPath),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  money(payment.amount, decimals: true),
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  extra,
                  style: const TextStyle(color: AppColors.text, fontSize: 12),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.white54),
            onPressed: () async {
              bool ok = await confirmDialog(
                context,
                "Delete payment",
                "Remove this payment?",
              );
              if (ok) {
                await app.deletePayment(payment);
              }
            },
          ),
        ],
      ),
    );
  }
}

class PaymentSheet extends StatefulWidget {
  final TxModel tx;
  final double outstanding;

  const PaymentSheet({super.key, required this.tx, required this.outstanding});

  @override
  State<PaymentSheet> createState() => _PaymentSheetState();
}

class _PaymentSheetState extends State<PaymentSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountController;
  final TextEditingController _noteController = TextEditingController();
  late DateTime _date;
  String _mode = "UPI";
  bool _saving = false;
  String? _proof;
  bool _saved = false;

  final List<String> _modes = ["UPI", "Bank Transfer", "Cash", "Other"];

  @override
  void initState() {
    super.initState();
    _amountController = TextEditingController(text: widget.outstanding.toStringAsFixed(2));
    DateTime now = dateOnly(DateTime.now());
    if (now.isBefore(widget.tx.startDate)) {
      _date = widget.tx.startDate;
    } else {
      _date = now;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _noteController.dispose();
    if (!_saved) {
      ProofService.delete(_proof);
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: widget.tx.startDate,
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() {
        _date = picked;
      });
    }
  }

  Future<void> _pickProof(ImageSource source) async {
    try {
      final path = await ProofService.pick(source);
      if (path == null || !mounted) return;

      await ProofService.delete(_proof);
      setState(() {
        _proof = path;
      });
    } catch (e) {
      if (mounted) {
        showMsg(context, "Could not attach image");
      }
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _saving = true;
      });

      double amount = double.parse(_amountController.text.trim());
      bool settle = amount >= widget.outstanding - 0.5;
      AppProvider app = context.read<AppProvider>();
      _saved = true;

      await app.addPayment(
        Payment(
          txId: widget.tx.id!,
          amount: amount,
          date: _date,
          mode: _mode,
          note: _noteController.text.trim(),
          proofPath: _proof,
        ),
        settle: settle,
      );

      if (!mounted) return;

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        20,
        20,
        20,
        MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Record payment",
                style: TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 4),
              Text(
                "Outstanding: ${money(widget.outstanding, decimals: true)}",
                style: const TextStyle(color: AppColors.text, fontSize: 13),
              ),
              const SizedBox(height: 16),
              CustomTextFormField(
                inputAcction: TextInputAction.next,
                labelText: "Amount",
                fontWeight: 300,
                enabledBorder: const Color(0xFFD6DADD),
                textColor: const Color(0xFFD6DADD),
                errorBorder: Colors.red,
                focusedBorder: const Color(0xFFD6DADD),
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: Icons.currency_rupee,
                fontSize: 12,
                controller: _amountController,
                borderRadius: 20,
                iconColor: Colors.white,
                validator: (value) {
                  double? number = double.tryParse((value ?? "").trim());
                  if (number == null || number <= 0) {
                    return "Enter a valid amount";
                  }
                  if (number > widget.outstanding + 0.5) {
                    return "Amount exceeds outstanding";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              DateField(label: "Payment date", value: _date, onTap: _pickDate),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                children: _modes.map((mode) {
                  return choiceChip(mode, _mode == mode, () {
                    setState(() {
                      _mode = mode;
                    });
                  });
                }).toList(),
              ),
              const SizedBox(height: 14),
              CustomTextFormField(
                inputAcction: TextInputAction.done,
                labelText: "Note (optional)",
                fontWeight: 300,
                enabledBorder: const Color(0xFFD6DADD),
                textColor: const Color(0xFFD6DADD),
                errorBorder: Colors.red,
                focusedBorder: const Color(0xFFD6DADD),
                keyboardType: TextInputType.text,
                prefixIcon: Icons.notes,
                fontSize: 12,
                controller: _noteController,
                borderRadius: 20,
                iconColor: Colors.white,
                validator: (value) {
                  return null;
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _pickProof(ImageSource.gallery),
                      icon: const Icon(
                        Icons.photo_library_outlined,
                        color: AppColors.accent,
                      ),
                      label: const Text(
                        "Proof from gallery",
                        style: TextStyle(color: AppColors.accent),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  IconButton.outlined(
                    onPressed: () => _pickProof(ImageSource.camera),
                    icon: const Icon(
                      Icons.photo_camera_outlined,
                      color: AppColors.accent,
                    ),
                  ),
                ],
              ),
              if (_proof != null)
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.file(
                          File(_proof!),
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Text(
                          "Proof attached",
                          style: TextStyle(color: AppColors.text),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.white54),
                        onPressed: () async {
                          await ProofService.delete(_proof);
                          if (mounted) {
                            setState(() {
                              _proof = null;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 48,
                child: FilledButton(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  onPressed: _saving
                      ? null
                      : () {
                    _save();
                  },
                  child: const Text(
                    "Save payment",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ProofOrIcon extends StatelessWidget {
  final String? path;

  const ProofOrIcon({super.key, required this.path});

  @override
  Widget build(BuildContext context) {
    final filePath = path;
    if (filePath == null || !File(filePath).existsSync()) {
      return const Icon(Icons.check_circle_outline, color: AppColors.green);
    }
    return GestureDetector(
      onTap: () {
        showDialog<void>(
          context: context,
          builder: (context) => Dialog(
            backgroundColor: Colors.black,
            insetPadding: const EdgeInsets.all(12),
            child: InteractiveViewer(child: Image.file(File(filePath))),
          ),
        );
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(8),
        child: Image.file(File(filePath), width: 40, height: 40, fit: BoxFit.cover),
      ),
    );
  }
}