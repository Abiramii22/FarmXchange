import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../services/firebase_service.dart';
import '../services/whatsapp_service.dart';
import 'login_screen.dart';
import 'profile_page.dart';

class AgentHome extends StatefulWidget {
  const AgentHome({super.key});

  @override
  State<AgentHome> createState() => _AgentHomeState();
}

class _AgentHomeState extends State<AgentHome> {
  static const Map<String, String> _ta = {
    'Stock update failed': 'ஸ்டாக் புதுப்பிப்பு தோல்வி',
    'Availability update failed': 'கிடைக்கும் நிலை புதுப்பிப்பு தோல்வி',
    'Add Machine': 'இயந்திரம் சேர்',
    'Machine': 'இயந்திரம்',
    'Machine Tamil': 'இயந்திரம் தமிழ்',
    'Agent Phone': 'முகவர் தொலைபேசி',
    'Location': 'இடம்',
    'Hourly Rate': 'மணி கட்டணம்',
    'Stock': 'ஸ்டாக்',
    'Image path/url': 'பட path/url',
    'Rating': 'மதிப்பீடு',
    'Review': 'மதிப்புரை',
    'Review Tamil': 'மதிப்புரை தமிழ்',
    'Back': 'பின்',
    'Save': 'சேமி',
    'Earnings': 'வருமானம்',
    'No paid earnings yet': 'இன்னும் பணம் செலுத்திய வருமானம் இல்லை',
    'User': 'பயனர்',
    'Phone': 'போன்',
    'Payment': 'பணம்',
    'No machines added yet': 'இன்னும் இயந்திரம் சேர்க்கவில்லை',
    'Active Products': 'கிடைக்கும் பொருட்கள்',
    'Rate': 'கட்டணம்',
    'Available': 'கிடைக்கும்',
    'Unavailable': 'கிடைக்கவில்லை',
    'No bookings yet': 'இன்னும் பதிவுகள் இல்லை',
    'Amount': 'தொகை',
    'Status': 'நிலை',
    'Usage time': 'பயன்பாட்டு நேரம்',
    'Route note': 'வழி குறிப்பு',
    'Method': 'முறை',
    'Refund': 'திருப்பி பணம்',
    'Accept': 'ஏற்கவும்',
    'Reject': 'நிராகரி',
    'Complete': 'முடிக்கவும்',
    'Payment paid': 'பணம் செலுத்தப்பட்டது',
    'Payment pending': 'பணம் நிலுவை',
    'Agent Dashboard': 'முகவர் டாஷ்போர்டு',
    'Machines': 'இயந்திரங்கள்',
    'Bookings': 'பதிவுகள்',
  };

  String t(String en, String ta) {
    if (!AppStore.isTamil) return en;
    return _ta[en] ?? _fixAgentTamil(ta);
  }

  String _fixAgentTamil(String value) {
    if (value.isEmpty || RegExp(r'[\u0B80-\u0BFF]').hasMatch(value)) {
      return value;
    }
    var current = value;
    for (var i = 0; i < 4; i++) {
      if (!RegExp(r'[ÃÂàâ]').hasMatch(current)) return current;
      try {
        final bytes = current.codeUnits
            .map((code) => code <= 255 ? code : '?'.codeUnitAt(0))
            .toList();
        final next = utf8.decode(bytes, allowMalformed: true);
        if (next == current) return current;
        current = next;
        if (RegExp(r'[\u0B80-\u0BFF]').hasMatch(current)) return current;
      } catch (_) {
        return current;
      }
    }
    return current;
  }

  void showMsg(String en, String ta) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t(en, ta))),
    );
  }

  Future<void> changeStock(String agentId, int change) async {
    try {
      await FirebaseService.incrementAgentStock(
        agentId: agentId,
        change: change,
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      showMsg(
        "Stock update failed: $e",
        "Stock update à®†à®•à®µà®¿à®²à¯à®²à¯ˆ: $e",
      );
    }
  }

  Future<void> changeAvailability(String agentId, bool available) async {
    try {
      await FirebaseService.updateAgentAvailability(
        agentId: agentId,
        available: available,
      ).timeout(const Duration(seconds: 10));
    } catch (e) {
      showMsg(
        "Availability update failed: $e",
        "Availability update à®†à®•à®µà®¿à®²à¯à®²à¯ˆ: $e",
      );
    }
  }

  Future<void> updateBookingAndNotify({
    required String bookingId,
    String? status,
    String? paymentStatus,
    bool complete = false,
  }) async {
    if (complete) {
      await FirebaseService.completeBooking(bookingId: bookingId);
    } else if (status != null) {
      await FirebaseService.updateBookingStatus(
        bookingId: bookingId,
        status: status,
      );
    } else if (paymentStatus != null) {
      await FirebaseService.updatePaymentStatus(
        bookingId: bookingId,
        paymentStatus: paymentStatus,
      );
    }

    final snap = await FirebaseFirestore.instance
        .collection('bookings')
        .doc(bookingId)
        .get();
    final data = snap.data();
    if (data == null) return;
    final message = (paymentStatus == 'Paid' || paymentStatus == 'Received')
        ? WhatsAppService.paymentDoneMessage(data)
        : WhatsAppService.statusMessage(data);
    await WhatsAppService.openMessage(
      phone: data['userPhone']?.toString() ?? '',
      message: message,
    );
    await WhatsAppService.openMessage(
      phone: data['agentPhone']?.toString() ?? '',
      message: message,
    );
  }

  Future<void> addMachine() async {
    final machine = TextEditingController();
    final machineTa = TextEditingController();
    final phone = TextEditingController(text: AppStore.currentUserPhone);
    final location = TextEditingController(text: AppStore.currentUserLocation);
    final price = TextEditingController();
    final stock = TextEditingController(text: "1");
    final image = TextEditingController(text: "assets/images/tractor.jpg");
    final rating = TextEditingController(text: "4.0");
    final review = TextEditingController();
    final reviewTa = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(t("Add Machine", "à®‡à®¯à®¨à¯à®¤à®¿à®°à®®à¯ à®šà¯‡à®°à¯")),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: machine,
                  decoration: InputDecoration(labelText: t("Machine", "à®‡à®¯à®¨à¯à®¤à®¿à®°à®®à¯")),
                ),
                TextField(
                  controller: machineTa,
                  decoration: InputDecoration(labelText: t("Machine Tamil", "à®‡à®¯à®¨à¯à®¤à®¿à®°à®®à¯ à®¤à®®à®¿à®´à¯")),
                ),
                TextField(
                  controller: phone,
                  keyboardType: TextInputType.phone,
                  decoration: InputDecoration(labelText: t("Agent Phone", "à®®à¯à®•à®µà®°à¯ à®¤à¯Šà®²à¯ˆà®ªà¯‡à®šà®¿")),
                ),
                TextField(
                  controller: location,
                  decoration: InputDecoration(labelText: t("Location", "à®‡à®Ÿà®®à¯")),
                ),
                TextField(
                  controller: price,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: t("Hourly Rate", "à®®à®£à®¿ à®•à®Ÿà¯à®Ÿà®£à®®à¯")),
                ),
                TextField(
                  controller: stock,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: t("Stock", "à®¸à¯à®Ÿà®¾à®•à¯")),
                ),
                TextField(
                  controller: image,
                  decoration: InputDecoration(labelText: t("Image path/url", "à®ªà®Ÿ path/url")),
                ),
                TextField(
                  controller: rating,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(labelText: t("Rating", "Rating")),
                ),
                TextField(
                  controller: review,
                  decoration: InputDecoration(labelText: t("Review", "Review")),
                ),
                TextField(
                  controller: reviewTa,
                  decoration: InputDecoration(labelText: t("Review Tamil", "Review Tamil")),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(t("Back", "à®ªà®¿à®©à¯")),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(t("Save", "à®šà¯‡à®®à®¿")),
            ),
          ],
        );
      },
    );

    if (ok != true || machine.text.trim().isEmpty) return;

    await FirebaseFirestore.instance.collection('agents').add({
      'machine': machine.text.trim(),
      'machineTa': machineTa.text.trim(),
      'agentName': AppStore.currentUserName,
      'agentPhone': phone.text.trim(),
      'ownerId': AppStore.currentUserPhone,
      'location': location.text.trim(),
      'locationTa': location.text.trim(),
      'image': image.text.trim(),
      'hourlyRate': double.tryParse(price.text.trim()) ?? 0,
      'distanceKm': 0,
      'stock': int.tryParse(stock.text.trim()) ?? 1,
      'available': (int.tryParse(stock.text.trim()) ?? 1) > 0,
      'rating': double.tryParse(rating.text.trim()) ?? 0,
      'review': review.text.trim(),
      'reviewTa': reviewTa.text.trim(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  String field(Map<String, dynamic> data, String enKey, String taKey) {
    final tamilValue = data[taKey]?.toString().trim() ?? '';
    final englishValue = data[enKey]?.toString().trim() ?? '';
    final value = AppStore.isTamil && tamilValue.isNotEmpty
        ? tamilValue
        : englishValue;
    if (enKey == 'machine') return AppStore.machineName(value);
    return AppStore.isTamil ? AppStore.cleanTamil(value) : value;
  }

  String imageFor(Map<String, dynamic> data) {
    final raw = data['image']?.toString() ?? '';
    final id = data['id']?.toString().toLowerCase() ?? '';
    final machine = data['machine']?.toString().toLowerCase() ?? '';

    if (raw.isNotEmpty && raw != 'assets/logo.png') return raw;
    if (id.contains('tractor') || machine.contains('tractor')) {
      return 'assets/images/tractor.jpg';
    }
    if (id.contains('baler') || machine.contains('baler')) {
      return 'assets/images/baler.jpg';
    }
    if (id.contains('seed') || machine.contains('seed')) {
      return 'assets/images/seed_drill.jpg';
    }
    if (id.contains('harvester') || machine.contains('harvester')) {
      return 'assets/images/harvester.jpg';
    }
    if (id.contains('plough') || machine.contains('plough')) {
      return 'assets/images/plough.jpg';
    }
    if (id.contains('tiller') || machine.contains('tiller')) {
      return 'assets/images/power_tiller.jpg';
    }
    if (id.contains('sprayer') || machine.contains('sprayer')) {
      return 'assets/images/Sprayer.jpg';
    }
    return raw;
  }

  Widget machineImage(Map<String, dynamic> data) {
    final image = imageFor(data);
    if (image.startsWith('http')) {
      return Image.network(image, width: 54, height: 54, fit: BoxFit.cover);
    }
    return Image.asset(
      image.isEmpty ? 'assets/logo.png' : image,
      width: 54,
      height: 54,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Image.asset(
        'assets/logo.png',
        width: 54,
        height: 54,
        fit: BoxFit.contain,
      ),
    );
  }

  bool samePhone(dynamic value, String myPhone) {
    final mine = FirebaseService.phoneDigits(myPhone);
    final other = FirebaseService.phoneDigits(value?.toString() ?? '');
    return mine.isNotEmpty && other.isNotEmpty && mine == other;
  }

  Widget agentEarningsCard(List<QueryDocumentSnapshot> products) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
      builder: (context, snapshot) {
        final myPhone = AppStore.currentUserPhone.trim();
        final myName = AppStore.currentUserName.trim().toLowerCase();
        final productIds = products.map((doc) => doc.id).toSet();
        final productNames = products.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['machine']?.toString().trim().toLowerCase() ?? '';
        }).toSet();
        final productPhones = products.map((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return FirebaseService.phoneDigits(
            data['agentPhone']?.toString() ?? '',
          );
        }).toSet();
        final earnedBookings = (snapshot.data?.docs ?? []).where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final agentName =
              data['agentName']?.toString().trim().toLowerCase() ?? '';
          final bookingAgentId = data['agentId']?.toString() ?? '';
          final bookingMachine =
              data['machine']?.toString().trim().toLowerCase() ?? '';
          final bookingAgentPhone = FirebaseService.phoneDigits(
            data['agentPhone']?.toString() ?? '',
          );
          final belongsToAgent = myPhone.isEmpty ||
              productIds.contains(bookingAgentId) ||
              productNames.contains(bookingMachine) ||
              productPhones.contains(bookingAgentPhone) ||
              samePhone(data['agentOwnerId'], myPhone) ||
              samePhone(data['agentPhone'], myPhone) ||
              samePhone(data['vendorPhone'], myPhone) ||
              (myName.isNotEmpty && agentName == myName);
          if (!belongsToAgent) return false;

          final payment = data['paymentStatus']?.toString() ?? '';
          final status = data['status']?.toString() ?? '';
          return payment == 'Paid' ||
              payment == 'Received' ||
              status == 'Completed';
        }).toList();
        final earnings = earnedBookings.fold<double>(0, (sum, doc) {
          final data = doc.data() as Map<String, dynamic>;
          final price =
              (data['price'] is num) ? (data['price'] as num).toDouble() : 0.0;
          return sum + price;
        });

        return InkWell(
          borderRadius: BorderRadius.circular(10),
          onTap: () => showEarningDetails(earnedBookings),
          child: _summaryCard(
            t("Earnings", "வருமானம்"),
            "Rs.${earnings.toStringAsFixed(0)}",
            Colors.blue,
          ),
        );
      },
    );
  }

  void showEarningDetails(List<QueryDocumentSnapshot> bookings) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) {
        if (bookings.isEmpty) {
          return Padding(
            padding: const EdgeInsets.all(18),
            child: Text(t("No paid earnings yet", "இன்னும் paid earnings இல்லை")),
          );
        }
        return ListView.builder(
          padding: const EdgeInsets.all(10),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final data = bookings[index].data() as Map<String, dynamic>;
            return ListTile(
              leading: const Icon(Icons.currency_rupee, color: Colors.green),
              title: Text(field(data, 'machine', 'machineTa')),
              subtitle: Text(
                "${t("User", "பயனர்")}: ${data['userName'] ?? ''}\n"
                "${t("Phone", "போன்")}: ${data['userPhone'] ?? ''}\n"
                "${t("Payment", "பணம்")}: ${AppStore.displayStatus((data['paymentStatus'] ?? '').toString())}",
              ),
              trailing: Text(
                "Rs.${data['price'] ?? 0}",
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              isThreeLine: true,
            );
          },
        );
      },
    );
  }

  Widget productsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('agents').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final rawDocs = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final machine = data['machine']?.toString().toLowerCase() ?? '';
          final myPhone = AppStore.currentUserPhone.trim();
          final owner = data['ownerId']?.toString() ?? '';
          final phone = data['agentPhone']?.toString().replaceAll(RegExp(r'[^0-9]'), '') ?? '';
          final mine = myPhone.isEmpty || owner.isEmpty || owner == myPhone || phone == myPhone;
          return !machine.contains('thresher') && mine;
        }).toList();
        final seen = <String>{};
        final docs = rawDocs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final key = (data['machine']?.toString().trim().toLowerCase() ??
                  doc.id.toLowerCase())
              .replaceAll(RegExp(r'\s+'), ' ');
          if (seen.contains(key)) return false;
          seen.add(key);
          return true;
        }).toList();
        if (docs.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(t("No machines added yet", "à®‡à®©à¯à®©à¯à®®à¯ à®‡à®¯à®¨à¯à®¤à®¿à®°à®®à¯ à®šà¯‡à®°à¯à®•à¯à®•à®µà®¿à®²à¯à®²à¯ˆ")),
                  const SizedBox(height: 10),
                  ElevatedButton.icon(
                    onPressed: addMachine,
                    icon: const Icon(Icons.add),
                    label: Text(t("Add Machine", "à®‡à®¯à®¨à¯à®¤à®¿à®°à®®à¯ à®šà¯‡à®°à¯")),
                  ),
                ],
              ),
            ),
          );
        }
        final activeProducts = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final stock =
              (data['stock'] is num) ? (data['stock'] as num).toInt() : 0;
          return data['available'] == true && stock > 0;
        }).length;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                children: [
                  Expanded(
                    child: agentEarningsCard(docs),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _summaryCard(
                      t("Active Products", "à®•à®¿à®Ÿà¯ˆà®•à¯à®•à¯à®®à¯ à®ªà¯Šà®°à¯à®Ÿà¯à®•à®³à¯"),
                      "$activeProducts",
                      Colors.green,
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final doc = docs[i];
                  final data = doc.data() as Map<String, dynamic>;
                  final stock = (data['stock'] is num)
                      ? (data['stock'] as num).toInt()
                      : 0;
                  final available = data['available'] == true && stock > 0;

                  return Card(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    child: Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: machineImage(data),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  field(data, 'machine', 'machineTa'),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${t("Rate", "à®•à®Ÿà¯à®Ÿà®£à®®à¯")}: Rs.${data['hourlyRate'] ?? 0}/hr",
                                ),
                                Row(
                                  children: [
                                    Text("${t("Stock", "à®¸à¯à®Ÿà®¾à®•à¯")}: "),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => changeStock(doc.id, -1),
                                      icon: const Icon(
                                        Icons.remove_circle_outline,
                                      ),
                                    ),
                                    Text(
                                      "$stock",
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    IconButton(
                                      visualDensity: VisualDensity.compact,
                                      onPressed: () => changeStock(doc.id, 1),
                                      icon: const Icon(Icons.add_circle_outline),
                                    ),
                                  ],
                                ),
                                SwitchListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  value: available,
                                  onChanged: stock <= 0
                                      ? null
                                      : (value) => changeAvailability(
                                            doc.id,
                                            value,
                                          ),
                                  title: Text(
                                    available
                                        ? t("Available", "à®•à®¿à®Ÿà¯ˆà®•à¯à®•à¯à®®à¯")
                                        : t("Unavailable", "à®•à®¿à®Ÿà¯ˆà®•à¯à®•à®µà®¿à®²à¯à®²à¯ˆ"),
                                    style: TextStyle(
                                      color:
                                          available ? Colors.green : Colors.red,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget bookingsTab() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .orderBy('createdAt', descending: true)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data!.docs;
        final earnings = bookings.fold<double>(0, (sum, doc) {
          final data = doc.data() as Map<String, dynamic>;
          final payment = data['paymentStatus']?.toString() ?? '';
          final status = data['status']?.toString() ?? '';
          final price = (data['price'] is num)
              ? (data['price'] as num).toDouble()
              : 0.0;
          return (payment == 'Paid' ||
                  payment == 'Received' ||
                  status == 'Completed')
              ? sum + price
              : sum;
        });

        if (bookings.isEmpty) {
          return Center(child: Text(t("No bookings yet", "à®‡à®©à¯à®©à¯à®®à¯ booking à®‡à®²à¯à®²à¯ˆ")));
        }

        return ListView.builder(
          itemCount: bookings.length + 1,
          itemBuilder: (context, index) {
            if (index == 0) {
              return Padding(
                padding: const EdgeInsets.all(10),
                child: _summaryCard(
                  t("Earnings", "à®µà®°à¯à®®à®¾à®©à®®à¯"),
                  "Rs.${earnings.toStringAsFixed(0)}",
                  Colors.blue,
                ),
              );
            }

            final doc = bookings[index - 1];
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status']?.toString() ?? 'Pending';

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 18),
                      child: Icon(Icons.book_online, color: Colors.green, size: 30),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            field(data, 'machine', 'machineTa'),
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text("${t("User", "à®ªà®¯à®©à®°à¯")}: ${data['userName'] ?? ''}"),
                          Text("${t("Phone", "à®ªà¯‹à®©à¯")}: ${data['userPhone'] ?? ''}"),
                          Text("${t("Amount", "à®¤à¯Šà®•à¯ˆ")}: Rs.${data['price'] ?? 0}"),
                          Text("${t("Status", "நிலை")}: ${AppStore.displayStatus(status)}"),
                          if ((data['usageTime']?.toString() ?? '').isNotEmpty)
                            Text("${t("Usage time", "à®ªà®¯à®©à¯à®ªà®¾à®Ÿà¯à®Ÿà¯ à®¨à¯‡à®°à®®à¯")}: ${data['usageTime']}"),
                          if ((data['workLocation']?.toString() ?? '').isNotEmpty)
                            Text("${t("Location", "à®‡à®Ÿà®®à¯")}: ${data['workLocation']}"),
                          if ((data['deliveryNote']?.toString() ?? '').isNotEmpty)
                            Text("${t("Route note", "à®µà®´à®¿ à®•à¯à®±à®¿à®ªà¯à®ªà¯")}: ${data['deliveryNote']}"),
                          Text("${t("Method", "à®®à¯à®±à¯ˆ")}: ${data['paymentMethod'] ?? 'COD'}"),
                          Text("${t("Payment", "பணம்")}: ${AppStore.displayStatus((data['paymentStatus'] ?? 'Pending').toString())}"),
                          Text("${t("Refund", "திருப்பி பணம்")}: ${AppStore.displayStatus((data['refundStatus'] ?? 'Not Requested').toString())}"),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    SizedBox(
                      width: 150,
                      child: Wrap(
                        alignment: WrapAlignment.end,
                        spacing: 6,
                        runSpacing: 6,
                        children: [
                          if (status == 'Pending') ...[
                            IconButton(
                              tooltip: t("Accept", "à®à®±à¯à®•à®µà¯à®®à¯"),
                              icon: const Icon(Icons.check_circle, color: Colors.green),
                              onPressed: () => updateBookingAndNotify(
                                bookingId: doc.id,
                                status: 'Accepted',
                              ),
                            ),
                            IconButton(
                              tooltip: t("Reject", "à®¨à®¿à®°à®¾à®•à®°à®¿"),
                              icon: const Icon(Icons.cancel, color: Colors.red),
                              onPressed: () => updateBookingAndNotify(
                                bookingId: doc.id,
                                status: 'Rejected',
                              ),
                            ),
                          ],
                          if (status == 'Accepted')
                            IconButton(
                              tooltip: t("Complete", "à®®à¯à®Ÿà®¿à®•à¯à®•à®µà¯à®®à¯"),
                              icon: const Icon(Icons.done_all, color: Colors.blue),
                              onPressed: () => updateBookingAndNotify(
                                bookingId: doc.id,
                                complete: true,
                              ),
                            ),
                          IconButton(
                            tooltip: t("Payment paid", "à®ªà®£à®®à¯ à®šà¯†à®²à¯à®¤à¯à®¤à®ªà¯à®ªà®Ÿà¯à®Ÿà®¤à¯"),
                            icon: const Icon(Icons.payments, color: Colors.green),
                            onPressed: () => updateBookingAndNotify(
                              bookingId: doc.id,
                              paymentStatus: 'Paid',
                            ),
                          ),
                          IconButton(
                            tooltip: t("Payment pending", "à®ªà®£à®®à¯ à®¨à®¿à®²à¯à®µà¯ˆ"),
                            icon: const Icon(Icons.pending_actions, color: Colors.orange),
                            onPressed: () => updateBookingAndNotify(
                              bookingId: doc.id,
                              paymentStatus: 'Pending',
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
        return false;
      },
      child: DefaultTabController(
        length: 2,
        child: Scaffold(
        appBar: AppBar(
          title: Text(t("Agent Dashboard", "à®®à¯à®•à®µà®°à¯ à®Ÿà®¾à®·à¯à®ªà¯‹à®°à¯à®Ÿà¯")),
          backgroundColor: Colors.blueGrey,
          actions: [
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfilePage()),
                );
              },
            ),
            IconButton(
              icon: const Icon(Icons.logout),
              onPressed: () {
                Navigator.pushAndRemoveUntil(
                  context,
                  MaterialPageRoute(builder: (_) => const LoginScreen()),
                  (route) => false,
                );
              },
            ),
          ],
          bottom: TabBar(
            tabs: [
              Tab(text: t("Machines", "à®‡à®¯à®¨à¯à®¤à®¿à®°à®™à¯à®•à®³à¯")),
              Tab(text: t("Bookings", "à®ªà®¤à®¿à®µà¯à®•à®³à¯")),
            ],
          ),
        ),
          body: TabBarView(
          children: [
            productsTab(),
            bookingsTab(),
          ],
        ),
        floatingActionButton: FloatingActionButton.extended(
          onPressed: addMachine,
          icon: const Icon(Icons.add),
          label: Text(t("Machine", "à®‡à®¯à®¨à¯à®¤à®¿à®°à®®à¯")),
          backgroundColor: Colors.green,
        ),
        ),
      ),
    );
  }

  Widget _summaryCard(String title, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(title, style: const TextStyle(fontSize: 12)),
          Text(
            value,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}

