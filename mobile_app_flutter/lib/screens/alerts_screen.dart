import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/alert_model.dart';

class AlertsScreen extends StatefulWidget {
  const AlertsScreen({super.key});

  @override
  State<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends State<AlertsScreen> {
  List<AlertModel> _alerts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchAlerts();
  }

  void _fetchAlerts() async {
    setState(() => _isLoading = true);
    final list = await ApiService.getAlerts();
    setState(() {
      _alerts = list;
      _isLoading = false;
    });
  }

  void _ackAlert(int id) async {
    await ApiService.acknowledgeAlert(id);
    _fetchAlerts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Live Security & Overload Alerts', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: Color(0xFF38BDF8)))
          : _alerts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.notifications_off_outlined, size: 54, color: Colors.blueGrey.shade600),
                      const SizedBox(height: 12),
                      Text('No active alerts at this time', style: TextStyle(color: Colors.blueGrey.shade400)),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () async => _fetchAlerts(),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _alerts.length,
                    itemBuilder: (context, index) {
                      final a = _alerts[index];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: a.isCritical ? Colors.redAccent.withOpacity(0.5) : Colors.orangeAccent.withOpacity(0.5),
                          ),
                        ),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            CircleAvatar(
                              backgroundColor: a.isCritical ? Colors.red.withOpacity(0.2) : Colors.orange.withOpacity(0.2),
                              child: Icon(
                                a.isCritical ? Icons.priority_high : Icons.warning_amber,
                                color: a.isCritical ? Colors.redAccent : Colors.orangeAccent,
                                size: 20,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        a.alertType.replaceAll('_', ' '),
                                        style: TextStyle(
                                          color: a.isCritical ? Colors.redAccent : Colors.orangeAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      if (a.isRead == 0)
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                          decoration: BoxDecoration(
                                            color: Colors.red,
                                            borderRadius: BorderRadius.circular(4),
                                          ),
                                          child: const Text('NEW', style: TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.bold)),
                                        ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    a.message,
                                    style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500),
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    a.checkpointName,
                                    style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            if (a.isRead == 0)
                              IconButton(
                                icon: const Icon(Icons.check, color: Colors.greenAccent),
                                tooltip: 'Acknowledge',
                                onPressed: () => _ackAlert(a.id),
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
