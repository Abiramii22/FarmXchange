class Booking {
  final String id;
  final String productId;
  final String product;
  final String user;
  final String userPhone;
  final String vendor;
  final String agentPhone;
  final String image;
  final double price;
  final double hourlyRate;
  final double distanceKm;
  final double distanceRate;
  final int durationHours;
  final String location;
  final String date;
  final String time;

  final String status;
  final bool isRefunded;
  final double refundAmount;
  final String cancelReason;

  final double rating;
  final String review;
  final String paymentStatus;
  final String machineType;
  final String engineCapacity;
  final String availability;

  Booking({
    this.id = "",
    required this.productId,
    required this.product,
    required this.user,
    required this.userPhone,
    required this.vendor,
    required this.agentPhone,
    required this.image,
    required this.price,
    required this.hourlyRate,
    required this.distanceKm,
    required this.distanceRate,
    required this.durationHours,
    required this.location,
    required this.date,
    required this.time,
    this.status = "Booked",
    this.isRefunded = false,
    this.refundAmount = 0,
    this.cancelReason = "",
    this.rating = 0,
    this.review = "",
    this.paymentStatus = "Pending",
    this.machineType = "Medium",
    this.engineCapacity = "N/A",
    this.availability = "Available",
  });

  Map<String, dynamic> toMap() {
    return {
      "productId": productId,
      "product": product,
      "user": user,
      "userPhone": userPhone,
      "vendor": vendor,
      "agentPhone": agentPhone,
      "image": image,
      "price": price,
      "hourlyRate": hourlyRate,
      "distanceKm": distanceKm,
      "distanceRate": distanceRate,
      "durationHours": durationHours,
      "location": location,
      "date": date,
      "time": time,
      "status": status,
      "isRefunded": isRefunded,
      "refundAmount": refundAmount,
      "cancelReason": cancelReason,
      "rating": rating,
      "review": review,
      "paymentStatus": paymentStatus,
      "machineType": machineType,
      "engineCapacity": engineCapacity,
      "availability": availability,
    };
  }

  factory Booking.fromMap(String id, Map<String, dynamic> map) {
    double asDouble(dynamic value) {
      if (value is num) return value.toDouble();
      return double.tryParse(value?.toString() ?? "") ?? 0;
    }

    int asInt(dynamic value) {
      if (value is num) return value.toInt();
      return int.tryParse(value?.toString() ?? "") ?? 1;
    }

    return Booking(
      id: id,
      productId: map["productId"]?.toString() ?? "",
      product: map["product"]?.toString() ?? "",
      user: map["user"]?.toString() ?? "",
      userPhone: map["userPhone"]?.toString() ?? "",
      vendor: map["vendor"]?.toString() ?? "",
      agentPhone: map["agentPhone"]?.toString() ?? "",
      image: map["image"]?.toString() ?? "",
      price: asDouble(map["price"]),
      hourlyRate: asDouble(map["hourlyRate"]),
      distanceKm: asDouble(map["distanceKm"]),
      distanceRate: asDouble(map["distanceRate"]),
      durationHours: asInt(map["durationHours"]),
      location: map["location"]?.toString() ?? "",
      date: map["date"]?.toString() ?? "",
      time: map["time"]?.toString() ?? "",
      status: map["status"]?.toString() ?? "Booked",
      isRefunded: map["isRefunded"] == true,
      refundAmount: asDouble(map["refundAmount"]),
      cancelReason: map["cancelReason"]?.toString() ?? "",
      rating: asDouble(map["rating"]),
      review: map["review"]?.toString() ?? "",
      paymentStatus: map["paymentStatus"]?.toString() ?? "Pending",
      machineType: map["machineType"]?.toString() ?? "Medium",
      engineCapacity: map["engineCapacity"]?.toString() ?? "N/A",
      availability: map["availability"]?.toString() ?? "Available",
    );
  }

  Booking copyWith({
    String? status,
    bool? isRefunded,
    double? refundAmount,
    String? cancelReason,
    double? rating,
    String? review,
    String? paymentStatus,
  }) {
    return Booking(
      id: id,
      productId: productId,
      product: product,
      user: user,
      userPhone: userPhone,
      vendor: vendor,
      agentPhone: agentPhone,
      image: image,
      price: price,
      hourlyRate: hourlyRate,
      distanceKm: distanceKm,
      distanceRate: distanceRate,
      durationHours: durationHours,
      location: location,
      date: date,
      time: time,
      status: status ?? this.status,
      isRefunded: isRefunded ?? this.isRefunded,
      refundAmount: refundAmount ?? this.refundAmount,
      cancelReason: cancelReason ?? this.cancelReason,
      rating: rating ?? this.rating,
      review: review ?? this.review,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      machineType: machineType,
      engineCapacity: engineCapacity,
      availability: availability,
    );
  }
}
