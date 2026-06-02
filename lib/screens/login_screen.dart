import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../services/firebase_service.dart';
import '../widgets/auth_background.dart';
import 'admin_home.dart';
import 'agent_home.dart';
import 'register_screen.dart';
import 'user_home.dart' as user;

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final mobile = TextEditingController();
  final password = TextEditingController();
  final resetPhone = TextEditingController();
  final resetEmail = TextEditingController();
  final resetNewPassword = TextEditingController();
  final roles = const ["user", "agent", "admin"];

  String selectedRole = "user";
  bool loggingIn = false;
  bool googleLoading = false;
  bool obscurePassword = true;

  @override
  void dispose() {
    mobile.dispose();
    password.dispose();
    resetPhone.dispose();
    resetEmail.dispose();
    resetNewPassword.dispose();
    super.dispose();
  }

  String t(String en, String ta) => AppStore.tr(en, ta);

  Widget homeForRole(String role) {
    final normalized = role.toLowerCase();
    if (normalized.contains('admin')) return const AdminHome();
    if (normalized.contains('agent')) return const AgentHome();
    return const user.UserHome();
  }

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
      SnackBar(content: Text(AppStore.isTamil ? ta : en)),
    );
  }

  Future<void> login() async {
    final phoneNumber = FirebaseService.normalizeIndianPhone(mobile.text);
    final userPassword = password.text.trim();

    if (phoneNumber.isEmpty || userPassword.isEmpty) {
      showMsg(
        "Enter phone number and password",
        "போன் எண் மற்றும் password உள்ளிடவும்",
      );
      return;
    }

    setState(() => loggingIn = true);
    try {
      final savedUser = await FirebaseService.loginWithPhonePassword(
        phone: phoneNumber,
        password: userPassword,
        expectedRole: selectedRole,
      ).timeout(const Duration(seconds: 15));
      final savedRole = savedUser['role']?.toString() ?? 'User';
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => homeForRole(savedRole)),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      final message = e.code == 'wrong-password' ||
              e.code == 'invalid-credential' ||
              e.code == 'user-not-found'
          ? "Phone number or password is wrong"
          : "Login failed: ${e.message ?? e.code}";
      showMsg(message, message);
    } catch (e) {
      final text = e.toString();
      final message = text.contains('user-not-found')
          ? "Register first, then login"
          : text.contains('role-mismatch')
              ? "Selected role does not match this registered account"
              : "Login failed: $e";
      showMsg(message, message);
    } finally {
      if (mounted) setState(() => loggingIn = false);
    }
  }

  Future<void> googleLogin() async {
    setState(() => googleLoading = true);
    try {
      final data = await FirebaseService.signInWithGoogle(
        expectedRole: selectedRole,
      ).timeout(const Duration(seconds: 30));
      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => homeForRole(data['role']?.toString() ?? 'user'),
        ),
        (route) => false,
      );
    } catch (e) {
      if (!mounted) return;
      final error = e.toString();
      final message = error.contains('google-not-registered')
          ? t(
              "Register with this Google email first, then login",
              "இந்த Google email-ல் முதலில் பதிவு செய்து பிறகு login செய்யவும்",
            )
          : error.contains('role-mismatch')
              ? t(
                  "Selected role does not match this account",
                  "தேர்ந்தெடுத்த role இந்த account-க்கு பொருந்தவில்லை",
                )
              : t(
                  "Google login failed. Check Google provider and SHA in Firebase.",
                  "Google login தோல்வி. Firebase-ல் Google provider மற்றும் SHA சரிபார்க்கவும்.",
                );
      showMsg(message, message);
    } finally {
      if (mounted) setState(() => googleLoading = false);
    }
  }

  Future<void> forgotPassword() async {
    resetPhone.text = mobile.text.trim();
    resetEmail.clear();
    resetNewPassword.clear();
    bool resetLoading = false;

    await showDialog<void>(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (dialogContext, setDialogState) {
            Future<void> changePassword() async {
              final phoneNumber = FirebaseService.normalizeIndianPhone(
                resetPhone.text,
              );
              final email = resetEmail.text.trim();
              final newPassword = resetNewPassword.text.trim();

              if (phoneNumber.isEmpty ||
                  !FirebaseService.isValidEmail(email) ||
                  newPassword.length < 6) {
                showMsg(
                  "Enter phone, registered email and 6+ character password",
                  "à®ªà¯‹à®©à¯, à®ªà®¤à®¿à®µà¯ à®šà¯†à®¯à¯à®¤ Email, 6 à®Žà®´à¯à®¤à¯à®¤à¯à®•à¯à®•à¯ à®®à¯‡à®²à¯ password à®‰à®³à¯à®³à®¿à®Ÿà®µà¯à®®à¯",
                );
                return;
              }

              setDialogState(() => resetLoading = true);
              try {
                await FirebaseService.resetPasswordInApp(
                  phone: phoneNumber,
                  email: email,
                  newPassword: newPassword,
                ).timeout(const Duration(seconds: 25));

                if (!mounted) return;
                password.text = newPassword;
                Navigator.of(dialogContext).pop();
                showMsg(
                  "Password changed. Login now.",
                  "Password à®®à®¾à®±à¯à®±à®ªà¯à®ªà®Ÿà¯à®Ÿà®¤à¯. à®‡à®ªà¯à®ªà¯‹à®¤à¯ login à®šà¯†à®¯à¯à®¯à®µà¯à®®à¯.",
                );
              } catch (e) {
                if (!mounted) return;
                final error = e.toString();
                final message = error.contains('not-found')
                    ? "Account not found. Check registered phone number."
                    : error.contains('permission-denied')
                        ? "Phone and email do not match this account."
                        : error.contains('invalid-argument')
                            ? "Enter registered phone, email and 6+ character password."
                            : "Password change failed. Try again after restarting the app.";
                showMsg(message, message);
              } finally {
                if (mounted && Navigator.of(dialogContext).canPop()) {
                  setDialogState(() => resetLoading = false);
                }
              }
            }

            return AlertDialog(
              title: Text(t("Change Password", "à®•à®Ÿà®µà¯à®šà¯à®šà¯Šà®²à¯ à®®à®¾à®±à¯à®±à¯")),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: resetPhone,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: t("Registered Phone", "à®ªà®¤à®¿à®µà¯ à®šà¯†à®¯à¯à®¤ à®ªà¯‹à®©à¯"),
                      ),
                    ),
                    TextField(
                      controller: resetEmail,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: t("Registered Email", "à®ªà®¤à®¿à®µà¯ à®šà¯†à®¯à¯à®¤ Email"),
                      ),
                    ),
                    TextField(
                      controller: resetNewPassword,
                      obscureText: true,
                      decoration: InputDecoration(
                        labelText: t("New Password", "à®ªà¯à®¤à®¿à®¯ à®•à®Ÿà®µà¯à®šà¯à®šà¯Šà®²à¯"),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: resetLoading
                      ? null
                      : () => Navigator.of(dialogContext).pop(),
                  child: Text(t("Cancel", "à®°à®¤à¯à®¤à¯")),
                ),
                ElevatedButton(
                  onPressed: resetLoading ? null : changePassword,
                  child: resetLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(t("Change", "à®®à®¾à®±à¯à®±à¯")),
                ),
              ],
            );
          },
        );
      },
    );
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
                  const Text(
                    "FarmXchange",
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  const SizedBox(height: 20),
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
                      labelText: t("Login as", "உள்நுழையும் வகை"),
                      prefixIcon: const Icon(Icons.badge),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: forgotPassword,
                      child: Text(
                        t("Forgot Password?", "Password மறந்துவிட்டதா?"),
                      ),
                    ),
                  ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.orange,
                      ),
                      onPressed: loggingIn ? null : login,
                      child: loggingIn
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : Text(t("Login", "உள்நுழை")),
                    ),
                  ),
                  const SizedBox(height: 10),
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: googleLoading ? null : googleLogin,
                      icon: googleLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.g_mobiledata, size: 28),
                      label: Text(
                        t("Continue with Google", "Google மூலம் தொடரவும்"),
                      ),
                    ),
                  ),
                  const SizedBox(height: 15),
                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const RegisterScreen(),
                        ),
                      ).then((_) => setState(() {}));
                    },
                    child: Text.rich(
                      TextSpan(
                        text: t("New user? ", "புதிய பயனரா? "),
                        children: [
                          TextSpan(
                            text: t("Register here", "இங்கே பதிவு செய்"),
                            style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold,
                            ),
                          )
                        ],
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
