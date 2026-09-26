// ============================================================
// MediReach — Multilingual Localization Engine
// Instant switcher for English (en), Telugu (te), and Hindi (hi).
// ============================================================
import 'package:flutter/material.dart';

enum AppLanguage { en, te, hi }

final appLanguageNotifier = ValueNotifier<AppLanguage>(AppLanguage.en);

class AppLocale {
  static const Map<AppLanguage, Map<String, String>> _strings = {
    AppLanguage.en: {
      'app_title': 'MediReach',
      'greeting': '👋 Hello, ',
      'sub_greeting': 'How can we help today?',
      'emergency_banner': 'Get Immediate Medical Help',
      'call': 'Call',
      'quick_services': 'Quick Services',
      'reminders': '🔔 Reminders',
      'nearby_healthcare': '📍 Nearby Healthcare',
      'diagnostics': 'Diagnostics',
      'teleconsult': 'Teleconsult',
      'appointment': 'Appointment',
      'referrals': 'Referrals',
      'my_records': 'My Records',
      'medicines': 'Medicines',
      'triage': 'Triage',
      'family_records': 'Family Records',
      'patients': 'Patients',
      'profile': 'Profile',
      'home': 'Home',
      'record_vitals': 'Record Vitals',
      'new_referral': 'New Referral',
      'book_appointment': 'Book Appointment',
      'offline_sync': 'Offline Sync',
      'search_hint': 'Search Doctors, Facilities, Services...',
      'low_risk': 'Low Priority',
      'mod_risk': 'Moderate Priority',
      'high_risk': 'High Risk',
      'emergency_risk': 'Emergency Alert',
    },
    AppLanguage.te: {
      'app_title': 'మెడిరీచ్',
      'greeting': '👋 నమస్కారం, ',
      'sub_greeting': 'ఈ రోజు మీకు ఎలా సహాయపడగలం?',
      'emergency_banner': 'తక్షణ అత్యవసర వైద్య సహాయం',
      'call': 'కాల్ చేయండి',
      'quick_services': 'త్వరిత సేవలు',
      'reminders': '🔔 రిమైండర్లు',
      'nearby_healthcare': '📍 సమీప ఆరోగ్య కేంద్రాలు',
      'diagnostics': 'రోగ నిర్ధారణ (ల్యాబ్)',
      'teleconsult': 'టెలికన్సల్ట్',
      'appointment': 'అపాయింట్‌మెంట్',
      'referrals': 'రెఫరల్స్',
      'my_records': 'వైద్య రికార్డులు',
      'medicines': 'మందులు',
      'triage': 'డిజిటల్ ట్రయేజ్',
      'family_records': 'కుటుంబ రికార్డులు',
      'patients': 'రోగులు',
      'profile': 'ప్రొఫైల్',
      'home': 'హోమ్',
      'record_vitals': 'వైటల్స్ నమోదు',
      'new_referral': 'కొత్త రెఫరల్',
      'book_appointment': 'అపాయింట్‌మెంట్ బుక్ చేయండి',
      'offline_sync': 'ఆఫ్‌లైన్ సింక్',
      'search_hint': 'వైద్యులు, ఆసుపత్రులు, సేవల కోసం శోధించండి...',
      'low_risk': 'సాధారణం (తక్కువ ప్రాధాన్యత)',
      'mod_risk': 'మితమైన ప్రాధాన్యత',
      'high_risk': 'అధిక ప్రమాదం',
      'emergency_risk': 'అత్యవసర పరిస్థితి',
    },
    AppLanguage.hi: {
      'app_title': 'मेडीरीच',
      'greeting': '👋 नमस्ते, ',
      'sub_greeting': 'आज हम आपकी क्या मदद कर सकते हैं?',
      'emergency_banner': 'तत्काल आपातकालीन चिकित्सा सहायता',
      'call': 'कॉल करें',
      'quick_services': 'त्वरित सेवाएं',
      'reminders': '🔔 रिमाइंडर्स',
      'nearby_healthcare': '📍 नजदीकी स्वास्थ्य केंद्र',
      'diagnostics': 'जांच / लैब टेस्ट',
      'teleconsult': 'टेलीकंसल्ट',
      'appointment': 'अपॉइंटमेंट',
      'referrals': 'रेफरल',
      'my_records': 'मेडिकल रिकॉर्ड्स',
      'medicines': 'दवाइयां',
      'triage': 'डिजिटल ट्राइएज',
      'family_records': 'परिवार रिकॉर्ड्स',
      'patients': 'मरीज',
      'profile': 'प्रोफाइल',
      'home': 'होम',
      'record_vitals': 'वाइटल्स दर्ज करें',
      'new_referral': 'नया रेफरल',
      'book_appointment': 'अपॉइंटमेंट बुक करें',
      'offline_sync': 'ऑफलाइन सिंक',
      'search_hint': 'डॉक्टर, अस्पताल या सेवा खोजें...',
      'low_risk': 'सामान्य (कम प्राथमिकता)',
      'mod_risk': 'मध्यम प्राथमिकता',
      'high_risk': 'उच्च जोखिम',
      'emergency_risk': 'आपातकालीन चेतावनी',
    },
  };

  static String tr(String key) {
    final lang = appLanguageNotifier.value;
    return _strings[lang]?[key] ?? _strings[AppLanguage.en]?[key] ?? key;
  }

  static String getLanguageName(AppLanguage l) {
    switch (l) {
      case AppLanguage.en: return 'English';
      case AppLanguage.te: return 'తెలుగు (Telugu)';
      case AppLanguage.hi: return 'हिंदी (Hindi)';
    }
  }
}
