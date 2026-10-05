import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ViolationDetailsScreen extends StatefulWidget {
  final String challanNumber;
  final String plateNumber;
  final double measuredWeight;
  final double allowedWeight;
  final double fineAmount;
  final int? violationId;

  const ViolationDetailsScreen({
    super.key,
    required this.challanNumber,
    required this.plateNumber,
    required this.measuredWeight,
    required this.allowedWeight,
    required this.fineAmount,
    this.violationId,
  });

  @override
  State<ViolationDetailsScreen> createState() => _ViolationDetailsScreenState();
}

class _ViolationDetailsScreenState extends State<ViolationDetailsScreen> {
  bool _isPaid = false;
  bool _isLoading = false;

  void _markPaid() async {
    setState(() => _isLoading = true);
    if (widget.violationId != null) {
      await ApiService.payChallan(widget.violationId!);
    }
    setState(() {
      _isLoading = false;
      _isPaid = true;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('E-Challan Fine Marked as PAID Successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final excess = widget.measuredWeight - widget.allowedWeight;

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('E-Challan Violation Record', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Challan Slip Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.redAccent.withOpacity(0.4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('CHALLAN NUMBER', style: TextStyle(color: Colors.blueGrey, fontSize: 11, fontWeight: FontWeight.bold)),
                          Text(
                            widget.challanNumber,
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: _isPaid ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: _isPaid ? Colors.greenAccent : Colors.redAccent),
                        ),
                        child: Text(
                          _isPaid ? 'PAID' : 'PENDING',
                          style: TextStyle(
                            color: _isPaid ? Colors.greenAccent : Colors.redAccent,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Divider(color: Colors.white24, height: 24),

                  _buildRow('Vehicle Number', widget.plateNumber),
                  _buildRow('Offense Section', 'Sec 194 MV Act 2019 (Overloading)'),
                  _buildRow('Checkpoint', 'Raipur Highway Toll Plaza (NH-53)'),
                  _buildRow('Measured Weight', '${widget.measuredWeight.toInt()} kg'),
                  _buildRow('Permitted Limit', '${widget.allowedWeight.toInt()} kg'),
                  _buildRow('Excess Weight', '+${excess.toInt()} kg'),
                  
                  const Divider(color: Colors.white24, height: 24),

                  // Fine Breakdown
                  const Text('PENALTY BREAKDOWN', style: TextStyle(color: Colors.blueGrey, fontSize: 11, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 6),
                  _buildRow('Base Overload Fine', '₹20,000'),
                  _buildRow('Excess Weight Surcharge', '₹${(widget.fineAmount - 20000).toInt()} (₹2,000/tonne)'),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total Penalty Amount', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                      Text(
                        '₹${widget.fineAmount.toInt()}',
                        style: const TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w900, fontSize: 22),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Action Buttons
            if (!_isPaid)
              ElevatedButton.icon(
                onPressed: _isLoading ? null : _markPaid,
                icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                label: const Text('COLLECT FINE & MARK PAID', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
            const SizedBox(height: 12),

            OutlinedButton.icon(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('E-Challan SMS notification dispatched to owner of ${widget.plateNumber}!')),
                );
              },
              icon: const Icon(Icons.send, color: Color(0xFF38BDF8)),
              label: const Text('DISPATCH SMS / WHATSAPP NOTICE', style: TextStyle(color: Color(0xFF38BDF8))),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFF38BDF8)),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 13)),
          Text(value, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }
}
