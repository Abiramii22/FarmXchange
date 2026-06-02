import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../data/app_store.dart';
import 'login_screen.dart';
import 'profile_page.dart';

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});

  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> {
  bool showMoreRecent = false;

  String t(String en, String ta) => AppStore.tr(en, ta);

  String bookingMachine(Map<String, dynamic> data) {
    return AppStore.displayMachine(data);
  }

  String field(Map<String, dynamic> data, String enKey, String taKey) {
    final key = AppStore.isTamil ? taKey : enKey;
    final value = (data[key] ?? data[enKey] ?? '').toString();
    if (enKey == 'machine') return AppStore.machineName(value);
    return AppStore.isTamil ? AppStore.cleanTamil(value) : value;
  }

  List<_DemandItem> demandItems(List<QueryDocumentSnapshot> bookings) {
    final counts = <String, int>{};
    for (final doc in bookings) {
      final data = doc.data() as Map<String, dynamic>;
      final machine = bookingMachine(data).trim();
      if (machine.isEmpty) continue;
      counts[machine] = (counts[machine] ?? 0) + 1;
    }
    final items = counts.entries
        .map((entry) => _DemandItem(entry.key, entry.value))
        .toList()
      ..sort((a, b) => b.count.compareTo(a.count));
    return items.take(5).toList();
  }

  List<QueryDocumentSnapshot> uniqueProducts(List<QueryDocumentSnapshot> agents) {
    final seen = <String>{};
    return agents.where((doc) {
      final data = doc.data() as Map<String, dynamic>;
      final key = (data['machine']?.toString().trim().toLowerCase() ??
              doc.id.toLowerCase())
          .replaceAll(RegExp(r'\s+'), ' ');
      if (key.isEmpty || seen.contains(key)) return false;
      seen.add(key);
      return true;
    }).toList();
  }

  void openBookingDetails(String title, List<QueryDocumentSnapshot> docs) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AdminDetailScreen(
          title: title,
          docs: docs,
          itemBuilder: (doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ListTile(
              leading: const Icon(Icons.book_online, color: Colors.green),
              title: Text(bookingMachine(data)),
              subtitle: Text(
                '${t("User", "பயனர்")}: ${data['userName'] ?? data['user'] ?? ''}\n'
                '${t("Phone", "தொலைபேசி")}: ${data['userPhone'] ?? ''}\n'
                '${t("Agent", "ஏஜெண்ட்")}: ${data['agentName'] ?? ''} (${data['agentPhone'] ?? ''})\n'
                '${t("Method", "முறை")}: ${data['paymentMethod'] ?? 'COD'} | ${t("Amount", "தொகை")}: Rs.${data['price'] ?? 0}\n'
                '${t("Status", "நிலை")}: ${AppStore.displayStatus((data['status'] ?? 'Pending').toString())} | ${t("Payment", "கட்டணம்")}: ${AppStore.displayStatus((data['paymentStatus'] ?? 'Pending').toString())} | ${t("Refund", "பணதிருப்பு")}: ${AppStore.displayStatus((data['refundStatus'] ?? 'Not Requested').toString())}',
              ),
              isThreeLine: true,
            );
          },
        ),
      ),
    );
  }

  void openProductDetails(List<QueryDocumentSnapshot> docs) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => _AdminDetailScreen(
          title: t('Products', 'பொருட்கள்'),
          docs: docs,
          itemBuilder: (doc) {
            final data = doc.data() as Map<String, dynamic>;
            return ListTile(
              leading: const Icon(Icons.agriculture, color: Colors.green),
              title: Text(field(data, 'machine', 'machineTa')),
              subtitle: Text(
                '${t('Agent', 'முகவர்')}: ${data['agentName'] ?? ''}\n'
                '${t('Phone', 'தொலைபேசி')}: ${data['agentPhone'] ?? ''}\n'
                '${t('Stock', 'கையிருப்பு')}: ${data['stock'] ?? 0} | ${t('Available', 'கிடைக்கும்')}: ${data['available'] == true ? t('Yes', 'ஆம்') : t('No', 'இல்லை')}',
              ),
              isThreeLine: true,
            );
          },
        ),
      ),
    );
  }

  void openHelpRequests() {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const _HelpRequestDetailScreen()),
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
      child: Scaffold(
        appBar: AppBar(
          title: Text(t('Admin Control Panel', 'நிர்வாக கட்டுப்பாட்டு பலகம்')),
          backgroundColor: const Color(0xFF4CAF50),
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
        ),
        body: StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('bookings')
              .orderBy('createdAt', descending: true)
              .snapshots(),
          builder: (context, bookingSnapshot) {
            return StreamBuilder<QuerySnapshot>(
              stream:
                  FirebaseFirestore.instance.collection('agents').snapshots(),
              builder: (context, agentSnapshot) {
                if (!bookingSnapshot.hasData || !agentSnapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }

                final bookings = bookingSnapshot.data!.docs;
                final agents = uniqueProducts(agentSnapshot.data!.docs);
                final revenue = bookings.fold<double>(0, (sum, doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final status = data['paymentStatus']?.toString() ?? '';
                  final price = (data['price'] is num)
                      ? (data['price'] as num).toDouble()
                      : 0;
                  return status == 'Paid' || status == 'Received'
                      ? sum + price
                      : sum;
                });
                final pending = bookings.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  return data['status']?.toString() == 'Pending';
                }).length;
                final refunds = bookings.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final refundStatus = data['refundStatus']?.toString() ?? '';
                  return data['paymentStatus']?.toString() == 'Refunded' ||
                      refundStatus == 'Refunded' ||
                      refundStatus == 'Processing' ||
                      refundStatus == 'Refund Failed';
                }).length;
                final seenRecent = <String>{};
                final recentBookings = bookings.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final key = bookingMachine(data).trim().toLowerCase();
                  if (key.isEmpty || seenRecent.contains(key)) return false;
                  seenRecent.add(key);
                  return true;
                }).take(3).toList();
                final demands = demandItems(bookings);

                return ListView(
                  padding: const EdgeInsets.all(12),
                  children: [
                    GridView.count(
                      crossAxisCount: 2,
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      childAspectRatio: 1.35,
                      children: [
                        adminCard(
                          t('Total Bookings', 'மொத்த பதிவுகள்'),
                          '${bookings.length}',
                          Icons.book_online,
                          onTap: () => openBookingDetails(
                            t('Total Bookings', 'மொத்த பதிவுகள்'),
                            bookings,
                          ),
                        ),
                        adminCard(
                          t('Revenue', 'வருவாய்'),
                          'Rs.${revenue.toStringAsFixed(0)}',
                          Icons.currency_rupee,
                          onTap: () => openBookingDetails(
                            t('Revenue', 'வருவாய்'),
                            bookings.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final status =
                                  data['paymentStatus']?.toString() ?? '';
                              return status == 'Paid' || status == 'Received';
                            }).toList(),
                          ),
                        ),
                        adminCard(t('Products', 'பொருட்கள்'), '${agents.length}',
                            Icons.agriculture,
                            onTap: () => openProductDetails(agents)),
                        adminCard(
                          t('Pending', 'நிலுவை'),
                          '$pending',
                          Icons.pending_actions,
                          onTap: () => openBookingDetails(
                            t('Pending', 'நிலுவை'),
                            bookings.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              return data['status']?.toString() == 'Pending';
                            }).toList(),
                          ),
                        ),
                        adminCard(
                          t('Refund Issues', 'பணம் திருப்புதல் சிக்கல்கள்'),
                          '$refunds',
                          Icons.replay_circle_filled,
                          onTap: () => openBookingDetails(
                            t('Refund Issues', 'பணம் திருப்புதல் சிக்கல்கள்'),
                            bookings.where((doc) {
                              final data = doc.data() as Map<String, dynamic>;
                              final refundStatus = data['refundStatus']?.toString() ?? '';
                              return data['paymentStatus']?.toString() ==
                                      'Refunded' ||
                                  refundStatus == 'Refunded' ||
                                  refundStatus == 'Processing' ||
                                  refundStatus == 'Refund Failed';
                            }).toList(),
                          ),
                        ),
                        StreamBuilder<QuerySnapshot>(
                          stream: FirebaseFirestore.instance
                              .collection('helpRequests')
                              .snapshots(),
                          builder: (context, helpSnapshot) {
                            final count = helpSnapshot.data?.docs.length ?? 0;
                            return adminCard(
                              t('Help Requests', 'உதவி கோரிக்கைகள்'),
                              '$count',
                              Icons.support_agent,
                              onTap: openHelpRequests,
                            );
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    _sectionTitle(t('Demand Chart', 'தேவை வரைபடம்')),
                    demandChart(demands),
                    const SizedBox(height: 15),
                    Row(
                      children: [
                        Expanded(
                          child: _sectionTitle(
                            t('Recent Bookings', 'சமீபத்திய பதிவுகள்'),
                          ),
                        ),
                        if (false)
                          TextButton(
                            onPressed: () {
                              setState(() => showMoreRecent = !showMoreRecent);
                            },
                            child: Text(
                              showMoreRecent
                                  ? t('Show Less', 'Show Less')
                                  : t('Show More', 'Show More'),
                            ),
                          ),
                      ],
                    ),
                    if (recentBookings.isEmpty)
                      emptyText(t('No recent bookings', 'சமீபத்திய பதிவுகள் இல்லை'))
                    else
                      ...recentBookings.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return Card(
                          child: ListTile(
                            leading: const Icon(Icons.agriculture),
                            title: Text(bookingMachine(data)),
                            subtitle: Text(
                              '${data['userName'] ?? data['user'] ?? ''} | ${data['paymentMethod'] ?? 'COD'} | Rs.${data['price'] ?? 0} | ${AppStore.displayStatus((data['status'] ?? 'Pending').toString())} | ${AppStore.displayStatus((data['paymentStatus'] ?? 'Pending').toString())}',
                            ),
                          ),
                        );
                      }),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }

  Widget demandChart(List<_DemandItem> items) {
    if (items.isEmpty) return emptyText(t('No demand yet', 'தேவை இன்னும் இல்லை'));
    final maxCount = items.first.count <= 0 ? 1 : items.first.count;

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: items.map((item) {
            final factor = item.count / maxCount;
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 7),
              child: Row(
                children: [
                  SizedBox(
                    width: 92,
                    child: Text(
                      item.machine,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        minHeight: 18,
                        value: factor,
                        backgroundColor: Colors.green.shade50,
                        valueColor: AlwaysStoppedAnimation<Color>(
                          Colors.green.shade600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${item.count}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget emptyText(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Text(text, style: const TextStyle(color: Colors.grey)),
    );
  }

  Widget _sectionTitle(String title) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget adminCard(String title, String value, IconData icon, {VoidCallback? onTap}) {
    return Card(
      elevation: 3,
      color: const Color(0xFFF1F8E9),
      child: InkWell(
        onTap: onTap,
        child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 30, color: Colors.green),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
            ),
            Text(
              value,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      ),
    );
  }
}

class _AdminDetailScreen extends StatelessWidget {
  final String title;
  final List<QueryDocumentSnapshot> docs;
  final Widget Function(QueryDocumentSnapshot doc) itemBuilder;

  const _AdminDetailScreen({
    required this.title,
    required this.docs,
    required this.itemBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title), backgroundColor: const Color(0xFF4CAF50)),
      body: docs.isEmpty
          ? Center(child: Text(AppStore.tr('No records', 'பதிவுகள் இல்லை')))
          : ListView.builder(
              itemCount: docs.length,
              itemBuilder: (context, index) => Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: itemBuilder(docs[index]),
              ),
            ),
    );
  }
}

class _HelpRequestDetailScreen extends StatelessWidget {
  const _HelpRequestDetailScreen();

  String dialPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    final last10 = digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
    if (last10.length == 10) return '+91$last10';
    return '+$digits';
  }

  Future<void> callUser(String phone) async {
    final dial = dialPhone(phone);
    if (dial.isEmpty) return;
    final uri = Uri(scheme: 'tel', path: dial);
    await launchUrl(uri);
  }
  Future<void> updateHelpStatus(String id, String status) async {
    await FirebaseFirestore.instance.collection('helpRequests').doc(id).set({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStore.tr('Help Requests', 'உதவி கோரிக்கைகள்')),
        backgroundColor: const Color(0xFF4CAF50),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('helpRequests')
            .orderBy('createdAt', descending: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Text(AppStore.tr('No help requests', 'உதவி கோரிக்கைகள் இல்லை')),
            );
          }
          return ListView.builder(
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final phone = data['userPhone']?.toString() ?? '';
              final status = data['status']?.toString() ?? 'Open';

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.support_agent, color: Colors.green),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              AppStore.tr(
                                data['issueType']?.toString() ?? 'Help',
                                data['issueType']?.toString() ?? 'உதவி',
                              ),
                              style: const TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ),
                          Chip(label: Text(AppStore.displayStatus(status))),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text('${AppStore.tr('User', 'பயனர்')}: ${data['userName'] ?? ''}'),
                      Text('${AppStore.tr('Phone', 'தொலைபேசி')}: $phone'),
                      if ((data['bookingId']?.toString() ?? '').isNotEmpty)
                        Text('${AppStore.tr('Booking', 'பதிவு')}: ${data['bookingId']}'),
                      Text('${data['message'] ?? ''}'),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        children: [
                          ElevatedButton.icon(
                            onPressed: () async {
                              await updateHelpStatus(doc.id, 'Calling');
                              await callUser(phone);
                            },
                            icon: const Icon(Icons.call),
                            label: Text(AppStore.tr('Call', 'அழை')),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.green,
                            ),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => updateHelpStatus(doc.id, 'Rejected'),
                            icon: const Icon(Icons.close, color: Colors.red),
                            label: Text(AppStore.tr('Reject', 'நிராகரி')),
                          ),
                          OutlinedButton.icon(
                            onPressed: () => updateHelpStatus(doc.id, 'Closed'),
                            icon: const Icon(Icons.done),
                            label: Text(AppStore.tr('Close', 'மூடு')),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
class _DemandItem {
  final String machine;
  final int count;

  _DemandItem(this.machine, this.count);
}

