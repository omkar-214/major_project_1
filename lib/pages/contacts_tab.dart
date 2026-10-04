import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vaultly/models/models.dart';
import 'package:vaultly/providers/app_provider.dart';
import 'package:vaultly/theme/app_colors.dart';
import 'package:vaultly/utils/format.dart';
import 'package:vaultly/widgets/common.dart';
import 'package:vaultly/widgets/customWidget.dart';
import 'package:vaultly/widgets/tx_card.dart';

Future<int?> showContactSheet(BuildContext context, {Contact? contact}) {
  return showModalBottomSheet<int>(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (context) => ContactSheet(contact: contact),
  );
}

class ContactSheet extends StatefulWidget {
  final Contact? contact;

  const ContactSheet({super.key, this.contact});

  @override
  State<ContactSheet> createState() => _ContactSheetState();
}

class _ContactSheetState extends State<ContactSheet> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _emailController;
  late String _type;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    Contact? contact = widget.contact;
    _nameController = TextEditingController(text: contact?.name ?? "");
    _phoneController = TextEditingController(text: contact?.phone ?? "");
    _emailController = TextEditingController(text: contact?.email ?? "");
    _type = contact?.type ?? "borrower";
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _saving = true;
      });

      AppProvider app = context.read<AppProvider>();
      Contact? existing = widget.contact;
      int id;

      if (existing == null) {
        id = await app.addContact(
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          type: _type,
        );
      } else {
        await app.updateContact(Contact(
          id: existing.id,
          uid: existing.uid,
          name: _nameController.text.trim(),
          phone: _phoneController.text.trim(),
          email: _emailController.text.trim(),
          type: _type,
        ));
        id = existing.id!;
      }

      if (!mounted) return;

      Navigator.pop(context, id);
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
              Text(
                widget.contact == null ? "New contact" : "Edit contact",
                style: const TextStyle(color: Colors.white, fontSize: 18),
              ),
              const SizedBox(height: 16),
              CustomTextFormField(
                inputAcction: TextInputAction.next,
                labelText: "Name",
                fontWeight: 300,
                enabledBorder: const Color(0xFFD6DADD),
                textColor: const Color(0xFFD6DADD),
                errorBorder: Colors.red,
                focusedBorder: const Color(0xFFD6DADD),
                keyboardType: TextInputType.text,
                prefixIcon: Icons.person_outline,
                fontSize: 12,
                controller: _nameController,
                borderRadius: 20,
                iconColor: Colors.white,
                validator: (value) {
                  if ((value ?? "").trim().isEmpty) {
                    return "Enter a name";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              CustomTextFormField(
                inputAcction: TextInputAction.next,
                labelText: "Mobile number",
                fontWeight: 300,
                enabledBorder: const Color(0xFFD6DADD),
                textColor: const Color(0xFFD6DADD),
                errorBorder: Colors.red,
                focusedBorder: const Color(0xFFD6DADD),
                keyboardType: TextInputType.phone,
                prefixIcon: Icons.phone,
                fontSize: 12,
                controller: _phoneController,
                borderRadius: 20,
                iconColor: Colors.white,
                validator: (value) {
                  String text = (value ?? "").trim();
                  if (text.length < 7) {
                    return "Enter a valid mobile number";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              CustomTextFormField(
                inputAcction: TextInputAction.done,
                labelText: "Email (optional)",
                fontWeight: 300,
                enabledBorder: const Color(0xFFD6DADD),
                textColor: const Color(0xFFD6DADD),
                errorBorder: Colors.red,
                focusedBorder: const Color(0xFFD6DADD),
                keyboardType: TextInputType.emailAddress,
                prefixIcon: Icons.email_outlined,
                fontSize: 12,
                controller: _emailController,
                borderRadius: 20,
                iconColor: Colors.white,
                validator: (value) {
                  String text = (value ?? "").trim();
                  if (text.isNotEmpty && !text.contains("@")) {
                    return "Enter a valid email";
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),
              Row(
                children: [
                  choiceChip("Borrower", _type == "borrower", () {
                    setState(() {
                      _type = "borrower";
                    });
                  }),
                  const SizedBox(width: 10),
                  choiceChip("Lender", _type == "lender", () {
                    setState(() {
                      _type = "lender";
                    });
                  }),
                ],
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
                  child: const Text("Save", style: TextStyle(color: Colors.white)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ContactsTab extends StatefulWidget {
  const ContactsTab({super.key});

  @override
  State<ContactsTab> createState() => _ContactsTabState();
}

class _ContactsTabState extends State<ContactsTab> {
  final TextEditingController _searchController = TextEditingController();

  String _query = "";
  String _type = "all";

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

    final list = app.contacts.where((contact) {
      if (_type != "all" && contact.type != _type) return false;
      if (query.isEmpty) return true;
      return contact.name.toLowerCase().contains(query) ||
          contact.phone.contains(query);
    }).toList();

    Widget listBody;
    if (list.isEmpty) {
      listBody = Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.people, size: 64, color: Colors.white24),
            const SizedBox(height: 12),
            Text(
              app.contacts.isEmpty ? "No contacts yet" : "No matching contacts",
              style: const TextStyle(color: AppColors.text),
            ),
          ],
        ),
      );
    } else {
      listBody = ListView.builder(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 90),
        itemCount: list.length,
        itemBuilder: (context, index) {
          return ContactTile(contact: list[index]);
        },
      );
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
          child: CustomTextFormField(
            inputAcction: TextInputAction.done,
            labelText: "Search by name or number",
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
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(
            children: [
              choiceChip("All", _type == "all", () {
                setState(() {
                  _type = "all";
                });
              }),
              const SizedBox(width: 8),
              choiceChip("Borrowers", _type == "borrower", () {
                setState(() {
                  _type = "borrower";
                });
              }),
              const SizedBox(width: 8),
              choiceChip("Lenders", _type == "lender", () {
                setState(() {
                  _type = "lender";
                });
              }),
            ],
          ),
        ),
        const SizedBox(height: 8),
        Expanded(child: listBody),
      ],
    );
  }
}

class ContactTile extends StatelessWidget {
  final Contact contact;

  const ContactTile({super.key, required this.contact});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    double net = app.outstandingSum(true, contactId: contact.id) -
        app.outstandingSum(false, contactId: contact.id);

    Color netColor = AppColors.text;
    String netLabel = "Settled";
    if (net > 0) {
      netColor = AppColors.green;
      netLabel = "You get";
    } else if (net < 0) {
      netColor = AppColors.red;
      netLabel = "You owe";
    }

    String typeLabel = contact.type == "lender" ? "Lender" : "Borrower";
    String letter = contact.name.isEmpty ? "?" : contact.name[0].toUpperCase();

    return AppCard(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ContactDetailPage(contactId: contact.id!),
          ),
        );
      },
      child: Row(
        children: [
          CircleAvatar(
            radius: 20,
            backgroundColor: AppColors.accent.withValues(alpha: 0.2),
            child: Text(
              letter,
              style: const TextStyle(color: AppColors.accent),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  contact.name,
                  style: const TextStyle(color: Colors.white, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  "$typeLabel • ${contact.phone}",
                  style: const TextStyle(color: AppColors.text, fontSize: 12),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                money(net.abs()),
                style: TextStyle(color: netColor, fontSize: 14),
              ),
              Text(
                netLabel,
                style: const TextStyle(color: AppColors.text, fontSize: 11),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class ContactDetailPage extends StatelessWidget {
  final int contactId;

  const ContactDetailPage({super.key, required this.contactId});

  @override
  Widget build(BuildContext context) {
    final app = context.watch<AppProvider>();
    final contact = app.contactById(contactId);

    if (contact == null) {
      return Scaffold(
        backgroundColor: AppColors.bg,
        appBar: pageBar("Contact"),
      );
    }

    final list = app.txsForContact(contactId);
    double receivable = app.outstandingSum(true, contactId: contactId);
    double payable = app.outstandingSum(false, contactId: contactId);
    String typeLabel = contact.type == "lender" ? "Lender" : "Borrower";

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: pageBar("Contact", actions: [
        IconButton(
          icon: const Icon(Icons.edit_outlined, color: Colors.white),
          onPressed: () => showContactSheet(context, contact: contact),
        ),
        IconButton(
          icon: const Icon(Icons.delete_outline, color: Colors.white),
          onPressed: () async {
            bool ok = await confirmDialog(
              context,
              "Delete contact",
              "All transactions of this contact will also be deleted.",
            );
            if (!ok || !context.mounted) return;

            Navigator.pop(context);
            await app.deleteContact(contactId);
          },
        ),
      ]),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            AppCard(
              margin: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    contact.name,
                    style: const TextStyle(color: Colors.white, fontSize: 18),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    "$typeLabel • ${contact.phone}",
                    style: const TextStyle(color: AppColors.text),
                  ),
                  if (contact.email.isNotEmpty)
                    Text(
                      contact.email,
                      style: const TextStyle(color: AppColors.text),
                    ),
                  const Divider(color: Colors.white24, height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "You get",
                            style: TextStyle(color: AppColors.text, fontSize: 12),
                          ),
                          Text(
                            money(receivable),
                            style: const TextStyle(color: AppColors.green, fontSize: 18),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          const Text(
                            "You owe",
                            style: TextStyle(color: AppColors.text, fontSize: 12),
                          ),
                          Text(
                            money(payable),
                            style: const TextStyle(color: AppColors.red, fontSize: 18),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SectionHeader(title: "Transactions"),
            const SizedBox(height: 10),
            if (list.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 8),
                child: Text(
                  "No transactions with this contact",
                  style: TextStyle(color: Colors.white54),
                ),
              )
            else
              ...list.map((tx) => TxCard(tx: tx)),
          ],
        ),
      ),
    );
  }
}