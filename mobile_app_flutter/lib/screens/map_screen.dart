import 'package:flutter/material.dart';
import '../services/api_service.dart';

class MapScreen extends StatefulWidget {
  const MapScreen({super.key});

  @override
  State<MapScreen> createState() => _MapScreenState();
}

class _MapScreenState extends State<MapScreen> {
  List<dynamic> _locations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchLocations();
  }

  void _fetchLocations() async {
    setState(() => _isLoading = true);
    final list = await ApiService.getLocations();
    setState(() {
      _locations = list;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Enforcement Checkpoints Map', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
          : Column(
              children: [
                // Simulated Radar / GIS Map Viewport
                Container(
                  height: 200,
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: const Color(0xFF1E293B),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFF2563EB).withOpacity(0.4)),
                  ),
                  child: Stack(
                    children: [
                      // Grid background pattern
                      Center(
                        child: Icon(Icons.map, size: 100, color: Colors.blueGrey.shade800),
                      ),
                      Positioned(
                        top: 40, left: 60,
                        child: _buildPin('CP-01 (Raipur)', true),
                      ),
                      Positioned(
                        top: 80, right: 70,
                        child: _buildPin('CP-02 (Bilaspur)', true),
                      ),
                      Positioned(
                        bottom: 40, left: 90,
                        child: _buildPin('CP-03 (Durg)', true),
                      ),
                      Positioned(
                        bottom: 60, right: 50,
                        child: _buildPin('CP-04 (Nagpur Border)', true),
                      ),
                    ],
                  ),
                ),

                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 18),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      'Active Highway Checkposts',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ),
                ),
                const SizedBox(height: 10),

                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: _locations.length,
                    itemBuilder: (context, index) {
                      final loc = _locations[index];
                      return Card(
                        color: const Color(0xFF1E293B),
                        margin: const EdgeInsets.only(bottom: 10),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: ListTile(
                          leading: const CircleAvatar(
                            backgroundColor: Color(0xFF2563EB),
                            child: Icon(Icons.location_on, color: Colors.white, size: 20),
                          ),
                          title: Text(
                            loc['name'] ?? '',
                            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(loc['highway'] ?? '', style: TextStyle(color: Colors.blueGrey.shade300, fontSize: 12)),
                              Text(
                                'Lat: ${loc['latitude']} • Lon: ${loc['longitude']} • ${loc['active_officers'] ?? 2} Officers Deployed',
                                style: TextStyle(color: Colors.blueGrey.shade500, fontSize: 11),
                              ),
                            ],
                          ),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Text('ONLINE', style: TextStyle(color: Colors.greenAccent, fontSize: 11, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPin(String name, bool active) {
    return Column(
      children: [
        const Icon(Icons.location_pin, color: Colors.redAccent, size: 28),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.black87,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(name, style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
