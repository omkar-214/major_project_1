import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vaultly/models/models.dart';
import 'package:vaultly/pages/contacts_tab.dart';
import 'package:vaultly/providers/app_provider.dart';
import 'package:vaultly/theme/app_colors.dart';
import 'package:vaultly/utils/format.dart';
import 'package:vaultly/widgets/common.dart';
import 'package:vaultly/widgets/customWidget.dart';

class AddTransactionPage extends StatefulWidget {
  final TxModel? edit;

  const AddTransactionPage({super.key, this.edit});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _amountController = TextEditingController();
  final TextEditingController _rateController = TextEditingController();
  final TextEditingController _notesController = TextEditingController();

  int? _contactId;
  bool _given = true;
  String _rateType = "monthly";
  DateTime _start = dateOnly(DateTime.now());
  DateTime? _due;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    TxModel? existing = widget.edit;
    if (existing != null) {
      _contactId = existing.contactId;
      _given = existing.given;
      _rateType = existing.rateType;
      _start = existing.startDate;
      _due = existing.dueDate;
      _amountController.text = existing.amount.toStringAsFixed(existing.amount % 1 == 0 ? 0 : 2);
      _rateController.text = existing.rate.toString();
      _notesController.text = existing.notes;
    }
  }

  @override
  void dispose() {
    _amountController.dispose();
    _rateController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: start ? _start : (_due ?? _start),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );

    if (picked == null) return;

    setState(() {
      if (start) {
        _start = picked;
      } else {
        _due = picked;
      }
    });
  }

  Future<void> _newContact() async {
    int? id = await showContactSheet(context);
    if (id != null && mounted) {
      setState(() {
        _contactId = id;
      });
    }
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      if (_contactId == null) {
        showMsg(context, "Please select a contact");
        return;
      }
      if (_due != null && _due!.isBefore(_start)) {
        showMsg(context, "Due date cannot be before start date");
        return;
      }

      setState(() {
        _saving = true;
      });

      AppProvider app = context.read<AppProvider>();
      TxModel tx = TxModel(
        id: widget.edit?.id,
        uid: "",
        contactId: _contactId!,
        amount: double.parse(_amountController.text.trim()),
        given: _given,
        rate: double.parse(_rateController.text.trim()),
        rateType: _rateType,
        startDate: _start,
        dueDate: _due,
        notes: _notesController.text.trim(),
      );

      if (widget.edit == null) {
        await app.addTransaction(tx);
      } else {
        await app.updateTransaction(tx);
      }

      if (!mounted) return;

      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    AppProvider app = context.watch<AppProvider>();
    bool editing = widget.edit != null;

    Widget saveChild;
    if (_saving) {
      saveChild = const SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
      );
    } else {
      saveChild = Text(
        editing ? "Update" : "Save",
        style: const TextStyle(color: Colors.white, fontSize: 16),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: pageBar(editing ? "Edit Transaction" : "New Transaction"),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int>(
                      key: ValueKey(_contactId),
                      initialValue: _contactId,
                      dropdownColor: AppColors.card,
                      style: const TextStyle(color: Colors.white),
                      iconEnabledColor: Colors.white54,
                      decoration: inputDeco("Contact", icon: Icons.person_outline),
                      items: app.contacts.map((contact) {
                        return DropdownMenuItem<int>(
                          value: contact.id,
                          child: Text(contact.name),
                        );
                      }).toList(),
                      onChanged: (value) {
                        setState(() {
                          _contactId = value;
                        });
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    style: IconButton.styleFrom(backgroundColor: AppColors.primary),
                    onPressed: () {
                      _newContact();
                    },
                    icon: const Icon(Icons.person_add, color: Colors.white),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  choiceChip("Given (I lent)", _given, () {
                    setState(() {
                      _given = true;
                    });
                  }),
                  const SizedBox(width: 10),
                  choiceChip("Taken (I borrowed)", !_given, () {
                    setState(() {
                      _given = false;
                    });
                  }),
                ],
              ),
              const SizedBox(height: 16),
              CustomTextFormField(
                controller: _amountController,
                textColor: Colors.white,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                labelText: "Amount",
                prefixIcon: Icons.currency_rupee,
                validator: (value) {
                  double? number = double.tryParse((value ?? "").trim());
                  if (number == null || number <= 0) {
                    return "Enter a valid amount";
                  }
                  return null;
                },
                fontWeight: 100,
                enabledBorder: Colors.white,
                errorBorder: AppColors.red,
                focusedBorder: Colors.white,
                fontSize: 12,
                borderRadius: 20,
                iconColor: Colors.white,
                inputAcction: TextInputAction.next,
              ),
              const SizedBox(height: 16),
              CustomTextFormField(
                controller: _rateController,
                textColor: Colors.white,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                labelText: "Interest rate (%)",
                prefixIcon: Icons.percent,
                validator: (value) {
                  double? number = double.tryParse((value ?? "").trim());
                  if (number == null || number < 0) {
                    return "Enter a valid rate";
                  }
                  return null;
                },
                fontWeight: 100,
                enabledBorder: Colors.white,
                errorBorder: AppColors.red,
                focusedBorder: Colors.white,
                fontSize: 12,
                borderRadius: 20,
                iconColor: Colors.white,
                inputAcction: TextInputAction.done,
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  choiceChip("Per month", _rateType == "monthly", () {
                    setState(() {
                      _rateType = "monthly";
                    });
                  }),
                  const SizedBox(width: 10),
                  choiceChip("Per year", _rateType == "yearly", () {
                    setState(() {
                      _rateType = "yearly";
                    });
                  }),
                ],
              ),
              const SizedBox(height: 16),
              DateField(
                label: "Start date",
                value: _start,
                onTap: () {
                  _pickDate(start: true);
                },
              ),
              const SizedBox(height: 16),
              DateField(
                label: "Due date (optional)",
                value: _due,
                onTap: () {
                  _pickDate(start: false);
                },
                onClear: () {
                  setState(() {
                    _due = null;
                  });
                },
              ),
              const SizedBox(height: 16),
              CustomTextFormField(
                controller: _notesController,
                textColor: Colors.white,
                keyboardType: TextInputType.text,
                labelText: "Notes",
                prefixIcon: Icons.notes,
                validator: (value) {
                  return null;
                },
                fontWeight: 100,
                enabledBorder: Colors.white,
                errorBorder: AppColors.red,
                focusedBorder: Colors.white,
                fontSize: 12,
                borderRadius: 20,
                iconColor: Colors.white,
                inputAcction: TextInputAction.done,
              ),
              const SizedBox(height: 24),
              SizedBox(
                height: 50,
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
                  child: saveChild,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}