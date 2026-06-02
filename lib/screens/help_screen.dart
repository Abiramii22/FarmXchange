import 'package:flutter/material.dart';

import '../data/app_store.dart';
import '../services/firebase_service.dart';

class HelpScreen extends StatefulWidget {
  const HelpScreen({super.key});

  @override
  State<HelpScreen> createState() => _HelpScreenState();
}

class _HelpScreenState extends State<HelpScreen> {
  final feedback = TextEditingController();

  @override
  void dispose() {
    feedback.dispose();
    super.dispose();
  }

  Future<void> submitFeedback() async {
    final text = feedback.text.trim();
    if (text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStore.tr(
              "Type your feedback first",
              "முதலில் உங்கள் கருத்தை எழுதவும்",
            ),
          ),
        ),
      );
      return;
    }

    try {
      await FirebaseService.addHelpRequest(message: text)
          .timeout(const Duration(seconds: 10));
      AppStore.logs.add("Feedback: $text");
      feedback.clear();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStore.tr(
              "Feedback saved. Admin can review it.",
              "Feedback saved. Admin can review it.",
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Help request failed: $e")),
      );
    }
  }

  Future<void> requestTalkToAdmin() async {
    try {
      await FirebaseService.addHelpRequest(
        message: "Need Help / Talk to us",
        issueType: "Need Help",
      ).timeout(const Duration(seconds: 10));
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStore.tr(
              "Request sent to admin",
              "கோரிக்கை admin-க்கு அனுப்பப்பட்டது",
            ),
          ),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Help request failed: $e")),
      );
    }
  }

  Widget section({
    required IconData icon,
    required String titleEn,
    required String titleTa,
    required List<String> linesEn,
    required List<String> linesTa,
  }) {
    final lines = AppStore.isTamil ? linesTa : linesEn;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.green),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    AppStore.tr(titleEn, titleTa),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...lines.map(
              (line) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Text("• $line"),
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
        title: Text(AppStore.tr("Help & About", "உதவி & பயன்பாட்டு விவரம்")),
        backgroundColor: Colors.green,
        actions: [
          DropdownButton<bool>(
            value: AppStore.isTamil,
            dropdownColor: Colors.white,
            underline: const SizedBox(),
            items: const [
              DropdownMenuItem(value: false, child: Text("English")),
              DropdownMenuItem(value: true, child: Text("தமிழ்")),
            ],
            onChanged: (value) {
              setState(() => AppStore.isTamil = value ?? false);
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(12),
        children: [
          ElevatedButton.icon(
            onPressed: requestTalkToAdmin,
            icon: const Icon(Icons.support_agent),
            label: Text(
              AppStore.tr(
                "Need Help / Talk to us",
                "உதவி வேண்டுமா / எங்களிடம் பேசுங்கள்",
              ),
            ),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
          ),
          const SizedBox(height: 10),
          section(
            icon: Icons.info_outline,
            titleEn: "About FarmXchange",
            titleTa: "FarmXchange பற்றி",
            linesEn: const [
              "FarmXchange connects farmers with equipment owners and agents.",
              "Users can book tools, machines, and farm services.",
              "Agents can manage equipment availability and booking updates.",
              "Admins can monitor bookings, revenue, refunds, and feedback.",
            ],
            linesTa: const [
              "FarmXchange விவசாயிகளை கருவி உரிமையாளர்கள் மற்றும் முகவர்களுடன் இணைக்கிறது.",
              "பயனர்கள் கருவிகள், இயந்திரங்கள், விவசாய சேவைகளை பதிவு செய்யலாம்.",
              "முகவர்கள் கருவி கிடைக்கும் நிலை மற்றும் booking updates-ஐ நிர்வகிக்கலாம்.",
              "நிர்வாகி bookings, வருமானம், refund, feedback ஆகியவற்றை கண்காணிக்கலாம்.",
            ],
          ),
          section(
            icon: Icons.login,
            titleEn: "How to Register and Login",
            titleTa: "பதிவு மற்றும் Login செய்வது எப்படி",
            linesEn: const [
              "Register with name, phone number, email, password, and role.",
              "Use the same password for login.",
              "For login, enter phone number and password.",
              "You can use Forgot Password to reset through email.",
            ],
            linesTa: const [
              "பெயர், போன் எண், email, password மற்றும் role வைத்து பதிவு செய்யவும்.",
              "அதே password-ஐ login செய்ய பயன்படுத்தவும்.",
              "Login செய்ய போன் எண் மற்றும் password உள்ளிடவும்.",
              "Forgot Password மூலம் email வழியாக reset செய்யலாம்.",
            ],
          ),
          section(
            icon: Icons.agriculture,
            titleEn: "Booking and Purchase",
            titleTa: "Booking மற்றும் Purchase",
            linesEn: const [
              "Choose a product or machine from the product list.",
              "Select date, time, duration, and work location.",
              "Confirm booking to save it in the database.",
              "Booking status and purchase details appear in the dashboard.",
            ],
            linesTa: const [
              "Product list-ல் இருந்து கருவி அல்லது இயந்திரத்தை தேர்வு செய்யவும்.",
              "தேதி, நேரம், நேர அளவு, வேலை இடம் ஆகியவற்றை தேர்வு செய்யவும்.",
              "Confirm booking அழுத்தினால் database-ல் save ஆகும்.",
              "Booking நிலை மற்றும் purchase details dashboard-ல் காணப்படும்.",
            ],
          ),
          section(
            icon: Icons.location_on,
            titleEn: "Location and Cost",
            titleTa: "Location மற்றும் செலவு கணக்கு",
            linesEn: const [
              "The app will ask location permission when live tracking is enabled.",
              "Nearby agents can be sorted using distance from the user.",
              "Final amount can include hourly charge, distance charge, and service charge.",
              "Location permission must be allowed on the phone.",
            ],
            linesTa: const [
              "Live tracking enable செய்தால் app location permission கேட்கும்.",
              "பயனர் இடத்திலிருந்து தூரம் வைத்து nearby agents காட்டலாம்.",
              "மொத்த தொகையில் hourly charge, distance charge, service charge சேர்க்கலாம்.",
              "மொபைலில் location permission allow செய்ய வேண்டும்.",
            ],
          ),
          section(
            icon: Icons.payments,
            titleEn: "Payment and Refund",
            titleTa: "Payment மற்றும் Refund",
            linesEn: const [
              "Cash on delivery can be marked as Pending, Paid, or Received.",
              "UPI apps such as Google Pay, PhonePe, Paytm can be opened through UPI link.",
              "Real online payment and automatic refund need a merchant account and backend API.",
              "Cancellation can show refund amount, deduction, and reason.",
            ],
            linesTa: const [
              "Cash on delivery-ஐ Pending, Paid, Received என்று mark செய்யலாம்.",
              "Google Pay, PhonePe, Paytm போன்ற UPI apps-ஐ UPI link மூலம் திறக்கலாம்.",
              "Real online payment மற்றும் automatic refund-க்கு merchant account மற்றும் backend API தேவை.",
              "Cancel செய்தால் refund amount, deduction, reason ஆகியவை காட்டலாம்.",
            ],
          ),
          section(
            icon: Icons.report_problem,
            titleEn: "Report a Fault",
            titleTa: "பிழை / குறை சொல்ல",
            linesEn: const [
              "Use this page to report app issues, wrong prices, location issues, or payment problems.",
              "Mention product name, agent name, booking date, and the issue clearly.",
              "Admin can review feedback and improve vendor quality.",
            ],
            linesTa: const [
              "App issue, தவறான விலை, location issue, payment problem ஆகியவற்றை இங்கே சொல்லலாம்.",
              "Product name, agent name, booking date, issue ஆகியவற்றை தெளிவாக எழுதவும்.",
              "Admin feedback பார்த்து vendor quality-ஐ மேம்படுத்தலாம்.",
            ],
          ),
          TextField(
            controller: feedback,
            minLines: 3,
            maxLines: 5,
            decoration: InputDecoration(
              labelText: AppStore.tr(
                "Vendor/App Feedback",
                "Vendor/App கருத்து",
              ),
              hintText: AppStore.tr(
                "Type good or bad feedback here",
                "நல்லது அல்லது குறைபாடு பற்றிய கருத்தை இங்கே எழுதவும்",
              ),
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 10),
          ElevatedButton.icon(
            onPressed: submitFeedback,
            icon: const Icon(Icons.send),
            label: Text(AppStore.tr("Submit Feedback", "கருத்தை சமர்ப்பிக்கவும்")),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
          ),
        ],
      ),
    );
  }
}
