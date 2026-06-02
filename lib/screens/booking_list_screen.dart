import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../services/firebase_service.dart';
import '../services/whatsapp_service.dart';

class BookingListScreen extends StatelessWidget {
  const BookingListScreen({super.key});

  String t(String en, String ta) => AppStore.tr(en, ta);

  List<Map<String, String>> cancelReasons() {
    return [
      {'en': 'Machine quality is not good', 'ta': 'இயந்திரத்தின் தரம் சரி இல்லை'},
      {'en': 'Expected HP is not available', 'ta': 'எதிர்பார்த்த HP இல்லை'},
      {'en': 'HP is higher than expected', 'ta': 'எதிர்பார்த்ததை விட HP அதிகமாக உள்ளது'},
      {'en': 'Rate is high', 'ta': 'விலை அதிகமாக உள்ளது'},
      {'en': 'Machine condition is not good', 'ta': 'இயந்திரத்தின் நிலை சரி இல்லை'},
      {'en': 'Booked by mistake', 'ta': 'தவறுதலாக பதிவு செய்துவிட்டேன்'},
      {'en': 'I do not need this product now', 'ta': 'இப்போது இந்த பொருள் எனக்கு தேவையில்லை'},
      {'en': 'Others', 'ta': 'மற்றவை'},
    ];
  }

  String money(dynamic value) {
    final amount =
        value is num ? value.toDouble() : double.tryParse('$value') ?? 0;
    return amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2);
  }

  String displayReason(String value) {
    final cleaned = AppStore.cleanTamil(value.trim());
    if (!AppStore.isTamil || cleaned.isEmpty) return cleaned;
    for (final reason in cancelReasons()) {
      if (cleaned.toLowerCase() == reason['en']!.toLowerCase()) {
        return reason['ta']!;
      }
    }
    if (cleaned.startsWith('Others:')) {
      return cleaned.replaceFirst('Others:', 'மற்றவை:');
    }
    return cleaned;
  }

  String imageFor(Map<String, dynamic> data) {
    final raw = data['image']?.toString() ?? '';
    final machine = data['machine']?.toString().toLowerCase() ?? '';
    if (raw.isNotEmpty &&
        raw != 'assets/logo.png' &&
        !raw.toLowerCase().contains('logo')) {
      return raw;
    }
    if (machine.contains('tractor')) return 'assets/images/tractor.jpg';
    if (machine.contains('baler')) return 'assets/images/baler.jpg';
    if (machine.contains('seed')) return 'assets/images/seed_drill.jpg';
    if (machine.contains('plough')) return 'assets/images/plough.jpg';
    if (machine.contains('harvester')) return 'assets/images/harvester.jpg';
    if (machine.contains('sprayer')) return 'assets/images/Sprayer.jpg';
    if (machine.contains('tiller')) return 'assets/images/power_tiller.jpg';
    return raw;
  }

  Future<void> cancelBooking(
    BuildContext context,
    QueryDocumentSnapshot booking,
  ) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final controller = TextEditingController();
        final reasons = cancelReasons();
        var selected = reasons.first;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            final isOther = selected['en'] == 'Others';
            return AlertDialog(
              title: Text(t("Cancel Reason", "ரத்து காரணம்")),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    ...reasons.map((reason) {
                      return RadioListTile<Map<String, String>>(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        value: reason,
                        groupValue: selected,
                        onChanged: (value) {
                          if (value == null) return;
                          setDialogState(() => selected = value);
                        },
                        title: Text(t(reason['en']!, reason['ta']!)),
                      );
                    }),
                    if (isOther) ...[
                      const SizedBox(height: 8),
                      TextField(
                        controller: controller,
                        minLines: 1,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: t("Other reason", "மற்ற காரணம்"),
                          hintText: t(
                            "Type cancellation reason",
                            "ரத்து காரணத்தை எழுதவும்",
                          ),
                          border: const OutlineInputBorder(),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(t("Back", "பின்")),
                ),
                ElevatedButton(
                  onPressed: () {
                    final custom = controller.text.trim();
                    if (isOther && custom.isEmpty) return;
                    final reasonText = isOther
                        ? '${t("Others", "மற்றவை")}: $custom'
                        : t(selected['en']!, selected['ta']!);
                    Navigator.pop(context, reasonText);
                  },
                  child: Text(t("Submit", "சமர்ப்பி")),
                ),
              ],
            );
          },
        );
      },
    );

    if (reason == null || reason.isEmpty) return;
    final data = booking.data() as Map<String, dynamic>;
    final price = (data['price'] is num) ? (data['price'] as num).toDouble() : 0;
    final refund = price * 0.8;
    final method = data['paymentMethod']?.toString() ?? 'COD';
    final paidOnline = method == 'Razorpay' &&
        (data['paymentStatus']?.toString() == 'Paid' ||
            data['paymentStatus']?.toString() == 'Received');

    if (paidOnline) {
      await FirebaseService.requestRazorpayRefund(
        bookingId: booking.id,
        amount: refund,
        reason: reason,
      );
    } else {
      await FirebaseFirestore.instance.collection('bookings').doc(booking.id).set({
        'status': 'Cancelled',
        'refundStatus': method == 'COD' ? 'Not Applicable' : 'Refunded',
        'cancelReason': reason,
        'refundAmount': method == 'COD' ? 0 : refund,
        'deductionAmount': method == 'COD' ? 0 : price - refund,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }

    final latest = {
      ...data,
      'status': 'Cancelled',
      'refundStatus': paidOnline
          ? 'Processing'
          : (method == 'COD' ? 'Not Applicable' : 'Refunded'),
      'cancelReason': reason,
      'refundAmount': paidOnline || method != 'COD' ? refund : 0,
      'deductionAmount': paidOnline || method != 'COD' ? price - refund : 0,
    };
    final message = WhatsAppService.statusMessage(latest);
    await WhatsAppService.openMessage(
      phone: latest['userPhone']?.toString() ?? '',
      message: message,
    );
    await WhatsAppService.openMessage(
      phone: latest['agentPhone']?.toString() ?? '',
      message: message,
    );
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseService.currentUserId();

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('bookings')
          .where('userId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final bookings = snapshot.data!.docs;
        if (bookings.isEmpty) {
          return Center(
            child: Text(
              t("No Bookings Yet", "இன்னும் பதிவுகள் இல்லை"),
              style: const TextStyle(fontSize: 18, color: Colors.grey),
            ),
          );
        }

        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 6),
          itemCount: bookings.length,
          itemBuilder: (context, index) {
            final doc = bookings[index];
            final data = doc.data() as Map<String, dynamic>;
            final status = data['status']?.toString() ?? 'Pending';
            final machine = AppStore.displayMachine(data);
            final statusText = AppStore.displayStatus(status);
            final paymentText = AppStore.displayStatus(
              (data['paymentStatus'] ?? 'Pending').toString(),
            );
            final refundText = AppStore.displayStatus(
              (data['refundStatus'] ?? 'Not Requested').toString(),
            );
            final image = imageFor(data);

            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
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
                          errorBuilder: (_, __, ___) => Image.asset(
                            'assets/logo.png',
                            width: 48,
                            height: 48,
                          ),
                        ),
                ),
                title: Text(
                  machine,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 5),
                    Text("${t("Amount", "தொகை")}: Rs.${money(data['price'])}"),
                    Text("${t("Status", "நிலை")}: $statusText"),
                    Text("${t("Payment", "பணம்")}: $paymentText"),
                    Text("${t("Refund", "திருப்பி பணம்")}: $refundText"),
                    if (status == "Cancelled") ...[
                      Text("${t("Reason", "காரணம்")}: ${displayReason((data['cancelReason'] ?? '').toString())}"),
                      Text(
                        "${t("Refund", "திருப்பி பணம்")}: Rs.${money(data['refundAmount'])}",
                        style: const TextStyle(color: Colors.blue),
                      ),
                      Text(
                        "${t("Deduction", "பிடித்தம்")}: Rs.${money(data['deductionAmount'])}",
                        style: const TextStyle(color: Colors.red),
                      ),
                    ],
                  ],
                ),
                trailing: status == "Cancelled"
                    ? Text(t("Cancelled", "à®°à®¤à¯à®¤à¯"))
                    : TextButton(
                        onPressed: () => cancelBooking(context, doc),
                        child: Text(
                          t("Cancel", "à®°à®¤à¯à®¤à¯"),
                          style: const TextStyle(color: Colors.red),
                        ),
                      ),
              ),
            );
          },
        );
      },
    );
  }
}
