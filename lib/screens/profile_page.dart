import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';
import 'login_screen.dart';

class ProfilePage extends StatefulWidget {
  final VoidCallback? onLanguageChanged;

  const ProfilePage({super.key, this.onLanguageChanged});

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final name = TextEditingController();
  final phone = TextEditingController();
  final email = TextEditingController();
  final location = TextEditingController();
  final address = TextEditingController();
  final roles = const ["User", "Agent", "Admin"];

  String selectedRole = AppStore.currentUserRole;
  bool loading = false;

  @override
  void initState() {
    super.initState();
    fillFields();
    loadProfile();
  }

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    email.dispose();
    location.dispose();
    address.dispose();
    super.dispose();
  }

  String t(String en, String ta) => AppStore.tr(en, ta);

  void fillFields() {
    name.text = AppStore.currentUserName;
    phone.text = AppStore.currentUserPhone;
    email.text = AppStore.currentUserEmail;
    selectedRole = AppStore.currentUserRole;
    location.text = AppStore.currentUserLocation;
    address.text = AppStore.currentUserAddress;
  }

  Future<void> loadProfile() async {
    await FirebaseService.loadProfile();
    if (!mounted) return;
    setState(fillFields);
  }

  Future<void> saveProfile() async {
    setState(() => loading = true);
    try {
      await FirebaseService.saveProfile(
        name: name.text,
        phone: phone.text,
        email: email.text,
        role: selectedRole,
        location: location.text,
        address: address.text,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t("Profile saved", "சுயவிவரம் சேமிக்கப்பட்டது"))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t("Profile save failed", "சுயவிவரம் சேமிக்க முடியவில்லை"))),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  Future<void> useCurrentLocation() async {
    setState(() => loading = true);
    try {
      final pos = await LocationService.currentPosition();
      location.text =
          "${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}";
      await saveProfile();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t(
              "Allow location permission and turn on GPS",
              "Location permission allow செய்து GPS on செய்யவும்",
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  String roleText(String role) {
    return t(
      role,
      role == "User"
          ? "பயனர்"
          : role == "Agent"
              ? "முகவர்"
              : "நிர்வாகி",
    );
  }

  InputDecoration decoration(String en, String ta, IconData icon) {
    return InputDecoration(
      labelText: t(en, ta),
      prefixIcon: Icon(icon),
      border: const OutlineInputBorder(),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(t("Profile", "சுயவிவரம்")),
        backgroundColor: Colors.green,
        actions: [
          DropdownButton<bool>(
            value: AppStore.isTamil,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: false, child: Text("English")),
              DropdownMenuItem(value: true, child: Text("தமிழ்")),
            ],
            onChanged: (value) {
              setState(() => AppStore.isTamil = value ?? false);
              widget.onLanguageChanged?.call();
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Icon(Icons.account_circle, size: 82, color: Colors.green),
          const SizedBox(height: 12),
          TextField(
            controller: name,
            decoration: decoration("Name", "பெயர்", Icons.person),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: phone,
            keyboardType: TextInputType.phone,
            decoration: decoration("Phone Number", "தொலைபேசி எண்", Icons.phone),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: email,
            keyboardType: TextInputType.emailAddress,
            decoration: decoration("Email ID", "மின்னஞ்சல் ID", Icons.email),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            value: roles.contains(selectedRole) ? selectedRole : roles.first,
            items: roles
                .map(
                  (role) => DropdownMenuItem(
                    value: role,
                    child: Text(roleText(role)),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() => selectedRole = value ?? roles.first);
            },
            decoration: decoration("Role", "பங்கு", Icons.badge),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: location,
            decoration: decoration("Location", "இடம்", Icons.location_on),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: loading ? null : useCurrentLocation,
            icon: const Icon(Icons.my_location),
            label: Text(t("Use Current GPS Location", "தற்போதைய GPS இடம் பயன்படுத்து")),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: address,
            minLines: 2,
            maxLines: 4,
            decoration: decoration("Address", "முகவரி", Icons.home),
          ),
          if (selectedRole.toLowerCase().contains('agent')) ...[
            const SizedBox(height: 12),
            _AgentEarningsCard(t: t),
          ],
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              onPressed: loading ? null : saveProfile,
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.save),
              label: Text(t("Save Profile", "சுயவிவரம் சேமி")),
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            ),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {
              Navigator.pushAndRemoveUntil(
                context,
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
            icon: const Icon(Icons.logout),
            label: Text(t("Back to Login", "Login பக்கத்திற்கு திரும்பு")),
          ),
        ],
      ),
    );
  }
}

class _AgentEarningsCard extends StatelessWidget {
  final String Function(String en, String ta) t;

  const _AgentEarningsCard({required this.t});

  bool samePhone(dynamic value, String myPhone) {
    final mine = FirebaseService.phoneDigits(myPhone);
    final other = FirebaseService.phoneDigits(value?.toString() ?? '');
    return mine.isNotEmpty && other.isNotEmpty && mine == other;
  }

  @override
  Widget build(BuildContext context) {
    final myPhone = AppStore.currentUserPhone;
    final myName = AppStore.currentUserName.trim().toLowerCase();
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(14),
              child: Center(child: CircularProgressIndicator()),
            ),
          );
        }
        final docs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final agentName =
              data['agentName']?.toString().trim().toLowerCase() ?? '';
          final payment = data['paymentStatus']?.toString() ?? '';
          final completed = payment == 'Paid' ||
              payment == 'Received' ||
              data['status']?.toString() == 'Completed';
          return completed &&
              (samePhone(data['agentOwnerId'], myPhone) ||
                  samePhone(data['agentPhone'], myPhone) ||
                  (myName.isNotEmpty && agentName == myName));
        }).toList();
        final total = docs.fold<double>(0, (sum, doc) {
          final data = doc.data() as Map<String, dynamic>;
          final price = data['price'];
          return sum + (price is num ? price.toDouble() : 0);
        });

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${t("Earnings", "வருமானம்")}: Rs.${total.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                if (docs.isEmpty)
                  Text(t('No earnings yet', 'இன்னும் வருமானம் இல்லை'))
                else
                  ...docs.take(5).map((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text(
                        '${data['userName'] ?? ''} | ${AppStore.displayMachine(data)} | Rs.${data['price'] ?? 0} | ${data['usageTime'] ?? ''}',
                      ),
                    );
                  }),
              ],
            ),
          ),
        );
      },
    );
  }
}
