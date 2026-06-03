import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/booking.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';
import '../services/razorpay_payment_service.dart';
import '../services/whatsapp_service.dart';

class BookingScreen extends StatefulWidget {
  final String? agentId;
  final Map<String, dynamic> agent;

  const BookingScreen({
    super.key,
    required this.agentId,
    required this.agent,
  });

  @override
  State<BookingScreen> createState() => _BookingScreenState();
}

class _BookingScreenState extends State<BookingScreen> {
  final locationController = TextEditingController(
    text: AppStore.currentUserLocation,
  );
  final noteController = TextEditingController();
  DateTime? selectedDate;
  TimeOfDay? selectedTime;
  int durationHours = 1;
  String paymentMethod = 'COD';
  bool loading = false;
  bool gettingLocation = false;
  double? userLat;
  double? userLng;

  @override
  void dispose() {
    locationController.dispose();
    noteController.dispose();
    super.dispose();
  }

  String t(String en, String ta) => AppStore.tr(en, ta);

  String field(String enKey, String taKey) {
    final key = AppStore.isTamil ? taKey : enKey;
    final value = (widget.agent[key] ?? widget.agent[enKey] ?? '').toString();
    if (enKey == 'machine') return AppStore.machineName(value);
    return AppStore.isTamil ? AppStore.cleanTamil(value) : value;
  }

  double number(String key) {
    final value = widget.agent[key];
    if (value is num) return value.toDouble();
    return double.tryParse(value?.toString() ?? '') ?? 0;
  }

  int get stock {
    final value = widget.agent['stock'];
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  double get hourlyRate => number('hourlyRate');
  double get baseDistance => number('distanceKm');
  double get distanceRate => number('distanceRate');

  double get adjustedDistance {
    final location = locationController.text.trim();
    final index = AppStore.locations().indexOf(location);
    final extra = index < 0 ? 0 : index * 1.5;
    return baseDistance + extra;
  }

  double get totalAmount {
    return (hourlyRate * durationHours) + (adjustedDistance * distanceRate);
  }

  String get usageTime {
    final date = selectedDate?.toIso8601String().split('T').first ?? '';
    final time = selectedTime?.format(context) ?? '';
    return '$date $time'.trim();
  }

  Future<void> pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: selectedDate ?? today,
      firstDate: today,
      lastDate: DateTime(2030),
    );
    if (picked == null || !mounted) return;
    setState(() => selectedDate = picked);
  }

  Future<void> pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: selectedTime ?? TimeOfDay.now(),
    );
    if (picked == null || !mounted) return;
    setState(() => selectedTime = picked);
  }

  Future<void> useGps() async {
    setState(() => gettingLocation = true);
    try {
      final pos = await LocationService.currentPosition();
      userLat = pos.latitude;
      userLng = pos.longitude;
      locationController.text =
          '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
      if (mounted) setState(() {});
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t(
              'Turn on location and allow permission',
              'Location on செய்து permission allow செய்யவும்',
            ),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => gettingLocation = false);
    }
  }


  Future<bool> ensureTrackingLocation() async {
    if (userLat != null && userLng != null) return true;
    try {
      final pos = await LocationService.currentPosition();
      userLat = pos.latitude;
      userLng = pos.longitude;
      if (locationController.text.trim().isEmpty) {
        locationController.text =
            '${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}';
      }
      return true;
    } catch (_) {
      if (!mounted) return false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t(
              'Turn on location and allow permission for tracking',
              'Tracking à®•à¯à®•à¯ location on à®šà¯†à®¯à¯à®¤à¯ permission allow à®šà¯†à®¯à¯à®¯à®µà¯à®®à¯',
            ),
          ),
        ),
      );
      return false;
    }
<<<<<<< HEAD
  }

=======
  }

>>>>>>> d314aebe5da72d346a98d707b27d1b0f1d86d376
  Future<void> confirmBooking() async {
    if (selectedDate == null || selectedTime == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(t('Select date and time', 'Date மற்றும் time select செய்யவும்')),
        ),
      );
      return;
    }
    if (locationController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('Enter work location', 'Work location enter செய்யவும்'))),
      );
      return;
    }

<<<<<<< HEAD
    final hasTrackingLocation = await ensureTrackingLocation();
    if (!hasTrackingLocation) return;

    setState(() => loading = true);
=======
    final hasTrackingLocation = await ensureTrackingLocation();
    if (!hasTrackingLocation) return;

    setState(() => loading = true);
>>>>>>> d314aebe5da72d346a98d707b27d1b0f1d86d376
    try {
      final machine = field('machine', 'machineTa');
      late final String bookingId;
      if (widget.agentId == null) {
        bookingId = await FirebaseService.createLocalProductBooking(
          product: widget.agent,
          workLocation: locationController.text.trim(),
          paymentMethod: paymentMethod,
          usageTime: usageTime,
          deliveryNote: noteController.text.trim(),
          userLat: userLat,
          userLng: userLng,
          durationHours: durationHours,
          distanceKm: adjustedDistance,
          distanceRate: distanceRate,
          totalAmount: totalAmount,
        ).timeout(const Duration(seconds: 15));
      } else {
        bookingId = await FirebaseService.createAgentBooking(
          agentId: widget.agentId!,
          agent: widget.agent,
          workLocation: locationController.text.trim(),
          paymentMethod: paymentMethod,
          usageTime: usageTime,
          deliveryNote: noteController.text.trim(),
          userLat: userLat,
          userLng: userLng,
          durationHours: durationHours,
          distanceKm: adjustedDistance,
          distanceRate: distanceRate,
          totalAmount: totalAmount,
        ).timeout(const Duration(seconds: 15));
      }

      var paymentStatus = paymentMethod == 'COD' ? 'COD Pending' : 'Pending';
      if (paymentMethod == 'Razorpay') {
        final razorpay = RazorpayPaymentService();
        try {
          await razorpay.payForBooking(
            bookingId: bookingId,
            amount: totalAmount,
            description: machine,
          );
          paymentStatus = 'Paid';
        } finally {
          razorpay.dispose();
        }
      }

      final booking = Booking(
        id: bookingId,
        productId: widget.agentId ?? widget.agent['id']?.toString() ?? '',
        product: machine,
        user: AppStore.currentUserName,
        userPhone: AppStore.currentUserPhone,
        vendor: widget.agent['agentName']?.toString() ?? '',
        agentPhone: widget.agent['agentPhone']?.toString() ?? '',
        image: widget.agent['image']?.toString() ?? '',
        price: totalAmount,
        hourlyRate: hourlyRate,
        distanceKm: adjustedDistance,
        distanceRate: distanceRate,
        durationHours: durationHours,
        location: locationController.text.trim(),
        date: selectedDate?.toIso8601String().split('T').first ?? '',
        time: selectedTime?.format(context) ?? '',
        status: 'Pending',
        paymentStatus: paymentStatus,
        machineType: widget.agent['machineType']?.toString() ?? 'Medium',
        engineCapacity: widget.agent['engineCapacity']?.toString() ?? 'N/A',
      );

      await WhatsAppService.openMessage(
        phone: booking.agentPhone,
        message: WhatsAppService.agentBookingMessage(booking),
      );
      await Future.delayed(const Duration(seconds: 2));
      await WhatsAppService.openMessage(
        phone: booking.userPhone,
        message: WhatsAppService.userBookingMessage(booking),
<<<<<<< HEAD
      );

      // Payment Done WhatsApp
      if (paymentStatus == 'Paid') {
        final paidMessage = WhatsAppService.paymentDoneMessage({
          'machine': booking.product,
          'price': booking.price,
          'paymentStatus': 'Paid',
          'status': booking.status,
          'userLat': userLat,
          'userLng': userLng,
          'workLocation': booking.location,
          'agentLocation': widget.agent['location'] ?? '',
          'agentPhone': booking.agentPhone,
          'userPhone': booking.userPhone,
        });
        await WhatsAppService.openMessage(phone: booking.userPhone, message: paidMessage);
        await WhatsAppService.openMessage(phone: booking.agentPhone, message: paidMessage);
=======
      );

      // Payment Done WhatsApp
      if (paymentStatus == 'Paid') {
        final paidMessage = WhatsAppService.paymentDoneMessage({
          'machine': booking.product,
          'price': booking.price,
          'paymentStatus': 'Paid',
          'status': booking.status,
          'userLat': userLat,
          'userLng': userLng,
          'workLocation': booking.location,
          'agentLocation': widget.agent['location'] ?? '',
          'agentPhone': booking.agentPhone,
          'userPhone': booking.userPhone,
        });
        await WhatsAppService.openMessage(phone: booking.userPhone, message: paidMessage);
        await WhatsAppService.openMessage(phone: booking.agentPhone, message: paidMessage);
>>>>>>> d314aebe5da72d346a98d707b27d1b0f1d86d376
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t('Booking confirmed', 'Booking confirmed'))),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('permission-denied')
          ? 'Firebase Functions permission denied. Check function deploy, IAM public access, App Check, and Razorpay env keys.'
          : 'Booking failed: $e';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t(message, message))),
      );
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final machine = field('machine', 'machineTa');
    final image = widget.agent['image']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(machine.isEmpty ? t('Booking', 'பதிவு') : machine),
        backgroundColor: Colors.green,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: image.startsWith('http')
                    ? Image.network(image, width: 96, height: 96, fit: BoxFit.cover)
                    : Image.asset(
                        image.isEmpty ? 'assets/logo.png' : image,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Image.asset(
                          'assets/logo.png',
                          width: 96,
                          height: 96,
                        ),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      machine,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('${t('Agent', 'முகவர்')}: ${widget.agent['agentName'] ?? ''}'),
                    Text('${t('Phone', 'தொலைபேசி')}: ${widget.agent['agentPhone'] ?? ''}'),
                    Text('${t('Stock', 'கையிருப்பு')}: $stock'),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Card(
            child: ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(
                selectedDate == null
                    ? t('Select Date', 'தேதி தேர்வு')
                    : selectedDate!.toIso8601String().split('T').first,
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: pickDate,
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.access_time),
              title: Text(
                selectedTime == null
                    ? t('Select Time', 'நேரம் தேர்வு')
                    : selectedTime!.format(context),
              ),
              trailing: const Icon(Icons.chevron_right),
              onTap: pickTime,
            ),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<int>(
            value: durationHours,
            decoration: InputDecoration(
              labelText: t('Hours', 'மணி நேரம்'),
              border: const OutlineInputBorder(),
            ),
            items: List.generate(8, (index) => index + 1)
                .map(
                  (value) => DropdownMenuItem(
                    value: value,
                    child: Text('$value ${t('hour', 'மணி')}'),
                  ),
                )
                .toList(),
            onChanged: (value) => setState(() => durationHours = value ?? 1),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: locationController,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              labelText: t('Work Location', 'வேலை இடம்'),
              prefixIcon: const Icon(Icons.place),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: gettingLocation ? null : useGps,
            icon: gettingLocation
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            label: Text(t('Use Current Location', 'தற்போதைய இடத்தை பயன்படுத்து')),
          ),
          const SizedBox(height: 8),
          DropdownButtonFormField<String>(
            value: paymentMethod,
            decoration: InputDecoration(
              labelText: t('Payment Method', 'கட்டண முறை'),
              border: const OutlineInputBorder(),
            ),
            items: [
              DropdownMenuItem(
                value: 'COD',
                child: Text(t('Cash on Delivery', 'கையில் பணம்')),
              ),
              const DropdownMenuItem(value: 'Razorpay', child: Text('Razorpay')),
            ],
            onChanged: (value) => setState(() => paymentMethod = value ?? 'COD'),
          ),
          const SizedBox(height: 10),
          TextField(
            controller: noteController,
            minLines: 1,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: t('Village / Route Note', 'கிராமம் / வழி குறிப்பு'),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          Card(
            color: Colors.green.shade50,
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    t('Distance Calculation', 'தூர கணக்கீடு'),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 6),
                  Text('${t('Hourly', 'மணிக்கு')}: Rs.${hourlyRate.toStringAsFixed(0)} x $durationHours'),
                  Text('${t('Distance', 'தூரம்')}: ${adjustedDistance.toStringAsFixed(1)} km x Rs.${distanceRate.toStringAsFixed(0)}'),
                  const Divider(),
                  Text(
                    '${t('Total', 'மொத்தம்')}: Rs.${totalAmount.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: Colors.green,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 50,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
              onPressed: loading ? null : confirmBooking,
              icon: loading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.check_circle),
              label: Text(t('CONFIRM BOOKING', 'பதிவை உறுதி செய்')),
            ),
          ),
        ],
      ),
    );
  }
}
