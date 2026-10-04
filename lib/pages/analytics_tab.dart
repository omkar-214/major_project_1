import 'dart:math';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:vaultly/providers/app_provider.dart';
import 'package:vaultly/theme/app_colors.dart';
import 'package:vaultly/utils/format.dart';
import 'package:vaultly/widgets/common.dart';

class ChartBar {
  final double value;
  final Color color;

  const ChartBar(this.value, this.color);
}

class ChartGroup {
  final String label;
  final List<ChartBar> bars;

  const ChartGroup(this.label, this.bars);
}

class SimpleBarChart extends StatelessWidget {
  final List<ChartGroup> groups;

  const SimpleBarChart({super.key, required this.groups});

  @override
  Widget build(BuildContext context) {
    double chartHeight = 110.0;
    double maxValue = 0;

    for (ChartGroup group in groups) {
      for (ChartBar bar in group.bars) {
        maxValue = max(maxValue, bar.value);
      }
    }
    if (maxValue <= 0) maxValue = 1;

    NumberFormat compact = NumberFormat.compact(locale: "en_IN");

    return SizedBox(
      height: chartHeight + 56,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: groups.map((group) {
          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: group.bars.map((bar) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 3),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          compact.format(bar.value),
                          style: const TextStyle(color: AppColors.text, fontSize: 9),
                        ),
                        const SizedBox(height: 2),
                        Container(
                          width: 14,
                          height: max(2.0, chartHeight * bar.value / maxValue),
                          decoration: BoxDecoration(
                            color: bar.color,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 6),
              Text(
                group.label,
                style: const TextStyle(color: AppColors.text, fontSize: 11),
              ),
            ],
          );
        }).toList(),
      ),
    );
  }
}

class ChartLegend extends StatelessWidget {
  final Color color;
  final String label;

  const ChartLegend(this.color, this.label, {super.key});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(color: AppColors.text, fontSize: 12),
        ),
        const SizedBox(width: 14),
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  final String title;
  final double value;
  final Color color;
  final IconData icon;

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.card,
          border: Border.all(color: Colors.white24),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                money(value),
                style: TextStyle(
                  color: color,
                  fontSize: 18,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: const TextStyle(color: AppColors.text, fontSize: 12),
            ),
          ],
        ),
      ),
    );
  }
}

class AnalyticsTab extends StatefulWidget {
  const AnalyticsTab({super.key});

  @override
  State<AnalyticsTab> createState() => _AnalyticsTabState();
}

class _AnalyticsTabState extends State<AnalyticsTab> {
  int? _year;
  int? _month;
  int? _contactId;

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();

    Set<int> years = {DateTime.now().year};
    for (final tx in app.txs) {
      years.add(tx.startDate.year);
    }
    List<int> yearList = years.toList();
    yearList.sort((a, b) => b.compareTo(a));

    DateTime? from;
    DateTime? to;
    if (_year != null) {
      if (_month == null) {
        from = DateTime(_year!);
        to = DateTime(_year! + 1);
      } else {
        from = DateTime(_year!, _month!);
        to = DateTime(_year!, _month! + 1);
      }
    }

    double earned = app.interestSum(true, from: from, to: to, contactId: _contactId);
    double paid = app.interestSum(false, from: from, to: to, contactId: _contactId);
    double receivable = app.outstandingSum(true, contactId: _contactId);
    double payable = app.outstandingSum(false, contactId: _contactId);
    double given = app.principalSum(true, from: from, to: to, contactId: _contactId);
    double taken = app.principalSum(false, from: from, to: to, contactId: _contactId);

    DateTime now = DateTime.now();
    List<ChartGroup> flow = [];
    for (int i = 5; i >= 0; i--) {
      DateTime monthStart = DateTime(now.year, now.month - i);
      DateTime monthEnd = DateTime(monthStart.year, monthStart.month + 1);
      flow.add(ChartGroup(DateFormat("MMM").format(monthStart), [
        ChartBar(
          app.interestSum(true, from: monthStart, to: monthEnd, contactId: _contactId),
          AppColors.green,
        ),
        ChartBar(
          app.interestSum(false, from: monthStart, to: monthEnd, contactId: _contactId),
          AppColors.orange,
        ),
      ]));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
      children: [
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int?>(
                key: ValueKey("y$_year"),
                initialValue: _year,
                dropdownColor: AppColors.card,
                style: const TextStyle(color: Colors.white),
                iconEnabledColor: Colors.white54,
                decoration: inputDeco("Year"),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text("All years"),
                  ),
                  ...yearList.map((year) {
                    return DropdownMenuItem<int?>(
                      value: year,
                      child: Text("$year"),
                    );
                  }),
                ],
                onChanged: (value) {
                  setState(() {
                    _year = value;
                    if (value == null) {
                      _month = null;
                    }
                  });
                },
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DropdownButtonFormField<int?>(
                key: ValueKey("m$_month$_year"),
                initialValue: _month,
                dropdownColor: AppColors.card,
                style: const TextStyle(color: Colors.white),
                iconEnabledColor: Colors.white54,
                decoration: inputDeco("Month"),
                items: [
                  const DropdownMenuItem<int?>(
                    value: null,
                    child: Text("All months"),
                  ),
                  ...List.generate(12, (index) {
                    return DropdownMenuItem<int?>(
                      value: index + 1,
                      child: Text(DateFormat("MMMM").format(DateTime(2000, index + 1))),
                    );
                  }),
                ],
                onChanged: _year == null
                    ? null
                    : (value) {
                  setState(() {
                    _month = value;
                  });
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        DropdownButtonFormField<int?>(
          key: ValueKey("c$_contactId"),
          initialValue: _contactId,
          dropdownColor: AppColors.card,
          style: const TextStyle(color: Colors.white),
          iconEnabledColor: Colors.white54,
          decoration: inputDeco("Contact", icon: Icons.person_outline),
          items: [
            const DropdownMenuItem<int?>(
              value: null,
              child: Text("All contacts"),
            ),
            ...app.contacts.map((contact) {
              return DropdownMenuItem<int?>(
                value: contact.id,
                child: Text(contact.name),
              );
            }),
          ],
          onChanged: (value) {
            setState(() {
              _contactId = value;
            });
          },
        ),
        const SizedBox(height: 20),
        Row(
          children: [
            StatCard(
              title: "Interest Earned",
              value: earned,
              color: AppColors.green,
              icon: Icons.trending_up,
            ),
            const SizedBox(width: 12),
            StatCard(
              title: "Interest Paid",
              value: paid,
              color: AppColors.orange,
              icon: Icons.trending_down,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            StatCard(
              title: "Receivables",
              value: receivable,
              color: AppColors.green,
              icon: Icons.call_received,
            ),
            const SizedBox(width: 12),
            StatCard(
              title: "Payables",
              value: payable,
              color: AppColors.red,
              icon: Icons.call_made,
            ),
          ],
        ),
        const SizedBox(height: 28),
        const SectionHeader(title: "Given vs Taken"),
        const SizedBox(height: 14),
        AppCard(
          margin: EdgeInsets.zero,
          child: SimpleBarChart(
            groups: [
              ChartGroup("Given", [ChartBar(given, AppColors.green)]),
              ChartGroup("Taken", [ChartBar(taken, AppColors.red)]),
            ],
          ),
        ),
        const SizedBox(height: 28),
        const SectionHeader(title: "Monthly interest flow"),
        const SizedBox(height: 10),
        const Row(
          children: [
            ChartLegend(AppColors.green, "Earned"),
            ChartLegend(AppColors.orange, "Paid"),
          ],
        ),
        const SizedBox(height: 10),
        AppCard(
          margin: EdgeInsets.zero,
          child: SimpleBarChart(groups: flow),
        ),
      ],
    );
  }
}