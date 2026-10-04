import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vaultly/models/models.dart';
import 'package:vaultly/pages/add_transaction_page.dart';
import 'package:vaultly/pages/analytics_tab.dart';
import 'package:vaultly/pages/backup_page.dart';
import 'package:vaultly/pages/contacts_tab.dart';
import 'package:vaultly/pages/login_page.dart';
import 'package:vaultly/pages/reminder_settings_page.dart';
import 'package:vaultly/pages/transaction_detail_page.dart';
import 'package:vaultly/pages/transactions_tab.dart';
import 'package:vaultly/providers/app_provider.dart';
import 'package:vaultly/services/notification_service.dart';
import 'package:vaultly/theme/app_colors.dart';
import 'package:vaultly/utils/format.dart';
import 'package:vaultly/widgets/common.dart';
import 'package:vaultly/widgets/tx_card.dart';

export 'package:vaultly/theme/app_colors.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;

  final List<String> _titles = ["Vaultly", "Transactions", "Contacts", "Analytics"];

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      context.read<AppProvider>().load();
      NotificationService.instance.requestPermission();
    });
  }

  Future<void> _logout() async {
    context.read<AppProvider>().clear();
    await FirebaseAuth.instance.signOut();

    if (!mounted) return;

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginPage()),
          (route) => false,
    );
  }

  void _onAdd() {
    if (_currentIndex == 2) {
      showContactSheet(context);
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => const AddTransactionPage()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget? fab;
    if (_currentIndex != 3) {
      fab = FloatingActionButton(
        backgroundColor: AppColors.primary,
        onPressed: _onAdd,
        child: Icon(
          _currentIndex == 2 ? Icons.person_add : Icons.add,
          color: Colors.white,
        ),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: AppColors.primary,
        title: Text(
          _titles[_currentIndex],
          style: const TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w400,
          ),
        ),
        actions: [
          IconButton(
            tooltip: "Reminders",
            icon: const Icon(Icons.notifications_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ReminderSettingsPage()),
              );
            },
          ),
          IconButton(
            tooltip: "Export / Backup",
            icon: const Icon(Icons.cloud_upload_outlined, color: Colors.white),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BackupPage()),
              );
            },
          ),
          IconButton(
            tooltip: "Logout",
            icon: const Icon(Icons.logout, color: Colors.white),
            onPressed: () {
              _logout();
            },
          ),
        ],
      ),
      body: SafeArea(
        child: IndexedStack(
          index: _currentIndex,
          children: const [
            DashboardTab(),
            TransactionsTab(),
            ContactsTab(),
            AnalyticsTab(),
          ],
        ),
      ),
      floatingActionButton: fab,
      bottomNavigationBar: Container(
        decoration: const BoxDecoration(
          border: Border(top: BorderSide(color: Colors.white24, width: 1)),
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) {
            setState(() {
              _currentIndex = index;
            });
          },
          type: BottomNavigationBarType.fixed,
          backgroundColor: AppColors.bg,
          selectedItemColor: AppColors.accent,
          unselectedItemColor: Colors.white54,
          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: "Home",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.receipt_long_outlined),
              activeIcon: Icon(Icons.receipt_long),
              label: "Transactions",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.people_outline),
              activeIcon: Icon(Icons.people),
              label: "Contacts",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart_outlined),
              activeIcon: Icon(Icons.bar_chart),
              label: "Analytics",
            ),
          ],
        ),
      ),
    );
  }
}

class DashboardTab extends StatelessWidget {
  const DashboardTab({super.key});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    User? user = FirebaseAuth.instance.currentUser;

    String name = "there";
    if (user?.displayName != null && user!.displayName!.trim().isNotEmpty) {
      name = user.displayName!;
    }

    final dues = app.dues.take(4).toList();
    final recent = app.txs.take(5).toList();

    return RefreshIndicator(
      onRefresh: app.load,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 90),
        children: [
          Text(
            "Hello, $name 👋",
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            "Your overview for today",
            style: TextStyle(color: AppColors.text, fontSize: 13),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  title: "Interest Earned",
                  amount: app.interestSum(true),
                  icon: Icons.trending_up,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  title: "Interest Paid",
                  amount: app.interestSum(false),
                  icon: Icons.trending_down,
                  color: AppColors.orange,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: SummaryCard(
                  title: "Receivables",
                  amount: app.outstandingSum(true),
                  icon: Icons.call_received,
                  color: AppColors.green,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: SummaryCard(
                  title: "Payables",
                  amount: app.outstandingSum(false),
                  icon: Icons.call_made,
                  color: AppColors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 28),
          const SectionHeader(title: "Upcoming & Overdue"),
          const SizedBox(height: 10),
          if (dues.isEmpty)
            const EmptyNote(text: "No upcoming or overdue payments")
          else
            ...dues.map((tx) => DueTile(tx: tx)),
          const SizedBox(height: 24),
          const SectionHeader(title: "Recent Transactions"),
          const SizedBox(height: 10),
          if (recent.isEmpty)
            const EmptyNote(text: "Tap + to add your first transaction")
          else
            ...recent.map((tx) => TxCard(tx: tx)),
        ],
      ),
    );
  }
}

class EmptyNote extends StatelessWidget {
  final String text;

  const EmptyNote({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Text(text, style: const TextStyle(color: Colors.white54)),
    );
  }
}

class SummaryCard extends StatelessWidget {
  final String title;
  final double amount;
  final IconData icon;
  final Color color;

  const SummaryCard({
    super.key,
    required this.title,
    required this.amount,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        border: Border.all(color: Colors.white24, width: 1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 12),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              money(amount),
              style: TextStyle(
                color: color,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: const TextStyle(color: AppColors.text, fontSize: 12),
          ),
        ],
      ),
    );
  }
}

class DueTile extends StatelessWidget {
  final TxModel tx;

  const DueTile({super.key, required this.tx});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    bool overdue = app.isOverdue(tx);
    Color color = overdue ? AppColors.red : AppColors.orange;
    final contact = app.contactById(tx.contactId);

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
          Icon(
            overdue ? Icons.warning_amber_rounded : Icons.schedule,
            color: color,
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
                  dueLabel(tx.dueDate!),
                  style: TextStyle(color: color, fontSize: 12),
                ),
              ],
            ),
          ),
          Text(
            money(app.outstandingOf(tx)),
            style: const TextStyle(color: Colors.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}