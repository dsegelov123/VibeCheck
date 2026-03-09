import 'package:url_launcher/url_launcher.dart';

class SafetyService {
  static const String samaritansPhone = '111'; // NHS 111 for triage
  static const String samaritansFull = '116123'; // Samaritans UK

  Future<void> callSamaritans() async {
    final Uri url = Uri.parse('tel:$samaritansFull');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  Future<void> openSamaritansWeb() async {
    final Uri url = Uri.parse('https://www.samaritans.org/');
    if (!await launchUrl(url)) {
      throw Exception('Could not launch $url');
    }
  }

  /// Check if the recent emotional patterns warrant a safety nudge
  bool shouldShowSafetyNudge(List<String> recentMoods) {
    if (recentMoods.length < 3) return false;
    
    // Example: If last 3 snapshots are 'sad' or 'anxious'
    int riskCount = recentMoods.where((m) => m == 'sad' || m == 'anxious').length;
    return riskCount >= 3;
  }
}
