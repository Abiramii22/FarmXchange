import 'package:flutter/services.dart';

import '../models/booking.dart';

class WhatsAppService {
  static const MethodChannel _channel = MethodChannel('farmxchange/whatsapp');

  static Future<bool> openMessage({
    required String phone,
    required String message,
  }) async {
    final normalizedPhone = _normalizePhone(phone);
    if (normalizedPhone.isEmpty) return false;

    try {
      final sent = await _channel.invokeMethod<bool>('openWhatsApp', {
        'phone': normalizedPhone,
        'message': message,
      });
      return sent ?? false;
    } on MissingPluginException {
      return false;
    } on PlatformException {
      return false;
    }
  }

  static String userBookingMessage(Booking booking) {
    final trackLink = trackingLinkForBooking(booking);
    return [
      'FarmXchange Order Confirmed',
      'Product: ${booking.product}',
      'Agent: ${booking.vendor}',
      'Agent Phone: ${displayPhone(booking.agentPhone)}',
      'Date: ${booking.date}',
      'Time: ${booking.time}',
      'Duration: ${booking.durationHours} hour(s)',
      'Delivery Location: ${booking.location}',
      'Amount: Rs.${booking.price.toStringAsFixed(0)}',
      'Payment: ${friendlyPayment(booking.paymentStatus)}',
      'Status: Order Confirmed',
      '',
      'Track your product: $trackLink',
      '',
      'Thank you. Visit again.',
    ].join('\n');
  }

  static String agentBookingMessage(Booking booking) {
    final trackLink = trackingLinkForBooking(booking);
    return [
      'Welcome to FarmXchange',
      'New Order Confirmed',
      'Product: ${booking.product}',
      'Customer: ${booking.user}',
      'Customer Phone: ${displayPhone(booking.userPhone)}',
      'Date: ${booking.date}',
      'Time: ${booking.time}',
      'Duration: ${booking.durationHours} hour(s)',
      'Delivery Location: ${booking.location}',
      'Amount: Rs.${booking.price.toStringAsFixed(0)}',
      'Payment: ${friendlyPayment(booking.paymentStatus)}',
      'Status: Order Confirmed',
      '',
      'Track delivery route: $trackLink',
    ].join('\n');
  }

  static String statusMessage(Map<String, dynamic> data) {
    final machine = data['machine'] ?? data['product'] ?? 'Machine';
    final status = friendlyStatus(data['status']?.toString() ?? 'Pending');
    final payment = friendlyPayment(data['paymentStatus']?.toString() ?? 'Pending');
    final refund = data['refundStatus'] ?? 'Not Requested';
    final trackLink = trackingLink(data);
    return [
      'FarmXchange Booking Update',
      'Product: $machine',
      'Status: $status',
      'Payment: $payment',
      'Refund: $refund',
      'Amount: Rs.${data['price'] ?? 0}',
      '',
      'Track order here: $trackLink',
      '',
      'User: ${displayPhone(data['userPhone']?.toString() ?? '')}',
      'Agent: ${displayPhone(data['agentPhone']?.toString() ?? '')}',
    ].join('\n');
  }

  static String paymentDoneMessage(Map<String, dynamic> data) {
    final machine = data['machine'] ?? data['product'] ?? 'Machine';
    return [
      'FarmXchange Payment Done',
      'Product: $machine',
      'Amount: Rs.${data['price'] ?? 0}',
      'Payment: Done',
      'Status: ${friendlyStatus(data['status']?.toString() ?? 'In Progress')}',
      '',
      'Track order here: ${trackingLink(data)}',
    ].join('\n');
  }

  static String friendlyStatus(String status) {
    final normalized = status.toLowerCase();
    if (normalized.contains('complete')) return 'Completed';
    if (normalized.contains('accept') || normalized.contains('progress')) {
      return 'In Progress';
    }
    if (normalized.contains('reject')) return 'Rejected';
    if (normalized.contains('cancel')) return 'Cancelled';
    if (normalized.contains('pending')) return 'Order Confirmed';
    return status;
  }

  static String friendlyPayment(String payment) {
    final normalized = payment.toLowerCase();
    if (normalized.contains('paid') ||
        normalized.contains('received') ||
        normalized.contains('done')) {
      return 'Payment Done';
    }
    if (normalized.contains('cod')) return 'COD Pending';
    return payment.isEmpty ? 'Pending' : payment;
  }

  static String trackingLink(Map<String, dynamic> data) {
    final origin = _latLng(data['userLat'], data['userLng']) ??
        _query(data['workLocation'] ?? data['location']);
    final destination = _latLng(data['agentLat'], data['agentLng']) ??
        _query(data['agentLocation'] ?? data['vendorLocation']);

    if (origin.isNotEmpty && destination.isNotEmpty) {
      return 'https://www.google.com/maps/dir/?api=1&origin=$origin&destination=$destination&travelmode=driving';
    }
    if (origin.isNotEmpty) {
      return 'https://www.google.com/maps/search/?api=1&query=$origin';
    }
    if (destination.isNotEmpty) {
      return 'https://www.google.com/maps/search/?api=1&query=$destination';
    }
    return 'FarmXchange app > My Bookings / Agent Dashboard';
  }

  static String trackingLinkForBooking(Booking booking) {
    final location = _query(booking.location);
    if (location.isEmpty) return 'FarmXchange app > My Bookings / Agent Dashboard';
    return 'https://www.google.com/maps/search/?api=1&query=$location';
  }

  static String trackingLinkForLocation(String location) {
    final query = _query(location);
    if (query.isEmpty) return 'FarmXchange app > My Bookings / Agent Dashboard';
    return 'https://www.google.com/maps/search/?api=1&query=$query';
  }

  static String displayPhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    final last10 = digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
    if (last10.length == 10) return '+91$last10';
    return '+$digits';
  }

  static String _normalizePhone(String phone) {
    final digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.isEmpty) return '';
    final last10 = digits.length >= 10 ? digits.substring(digits.length - 10) : digits;
    if (last10.length == 10) return '91$last10';
    return digits;
  }

  static String? _latLng(dynamic lat, dynamic lng) {
    if (lat is num && lng is num) {
      return '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
    }
    return null;
  }

  static String _query(dynamic value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) return '';
    final parts = text.split(',');
    if (parts.length == 2) {
      final lat = double.tryParse(parts[0].trim());
      final lng = double.tryParse(parts[1].trim());
      if (lat != null && lng != null) {
        return '${lat.toStringAsFixed(6)},${lng.toStringAsFixed(6)}';
      }
    }
    return Uri.encodeComponent(text);
  }
}