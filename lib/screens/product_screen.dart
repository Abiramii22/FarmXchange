import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../models/product_item.dart';
import '../services/firebase_service.dart';
import '../services/location_service.dart';
import 'booking_screen.dart';

class ProductScreen extends StatefulWidget {
  const ProductScreen({super.key});

  @override
  State<ProductScreen> createState() => _ProductScreenState();
}

class _ProductScreenState extends State<ProductScreen> {
  final search = TextEditingController();
  bool availableOnly = false;
  bool nearestFirst = false;
  double maxPrice = 5000;
  double? userLat;
  double? userLng;
  String selectedDistrict = "All";

  @override
  void dispose() {
    search.dispose();
    super.dispose();
  }

  String t(String en, String ta) => AppStore.tr(en, ta);

  static const Map<String, String> districtTa = {
    "Ariyalur": "அரியலூர்",
    "Chengalpattu": "செங்கல்பட்டு",
    "Chennai": "சென்னை",
    "Madurai": "மதுரை",
    "Coimbatore": "கோயம்புத்தூர்",
    "Cuddalore": "கடலூர்",
    "Dharmapuri": "தர்மபுரி",
    "Dindigul": "திண்டுக்கல்",
    "Erode": "ஈரோடு",
    "Kallakurichi": "கள்ளக்குறிச்சி",
    "Kancheepuram": "காஞ்சிபுரம்",
    "Karur": "கரூர்",
    "Krishnagiri": "கிருஷ்ணகிரி",
    "Mayiladuthurai": "மயிலாடுதுறை",
    "Nagapattinam": "நாகப்பட்டினம்",
    "Kanniyakumari": "கன்னியாகுமரி",
    "Namakkal": "நாமக்கல்",
    "Perambalur": "பெரம்பலூர்",
    "Pudukkottai": "புதுக்கோட்டை",
    "Ramanathapuram": "ராமநாதபுரம்",
    "Ranipet": "ராணிப்பேட்டை",
    "Trichy": "திருச்சி",
    "Salem": "சேலம்",
    "Sivagangai": "சிவகங்கை",
    "Tenkasi": "தென்காசி",
    "Thanjavur": "தஞ்சாவூர்",
    "Theni": "தேனி",
    "Thoothukudi": "தூத்துக்குடி",
    "Tiruchirappalli": "திருச்சிராப்பள்ளி",
    "Tirunelveli": "திருநெல்வேலி",
    "Tirupathur": "திருப்பத்தூர்",
    "Tiruppur": "திருப்பூர்",
    "Tiruvallur": "திருவள்ளூர்",
    "Tiruvannamalai": "திருவண்ணாமலை",
    "Tiruvarur": "திருவாரூர்",
    "Vellore": "வேலூர்",
    "Viluppuram": "விழுப்புரம்",
    "Virudhunagar": "விருதுநகர்",
  };

  String districtLabel(String district) {
    if (district == "All") return t("All Districts", "அனைத்து மாவட்டங்கள்");
    return AppStore.isTamil ? (districtTa[district] ?? district) : district;
  }

  Map<String, dynamic> localProductMap(ProductItem p) {
    return {
      'id': p.id,
      'machine': p.nameEn,
      'machineTa': p.nameTa,
      'agentName': p.agentName,
      'agentPhone': p.agentPhone,
      'location': p.locationEn,
      'locationTa': p.locationTa,
      'image': p.image,
      'hourlyRate': p.hourlyRate,
      'distanceRate': p.distanceRate,
      'distanceKm': p.distanceKm,
      'stock': p.stock,
      'available': p.available && p.stock > 0,
      'rating': p.rating,
      'review': p.reviewEn,
      'reviewTa': p.reviewTa,
    };
  }

  String field(Map<String, dynamic> data, String enKey, String taKey) {
    final key = AppStore.isTamil ? taKey : enKey;
    final value = (data[key] ?? data[enKey] ?? '').toString();
    if (enKey == 'machine') return AppStore.machineName(value);
    if (enKey == 'location') {
      return districtLabel((data[enKey] ?? value).toString());
    }
    return AppStore.isTamil ? AppStore.cleanTamil(value) : value;
  }

  String imageFor(Map<String, dynamic> data) {
    final raw = data['image']?.toString() ?? '';
    final id = data['id']?.toString().toLowerCase() ?? '';
    final machine = data['machine']?.toString().toLowerCase() ?? '';

    if (raw.isNotEmpty &&
        raw != 'assets/logo.png' &&
        !raw.toLowerCase().contains('logo')) {
      return raw;
    }
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

  Widget productImage(Map<String, dynamic> data) {
    final image = imageFor(data);
    if (image.startsWith('http')) {
      return Image.network(
        image,
        width: double.infinity,
        height: 150,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => fallbackImage(),
      );
    }

    return Image.asset(
      image.isEmpty ? 'assets/logo.png' : image,
      width: double.infinity,
      height: 150,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => fallbackImage(),
    );
  }

  Widget fallbackImage() {
    return Image.asset(
      'assets/logo.png',
      width: double.infinity,
      height: 150,
      fit: BoxFit.contain,
    );
  }

  Future<void> getGps() async {
    try {
      final pos = await LocationService.currentPosition();
      setState(() {
        userLat = pos.latitude;
        userLng = pos.longitude;
        nearestFirst = true;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t("GPS location enabled", "GPS இடம் இயக்கப்பட்டது"))),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t(
              "Turn on location and allow permission",
              "Location on செய்து permission allow செய்யவும்",
            ),
          ),
        ),
      );
    }
  }

  Future<void> bookMachine({
    required String? docId,
    required Map<String, dynamic> data,
  }) async {
    final locationController = TextEditingController(
      text: AppStore.currentUserLocation,
    );
    final usageTimeController = TextEditingController();
    final deliveryNoteController = TextEditingController();
    String paymentMethod = 'COD';
    double? bookingLat = userLat;
    double? bookingLng = userLng;

    final ok = await showDialog<bool>(
      context: context,
      builder: (context) {
        bool gettingLocation = false;
        return StatefulBuilder(
          builder: (context, setDialogState) {
            Future<void> useGps() async {
              setDialogState(() => gettingLocation = true);
              try {
                final pos = await LocationService.currentPosition();
                bookingLat = pos.latitude;
                bookingLng = pos.longitude;
                locationController.text =
                    "${pos.latitude.toStringAsFixed(6)}, ${pos.longitude.toStringAsFixed(6)}";
              } catch (_) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        t(
                          "Turn on location and allow permission",
                          "Location on செய்து permission allow செய்யவும்",
                        ),
                      ),
                    ),
                  );
                }
              } finally {
                setDialogState(() => gettingLocation = false);
              }
            }

            return AlertDialog(
              title: Text(t("Booking Location", "Booking இடம்")),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                  TextField(
                    controller: locationController,
                    decoration: InputDecoration(
                      labelText: t("Type or use GPS location", "இடம் type செய்யவும் அல்லது GPS பயன்படுத்தவும்"),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: usageTimeController,
                    decoration: InputDecoration(
                      labelText: t("Usage time", "பயன்பாட்டு நேரம்"),
                      hintText: t("Example: 10 AM to 2 PM", "உதாரணம்: காலை 10 முதல் மதியம் 2 வரை"),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: paymentMethod,
                    items: const [
                      DropdownMenuItem(value: 'COD', child: Text('Cash on Delivery')),
                      DropdownMenuItem(value: 'UPI', child: Text('UPI')),
                      DropdownMenuItem(value: 'Google Pay', child: Text('Google Pay')),
                      DropdownMenuItem(value: 'PhonePe', child: Text('PhonePe')),
                      DropdownMenuItem(value: 'Paytm', child: Text('Paytm')),
                    ],
                    onChanged: (value) {
                      setDialogState(() => paymentMethod = value ?? 'COD');
                    },
                    decoration: InputDecoration(
                      labelText: t("Payment method", "பணம் செலுத்தும் முறை"),
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: deliveryNoteController,
                    minLines: 1,
                    maxLines: 2,
                    decoration: InputDecoration(
                      labelText: t("Village / route note", "கிராமம் / வழி குறிப்பு"),
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
                    label: Text(t("Use Current Location", "தற்போதைய இடம்")),
                  ),
                  Text(
                    t(
                      "Guide: Turn on phone GPS, allow location permission, then press current location.",
                      "வழிகாட்டி: Phone GPS on செய்யவும், permission allow செய்யவும், பிறகு தற்போதைய இடத்தை அழுத்தவும்.",
                    ),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: Text(t("Back", "பின்")),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  child: Text(t("Confirm", "உறுதி செய்")),
                ),
              ],
            );
          },
        );
      },
    );

    if (ok != true || locationController.text.trim().isEmpty) return;

    try {
      if (docId == null) {
        await FirebaseService.createLocalProductBooking(
          product: data,
          workLocation: locationController.text.trim(),
          paymentMethod: paymentMethod,
          usageTime: usageTimeController.text.trim(),
          deliveryNote: deliveryNoteController.text.trim(),
          userLat: bookingLat,
          userLng: bookingLng,
        ).timeout(const Duration(seconds: 15));
      } else {
        await FirebaseService.createAgentBooking(
          agentId: docId,
          agent: data,
          workLocation: locationController.text.trim(),
          paymentMethod: paymentMethod,
          usageTime: usageTimeController.text.trim(),
          deliveryNote: deliveryNoteController.text.trim(),
          userLat: bookingLat,
          userLng: bookingLng,
        ).timeout(const Duration(seconds: 15));
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t("Booking request sent", "Booking request அனுப்பப்பட்டது"))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            t(
              "Booking failed: $e",
              "Booking ஆகவில்லை: $e",
            ),
          ),
        ),
      );
    }
  }

  List<_ProductRow> filterRows(List<_ProductRow> rows) {
    final q = search.text.trim().toLowerCase();
    final filtered = rows.where((row) {
      final data = row.data;
      final name = field(data, 'machine', 'machineTa').toLowerCase();
      if (name.contains('thresher')) return false;
      final price = (data['hourlyRate'] is num)
          ? (data['hourlyRate'] as num).toDouble()
          : 0.0;
      final stock = (data['stock'] is num) ? (data['stock'] as num).toInt() : 0;
      final available = data['available'] == true && stock > 0;
      final district = (data['location'] ?? '').toString();

      return (q.isEmpty || name.contains(q)) &&
          (selectedDistrict == "All" || district == selectedDistrict) &&
          (!availableOnly || available) &&
          price <= maxPrice;
    }).toList();

    if (nearestFirst) {
      filtered.sort((a, b) {
        final ad = (a.data['distanceKm'] is num)
            ? (a.data['distanceKm'] as num).toDouble()
            : 9999.0;
        final bd = (b.data['distanceKm'] is num)
            ? (b.data['distanceKm'] as num).toDouble()
            : 9999.0;
        return ad.compareTo(bd);
      });
    }
    return filtered;
  }

  Widget filters() {
    final districts = [
      "All",
      ...AppStore.locations(),
    ];
    if (!districts.contains(selectedDistrict)) selectedDistrict = "All";

    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 0),
      child: Column(
        children: [
          DropdownButtonFormField<String>(
            value: selectedDistrict,
            items: districts
                .map(
                  (district) => DropdownMenuItem(
                    value: district,
                    child: Text(
                      districtLabel(district),
                    ),
                  ),
                )
                .toList(),
            onChanged: (value) {
              setState(() => selectedDistrict = value ?? "All");
            },
            decoration: InputDecoration(
              labelText: t("District", "மாவட்டம்"),
              prefixIcon: const Icon(Icons.place),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 8),
          TextField(
            controller: search,
            onChanged: (_) => setState(() {}),
            decoration: InputDecoration(
              hintText: t("Search machine", "இயந்திரம் தேடு"),
              prefixIcon: const Icon(Icons.search),
              border: const OutlineInputBorder(),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: CheckboxListTile(
                  dense: true,
                  value: availableOnly,
                  onChanged: (value) {
                    setState(() => availableOnly = value ?? false);
                  },
                  title: Text(t("Available", "கிடைக்கும்")),
                  controlAffinity: ListTileControlAffinity.leading,
                ),
              ),
              IconButton(
                tooltip: t("Nearest", "அருகில்"),
                onPressed: getGps,
                icon: Icon(
                  Icons.my_location,
                  color: nearestFirst ? Colors.green : Colors.grey,
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text(t("Max price", "அதிகபட்ச விலை")),
              Expanded(
                child: Slider(
                  min: 100,
                  max: 5000,
                  divisions: 49,
                  value: maxPrice,
                  label: "Rs.${maxPrice.toInt()}",
                  onChanged: (value) {
                    setState(() => maxPrice = value);
                  },
                ),
              ),
              Text("Rs.${maxPrice.toInt()}"),
            ],
          ),
        ],
      ),
    );
  }

  Widget card(_ProductRow row) {
    final data = row.data;
    final stock = (data['stock'] is num) ? (data['stock'] as num).toInt() : 0;
    final available = data['available'] == true && stock > 0;
    final machine = field(data, 'machine', 'machineTa');
    final location = field(data, 'location', 'locationTa');
    final review = field(data, 'review', 'reviewTa');

    return Card(
      margin: const EdgeInsets.all(10),
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: productImage(data),
            ),
            const SizedBox(height: 10),
            Text(
              machine.isEmpty ? t("Unknown Machine", "பெயர் இல்லாத இயந்திரம்") : machine,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 5),
            Text(
              "Rs.${data['hourlyRate'] ?? 0}/hr",
              style: const TextStyle(
                color: Colors.green,
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            Text("${t("Location", "இடம்")}: $location"),
            Text("${t("Phone", "தொலைபேசி")}: ${data['agentPhone'] ?? ""}"),
            Text("${t("Distance", "தூரம்")}: ${data['distanceKm'] ?? 0} km"),
            Text("${t("Stock", "ஸ்டாக்")}: $stock"),
            Text("${t("Rating", "Rating")}: ${data['rating'] ?? 0}/5"),
            const SizedBox(height: 5),
            Text(
              available
                  ? t("Available", "கிடைக்கும்")
                  : t("Not Available", "கிடைக்கவில்லை"),
              style: TextStyle(
                color: available ? Colors.green : Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
            if (review.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(review, style: const TextStyle(fontSize: 12)),
            ],
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
                onPressed: available
                    ? () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => BookingScreen(
                              agentId: row.docId,
                              agent: data,
                            ),
                          ),
                        )
                    : null,
                child: Text(t("Book", "பதிவு செய்")),
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Text(t("FarmX Products", "பொருட்கள்")),
        backgroundColor: Colors.green,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('agents').snapshots(),
        builder: (context, snapshot) {
          final rows = <_ProductRow>[];
          if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
            rows.addAll(snapshot.data!.docs.map((doc) {
              return _ProductRow(
                docId: doc.id,
                data: doc.data() as Map<String, dynamic>,
              );
            }));
          } else {
            rows.addAll(
              AppStore.products.map(
                (product) => _ProductRow(
                  docId: null,
                  data: localProductMap(product),
                ),
              ),
            );
          }

          final uniqueRows = <_ProductRow>[];
          final seen = <String>{};
          for (final row in rows) {
            final key = field(row.data, 'machine', 'machineTa')
                .trim()
                .toLowerCase()
                .replaceAll(RegExp(r'\s+'), ' ');
            if (key.isEmpty || seen.contains(key)) continue;
            seen.add(key);
            uniqueRows.add(row);
          }

          final visible = filterRows(uniqueRows);

          return Column(
            children: [
              filters(),
              if (!snapshot.hasData)
                const LinearProgressIndicator(minHeight: 2),
              Expanded(
                child: visible.isEmpty
                    ? Center(child: Text(t("No matching machines", "பொருந்தும் இயந்திரம் இல்லை")))
                    : ListView.builder(
                        itemCount: visible.length,
                        itemBuilder: (context, index) => card(visible[index]),
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ProductRow {
  final String? docId;
  final Map<String, dynamic> data;

  _ProductRow({
    required this.docId,
    required this.data,
  });
}
