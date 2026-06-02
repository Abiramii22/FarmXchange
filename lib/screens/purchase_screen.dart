import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../services/firebase_service.dart';

class PurchaseScreen extends StatelessWidget {
  const PurchaseScreen({super.key});

  String t(String en, String ta) => AppStore.tr(en, ta);

  Future<void> addReview(BuildContext context, String bookingId) async {
    double rating = 4;
    final review = TextEditingController();

    final saved = await showDialog<bool>(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: Text(t("Review & Rating", "மதிப்புரை & மதிப்பீடு")),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final value = i + 1;
                      return IconButton(
                        icon: Icon(
                          value <= rating ? Icons.star : Icons.star_border,
                          color: Colors.orange,
                        ),
                        onPressed: () {
                          setDialogState(() => rating = value.toDouble());
                        },
                      );
                    }),
                  ),
                  TextField(
                    controller: review,
                    maxLines: 3,
                    decoration: InputDecoration(
                      hintText: t("Write your review", "உங்கள் மதிப்புரையை எழுதவும்"),
                    ),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(t("Back", "பின்")),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(t("Save", "சேமி")),
                ),
              ],
            );
          },
        );
      },
    );

    if (saved != true) return;
    await FirebaseFirestore.instance.collection('bookings').doc(bookingId).set({
      'rating': rating,
      'review': review.text.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseService.currentUserId();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('bookings').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final purchases = snapshot.data!.docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          return data['userId']?.toString() == userId;
        }).toList();

        if (purchases.isEmpty) {
          return Center(
            child: Text(
              t("No Purchases Yet", "இன்னும் வாங்கியவை இல்லை"),
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          itemCount: purchases.length,
          itemBuilder: (context, i) {
            final doc = purchases[i];
            final data = doc.data() as Map<String, dynamic>;
            final image = data['image']?.toString() ?? '';
            final machine = AppStore.displayMachine(data);
            final status = AppStore.displayStatus(
              (data['status'] ?? 'Pending').toString(),
            );
            final payment = AppStore.displayStatus(
              (data['paymentStatus'] ?? 'Pending').toString(),
            );

            return Card(
              margin: const EdgeInsets.all(10),
              elevation: 3,
              child: ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: image.startsWith('http')
                      ? Image.network(image, width: 48, height: 48, fit: BoxFit.cover)
                      : Image.asset(
                          image.isEmpty ? 'assets/logo.png' : image,
                          width: 48,
                          height: 48,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) =>
                              Image.asset('assets/logo.png', width: 48, height: 48),
                        ),
                ),
                title: Text(
                  machine,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${t("Agent", "முகவர்")}: ${data['agentName'] ?? ''}"),
                    Text("${t("Contact", "தொடர்பு")}: ${data['agentPhone'] ?? ''}"),
                    Text("${t("Price", "விலை")}: Rs.${data['price'] ?? 0}"),
                    Text("${t("Status", "நிலை")}: $status"),
                    Text("${t("Payment", "பணம்")}: $payment"),
                    if ((data['rating'] is num) && (data['rating'] as num) > 0)
                      Text("${t("Your rating", "உங்கள் மதிப்பீடு")}: ${data['rating']}/5"),
                    if ((data['review']?.toString() ?? '').isNotEmpty)
                      Text(data['review'].toString()),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.rate_review, color: Colors.orange),
                  onPressed: () => addReview(context, doc.id),
                  tooltip: t("Review", "மதிப்புரை"),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
