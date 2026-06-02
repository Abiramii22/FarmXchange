import 'dart:convert';

class ProductItem {
  final String id;
  final String nameEn;
  final String nameTa;
  final String image;
  final String agentName;
  final String agentPhone;
  final String locationEn;
  final String locationTa;
  final String machineType;
  final String engineCapacity;
  final int stock;
  final bool available;
  final double hourlyRate;
  final double distanceRate;
  final double distanceKm;
  final bool distanceAvailable;
  final bool vendorAvailable;
  final double rating;
  final int reviewCount;
  final int demandScore;
  final String reviewEn;
  final String reviewTa;

  const ProductItem({
    required this.id,
    required this.nameEn,
    required this.nameTa,
    required this.image,
    required this.agentName,
    required this.agentPhone,
    required this.locationEn,
    required this.locationTa,
    required this.machineType,
    required this.engineCapacity,
    required this.stock,
    required this.available,
    required this.hourlyRate,
    required this.distanceRate,
    required this.distanceKm,
    this.distanceAvailable = true,
    this.vendorAvailable = true,
    required this.rating,
    required this.reviewCount,
    required this.demandScore,
    required this.reviewEn,
    required this.reviewTa,
  });

  String _cleanTamil(String value) {
    if (!value.contains('\u00e0') && !value.contains('\u00c3')) return value;
    final bytes = <int>[];
    for (final code in value.codeUnits) {
      if (code > 255) return value;
      bytes.add(code);
    }
    try {
      return utf8.decode(bytes, allowMalformed: true);
    } catch (_) {
      return value;
    }
  }

  String name(bool tamil) => tamil ? _cleanTamil(nameTa) : nameEn;
  String location(bool tamil) => tamil ? _cleanTamil(locationTa) : locationEn;
  String review(bool tamil) => tamil ? _cleanTamil(reviewTa) : reviewEn;

  ProductItem copyWith({
    int? stock,
    bool? available,
  }) {
    return ProductItem(
      id: id,
      nameEn: nameEn,
      nameTa: nameTa,
      image: image,
      agentName: agentName,
      agentPhone: agentPhone,
      locationEn: locationEn,
      locationTa: locationTa,
      machineType: machineType,
      engineCapacity: engineCapacity,
      stock: stock ?? this.stock,
      available: available ?? this.available,
      hourlyRate: hourlyRate,
      distanceRate: distanceRate,
      distanceKm: distanceKm,
      distanceAvailable: distanceAvailable,
      vendorAvailable: vendorAvailable,
      rating: rating,
      reviewCount: reviewCount,
      demandScore: demandScore,
      reviewEn: reviewEn,
      reviewTa: reviewTa,
    );
  }

  String distanceStatus(bool tamil) {
    return distanceAvailable
        ? (tamil ? "தூரம் கிடைக்கும்" : "Distance available")
        : (tamil ? "தூரத்தில் தாமதம்" : "Distance delay");
  }

  String vendorStatus(bool tamil) {
    return vendorAvailable
        ? (tamil ? "வெண்டர் கிடைக்கும்" : "Vendor available")
        : (tamil ? "வெண்டர் தாமதம்" : "Vendor delay");
  }
}
