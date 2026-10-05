import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'login_screen.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _serverController = TextEditingController(text: ApiService.baseUrl);
  bool _audioAlerts = true;
  bool _hapticFeedback = true;

  void _saveServerUrl() {
    ApiService.baseUrl = _serverController.text.trim();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Backend Server URL Updated!')),
    );
  }

  void _logout() {
    ApiService.authToken = null;
    ApiService.currentUser = null;
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ApiService.currentUser ?? {
      'full_name': 'Inspector Rajesh Verma',
      'username': 'rto_admin',
      'role': 'Senior Enforcement Officer',
      'badge_id': 'CG-RTO-001',
    };

    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text('Officer Profile & Settings', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(18),
        child: Column(
          children: [
            // Officer Info Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: const Color(0xFF2563EB),
                    child: const Icon(Icons.person, size: 36, color: Colors.white),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user['full_name'] ?? 'Officer',
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Badge: ${user['badge_id'] ?? 'CG-RTO-001'}',
                          style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        Text(
                          'Role: ${(user['role'] ?? 'officer').toString().toUpperCase()}',
                          style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Server URL Config
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Backend API Connection', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
                  const SizedBox(height: 6),
                  Text('Set backend IP address for physical phone / Wi-Fi testing', style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _serverController,
                    style: const TextStyle(color: Colors.white, fontSize: 13),
                    decoration: InputDecoration(
                      labelText: 'Server Base URL',
                      labelStyle: TextStyle(color: Colors.blueGrey.shade300),
                      filled: true,
                      fillColor: const Color(0xFF0F172A),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.save, color: Color(0xFF38BDF8)),
                        onPressed: _saveServerUrl,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),

            // Preferences
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  SwitchListTile(
                    title: const Text('Loud Siren Audio Alerts', style: TextStyle(color: Colors.white, fontSize: 14)),
                    subtitle: Text('Play horn on critical overload', style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12)),
                    value: _audioAlerts,
                    activeColor: const Color(0xFF38BDF8),
                    onChanged: (val) => setState(() => _audioAlerts = val),
                  ),
                  SwitchListTile(
                    title: const Text('Haptic Vibration', style: TextStyle(color: Colors.white, fontSize: 14)),
                    subtitle: Text('Vibrate phone when violation recorded', style: TextStyle(color: Colors.blueGrey.shade400, fontSize: 12)),
                    value: _hapticFeedback,
                    activeColor: const Color(0xFF38BDF8),
                    onChanged: (val) => setState(() => _hapticFeedback = val),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Logout Button
            ElevatedButton.icon(
              onPressed: _logout,
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text('LOGOUT OF ENFORCEMENT SESSION', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFDC2626),
                padding: const EdgeInsets.symmetric(vertical: 16),
                minimumSize: const Size.fromHeight(50),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
