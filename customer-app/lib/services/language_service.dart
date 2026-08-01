import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppLanguage { english, hindi, marathi }

class LanguageService extends ChangeNotifier {
  LanguageService._();
  static final instance = LanguageService._();
  static const _storageKey = 'app_language';

  AppLanguage language = AppLanguage.english;

  String get code => switch (language) {
        AppLanguage.english => 'en',
        AppLanguage.hindi => 'hi',
        AppLanguage.marathi => 'mr',
      };

  String get languageName => switch (language) {
        AppLanguage.english => 'English',
        AppLanguage.hindi => 'हिन्दी',
        AppLanguage.marathi => 'मराठी',
      };

  Future<void> load() async {
    final saved =
        (await SharedPreferences.getInstance()).getString(_storageKey);
    language = AppLanguage.values.firstWhere(
      (item) => item.name == saved,
      orElse: () => AppLanguage.english,
    );
  }

  Future<void> setLanguage(AppLanguage value) async {
    if (language == value) return;
    language = value;
    await (await SharedPreferences.getInstance())
        .setString(_storageKey, value.name);
    notifyListeners();
  }

  String tr(String english) {
    if (language == AppLanguage.english) return english;
    final values = language == AppLanguage.hindi ? _hindi : _marathi;
    return values[english] ?? english;
  }

  static const Map<String, String> _hindi = {
    'Language': 'भाषा',
    'English': 'अंग्रेज़ी',
    'Hindi': 'हिन्दी',
    'Marathi': 'मराठी',
    'Home': 'होम',
    'My Bookings': 'मेरी बुकिंग',
    'Products': 'उत्पाद',
    'Wallet': 'वॉलेट',
    'Profile': 'प्रोफ़ाइल',
    'My Profile': 'मेरी प्रोफ़ाइल',
    'Notifications': 'सूचनाएँ',
    'Help & Support': 'सहायता',
    'Order Water': 'पानी ऑर्डर करें',
    'Repeat Order': 'दोबारा ऑर्डर',
    'My Orders': 'मेरे ऑर्डर',
    'My Wallet': 'मेरा वॉलेट',
    'Support': 'सहायता',
    'New order': 'नया ऑर्डर',
    'Quick reorder': 'जल्दी दोबारा ऑर्डर',
    'Track & history': 'ट्रैक और इतिहास',
    'Balance & history': 'बैलेंस और इतिहास',
    'Help & support': 'सहायता',
    'Wallet Balance': 'वॉलेट बैलेंस',
    'Available Balance': 'उपलब्ध बैलेंस',
    'Event Type': 'कार्यक्रम का प्रकार',
    'Number of Cans': 'कैन की संख्या',
    'Per Can Rate': 'प्रति कैन दर',
    'Total Amount': 'कुल राशि',
    'Event Date & Time': 'कार्यक्रम की तारीख और समय',
    'Select event type': 'कार्यक्रम का प्रकार चुनें',
    'Select number of cans': 'कैन की संख्या चुनें',
    'Enter number of cans': 'कैन की संख्या दर्ज करें',
    'Select date': 'तारीख चुनें',
    'Select time': 'समय चुनें',
    'Select your village': 'अपना गाँव चुनें',
    'Enter address or hall name': 'पता या हॉल का नाम दर्ज करें',
    'Select Required Delivery Time': 'आवश्यक डिलीवरी समय चुनें',
    'Fill in your event details to request a bulk water order.':
        'बल्क पानी ऑर्डर के लिए कार्यक्रम का विवरण भरें।',
    'No delivery slots remain today. Please choose another date.':
        'आज कोई डिलीवरी स्लॉट उपलब्ध नहीं है। कृपया दूसरी तारीख चुनें।',
    'Pending Dues': 'बकाया राशि',
    'Add Money': 'पैसे जोड़ें',
    'View Details': 'विवरण देखें',
    'View All': 'सभी देखें',
    'Most Popular': 'सबसे लोकप्रिय',
    'Shop By Need': 'ज़रूरत के अनुसार',
    'Stay Hydrated, Stay Healthy': 'हाइड्रेटेड रहें, स्वस्थ रहें',
    'Edit': 'संपादित करें',
    'Profile saved.': 'प्रोफ़ाइल सहेजी गई।',
    'Profile photo': 'प्रोफ़ाइल फ़ोटो',
    'Gallery': 'गैलरी',
    'Camera': 'कैमरा',
    'Remove current photo': 'मौजूदा फ़ोटो हटाएँ',
    'Add photo': 'फ़ोटो जोड़ें',
    'Change photo': 'फ़ोटो बदलें',
    'Your Profile': 'आपकी प्रोफ़ाइल',
    'Full Name': 'पूरा नाम',
    'Mobile Number': 'मोबाइल नंबर',
    'Village / Area': 'गाँव / क्षेत्र',
    'Address / Hall Name': 'पता / हॉल का नाम',
    'SAVE CHANGES': 'बदलाव सहेजें',
    'Welcome back': 'वापस आपका स्वागत है',
    'Create your account': 'अपना खाता बनाएँ',
    'Password': 'पासवर्ड',
    'LOGIN': 'लॉगिन',
    'CREATE ACCOUNT': 'खाता बनाएँ',
    'Payment': 'भुगतान',
    'Order Summary': 'ऑर्डर सारांश',
    'Apply': 'लागू करें',
    'Remove': 'हटाएँ',
    'Total': 'कुल',
    'Advance': 'अग्रिम',
    'Balance': 'शेष',
    'Booking Confirmed!': 'बुकिंग पुष्टि हो गई!',
    'Booking Pending': 'बुकिंग लंबित',
    'Request for Change': 'बदलाव का अनुरोध',
    'Request Cancellation': 'रद्द करने का अनुरोध',
    'Change Request': 'बदलाव अनुरोध',
    'Cancel Request': 'रद्द अनुरोध',
    'Transaction History': 'लेनदेन इतिहास',
    'No wallet transactions yet': 'अभी कोई वॉलेट लेनदेन नहीं',
    'Logout': 'लॉग आउट',
  };

  static const Map<String, String> _marathi = {
    'Language': 'भाषा',
    'English': 'इंग्रजी',
    'Hindi': 'हिंदी',
    'Marathi': 'मराठी',
    'Home': 'मुख्यपृष्ठ',
    'My Bookings': 'माझ्या बुकिंग्स',
    'Products': 'उत्पादने',
    'Wallet': 'वॉलेट',
    'Profile': 'प्रोफाइल',
    'My Profile': 'माझे प्रोफाइल',
    'Notifications': 'सूचना',
    'Help & Support': 'मदत व सहाय्य',
    'Order Water': 'पाणी मागवा',
    'Repeat Order': 'पुन्हा ऑर्डर',
    'My Orders': 'माझे ऑर्डर',
    'My Wallet': 'माझे वॉलेट',
    'Support': 'मदत',
    'New order': 'नवीन ऑर्डर',
    'Quick reorder': 'जलद पुन्हा ऑर्डर',
    'Track & history': 'ट्रॅक व इतिहास',
    'Balance & history': 'शिल्लक व इतिहास',
    'Help & support': 'मदत व सहाय्य',
    'Wallet Balance': 'वॉलेट शिल्लक',
    'Available Balance': 'उपलब्ध शिल्लक',
    'Event Type': 'कार्यक्रमाचा प्रकार',
    'Number of Cans': 'कॅनची संख्या',
    'Per Can Rate': 'प्रति कॅन दर',
    'Total Amount': 'एकूण रक्कम',
    'Event Date & Time': 'कार्यक्रमाची तारीख आणि वेळ',
    'Select event type': 'कार्यक्रमाचा प्रकार निवडा',
    'Select number of cans': 'कॅनची संख्या निवडा',
    'Enter number of cans': 'कॅनची संख्या टाका',
    'Select date': 'तारीख निवडा',
    'Select time': 'वेळ निवडा',
    'Select your village': 'तुमचे गाव निवडा',
    'Enter address or hall name': 'पत्ता किंवा हॉलचे नाव टाका',
    'Select Required Delivery Time': 'आवश्यक वितरण वेळ निवडा',
    'Fill in your event details to request a bulk water order.':
        'मोठ्या पाणी ऑर्डरसाठी कार्यक्रमाचा तपशील भरा.',
    'No delivery slots remain today. Please choose another date.':
        'आज कोणताही वितरण स्लॉट उपलब्ध नाही. कृपया दुसरी तारीख निवडा.',
    'Pending Dues': 'थकबाकी',
    'Add Money': 'पैसे जोडा',
    'View Details': 'तपशील पहा',
    'View All': 'सर्व पहा',
    'Most Popular': 'सर्वात लोकप्रिय',
    'Shop By Need': 'गरजेनुसार निवडा',
    'Stay Hydrated, Stay Healthy': 'पाणी प्या, निरोगी राहा',
    'Edit': 'संपादित करा',
    'Profile saved.': 'प्रोफाइल जतन झाले.',
    'Profile photo': 'प्रोफाइल फोटो',
    'Gallery': 'गॅलरी',
    'Camera': 'कॅमेरा',
    'Remove current photo': 'सध्याचा फोटो काढा',
    'Add photo': 'फोटो जोडा',
    'Change photo': 'फोटो बदला',
    'Your Profile': 'तुमचे प्रोफाइल',
    'Full Name': 'पूर्ण नाव',
    'Mobile Number': 'मोबाइल क्रमांक',
    'Village / Area': 'गाव / परिसर',
    'Address / Hall Name': 'पत्ता / हॉलचे नाव',
    'SAVE CHANGES': 'बदल जतन करा',
    'Welcome back': 'पुन्हा स्वागत',
    'Create your account': 'तुमचे खाते तयार करा',
    'Password': 'पासवर्ड',
    'LOGIN': 'लॉगिन',
    'CREATE ACCOUNT': 'खाते तयार करा',
    'Payment': 'पेमेंट',
    'Order Summary': 'ऑर्डर सारांश',
    'Apply': 'लागू करा',
    'Remove': 'काढा',
    'Total': 'एकूण',
    'Advance': 'अग्रिम',
    'Balance': 'शिल्लक',
    'Booking Confirmed!': 'बुकिंग निश्चित झाली!',
    'Booking Pending': 'बुकिंग प्रलंबित',
    'Request for Change': 'बदलासाठी विनंती',
    'Request Cancellation': 'रद्द करण्याची विनंती',
    'Change Request': 'बदल विनंती',
    'Cancel Request': 'रद्द विनंती',
    'Transaction History': 'व्यवहार इतिहास',
    'No wallet transactions yet': 'अजून वॉलेट व्यवहार नाहीत',
    'Logout': 'लॉग आउट',
  };
}

String tr(String english) => LanguageService.instance.tr(english);
