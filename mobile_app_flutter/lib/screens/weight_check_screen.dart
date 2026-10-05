import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/weight_record.dart';
import 'violation_details_screen.dart';

class WeightCheckScreen extends StatefulWidget {
  final String? prefillPlate;
  const WeightCheckScreen({super.key, this.prefillPlate});

  @override
  State<WeightCheckScreen> createState() => _WeightCheckScreenState();
}

class _WeightCheckScreenState extends State<WeightCheckScreen> {
  late TextEditingController _plateController;
  final _weightController = TextEditingController(text: '14500');
  bool _isLoading = false;
  WeightRecord? _result;
  String? _challanNumber;
  double _fineAmount = 0.0;

  @override
  void initState() {
    super.initState();
    _plateController = TextEditingController(text: widget.prefillPlate ?? 'CG10AB1234');
  }

  void _triggerWeightCheck() async {
    final plate = _plateController.text.trim();
    final weight = double.tryParse(_weightController.text.trim()) ?? 0.0;
    if (plate.isEmpty || weight <= 0) return;

    setState(() {
      _isLoading = true;
      _result = null;
    });

    final record = await ApiService.checkWeight(plateNumber: plate, weightKg: weight);

    setState(() {
      _isLoading = false;
      _result = record;
      if (record != null && record.isOverload) {
        // Calculate fine locally or fetch from backend response
        double excess = record.excessWeightKg;
        _fineAmount = 20000.0 + ((excess / 1000.0).ceil() * 2000.0);
        _challanNumber = 'ECH-CG-2026-${10000 + DateTime.now().millisecond}';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Weigh-in-Motion (WIM)', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Sensor Header
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.blueGrey.shade800),
              ),
              child: Row(
                children: [
                  const Icon(Icons.developer_board, color: Color(0xFF38BDF8), size: 28),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('ESP32 Weighbridge Scale #01', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        Text('HX711 24-bit ADC • Continuous WIM Mode', style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Plate Input
            TextField(
              controller: _plateController,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Vehicle License Plate',
                labelStyle: TextStyle(color: Colors.blueGrey.shade300),
                prefixIcon: const Icon(Icons.directions_car, color: Color(0xFF38BDF8)),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 14),

            // Measured Weight Input
            TextField(
              controller: _weightController,
              keyboardType: TextInputType.number,
              style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              decoration: InputDecoration(
                labelText: 'Measured Weight (kg)',
                labelStyle: TextStyle(color: Colors.blueGrey.shade300),
                prefixIcon: const Icon(Icons.scale, color: Color(0xFF38BDF8)),
                suffixText: 'KG',
                suffixStyle: const TextStyle(color: Color(0xFF38BDF8), fontWeight: FontWeight.bold),
                filled: true,
                fillColor: const Color(0xFF1E293B),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
            const SizedBox(height: 18),

            // Check Button
            ElevatedButton(
              onPressed: _isLoading ? null : _triggerWeightCheck,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF2563EB),
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('SUBMIT WEIGHT MEASUREMENT', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
            ),
            const SizedBox(height: 24),

            // Result Display Card
            if (_result != null) ...[
              Container(
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: _result!.isOverload ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                    width: 2,
                  ),
                ),
                child: Column(
                  children: [
                    // Status Badge
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: _result!.isOverload ? const Color(0xFFEF4444) : const Color(0xFF10B981),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        _result!.isOverload ? '🔴 OVERLOAD DETECTED' : '🟢 PERMISSIBLE WEIGHT',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Weight Comparison Box
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildWeightMetric('Measured Gross', '${_result!.measuredWeightKg.toInt()} kg', Colors.white),
                        _buildWeightMetric('Permitted Limit', '${_result!.allowedWeightKg.toInt()} kg', const Color(0xFF38BDF8)),
                        _buildWeightMetric(
                          'Excess Weight',
                          '+${_result!.excessWeightKg.toInt()} kg',
                          _result!.isOverload ? const Color(0xFFEF4444) : Colors.greenAccent,
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // If Overload, Show Fine and E-Challan Action
                    if (_result!.isOverload) ...[
                      const Divider(color: Colors.white24),
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Penalty Fine (MV Act):', style: TextStyle(color: Colors.white70, fontSize: 14)),
                          Text(
                            '₹${_fineAmount.toInt()}',
                            style: const TextStyle(color: Color(0xFFEF4444), fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => ViolationDetailsScreen(
                                challanNumber: _challanNumber ?? 'ECH-CG-2026-9812',
                                plateNumber: _result!.plateNumber,
                                measuredWeight: _result!.measuredWeightKg,
                                allowedWeight: _result!.allowedWeightKg,
                                fineAmount: _fineAmount,
                              ),
                            ),
                          );
                        },
                        icon: const Icon(Icons.receipt, color: Colors.white),
                        label: const Text('VIEW E-CHALLAN DETAILS', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFDC2626),
                          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildWeightMetric(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(value, style: TextStyle(color: valueColor, fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 11)),
      ],
    );
  }
}
