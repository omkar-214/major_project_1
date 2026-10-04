import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vaultly/providers/app_provider.dart';
import 'package:vaultly/theme/app_colors.dart';
import 'package:vaultly/widgets/common.dart';
import 'package:vaultly/widgets/customWidget.dart';
import 'package:vaultly/widgets/tx_card.dart';

class TransactionsTab extends StatefulWidget {
  const TransactionsTab({super.key});

  @override
  State<TransactionsTab> createState() => _TransactionsTabState();
}

class _TransactionsTabState extends State<TransactionsTab> {
  final TextEditingController _searchController = TextEditingController();

  String _query = "";
  String _filter = "all";

  final Map<String, String> _filters = {
    "all": "All",
    "given": "Given",
    "taken": "Taken",
    "open": "Open",
    "settled": "Settled",
  };

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _query = _searchController.text;
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    String query = _query.trim().toLowerCase();

    final list = app.txs.where((tx) {
      if (_filter == "given" && !tx.given) return false;
      if (_filter == "taken" && tx.given) return false;
      if (_filter == "open" && tx.settledAt != null) return false;
      if (_filter == "settled" && tx.settledAt == null) return false;
      if (query.isEmpty) return true;

      final contact = app.contactById(tx.contactId);
      bool nameMatch = contact?.name.toLowerCase().contains(query) ?? false;
      bool notesMatch = tx.notes.toLowerCase().contains(query);
      return nameMatch || notesMatch;
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: CustomTextFormField(
            inputAcction: TextInputAction.done,
            labelText: "Search by name or notes",
            fontWeight: 300,
            enabledBorder: const Color(0xFFD6DADD),
            textColor: const Color(0xFFD6DADD),
            errorBorder: Colors.red,
            focusedBorder: const Color(0xFFD6DADD),
            keyboardType: TextInputType.text,
            prefixIcon: Icons.search,
            fontSize: 12,
            controller: _searchController,
            borderRadius: 20,
            iconColor: Colors.white,
            validator: (value) {
              return null;
            },
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: _filters.entries.map((entry) {
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: choiceChip(entry.value, _filter == entry.key, () {
                  setState(() {
                    _filter = entry.key;
                  });
                }),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 8),
        Expanded(
          child: list.isEmpty
              ? Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.receipt_long, size: 64, color: Colors.white24),
                const SizedBox(height: 12),
                Text(
                  app.txs.isEmpty
                      ? "No transactions yet"
                      : "No matching transactions",
                  style: const TextStyle(color: AppColors.text),
                ),
              ],
            ),
          )
              : ListView.builder(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
            itemCount: list.length,
            itemBuilder: (context, index) {
              return TxCard(tx: list[index]);
            },
          ),
        ),
      ],
    );
  }
}