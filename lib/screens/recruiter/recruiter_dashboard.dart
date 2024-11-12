import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nt/screens/applications_screen.dart';
import 'package:nt/services/providers/auth_provider.dart';
import 'package:nt/services/providers/get_user_infos_provider.dart';
import 'package:nt/widgets/opportunity_card.dart';
import 'package:intl/intl.dart';

class RecruiterDashboard extends ConsumerStatefulWidget {
  const RecruiterDashboard({super.key});

  @override
  ConsumerState<RecruiterDashboard> createState() => _RecruiterDashboardState();
}

class _RecruiterDashboardState extends ConsumerState<RecruiterDashboard> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recruiter Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () => _showCreateOpportunityDialog(context),
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('opportunities')
            .where('recruiterId', isEqualTo: ref.read(userProvider)?.id)
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          return ListView.builder(
            itemCount: snapshot.data!.docs.length,
            itemBuilder: (context, index) {
              final opportunity = snapshot.data!.docs[index];
              return OpportunityCard(
                title: opportunity['title'],
                description: opportunity['description'],
                sport: opportunity['sport'],
                location: opportunity['location'],
                deadline: (opportunity['deadline'] as Timestamp).toDate(),
                onTap: () => _viewApplications(opportunity.id),
              );
            },
          );
        },
      ),
    );
  }

  Future<void> _showCreateOpportunityDialog(BuildContext context) async {
    final formKey = GlobalKey<FormState>();
    final titleController = TextEditingController();
    final descriptionController = TextEditingController();
    String? selectedSport;
    DateTime? deadline;

    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Create Opportunity'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: titleController,
                  decoration: const InputDecoration(labelText: 'Title'),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                TextFormField(
                  controller: descriptionController,
                  decoration: const InputDecoration(labelText: 'Description'),
                  maxLines: 3,
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Required' : null,
                ),
                DropdownButtonFormField<String>(
                  value: selectedSport,
                  decoration: const InputDecoration(labelText: 'Sport'),
                  items: ['Basketball', 'Football', 'Soccer']
                      .map((sport) => DropdownMenuItem(
                            value: sport,
                            child: Text(sport),
                          ))
                      .toList(),
                  onChanged: (value) => selectedSport = value,
                  validator: (value) => value == null ? 'Required' : null,
                ),
                ListTile(
                  title: Text(
                    deadline == null
                        ? 'Select Deadline'
                        : DateFormat.yMMMd().format(deadline!),
                  ),
                  trailing: const Icon(Icons.calendar_today),
                  onTap: () async {
                    final date = await showDatePicker(
                      context: context,
                      initialDate: DateTime.now(),
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 365)),
                    );
                    if (date != null) {
                      setState(() => deadline = date);
                    }
                  },
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (formKey.currentState?.validate() ?? false) {
                try {
                  final user = ref.read(userProvider);
                  await FirebaseFirestore.instance
                      .collection('opportunities')
                      .add({
                    'recruiterId': user?.id,
                    'title': titleController.text,
                    'description': descriptionController.text,
                    'sport': selectedSport,
                    'deadline': deadline,
                    'createdAt': FieldValue.serverTimestamp(),
                    'status': 'open',
                  });
                  if (mounted) Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text(e.toString())),
                  );
                }
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  void _viewApplications(String opportunityId) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => ApplicationsScreen(opportunityId: opportunityId),
      ),
    );
  }
}
