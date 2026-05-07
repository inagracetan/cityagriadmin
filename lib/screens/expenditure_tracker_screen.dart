import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firebase_service.dart';
import '../models/expenditure.dart';
import 'package:intl/intl.dart';
import '../core/constants.dart';
import '../widgets/skeleton_loading.dart';



class ExpenditureTrackerScreen extends StatefulWidget {
  final bool isActive;
  const ExpenditureTrackerScreen({super.key, this.isActive = true});

  @override
  State<ExpenditureTrackerScreen> createState() =>
      _ExpenditureTrackerScreenState();
}

class _ExpenditureTrackerScreenState extends State<ExpenditureTrackerScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final formatCurrency = NumberFormat.simpleCurrency(name: 'PHP ');

  Stream<List<Expenditure>>? _expendituresStream;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _expendituresStream = context.read<FirebaseService>().streamExpenditures();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          color: Theme.of(context).cardColor,
          child: TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).colorScheme.primary,
            unselectedLabelColor: Colors.grey,
            indicatorColor: Theme.of(context).colorScheme.primary,
            tabs: const [
              Tab(icon: Icon(Icons.description), text: 'PR List (Requisition)'),
              Tab(
                icon: Icon(Icons.shopping_cart),
                text: 'PO Tracker (Procurement)',
              ),
            ],
          ),
        ),
        Expanded(
          child: StreamBuilder<List<Expenditure>>(
            stream: _expendituresStream,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const SkeletonList();
              }

              final expenditures = snapshot.data ?? [];
              
              if (expenditures.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.assignment_outlined, size: 64, color: Colors.grey.shade300),
                      const SizedBox(height: 16),
                      Text(
                        'No procurement records found.',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 16),
                      ),
                    ],
                  ),
                );
              }

              return TabBarView(
                controller: _tabController,
                children: [
                  _buildPRList(expenditures),
                  _buildPOTracker(expenditures),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPRList(List<Expenditure> expenditures) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: expenditures.length,
      itemBuilder: (context, index) {
        final exp = expenditures[index];
        return Card(
          child: ListTile(
            title: Text('PR #: ${exp.prNumber}'),
            subtitle: Text('${exp.activityName} - ${exp.sector}'),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  formatCurrency.format(exp.amount),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                Text(
                  exp.poNumber != null && exp.poNumber!.isNotEmpty
                      ? 'Converted to PO'
                      : 'Awaiting PO',
                  style: TextStyle(
                    color: exp.poNumber != null && exp.poNumber!.isNotEmpty
                        ? Colors.green
                        : Colors.orange,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildPOTracker(List<Expenditure> expenditures) {
    final poList = expenditures
        .where((e) => e.poNumber != null && e.poNumber!.isNotEmpty)
        .toList();
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: poList.length,
      itemBuilder: (context, index) {
        final exp = poList[index];
        return Card(
          child: ListTile(
            title: Text('PO #: ${exp.poNumber}'),
            subtitle: Text(
              'Date: ${exp.poDate ?? 'N/A'} | Status: ${exp.poStatus ?? AppConstants.statusPending}',
            ),
            trailing: Text(
              formatCurrency.format(exp.amount),
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            onTap: () => _showPOUpdateDialog(context, exp),
          ),
        );
      },
    );
  }

  void _showPOUpdateDialog(BuildContext context, Expenditure exp) {
    final poNumberCtl = TextEditingController(text: exp.poNumber);
    final poDateCtl = TextEditingController(text: exp.poDate);
    String selectedStatus = exp.poStatus ?? AppConstants.statusPending;
    if (!AppConstants.prStatuses.contains(selectedStatus)) {
      // If legacy status, fallback to something in prStatuses or keep as is for selection
      // But for the dropdown, it MUST be in the items list
    }

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: const Text('Update PO Information'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: poNumberCtl,
                decoration: const InputDecoration(labelText: 'PO Number'),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: poDateCtl,
                decoration: const InputDecoration(labelText: 'PO Date'),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime(SystemConfig.currentFiscalYear),
                    lastDate: DateTime(SystemConfig.currentFiscalYear + 5),
                  );
                  if (date != null) {
                    poDateCtl.text = DateFormat('MM/dd/yyyy').format(date);
                  }
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: selectedStatus,
                decoration: const InputDecoration(labelText: 'Status'),
                items: AppConstants.prStatuses
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => setState(() => selectedStatus = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                if (poNumberCtl.text.isEmpty || poDateCtl.text.isEmpty || selectedStatus.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Please complete all fields (PO Number, Date, and Status)')),
                  );
                  return;
                }
                final updated = exp.copyWith(
                  poNumber: poNumberCtl.text,
                  poDate: poDateCtl.text,
                  poStatus: selectedStatus,
                );
                context.read<FirebaseService>().updateExpenditure(
                  updated,
                  exp.amount,
                );
                Navigator.pop(context);
              },
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }
}

