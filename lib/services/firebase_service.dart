import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../data/app_store.dart';
import '../models/booking.dart';

class FirebaseService {
  static final FirebaseAuth auth = FirebaseAuth.instance;
  static final FirebaseFirestore db = FirebaseFirestore.instance;

  static String currentUserId() {
    if (AppStore.currentUserPhone.trim().isNotEmpty) {
      return AppStore.currentUserPhone.trim();
    }
    return auth.currentUser?.uid ?? '';
  }

  static String normalizeIndianPhone(String input) {
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 12 && digits.startsWith('91')) {
      return '+${digits.substring(digits.length - 12)}';
    }
    if (digits.length >= 10) {
      return '+91${digits.substring(digits.length - 10)}';
    }
    return '';
  }

  static String phoneDigits(String input) {
    final normalized = normalizeIndianPhone(input);
    if (normalized.isNotEmpty) {
      return normalized.replaceAll(RegExp(r'[^0-9]'), '');
    }
    final digits = input.replaceAll(RegExp(r'[^0-9]'), '');
    if (digits.length >= 10) return digits.substring(digits.length - 10);
    return digits;
  }

  static bool isValidEmail(String input) {
    return RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(input.trim());
  }

  static String authEmailForPhone(String phone) {
    final digits = phoneDigits(phone);
    return '$digits@farmxchange.local';
  }

  static Future<String?> validateUniqueRegistration({
    required String name,
    required String password,
  }) async {
    final nameLower = name.trim().toLowerCase();
    final passwordKey = password.trim();
    if (nameLower.isEmpty || passwordKey.isEmpty) return null;

    final nameQuery = await db
        .collection('users')
        .where('nameLower', isEqualTo: nameLower)
        .limit(1)
        .get();
    if (nameQuery.docs.isNotEmpty) return 'name-used';

    final passwordQuery = await db
        .collection('users')
        .where('passwordKey', isEqualTo: passwordKey)
        .limit(1)
        .get();
    if (passwordQuery.docs.isNotEmpty) return 'password-used';

    return null;
  }

  static Future<void> registerWithPassword({
    required String name,
    required String phone,
    required String email,
    required String password,
    required String role,
  }) async {
    final digits = phoneDigits(phone);
    if (digits.isEmpty) throw Exception('invalid-phone');

    final credential = await auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    await credential.user?.updateDisplayName(name.trim());

    await db.collection('users').doc(digits).set({
      'uid': credential.user?.uid ?? digits,
      'name': name.trim(),
      'nameLower': name.trim().toLowerCase(),
      'phone': digits,
      'email': email.trim().toLowerCase(),
      'authEmail': email.trim().toLowerCase(),
      'role': role,
      'location': AppStore.currentUserLocation,
      'address': AppStore.currentUserAddress,
      'phoneVerified': false,
      'authMode': 'password',
      'passwordKey': password.trim(),
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    AppStore.currentUserName = name.trim();
    AppStore.currentUserPhone = digits;
    AppStore.currentUserEmail = email.trim().toLowerCase();
    AppStore.currentUserRole = role;
  }

  static Future<Map<String, dynamic>> loginWithPhonePassword({
    required String phone,
    required String password,
    String? expectedRole,
  }) async {
    final savedUser = await findUserByPhone(phone);
    if (savedUser == null) throw Exception('user-not-found');

    final savedRole = savedUser['role']?.toString().trim().toLowerCase() ?? 'user';
    final selectedRole = expectedRole?.trim().toLowerCase();
    if (selectedRole != null &&
        selectedRole.isNotEmpty &&
        savedRole != selectedRole) {
      throw Exception('role-mismatch');
    }

    final digits = phoneDigits(phone);
    final authEmail =
        savedUser['authEmail']?.toString().trim().toLowerCase() ??
            savedUser['email']?.toString().trim().toLowerCase() ??
            authEmailForPhone(digits);

    try {
      await auth.signInWithEmailAndPassword(email: authEmail, password: password);
      await loadUserData(savedUser);
    } on FirebaseAuthException {
      rethrow;
    }

    await db.collection('users').doc(digits).set({
      'lastLoginAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return savedUser;
  }


  static Future<Map<String, dynamic>?> findRegisteredUserForGoogle({
    required String email,
    required String uid,
  }) async {
    final cleanEmail = email.trim().toLowerCase();
    if (cleanEmail.isNotEmpty) {
      final authEmailQuery = await db
          .collection('users')
          .where('authEmail', isEqualTo: cleanEmail)
          .limit(1)
          .get();
      if (authEmailQuery.docs.isNotEmpty) return authEmailQuery.docs.first.data();

      final emailQuery = await db
          .collection('users')
          .where('email', isEqualTo: cleanEmail)
          .limit(1)
          .get();
      if (emailQuery.docs.isNotEmpty) return emailQuery.docs.first.data();
    }
    if (uid.isNotEmpty) {
      final uidQuery = await db
          .collection('users')
          .where('uid', isEqualTo: uid)
          .limit(1)
          .get();
      if (uidQuery.docs.isNotEmpty) return uidQuery.docs.first.data();
    }
    return null;
  }

  static Future<Map<String, dynamic>> signInWithGoogle({String? expectedRole}) async {
    final googleUser = await GoogleSignIn(scopes: ['email', 'profile']).signIn();
    if (googleUser == null) throw Exception('google-login-cancelled');

    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );
    final userCredential = await auth.signInWithCredential(credential);
    final user = userCredential.user;
    if (user == null) throw Exception('google-login-failed');

    final registered = await findRegisteredUserForGoogle(
      email: user.email ?? '',
      uid: user.uid,
    );
    if (registered == null) {
      await GoogleSignIn().signOut();
      await auth.signOut();
      throw Exception('google-not-registered');
    }

    final savedRole =
        registered['role']?.toString().trim().toLowerCase() ?? 'user';
    final selectedRole = expectedRole?.trim().toLowerCase();
    if (selectedRole != null &&
        selectedRole.isNotEmpty &&
        savedRole != selectedRole) {
      await GoogleSignIn().signOut();
      await auth.signOut();
      throw Exception('role-mismatch');
    }

    await loadUserData(registered);
    final phone = registered['phone']?.toString().trim() ?? '';
    if (phone.isNotEmpty) {
      await db.collection('users').doc(phone).set({
        'lastLoginAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
    return registered;
  }

  static Future<void> loadUserData(Map<String, dynamic> data) async {
    AppStore.currentUserName = data['name']?.toString() ?? 'User';
    AppStore.currentUserPhone = data['phone']?.toString() ?? '';
    AppStore.currentUserEmail = data['email']?.toString() ?? '';
    AppStore.currentUserRole = data['role']?.toString() ?? 'User';
    AppStore.currentUserLocation = data['location']?.toString() ?? '';
    AppStore.currentUserAddress = data['address']?.toString() ?? '';
  }

  static Future<void> saveCurrentUser({
    required String name,
    required String phone,
    required String role,
    String email = "",
  }) async {
    final user = auth.currentUser;
    if (user == null) return;

    final digits = phoneDigits(phone);
    await db.collection('users').doc(digits).set({
      'uid': user.uid,
      'name': name.trim().isEmpty ? 'User' : name.trim(),
      'phone': digits,
      'email': email.trim().toLowerCase(),
      'role': role,
      'location': AppStore.currentUserLocation,
      'address': AppStore.currentUserAddress,
      'phoneVerified': true,
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    AppStore.currentUserName = name.trim().isEmpty ? 'User' : name.trim();
    AppStore.currentUserPhone = digits;
    AppStore.currentUserEmail = email.trim().toLowerCase();
    AppStore.currentUserRole = role;
  }

  static Future<void> saveDemoUser({
    required String name,
    required String phone,
    required String role,
    String email = "",
  }) async {
    final digits = phoneDigits(phone);
    if (digits.isEmpty) return;

    await db.collection('users').doc(digits).set({
      'uid': digits,
      'name': name.trim().isEmpty ? 'User' : name.trim(),
      'phone': digits,
      'email': email.trim().toLowerCase(),
      'role': role,
      'location': AppStore.currentUserLocation,
      'address': AppStore.currentUserAddress,
      'phoneVerified': true,
      'authMode': 'demoOtp',
      'updatedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    AppStore.currentUserName = name.trim().isEmpty ? 'User' : name.trim();
    AppStore.currentUserPhone = digits;
    AppStore.currentUserEmail = email.trim().toLowerCase();
    AppStore.currentUserRole = role;
  }

  static Future<Map<String, dynamic>?> findUserByPhone(String phone) async {
    final normalized = normalizeIndianPhone(phone);
    final allDigits = normalized.isNotEmpty
        ? normalized.replaceAll(RegExp(r'[^0-9]'), '')
        : phone.replaceAll(RegExp(r'[^0-9]'), '');
    final last10 = allDigits.length >= 10
        ? allDigits.substring(allDigits.length - 10)
        : allDigits;
    final ids = <String>{
      if (allDigits.isNotEmpty) allDigits,
      if (last10.isNotEmpty) last10,
      if (last10.length == 10) '91$last10',
    }.toList();

    for (final id in ids) {
      final doc = await db.collection('users').doc(id).get();
      if (doc.exists) return doc.data();
    }

    for (final id in ids) {
      final query = await db
          .collection('users')
          .where('phone', isEqualTo: id)
          .limit(1)
          .get();
      if (query.docs.isNotEmpty) return query.docs.first.data();
    }

    return null;
  }

  static Future<String> loadCurrentUser() async {
    final user = auth.currentUser;
    if (user == null) return 'User';

    final phoneId = AppStore.currentUserPhone.trim();
    final doc = phoneId.isNotEmpty
        ? await db.collection('users').doc(phoneId).get()
        : await db.collection('users').doc(user.uid).get();
    final data = doc.data();
    if (data == null) return 'User';

    await loadUserData(data);
    final loginDocId =
        AppStore.currentUserPhone.isNotEmpty ? AppStore.currentUserPhone : user.uid;
    await db.collection('users').doc(loginDocId).set({
      'phoneVerified': true,
      'lastLoginAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
    return data['role']?.toString() ?? 'User';
  }

  static Future<void> saveProfile({
    required String name,
    required String phone,
    required String email,
    required String role,
    required String location,
    required String address,
  }) async {
    final digits = phoneDigits(phone);
    AppStore.currentUserName = name.trim();
    AppStore.currentUserPhone = digits;
    AppStore.currentUserEmail = email.trim().toLowerCase();
    AppStore.currentUserRole = role;
    AppStore.currentUserLocation = location.trim();
    AppStore.currentUserAddress = address.trim();

    final userId = currentUserId().isEmpty ? digits : currentUserId();
    if (userId.isEmpty) return;

    await db.collection('users').doc(userId).set({
      'uid': auth.currentUser?.uid ?? userId,
      'name': AppStore.currentUserName,
      'phone': AppStore.currentUserPhone,
      'email': AppStore.currentUserEmail,
      'role': AppStore.currentUserRole,
      'location': AppStore.currentUserLocation,
      'address': AppStore.currentUserAddress,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> loadProfile() async {
    final userId = currentUserId();
    if (userId.isEmpty) return;

    final doc = await db.collection('users').doc(userId).get();
    final data = doc.data();
    if (data == null) return;

    AppStore.currentUserName = data['name']?.toString() ?? AppStore.currentUserName;
    AppStore.currentUserPhone = data['phone']?.toString() ?? AppStore.currentUserPhone;
    AppStore.currentUserEmail = data['email']?.toString() ?? AppStore.currentUserEmail;
    AppStore.currentUserRole = data['role']?.toString() ?? AppStore.currentUserRole;
    AppStore.currentUserLocation =
        data['location']?.toString() ?? AppStore.currentUserLocation;
    AppStore.currentUserAddress =
        data['address']?.toString() ?? AppStore.currentUserAddress;
  }

  static Future<void> seedAgentsFromLocalProducts() async {
    for (final product in AppStore.products) {
      final ref = db.collection('agents').doc(product.id);
      final existing = await ref.get();
      if (existing.exists) {
        await ref.set({
          'machine': product.nameEn,
          'machineTa': product.nameTa,
          'locationTa': product.locationTa,
          'image': product.image,
          'reviewTa': product.reviewTa,
          'updatedAt': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));
        continue;
      }

      await ref.set({
        'machine': product.nameEn,
        'machineTa': product.nameTa,
        'agentName': product.agentName,
        'agentPhone': product.agentPhone,
        'location': product.locationEn,
        'locationTa': product.locationTa,
        'image': product.image,
        'hourlyRate': product.hourlyRate,
        'distanceRate': product.distanceRate,
        'distanceKm': product.distanceKm,
        'stock': product.stock,
        'available': product.available && product.stock > 0,
        'rating': product.rating,
        'review': product.reviewEn,
        'reviewTa': product.reviewTa,
        'distanceAvailable': product.distanceAvailable,
        'vendorAvailable': product.vendorAvailable,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    }
  }

  static Future<String> createLocalProductBooking({
    required Map<String, dynamic> product,
    required String workLocation,
    String paymentMethod = 'COD',
    String usageTime = '',
    String deliveryNote = '',
    double? userLat,
    double? userLng,
    int durationHours = 1,
    double? distanceKm,
    double? distanceRate,
    double? totalAmount,
  }) async {
    final agentId = product['id']?.toString() ??
        product['machine']?.toString().toLowerCase().replaceAll(' ', '_') ??
        db.collection('agents').doc().id;

    await db.collection('agents').doc(agentId).set({
      ...product,
      'available': product['available'] == true,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    return createAgentBooking(
      agentId: agentId,
      agent: product,
      workLocation: workLocation,
      paymentMethod: paymentMethod,
      usageTime: usageTime,
      deliveryNote: deliveryNote,
      userLat: userLat,
      userLng: userLng,
      durationHours: durationHours,
      distanceKm: distanceKm,
      distanceRate: distanceRate,
      totalAmount: totalAmount,
    );
  }

  static Future<void> saveBooking(Booking booking) async {
    final user = auth.currentUser;
    final userId = currentUserId();
    final agentPhoneDigits = phoneDigits(booking.agentPhone);
    final data = booking.toMap()
      ..['uid'] = user?.uid
      ..['userId'] = userId
      ..['userName'] = booking.user
      ..['machine'] = booking.product
      ..['machineTa'] = booking.product
      ..['agentId'] = booking.productId
      ..['agentOwnerId'] = agentPhoneDigits
      ..['agentName'] = booking.vendor
      ..['agentPhone'] = agentPhoneDigits.isEmpty ? booking.agentPhone : agentPhoneDigits
      ..['workLocation'] = booking.location
      ..['usageTime'] = '${booking.date} ${booking.time}'
      ..['paymentMethod'] = 'COD'
      ..['createdAt'] = FieldValue.serverTimestamp()
      ..['updatedAt'] = FieldValue.serverTimestamp();

    final doc = await db.collection('bookings').add(data);
    AppStore.bookings.add(Booking.fromMap(doc.id, booking.toMap()));
  }

  static Future<void> loadBookings() async {
    final user = auth.currentUser;
    Query<Map<String, dynamic>> query = db.collection('bookings');

    if (user != null) {
      query = query.where('uid', isEqualTo: user.uid);
    }

    final snapshot = await query.get();
    AppStore.bookings = snapshot.docs
        .map((doc) => Booking.fromMap(doc.id, doc.data()))
        .toList();
  }

  static Future<void> updateBooking(Booking booking) async {
    if (booking.id.isEmpty) return;
    await db.collection('bookings').doc(booking.id).set({
      ...booking.toMap(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<String> createAgentBooking({
    required String agentId,
    required Map<String, dynamic> agent,
    required String workLocation,
    String paymentMethod = 'COD',
    String usageTime = '',
    String deliveryNote = '',
    double? userLat,
    double? userLng,
    int durationHours = 1,
    double? distanceKm,
    double? distanceRate,
    double? totalAmount,
  }) async {
    final stock = (agent['stock'] is num) ? (agent['stock'] as num).toInt() : 0;
    if (agent['available'] != true || stock <= 0) {
      throw Exception('not-available');
    }

    final bookingRef = db.collection('bookings').doc();
    final agentRef = db.collection('agents').doc(agentId);

    await db.runTransaction((transaction) async {
      final agentSnap = await transaction.get(agentRef);
      final latest = agentSnap.data() ?? {};
      final latestStock =
          (latest['stock'] is num) ? (latest['stock'] as num).toInt() : 0;
      if (latest['available'] != true || latestStock <= 0) {
        throw Exception('not-available');
      }

      transaction.set(bookingRef, {
        'userId': currentUserId(),
        'userName': AppStore.currentUserName,
        'userPhone': AppStore.currentUserPhone,
        'agentId': agentId,
        'agentOwnerId': latest['ownerId'] ??
            latest['agentPhone'] ??
            agent['ownerId'] ??
            agent['agentPhone'] ??
            '',
        'agentName': latest['agentName'] ?? agent['agentName'] ?? '',
        'agentPhone': phoneDigits(
          (latest['agentPhone'] ?? agent['agentPhone'] ?? '').toString(),
        ),
        'agentLocation': latest['location'] ?? agent['location'] ?? '',
        'agentLat': latest['lat'] ?? agent['lat'],
        'agentLng': latest['lng'] ?? agent['lng'],
        'machine': latest['machine'] ?? agent['machine'] ?? 'Unknown Machine',
        'machineTa': latest['machineTa'] ?? agent['machineTa'] ?? '',
        'image': latest['image'] ?? agent['image'] ?? '',
        'hourlyRate': latest['hourlyRate'] ?? agent['hourlyRate'] ?? 0,
        'durationHours': durationHours,
        'distanceKm': distanceKm ?? latest['distanceKm'] ?? agent['distanceKm'] ?? 0,
        'distanceRate':
            distanceRate ?? latest['distanceRate'] ?? agent['distanceRate'] ?? 0,
        'price': totalAmount ?? latest['hourlyRate'] ?? agent['hourlyRate'] ?? 0,
        'workLocation': workLocation,
        'userLat': userLat,
        'userLng': userLng,
        'usageTime': usageTime,
        'deliveryNote': deliveryNote,
        'status': 'Pending',
        'paymentMethod': paymentMethod,
        'paymentStatus': paymentMethod == 'COD' ? 'COD Pending' : 'Pending',
        'refundStatus': 'Not Requested',
        'refundAmount': 0,
        'deductionAmount': 0,
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
      });

      final nextStock = latestStock - 1;
      transaction.update(agentRef, {
        'stock': FieldValue.increment(-1),
        'available': nextStock > 0,
        'updatedAt': FieldValue.serverTimestamp(),
      });
    });

    return bookingRef.id;
  }

  static Future<void> updateAgentAvailability({
    required String agentId,
    required bool available,
  }) {
    return db.collection('agents').doc(agentId).set({
      'available': available,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> incrementAgentStock({
    required String agentId,
    required int change,
  }) async {
    final ref = db.collection('agents').doc(agentId);
    await db.runTransaction((transaction) async {
      final snap = await transaction.get(ref);
      final data = snap.data() ?? {};
      final stock = (data['stock'] is num) ? (data['stock'] as num).toInt() : 0;
      final nextStock = (stock + change).clamp(0, 999).toInt();
      transaction.set(ref, {
        'stock': nextStock,
        'available': nextStock > 0
            ? (change > 0 ? true : data['available'] == true)
            : false,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    });
  }

  static Future<void> updateBookingStatus({
    required String bookingId,
    required String status,
  }) {
    return db.collection('bookings').doc(bookingId).set({
      'status': status,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> updatePaymentStatus({
    required String bookingId,
    required String paymentStatus,
  }) {
    return db.collection('bookings').doc(bookingId).set({
      'paymentStatus': paymentStatus,
      if (paymentStatus == 'Paid' || paymentStatus == 'Received') 'paidAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> completeBooking({
    required String bookingId,
  }) {
    return db.collection('bookings').doc(bookingId).set({
      'status': 'Completed',
      'paymentStatus': 'Received',
      'completedAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));
  }

  static Future<void> requestRazorpayRefund({
    required String bookingId,
    required double amount,
    required String reason,
  }) async {
    await db.collection('bookings').doc(bookingId).set({
      'status': 'Cancelled',
      'refundStatus': 'Processing',
      'refundReason': reason,
      'updatedAt': FieldValue.serverTimestamp(),
    }, SetOptions(merge: true));

    await FirebaseFunctions.instance.httpsCallable('requestRazorpayRefund').call({
      'bookingId': bookingId,
      'amount': amount,
      'reason': reason,
    });
  }
  static Future<void> addHelpRequest({
    required String message,
    String bookingId = '',
    String issueType = 'General',
  }) {
    return db.collection('helpRequests').add({
      'userId': currentUserId(),
      'userName': AppStore.currentUserName,
      'userPhone': AppStore.currentUserPhone,
      'bookingId': bookingId,
      'issueType': issueType,
      'message': message,
      'status': 'Open',
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  static Future<void> resetPasswordInApp({
    required String phone,
    required String email,
    required String newPassword,
  }) async {
    final digits = phoneDigits(phone);
    if (digits.isEmpty || !isValidEmail(email) || newPassword.length < 6) {
      throw Exception('invalid-reset-details');
    }

    await FirebaseFunctions.instance.httpsCallable('resetPasswordWithPhone').call({
      'phone': digits,
      'email': email.trim().toLowerCase(),
      'newPassword': newPassword,
    });
  }

  static Future<void> clearSession({bool signOut = true}) async {
    if (signOut) {
      await auth.signOut();
    }
    AppStore.currentUserName = '';
    AppStore.currentUserPhone = '';
    AppStore.currentUserEmail = '';
    AppStore.currentUserRole = 'User';
    AppStore.currentUserLocation = '';
    AppStore.currentUserAddress = '';
  }
}
