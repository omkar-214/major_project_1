import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vaultly/models/models.dart';
import 'package:vaultly/pages/transaction_detail_page.dart';
import 'package:vaultly/providers/app_provider.dart';
import 'package:vaultly/theme/app_colors.dart';
import 'package:vaultly/utils/format.dart';
import 'package:vaultly/widgets/common.dart';

class TxCard extends StatelessWidget {
  final TxModel tx;

  const TxCard({super.key, required this.tx});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final contact = app.contactById(tx.contactId);
    Color color = tx.given ? AppColors.green : AppColors.red;
    bool overdue = app.isOverdue(tx);
    double outstanding = app.outstandingOf(tx);

    String subtitle = tx.given ? "Given" : "Taken";
    subtitle += " • ${fmtDate(tx.startDate)} • ${app.statusOf(tx)}";

    String dueText;
    if (tx.settledAt != null) {
      dueText = "Settled";
    } else {
      dueText = "Due ${money(outstanding)}";
    }

    return AppCard(
      borderColor: overdue ? AppColors.red.withValues(alpha: 0.6) : null,
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => TransactionDetailPage(txId: tx.id!),
          ),
        );
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 18,
            backgroundColor: color.withValues(alpha: 0.15),
            child: Icon(
              tx.given ? Icons.arrow_upward : Icons.arrow_downward,
              color: color,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact?.name ?? "Unknown",
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                money(tx.amount),
                style: TextStyle(color: color, fontSize: 14),
              ),
              const SizedBox(height: 2),
              Text(
                dueText,
                style: const TextStyle(color: AppColors.text, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}