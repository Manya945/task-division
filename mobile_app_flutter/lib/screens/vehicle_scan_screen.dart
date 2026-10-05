import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'weight_check_screen.dart';

class VehicleScanScreen extends StatefulWidget {
  const VehicleScanScreen({super.key});

  @override
  State<VehicleScanScreen> createState() => _VehicleScanScreenState();
}

class _VehicleScanScreenState extends State<VehicleScanScreen> {
  final _plateController = TextEditingController(text: 'CG10AB1234');
  bool _isScanning = false;
  Map<String, dynamic>? _scanResult;
  String? _error;

  void _performScan([String? manualPlate]) async {
    final plate = manualPlate ?? _plateController.text.trim();
    if (plate.isEmpty) return;

    setState(() {
      _isScanning = true;
      _error = null;
    });

    final res = await ApiService.scanPlate(plateHint: plate);

    setState(() {
      _isScanning = false;
      if (res != null && res['success'] == true) {
        _scanResult = res;
      } else {
        _error = 'Failed to recognize plate. Check camera focus or backend server.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('ANPR Camera Scanner', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Camera Viewfinder Simulation
            Container(
              height: 220,
              decoration: BoxDecoration(
                color: Colors.black,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFF38BDF8), width: 2),
              ),
              child: Stack(
                children: [
                  Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.camera_alt_outlined,
                          size: 48,
                          color: _isScanning ? const Color(0xFF38BDF8) : Colors.blueGrey.shade600,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _isScanning ? 'AI Engine Scanning License Plate...' : 'Position Front Number Plate in Frame',
                          style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 13),
                        ),
                      ],
                    ),
                  ),

                  // Viewfinder corners
                  Positioned(
                    top: 16, left: 16,
                    child: Container(width: 24, height: 24, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF38BDF8), width: 3), left: BorderSide(color: Color(0xFF38BDF8), width: 3)))),
                  ),
                  Positioned(
                    top: 16, right: 16,
                    child: Container(width: 24, height: 24, decoration: const BoxDecoration(border: Border(top: BorderSide(color: Color(0xFF38BDF8), width: 3), right: BorderSide(color: Color(0xFF38BDF8), width: 3)))),
                  ),
                  Positioned(
                    bottom: 16, left: 16,
                    child: Container(width: 24, height: 24, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF38BDF8), width: 3), left: BorderSide(color: Color(0xFF38BDF8), width: 3)))),
                  ),
                  Positioned(
                    bottom: 16, right: 16,
                    child: Container(width: 24, height: 24, decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Color(0xFF38BDF8), width: 3), right: BorderSide(color: Color(0xFF38BDF8), width: 3)))),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Plate Input / Manual Override
            Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _plateController,
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, letterSpacing: 1.5),
                    textCapitalization: TextCapitalization.characters,
                    decoration: InputDecoration(
                      labelText: 'Vehicle Number Plate',
                      labelStyle: TextStyle(color: Colors.blueGrey.shade300),
                      prefixIcon: const Icon(Icons.pin, color: Color(0xFF38BDF8)),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: _isScanning ? null : () => _performScan(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: _isScanning
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Text('CAPTURE', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                ),
              ],
            ),
            const SizedBox(height: 14),

            // Quick Demo Plates
            const Text('Demo Fleet Presets:', style: TextStyle(color: Colors.blueGrey, fontSize: 12)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                ActionChip(
                  label: const Text('CG10AB1234 (Tata Prima)'),
                  backgroundColor: const Color(0xFF1E293B),
                  labelStyle: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11),
                  onPressed: () {
                    _plateController.text = 'CG10AB1234';
                    _performScan('CG10AB1234');
                  },
                ),
                ActionChip(
                  label: const Text('MH12DE1433 (Ashok Leyland)'),
                  backgroundColor: const Color(0xFF1E293B),
                  labelStyle: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11),
                  onPressed: () {
                    _plateController.text = 'MH12DE1433';
                    _performScan('MH12DE1433');
                  },
                ),
                ActionChip(
                  label: const Text('DL01AA9988 (BharatBenz)'),
                  backgroundColor: const Color(0xFF1E293B),
                  labelStyle: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11),
                  onPressed: () {
                    _plateController.text = 'DL01AA9988';
                    _performScan('DL01AA9988');
                  },
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Scan Results Card
            if (_scanResult != null) ...[
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1E293B),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFF10B981).withOpacity(0.5)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('AI OCR Detection', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 15)),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: Colors.green.shade900,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            'CONFIDENCE: ${((_scanResult!['ocr_details']['confidence'] ?? 0.95) * 100).toInt()}%',
                            style: const TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold),
                          ),
                        )
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Indian HSRP Plate Graphic Box
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFCC00), // Indian commercial plate yellow
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.black, width: 2),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF003399),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: const Text('IND', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _scanResult!['plate_number'],
                            style: const TextStyle(
                              color: Colors.black,
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 2,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),

                    // VAHAN Info
                    if (_scanResult!['vehicle_info'] != null) ...[
                      _buildInfoRow('Owner:', _scanResult!['vehicle_info']['owner_name']),
                      _buildInfoRow('Vehicle Type:', _scanResult!['vehicle_info']['vehicle_type']),
                      _buildInfoRow('Permitted GVW:', '${(_scanResult!['vehicle_info']['permitted_weight_kg'] as num).toInt()} kg'),
                      _buildInfoRow('RTO State:', _scanResult!['vehicle_info']['state']),
                    ],

                    const SizedBox(height: 18),
                    ElevatedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => WeightCheckScreen(prefillPlate: _scanResult!['plate_number']),
                          ),
                        );
                      },
                      icon: const Icon(Icons.scale, color: Colors.white),
                      label: const Text('PROCEED TO WEIGHT CHECK', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF10B981),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
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
