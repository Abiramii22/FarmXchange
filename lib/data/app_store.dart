import 'dart:convert';

import 'package:flutter/material.dart';

import '../models/booking.dart';
import '../models/product_item.dart';

class AppStore {
  static bool isTamil = false;
  static Locale currentLocale = const Locale('en');
  static List<Booking> bookings = [];
  static String currentUserName = "";
  static String currentUserPhone = "";
  static String currentUserEmail = "";
  static String currentUserRole = "User";
  static String currentUserLocation = "";
  static String currentUserAddress = "";

  static double totalEarnings = 0;
  static double totalProfit = 0;
  static double totalLoss = 0;

  static List<String> logs = [];
  static Map<String, int> productDemand = {};

  static const List<String> locationsEn = [
    "Ariyalur",
    "Chengalpattu",
    "Chennai",
    "Madurai",
    "Coimbatore",
    "Cuddalore",
    "Dharmapuri",
    "Dindigul",
    "Erode",
    "Kallakurichi",
    "Kancheepuram",
    "Karur",
    "Krishnagiri",
    "Mayiladuthurai",
    "Nagapattinam",
    "Kanniyakumari",
    "Namakkal",
    "Perambalur",
    "Pudukkottai",
    "Ramanathapuram",
    "Ranipet",
    "Trichy",
    "Salem",
    "Sivagangai",
    "Tenkasi",
    "Thanjavur",
    "Theni",
    "Thoothukudi",
    "Tiruchirappalli",
    "Tirunelveli",
    "Tirupathur",
    "Tiruppur",
    "Tiruvallur",
    "Tiruvannamalai",
    "Tiruvarur",
    "Vellore",
    "Viluppuram",
    "Virudhunagar",
  ];

  static const List<String> locationsTa = [
    "மதுரை",
    "கோயம்புத்தூர்",
    "திருச்சி",
    "சேலம்",
    "தஞ்சாவூர்",
  ];

  static List<ProductItem> products = [
    ProductItem(
      id: "tractor",
      nameEn: "Tractor",
      nameTa: "டிராக்டர்",
      image: "assets/images/tractor.jpg",
      agentName: "Ravi Farm Tools",
      agentPhone: "9876543210",
      locationEn: "Madurai",
      locationTa: "மதுரை",
      machineType: "Heavy",
      engineCapacity: "45 HP",
      stock: 3,
      available: true,
      hourlyRate: 950,
      distanceRate: 18,
      distanceKm: 4.5,
      rating: 4.6,
      reviewCount: 42,
      demandScore: 96,
      reviewEn: "Strong pulling power, good for wet land.",
      reviewTa: "ஈர நிலத்துக்கு நல்ல இழுவை சக்தி.",
    ),
    ProductItem(
      id: "plough",
      nameEn: "Plough",
      nameTa: "கலப்பை",
      image: "assets/images/plough.jpg",
      agentName: "Green Agro Service",
      agentPhone: "9898981212",
      locationEn: "Thanjavur",
      locationTa: "தஞ்சாவூர்",
      machineType: "Medium",
      engineCapacity: "Attachment",
      stock: 5,
      available: true,
      hourlyRate: 280,
      distanceRate: 10,
      distanceKm: 9,
      rating: 4.3,
      reviewCount: 28,
      demandScore: 82,
      reviewEn: "Clean soil turning and low fuel use.",
      reviewTa: "மண் திருப்புதல் சுத்தமாக உள்ளது.",
    ),
    ProductItem(
      id: "harvester",
      nameEn: "Harvester",
      nameTa: "அறுவடை இயந்திரம்",
      image: "assets/images/harvester.jpg",
      agentName: "Delta Machines",
      agentPhone: "9003300440",
      locationEn: "Trichy",
      locationTa: "திருச்சி",
      machineType: "Heavy",
      engineCapacity: "76 HP",
      stock: 2,
      available: true,
      hourlyRate: 1450,
      distanceRate: 28,
      distanceKm: 13,
      distanceAvailable: false,
      rating: 4.8,
      reviewCount: 35,
      demandScore: 91,
      reviewEn: "Fast harvest, operator handled it well.",
      reviewTa: "வேகமான அறுவடை, ஆபரேட்டர் நன்றாக செய்தார்.",
    ),
    ProductItem(
      id: "power_tiller",
      nameEn: "Power Tiller",
      nameTa: "பவர் டில்லர்",
      image: "assets/images/power_tiller.jpg",
      agentName: "Selvam Equipments",
      agentPhone: "9444412345",
      locationEn: "Salem",
      locationTa: "சேலம்",
      machineType: "Small",
      engineCapacity: "12 HP",
      stock: 4,
      available: true,
      hourlyRate: 420,
      distanceRate: 12,
      distanceKm: 6,
      rating: 4.2,
      reviewCount: 19,
      demandScore: 74,
      reviewEn: "Easy for small farms and narrow paths.",
      reviewTa: "சிறு நிலத்துக்கு எளிதாக பயன்படுத்தலாம்.",
    ),
    ProductItem(
      id: "seed_drill",
      nameEn: "Seed Drill",
      nameTa: "விதை விதைப்பான்",
      image: "assets/images/seed_drill.jpg",
      agentName: "Kongu Agro",
      agentPhone: "9500607080",
      locationEn: "Coimbatore",
      locationTa: "கோயம்புத்தூர்",
      machineType: "Medium",
      engineCapacity: "Attachment",
      stock: 6,
      available: true,
      hourlyRate: 360,
      distanceRate: 11,
      distanceKm: 3,
      rating: 4.5,
      reviewCount: 22,
      demandScore: 86,
      reviewEn: "Even seed spacing and quick setup.",
      reviewTa: "விதை இடைவெளி சமமாக வருகிறது.",
    ),
    ProductItem(
      id: "baler",
      nameEn: "Baler",
      nameTa: "வைக்கோல் கட்டு இயந்திரம்",
      image: "assets/images/baler.jpg",
      agentName: "Farm Lift Rental",
      agentPhone: "9360011223",
      locationEn: "Trichy",
      locationTa: "திருச்சி",
      machineType: "Heavy",
      engineCapacity: "50 HP",
      stock: 1,
      available: true,
      hourlyRate: 880,
      distanceRate: 20,
      distanceKm: 16,
      distanceAvailable: false,
      vendorAvailable: false,
      rating: 4.1,
      reviewCount: 14,
      demandScore: 68,
      reviewEn: "Good bale shape, limited slots.",
      reviewTa: "கட்டு வடிவம் நல்லது, slots குறைவாக உள்ளது.",
    ),
    ProductItem(
      id: "sickle",
      nameEn: "Sickle",
      nameTa: "அரிவாள்",
      image: "assets/images/sickle.jpg",
      agentName: "Village Tools",
      agentPhone: "9788899001",
      locationEn: "Madurai",
      locationTa: "மதுரை",
      machineType: "Manual",
      engineCapacity: "N/A",
      stock: 12,
      available: true,
      hourlyRate: 60,
      distanceRate: 5,
      distanceKm: 2,
      rating: 4.0,
      reviewCount: 31,
      demandScore: 61,
      reviewEn: "Sharp and useful for quick cutting.",
      reviewTa: "விரைவான வெட்டுக்கு கூர்மையாக உள்ளது.",
    ),
    ProductItem(
      id: "spade",
      nameEn: "Spade",
      nameTa: "மண்வெட்டி",
      image: "assets/images/spade.jpg",
      agentName: "Village Tools",
      agentPhone: "9788899001",
      locationEn: "Coimbatore",
      locationTa: "கோயம்புத்தூர்",
      machineType: "Manual",
      engineCapacity: "N/A",
      stock: 10,
      available: true,
      hourlyRate: 70,
      distanceRate: 5,
      distanceKm: 5,
      rating: 4.4,
      reviewCount: 26,
      demandScore: 58,
      reviewEn: "Light weight and strong handle.",
      reviewTa: "எடை குறைவு, கைப்பிடி வலிமையாக உள்ளது.",
    ),
    ProductItem(
      id: "sprayer",
      nameEn: "Sprayer",
      nameTa: "தெளிப்பான்",
      image: "assets/images/Sprayer.jpg",
      agentName: "Agri Spray Service",
      agentPhone: "9090904545",
      locationEn: "Dindigul",
      locationTa: "Dindigul",
      machineType: "Spraying Tool",
      engineCapacity: "Battery",
      stock: 7,
      available: true,
      hourlyRate: 180,
      distanceRate: 8,
      distanceKm: 6.5,
      rating: 4.4,
      reviewCount: 18,
      demandScore: 79,
      reviewEn: "Good coverage for pesticide and fertilizer spray.",
      reviewTa: "பூச்சிக்கொல்லி மற்றும் உர தெளிப்புக்கு நல்ல coverage தருகிறது.",
    ),
    ProductItem(
      id: "spanner_set",
      nameEn: "Spanner Set",
      nameTa: "ஸ்பானர் செட்",
      image: "assets/images/spanner_set.jpg",
      agentName: "Repair Hub",
      agentPhone: "9123456780",
      locationEn: "Salem",
      locationTa: "சேலம்",
      machineType: "Tool Kit",
      engineCapacity: "N/A",
      stock: 0,
      available: false,
      hourlyRate: 90,
      distanceRate: 5,
      distanceKm: 7,
      vendorAvailable: false,
      rating: 3.9,
      reviewCount: 12,
      demandScore: 43,
      reviewEn: "Useful kit, currently not available.",
      reviewTa: "பயனுள்ள kit, தற்போது கிடைக்கவில்லை.",
    ),
  ];

  static String cleanTamil(String value) {
    if (value.isEmpty) return value;
    var current = value;
    final tamil = RegExp(r'[\u0B80-\u0BFF]');

    for (var i = 0; i < 6; i++) {
      if (tamil.hasMatch(current)) return current;
      if (!current.contains('Ã') &&
          !current.contains('Â') &&
          !current.contains('à') &&
          !current.contains('â')) {
        return current;
      }

      final bytes = <int>[];
      var ok = true;
      for (final code in current.codeUnits) {
        if (code > 255) {
          ok = false;
          break;
        }
        bytes.add(code);
      }
      if (!ok) return current;

      try {
        final next = utf8.decode(bytes, allowMalformed: true);
        if (next == current) return current;
        current = next;
      } catch (_) {
        return current;
      }
    }
    return current;
  }

  static String fixText(String value) {
    if (value.isEmpty) return value;
    return cleanTamil(value);
  }

  static void setLanguage(String langCode) {
    currentLocale = Locale(langCode);
    isTamil = langCode == 'ta';
  }

  static String tr(String en, String ta) => fixText(isTamil ? ta : en);

  static List<String> locations() => locationsEn;

  static String machineName(String value) {
    final cleaned = cleanTamil(value.trim());
    if (!isTamil || cleaned.isEmpty) return cleaned;
    if (RegExp(r'[\u0B80-\u0BFF]').hasMatch(cleaned)) return cleaned;

    final key = cleaned
        .toLowerCase()
        .replaceAll(RegExp(r'[_-]+'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    final names = <String, String>{
      'tractor': 'டிராக்டர்',
      'plough': 'கலப்பை',
      'harvester': 'அறுவடை இயந்திரம்',
      'power tiller': 'பவர் டில்லர்',
      'seed drill': 'விதை விதைப்பான்',
      'baler': 'வைக்கோல் கட்டு இயந்திரம்',
      'sickle': 'அரிவாள்',
      'spade': 'மண்வெட்டி',
      'sprayer': 'தெளிப்பான்',
      'spanner set': 'ஸ்பானர் செட்',
      'hammer': 'சுத்தியல்',
      'unknown machine': 'இயந்திரம்',
      'machine': 'இயந்திரம்',
    };
    return names[key] ?? cleaned;
  }

  static String displayMachine(Map<String, dynamic> data) {
    final ta = cleanTamil(data['machineTa']?.toString() ?? '');
    final en = data['machine']?.toString() ??
        data['product']?.toString() ??
        data['name']?.toString() ??
        'Machine';
    if (!isTamil) return cleanTamil(en);
    return machineName(ta.isNotEmpty ? ta : en);
  }

  static String displayStatus(String value) {
    final cleaned = cleanTamil(value.trim());
    if (!isTamil || cleaned.isEmpty) return cleaned;
    final key = cleaned.toLowerCase();
    final values = <String, String>{
      'pending': 'நிலுவை',
      'accepted': 'ஏற்கப்பட்டது',
      'rejected': 'நிராகரிக்கப்பட்டது',
      'completed': 'முடிந்தது',
      'cancelled': 'ரத்து செய்யப்பட்டது',
      'paid': 'செலுத்தப்பட்டது',
      'failed': 'தோல்வி',
      'received': 'பெறப்பட்டது',
      'cod pending': 'COD நிலுவை',
      'not requested': 'கோரப்படவில்லை',
      'not applicable': 'பொருந்தாது',
      'refunded': 'திருப்பி செலுத்தப்பட்டது',
      'processing': 'செயலாக்கத்தில்',
      'refund failed': 'திருப்பி செலுத்தல் தோல்வி',
      'open': 'திறந்துள்ளது',
      'calling': 'அழைக்கப்படுகிறது',
      'closed': 'மூடப்பட்டது',
    };
    return values[key] ?? cleaned;
  }

  static ProductItem? productById(String id) {
    for (final product in products) {
      if (product.id == id) return product;
    }
    return null;
  }

  static String productName(String id, String fallback) {
    return productById(id)?.name(isTamil) ?? fallback;
  }

  static int demandFor(String productId, int baseDemand) {
    return baseDemand + (productDemand[productId] ?? 0) * 4;
  }
}
