import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../services/firebase_service.dart';
import '../widgets/auth_background.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final name = TextEditingController();
  final mobile = TextEditingController();
  final email = TextEditingController();
  final password = TextEditingController();
  final roles = const ["user", "agent", "admin"];

  String selectedRole = "user";
  bool loading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    name.dispose();
    mobile.dispose();
    email.dispose();
    password.dispose();
    super.dispose();
  }

  String t(String en, String ta) => AppStore.tr(en, ta);

  String roleText(String role) {
    switch (role.toLowerCase()) {
      case "user":
        return t("User", "பயனர்");
      case "agent":
        return t("Agent", "முகவர்");
      case "admin":
        return t("Admin", "நிர்வாகி");
    }
    return role;
  }

  void showMsg(String en, String ta) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t(en, ta))),
    );
  }

  Future<void> register() async {
    final userName = name.text.trim();
    final phoneNumber = FirebaseService.normalizeIndianPhone(mobile.text);
    final userEmail = email.text.trim();
    final userPassword = password.text.trim();

    if (userName.isEmpty ||
        phoneNumber.isEmpty ||
        !FirebaseService.isValidEmail(userEmail) ||
        userPassword.length < 6) {
      showMsg(
        "Enter name, valid phone, email and 6+ character password",
        "பெயர், சரியான போன் எண், email மற்றும் 6 எழுத்துக்கு மேல் password உள்ளிடவும்",
      );
      return;
    }

    setState(() => loading = true);
    try {
      final duplicate = await FirebaseService.validateUniqueRegistration(
        name: userName,
        password: userPassword,
      );
      if (duplicate == 'name-used') {
        showMsg(
          "This name is already used. Please use another name.",
          "இந்த பெயர் ஏற்கனவே பயன்படுத்தப்பட்டுள்ளது. வேறு பெயர் இடவும்.",
        );
        return;
      }
      if (duplicate == 'password-used') {
        showMsg(
          "This password is already used. Please choose another password.",
          "இந்த password ஏற்கனவே பயன்படுத்தப்பட்டுள்ளது. வேறு password இடவும்.",
        );
        return;
      }

      await FirebaseService.registerWithPassword(
        name: userName,
        phone: phoneNumber,
        email: userEmail,
        password: userPassword,
        role: selectedRole,
      );
      if (!mounted) return;
      showMsg(
        "Registration completed. Login with phone number and password.",
        "பதிவு முடிந்தது. போன் எண் மற்றும் password வைத்து login செய்யவும்.",
      );
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LoginScreen()),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      final message = e.toString().contains('email-already-in-use')
          ? "This phone number is already registered."
          : "Registration failed: $e";
      showMsg(message, message);
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: AuthBackground(
        child: Center(
          child: SingleChildScrollView(
            child: Container(
              width: 360,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.96),
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(
                    blurRadius: 24,
                    offset: Offset(0, 10),
                    color: Color(0x260B5A21),
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Align(
                    alignment: Alignment.centerRight,
                    child: DropdownButton<bool>(
                      value: AppStore.isTamil,
                      underline: const SizedBox(),
                      items: const [
                        DropdownMenuItem(value: false, child: Text("English")),
                        DropdownMenuItem(value: true, child: Text("தமிழ்")),
                      ],
                      onChanged: (value) {
                        setState(() => AppStore.isTamil = value ?? false);
                      },
                    ),
                  ),
                  Image.asset('assets/logo.png', height: 90),
                  const SizedBox(height: 10),
                  Text(
                    t("Register", "பதிவு"),
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 20),
                  TextField(
                    controller: name,
                    decoration: InputDecoration(
                      hintText: t("Name", "பெயர்"),
                      prefixIcon: const Icon(Icons.person),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: mobile,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      hintText: t("Phone Number", "போன் எண்"),
                      prefixIcon: const Icon(Icons.phone),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: email,
                    keyboardType: TextInputType.emailAddress,
                    decoration: InputDecoration(
                      hintText: t("Email ID", "மின்னஞ்சல் ID"),
                      prefixIcon: const Icon(Icons.email),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextField(
                    controller: password,
                    obscureText: obscurePassword,
                    decoration: InputDecoration(
                      hintText: t("Password", "கடவுச்சொல்"),
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() => obscurePassword = !obscurePassword);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(
                      t(
                        "Use this password for login. You can reset anytime using Forgot Password.",
                        "இந்த password-ஐ login செய்ய பயன்படுத்தவும். Forgot Password மூலம் எப்போது வேண்டுமானாலும் reset செய்யலாம்.",
                      ),
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ),
                  const SizedBox(height: 15),
                  DropdownButtonFormField<String>(
                    value: selectedRole,
                    items: roles
                        .map(
                          (role) => DropdownMenuItem(
                            value: role,
                            child: Text(roleText(role)),
                          ),
                        )
                        .toList(),
                    onChanged: (value) {
                      setState(() => selectedRole = value ?? roles.first);
                    },
                    decoration: InputDecoration(
                      labelText: t("Register as", "எந்த வகையில் பதிவு"),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      onPressed: loading ? null : register,
                      child: loading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(t("Register", "பதிவு செய்")),
                    ),
                  ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Text(
                      t("Back to Login", "Login பக்கத்திற்கு திரும்பு"),
                      style: const TextStyle(
                        color: Colors.orange,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
