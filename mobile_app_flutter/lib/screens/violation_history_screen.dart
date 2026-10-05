import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/violation.dart';
import 'violation_details_screen.dart';

class ViolationHistoryScreen extends StatefulWidget {
  const ViolationHistoryScreen({super.key});

  @override
  State<ViolationHistoryScreen> createState() => _ViolationHistoryScreenState();
}

class _ViolationHistoryScreenState extends State<ViolationHistoryScreen> {
  List<Violation> _violations = [];
  bool _isLoading = true;
  String _filter = 'ALL';

  @override
  void initState() {
    super.initState();
    _fetchViolations();
  }

  void _fetchViolations() async {
    setState(() => _isLoading = true);
    final list = await ApiService.getViolations();
    setState(() {
      _violations = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _violations.where((v) {
      if (_filter == 'PENDING') return !v.isPaid;
      if (_filter == 'PAID') return v.isPaid;
      return true;
    }).toList();

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('E-Challan History', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          // Filter Tabs
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            color: const Color(0xFF1E293B),
            child: Row(
              children: [
                _buildFilterChip('ALL'),
                const SizedBox(width: 8),
                _buildFilterChip('PENDING'),
                const SizedBox(width: 8),
                _buildFilterChip('PAID'),
              ],
            ),
          ),

          // Violations List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
                : filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.check_circle_outline, size: 54, color: Colors.blueGrey.shade600),
                            const SizedBox(height: 12),
                            Text('No violations found in this view', style: TextStyle(color: Colors.blueGrey.shade400)),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async => _fetchViolations(),
                        child: ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filtered.length,
                          itemBuilder: (context, index) {
                            final v = filtered[index];
                            return Card(
                              color: const Color(0xFF1E293B),
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                                side: BorderSide(
                                  color: v.isPaid ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
                                ),
                              ),
                              child: ListTile(
                                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                leading: CircleAvatar(
                                  backgroundColor: v.isPaid ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                                  child: Icon(
                                    v.isPaid ? Icons.check : Icons.warning,
                                    color: v.isPaid ? Colors.greenAccent : Colors.redAccent,
                                  ),
                                ),
                                title: Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      v.plateNumber,
                                      style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                    Text(
                                      '₹${v.fineAmount.toInt()}',
                                      style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold, fontSize: 15),
                                    ),
                                  ],
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const SizedBox(height: 4),
                                    Text(
                                      'Excess: +${v.excessWeightKg.toInt()} kg | ${v.challanNumber}',
                                      style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 12),
                                    ),
                                    Text(
                                      v.checkpointName,
                                      style: TextStyle(color: Colors.blueGrey.shade500, fontSize: 11),
                                    ),
                                  ],
                                ),
                                trailing: const Icon(Icons.chevron_right, color: Colors.white54),
                                onTap: () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => ViolationDetailsScreen(
                                        challanNumber: v.challanNumber,
                                        plateNumber: v.plateNumber,
                                        measuredWeight: v.measuredWeightKg,
                                        allowedWeight: v.permittedWeightKg,
                                        fineAmount: v.fineAmount,
                                        violationId: v.id,
                                      ),
                                    ),
                                  );
                                },
                              ),
                            );
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label) {
    final isSelected = _filter == label;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => setState(() => _filter = label),
      selectedColor: const Color(0xFF2563EB),
      backgroundColor: const Color(0xFF0F172A),
      labelStyle: TextStyle(
        color: isSelected ? Colors.white : Colors.blueGrey.shade300,
        fontWeight: FontWeight.bold,
        fontSize: 12,
      ),
    );
  }
}
