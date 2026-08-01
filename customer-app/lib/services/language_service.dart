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
    notifyListeners();
    await (await SharedPreferences.getInstance())
        .setString(_storageKey, value.name);
  }

  String tr(String english) {
    if (language == AppLanguage.english) return english;
    final values = language == AppLanguage.hindi ? _hindi : _marathi;
    final direct = values[english];
    if (direct != null) return direct;

    // Admin-controlled home text may contain emoji, different punctuation,
    // spacing or a small wording variation. Resolve those values to the same
    // translation without changing the English value stored in the database.
    final normalized = _normalize(english);
    final canonical = switch (normalized) {
      'stay hydrated stay healthy' => 'Stay Hydrated, Stay Healthy',
      'custom need' ||
      'custom needs' ||
      'custom quantity' ||
      'custom pack' ||
      'custom order' =>
        'Custom Need',
      '100% pure' || '100% pure safe' || 'pure safe' => '100% Pure & Safe',
      'on time delivery' || 'ontime delivery' => 'On-Time Delivery',
      'easy return' || 'easy returns' => 'Easy Returns',
      'best price' || 'best price guaranteed' => 'Best Price Guaranteed',
      _ => null,
    };
    if (canonical != null && values[canonical] != null) {
      return values[canonical]!;
    }
    for (final entry in values.entries) {
      if (_normalize(entry.key) == normalized) return entry.value;
    }
    return english;
  }

  static String _normalize(String value) => value
      .toLowerCase()
      .replaceAll(RegExp(r'[^a-z0-9%]+'), ' ')
      .trim()
      .replaceAll(RegExp(r'\s+'), ' ');

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
    'Good Morning': 'सुप्रभात',
    'Good Afternoon': 'नमस्कार',
    'Good Evening': 'शुभ संध्या',
    'Customer': 'ग्राहक',
    'Weekend Splash Offer': 'वीकेंड स्प्लैश ऑफर',
    'Get up to 15% OFF on all orders above Rs.300':
        '₹300 से अधिक के सभी ऑर्डर पर 15% तक की छूट पाएँ',
    'Use Code': 'कोड लगाएँ',
    'Your account booking history': 'आपके खाते की बुकिंग हिस्ट्री',
    'No bookings found': 'कोई बुकिंग नहीं मिली',
    'No bookings are linked to this account yet. Place a bulk order to get started.':
        'इस खाते से अभी कोई बुकिंग जुड़ी नहीं है। शुरू करने के लिए बल्क ऑर्डर करें।',
    'Event': 'कार्यक्रम',
    'Date': 'तारीख',
    'Village': 'गाँव',
    'Offer': 'ऑफर',
    'cans': 'कैन',
    'Wedding': 'शादी',
    'Birthday': 'जन्मदिन',
    'Other': 'अन्य',
    'PENDING': 'लंबित',
    'CONFIRMED': 'पुष्ट',
    'CANCELLED': 'रद्द',
    'DELIVERED': 'डिलीवर',
    'The 30% advance is non-refundable. Admin approval is required.':
        '30% अग्रिम वापस नहीं होगा। एडमिन की मंजूरी आवश्यक है।',
    'Reason for cancellation': 'रद्द करने का कारण',
    'Close': 'बंद करें',
    'Submit Request': 'अनुरोध भेजें',
    'Enter only the details you want changed. Admin approval is required.':
        'केवल वही विवरण भरें जिन्हें बदलना है। एडमिन की मंजूरी आवश्यक है।',
    'New date': 'नई तारीख',
    'New time': 'नया समय',
    'New quantity': 'नई मात्रा',
    'New address': 'नया पता',
    'Reason for change *': 'बदलाव का कारण *',
    'Request submitted to admin.': 'अनुरोध एडमिन को भेज दिया गया।',
    'Enter amount': 'राशि दर्ज करें',
    'ADD MONEY SECURELY': 'सुरक्षित रूप से पैसे जोड़ें',
    'Wallet transaction': 'वॉलेट लेनदेन',
    'Wallet top-up via Razorpay': 'रेज़रपे से वॉलेट में पैसे जोड़े',
    'Money added to wallet successfully.':
        'वॉलेट में पैसे सफलतापूर्वक जुड़ गए।',
    'Call': 'कॉल करें',
    'Need help with an order?': 'ऑर्डर में सहायता चाहिए?',
    'Reach out to {plant_name} directly.': 'सीधे {plant_name} से संपर्क करें।',
    'Frequently asked': 'अक्सर पूछे जाने वाले प्रश्न',
    'How do I place a bulk order?': 'मैं बल्क ऑर्डर कैसे करूँ?',
    'Tap "Request Bulk Order" on the home screen, fill in your event details, and pay the 30% advance to confirm.':
        'होम स्क्रीन पर "बल्क ऑर्डर का अनुरोध" दबाएँ, विवरण भरें और पुष्टि के लिए 30% अग्रिम दें।',
    'Why do I pay 30% advance?': 'मैं 30% अग्रिम क्यों देता हूँ?',
    'The 30% advance confirms your booking and blocks your event date. The remaining 70% is paid as cash on delivery.':
        '30% अग्रिम आपकी बुकिंग की पुष्टि करता है। शेष 70% डिलीवरी पर नकद दिया जाता है।',
    'Is the advance refundable?': 'क्या अग्रिम वापस मिलता है?',
    'The 30% advance is non-refundable. Submit a cancellation request from My Bookings; after admin approval, the date and cans are released immediately.':
        '30% अग्रिम वापस नहीं होगा। मेरी बुकिंग से रद्द करने का अनुरोध भेजें; मंजूरी के बाद तारीख और कैन तुरंत उपलब्ध हो जाएंगे।',
    'When is a delivery charge added?': 'डिलीवरी शुल्क कब लगता है?',
    'How will I know my booking is confirmed?':
        'बुकिंग की पुष्टि कैसे पता चलेगी?',
    'A delivery charge applies only to orders under 25 cans, for every village except Kasara Balkunda (which is free).':
        '25 कैन से कम के ऑर्डर पर डिलीवरी शुल्क लगता है; कसारा बालकुंडा में डिलीवरी मुफ्त है।',
    'Online payments confirm instantly. For cash, the plant confirms once the advance is received — you can track it under "My Bookings".':
        'ऑनलाइन भुगतान तुरंत पुष्ट होता है। नकद में अग्रिम मिलने के बाद प्लांट पुष्टि करता है—इसे "मेरी बुकिंग" में देखें।',
    'Request Bulk Order': 'बल्क ऑर्डर करें',
    'REQUEST BULK ORDER': 'बल्क ऑर्डर करें',
    'Bulk Order Enquiry': 'बल्क ऑर्डर पूछताछ',
    '100% Pure & Safe': '100% शुद्ध और सुरक्षित',
    'On-Time Delivery': 'समय पर डिलीवरी',
    'Easy Returns': 'आसान वापसी',
    'Best Price Guaranteed': 'सर्वोत्तम मूल्य की गारंटी',
    'Large Events': 'बड़े कार्यक्रम',
    'Custom Need': 'अपनी जरूरत',
    'Search for water products': 'पानी के उत्पाद खोजें',
    'Search for Jar Water 20L': '20 लीटर पानी का जार खोजें',
    'Search for Water Bottle 1.5L': '1.5 लीटर पानी की बोतल खोजें',
    'Search for Jar Water 10L': '10 लीटर पानी का जार खोजें',
    'All Product Packs': 'सभी उत्पाद पैक',
    'Pack Details': 'पैक का विवरण',
    'Search Products': 'उत्पाद खोजें',
    'Choose the right pack': 'सही पैक चुनें',
    'Fresh, sealed water cans for every event size.':
        'हर प्रकार के कार्यक्रम के लिए ताज़े और सीलबंद पानी के कैन।',
    'Mini Event Pack': 'मिनी इवेंट पैक',
    'Standard Event Pack': 'स्टैंडर्ड इवेंट पैक',
    'Large Event Pack': 'लार्ज इवेंट पैक',
    'Jumbo Event Pack': 'जंबो इवेंट पैक',
    'Custom Event Pack': 'कस्टम इवेंट पैक',
    '20 Cans': '20 कैन',
    '50 Cans': '50 कैन',
    '100 Cans': '100 कैन',
    '150 Cans': '150 कैन',
    'Choose Quantity': 'मात्रा चुनें',
    'Sealed & Safe': 'सीलबंद और सुरक्षित',
    'Ideal for': 'इसके लिए उपयुक्त',
    'Current rate': 'वर्तमान दर',
    'Delivery policy for this pack': 'इस पैक की डिलीवरी नीति',
    'Available delivery areas': 'उपलब्ध डिलीवरी क्षेत्र',
    'Balance on delivery': 'डिलीवरी पर शेष राशि',
    'advance': 'अग्रिम',
    'CHOOSE QUANTITY': 'मात्रा चुनें',
    'BOOK THIS PACK': 'यह पैक बुक करें',
    'Booking ID': 'बुकिंग आईडी',
    'Cans': 'कैन',
    'Date & Time': 'तारीख और समय',
    'Advance Paid': 'अग्रिम भुगतान हुआ',
    'Advance Due': 'अग्रिम बकाया',
    'Balance (COD)': 'शेष राशि (COD)',
    'BACK TO HOME': 'होम पर वापस जाएँ',
    'Advance is NON-REFUNDABLE': 'अग्रिम राशि वापस नहीं होगी',
    'Cash Payment Selected': 'नकद भुगतान चुना गया',
    'I WILL PAY CASH': 'मैं नकद भुगतान करूँगा',
    'per can': 'प्रति कैन',
    'Search pack name or quantity': 'पैक का नाम या मात्रा खोजें',
    'Clear all': 'सभी हटाएँ',
    'Have an offer code?': 'क्या आपके पास ऑफर कोड है?',
    'Enter code': 'कोड दर्ज करें',
    'If cancelled, the event date will not be unblocked.':
        '30% अग्रिम वापस नहीं होगा; मंजूर रद्दीकरण के बाद तारीख और कैन फिर उपलब्ध होंगे।',
    'Advance to Confirm Booking': 'बुकिंग की पुष्टि के लिए अग्रिम',
    'Cash on Delivery': 'डिलीवरी पर नकद',
    'PAY': 'भुगतान करें',
    'ONLINE': 'ऑनलाइन',
    'FROM WALLET': 'वॉलेट से',
    'CASH': 'नकद',
    'Available balance': 'उपलब्ध बैलेंस',
    'Date is blocked only after advance is paid/confirmed.':
        'अग्रिम भुगतान/पुष्टि के बाद ही क्षमता आरक्षित होती है।',
    'controlled by Mahalakshmi Water Plant':
        'महालक्ष्मी वॉटर प्लांट द्वारा निर्धारित',
    'A compact water supply pack for small celebrations and gatherings.':
        'छोटे समारोह और आयोजनों के लिए पानी का कॉम्पैक्ट पैक।',
    'A balanced event pack with enough drinking water for medium gatherings.':
        'मध्यम आयोजनों के लिए पर्याप्त पेयजल वाला संतुलित पैक।',
    'Reliable bulk water supply designed for busy full-day celebrations.':
        'बड़े पूरे-दिन के आयोजनों के लिए भरोसेमंद बल्क पानी आपूर्ति।',
    'Our largest ready pack for high-attendance events and celebrations.':
        'बहुत अधिक मेहमानों वाले आयोजनों के लिए हमारा सबसे बड़ा तैयार पैक।',
    'Choose the exact number of cans needed for your unique event.':
        'अपने कार्यक्रम के लिए आवश्यक कैन की सही संख्या चुनें।',
    'Small functions, family events and intimate celebrations':
        'छोटे कार्यक्रम, पारिवारिक आयोजन और निजी समारोह',
    'Birthdays, community functions and medium-size events':
        'जन्मदिन, सामुदायिक कार्यक्रम और मध्यम आयोजन',
    'Weddings, receptions and large public functions':
        'शादी, रिसेप्शन और बड़े सार्वजनिक कार्यक्रम',
    'Large weddings, festivals and major community events':
        'बड़ी शादियाँ, त्योहार और प्रमुख सामुदायिक आयोजन',
    'Any event requiring a personalised water quantity':
        'कोई भी कार्यक्रम जिसमें अपनी मात्रा के अनुसार पानी चाहिए',
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
    'Good Morning': 'शुभ सकाळ',
    'Good Afternoon': 'शुभ दुपार',
    'Good Evening': 'शुभ संध्याकाळ',
    'Customer': 'ग्राहक',
    'Weekend Splash Offer': 'वीकेंड स्प्लॅश ऑफर',
    'Get up to 15% OFF on all orders above Rs.300':
        '₹300 पेक्षा जास्त सर्व ऑर्डरवर 15% पर्यंत सूट मिळवा',
    'Use Code': 'कोड वापरा',
    'Your account booking history': 'तुमच्या खात्याचा बुकिंग इतिहास',
    'No bookings found': 'कोणतीही बुकिंग आढळली नाही',
    'No bookings are linked to this account yet. Place a bulk order to get started.':
        'या खात्याशी अजून कोणतीही बुकिंग जोडलेली नाही. सुरुवात करण्यासाठी मोठी ऑर्डर करा.',
    'Event': 'कार्यक्रम',
    'Date': 'तारीख',
    'Village': 'गाव',
    'Offer': 'ऑफर',
    'cans': 'कॅन',
    'Wedding': 'लग्न',
    'Birthday': 'वाढदिवस',
    'Other': 'इतर',
    'PENDING': 'प्रलंबित',
    'CONFIRMED': 'निश्चित',
    'CANCELLED': 'रद्द',
    'DELIVERED': 'वितरित',
    'The 30% advance is non-refundable. Admin approval is required.':
        '30% आगाऊ रक्कम परत मिळणार नाही. अ‍ॅडमिनची मंजुरी आवश्यक आहे.',
    'Reason for cancellation': 'रद्द करण्याचे कारण',
    'Close': 'बंद करा',
    'Submit Request': 'विनंती पाठवा',
    'Enter only the details you want changed. Admin approval is required.':
        'फक्त बदलायचे तपशील भरा. अ‍ॅडमिनची मंजुरी आवश्यक आहे.',
    'New date': 'नवीन तारीख',
    'New time': 'नवीन वेळ',
    'New quantity': 'नवीन संख्या',
    'New address': 'नवीन पत्ता',
    'Reason for change *': 'बदलाचे कारण *',
    'Request submitted to admin.': 'विनंती अ‍ॅडमिनकडे पाठवली.',
    'Enter amount': 'रक्कम टाका',
    'ADD MONEY SECURELY': 'सुरक्षितपणे पैसे जोडा',
    'Wallet transaction': 'वॉलेट व्यवहार',
    'Wallet top-up via Razorpay': 'रेझरपेद्वारे वॉलेटमध्ये पैसे जोडले',
    'Money added to wallet successfully.':
        'वॉलेटमध्ये पैसे यशस्वीरित्या जोडले.',
    'Call': 'कॉल करा',
    'Need help with an order?': 'ऑर्डरसाठी मदत हवी आहे?',
    'Reach out to {plant_name} directly.': 'थेट {plant_name} शी संपर्क करा.',
    'Frequently asked': 'नेहमी विचारले जाणारे प्रश्न',
    'How do I place a bulk order?': 'मी मोठी ऑर्डर कशी देऊ?',
    'Tap "Request Bulk Order" on the home screen, fill in your event details, and pay the 30% advance to confirm.':
        'होम स्क्रीनवर "मोठी ऑर्डर विनंती" दाबा, तपशील भरा आणि पुष्टीसाठी 30% आगाऊ रक्कम भरा.',
    'Why do I pay 30% advance?': 'मी 30% आगाऊ रक्कम का भरतो?',
    'The 30% advance confirms your booking and blocks your event date. The remaining 70% is paid as cash on delivery.':
        '30% आगाऊ रक्कम बुकिंग निश्चित करते. उर्वरित 70% वितरणावेळी रोख भरले जाते.',
    'Is the advance refundable?': 'आगाऊ रक्कम परत मिळते का?',
    'The 30% advance is non-refundable. Submit a cancellation request from My Bookings; after admin approval, the date and cans are released immediately.':
        '30% आगाऊ रक्कम परत मिळणार नाही. माझ्या बुकिंगमधून रद्द विनंती करा; मंजुरीनंतर तारीख आणि कॅन लगेच उपलब्ध होतील.',
    'When is a delivery charge added?': 'वितरण शुल्क कधी लागते?',
    'How will I know my booking is confirmed?':
        'बुकिंग निश्चित झाल्याचे कसे कळेल?',
    'A delivery charge applies only to orders under 25 cans, for every village except Kasara Balkunda (which is free).':
        '25 कॅनपेक्षा कमी ऑर्डरवर वितरण शुल्क लागते; कसारा बालकुंडा येथे वितरण मोफत आहे.',
    'Online payments confirm instantly. For cash, the plant confirms once the advance is received — you can track it under "My Bookings".':
        'ऑनलाइन पेमेंट लगेच निश्चित होते. रोख आगाऊ रक्कम मिळाल्यावर प्लांट पुष्टी करते—ते "माझ्या बुकिंग्स" मध्ये पाहा.',
    'Request Bulk Order': 'मोठी ऑर्डर करा',
    'REQUEST BULK ORDER': 'मोठी ऑर्डर करा',
    'Bulk Order Enquiry': 'मोठ्या ऑर्डरची चौकशी',
    '100% Pure & Safe': '100% शुद्ध आणि सुरक्षित',
    'On-Time Delivery': 'वेळेवर वितरण',
    'Easy Returns': 'सोपे परत देणे',
    'Best Price Guaranteed': 'सर्वोत्तम किंमतीची हमी',
    'Large Events': 'मोठे कार्यक्रम',
    'Custom Need': 'तुमची गरज',
    'Search for water products': 'पाण्याची उत्पादने शोधा',
    'Search for Jar Water 20L': '20 लिटर पाण्याचा जार शोधा',
    'Search for Water Bottle 1.5L': '1.5 लिटर पाण्याची बाटली शोधा',
    'Search for Jar Water 10L': '10 लिटर पाण्याचा जार शोधा',
    'All Product Packs': 'सर्व उत्पादन पॅक',
    'Pack Details': 'पॅक तपशील',
    'Search Products': 'उत्पादने शोधा',
    'Choose the right pack': 'योग्य पॅक निवडा',
    'Fresh, sealed water cans for every event size.':
        'प्रत्येक कार्यक्रमासाठी ताजे आणि सीलबंद पाण्याचे कॅन.',
    'Mini Event Pack': 'मिनी इव्हेंट पॅक',
    'Standard Event Pack': 'स्टँडर्ड इव्हेंट पॅक',
    'Large Event Pack': 'लार्ज इव्हेंट पॅक',
    'Jumbo Event Pack': 'जंबो इव्हेंट पॅक',
    'Custom Event Pack': 'कस्टम इव्हेंट पॅक',
    '20 Cans': '20 कॅन',
    '50 Cans': '50 कॅन',
    '100 Cans': '100 कॅन',
    '150 Cans': '150 कॅन',
    'Choose Quantity': 'संख्या निवडा',
    'Sealed & Safe': 'सीलबंद आणि सुरक्षित',
    'Ideal for': 'यासाठी योग्य',
    'Current rate': 'सध्याचा दर',
    'Delivery policy for this pack': 'या पॅकचे वितरण धोरण',
    'Available delivery areas': 'उपलब्ध वितरण क्षेत्रे',
    'Balance on delivery': 'वितरणावेळी शिल्लक',
    'advance': 'आगाऊ',
    'CHOOSE QUANTITY': 'संख्या निवडा',
    'BOOK THIS PACK': 'हा पॅक बुक करा',
    'Booking ID': 'बुकिंग आयडी',
    'Cans': 'कॅन',
    'Date & Time': 'तारीख आणि वेळ',
    'Advance Paid': 'आगाऊ रक्कम भरली',
    'Advance Due': 'आगाऊ रक्कम बाकी',
    'Balance (COD)': 'शिल्लक (COD)',
    'BACK TO HOME': 'होमवर परत जा',
    'Advance is NON-REFUNDABLE': 'आगाऊ रक्कम परत मिळणार नाही',
    'Cash Payment Selected': 'रोख पेमेंट निवडले',
    'I WILL PAY CASH': 'मी रोख पैसे देईन',
    'per can': 'प्रति कॅन',
    'Search pack name or quantity': 'पॅकचे नाव किंवा संख्या शोधा',
    'Clear all': 'सर्व हटवा',
    'Have an offer code?': 'तुमच्याकडे ऑफर कोड आहे का?',
    'Enter code': 'कोड टाका',
    'If cancelled, the event date will not be unblocked.':
        '30% आगाऊ रक्कम परत मिळणार नाही; मंजूर रद्दीकरणानंतर तारीख आणि कॅन पुन्हा उपलब्ध होतील.',
    'Advance to Confirm Booking': 'बुकिंग निश्चित करण्यासाठी आगाऊ रक्कम',
    'Cash on Delivery': 'वितरणावेळी रोख',
    'PAY': 'पेमेंट करा',
    'ONLINE': 'ऑनलाइन',
    'FROM WALLET': 'वॉलेटमधून',
    'CASH': 'रोख',
    'Available balance': 'उपलब्ध शिल्लक',
    'Date is blocked only after advance is paid/confirmed.':
        'आगाऊ रक्कम भरल्यानंतर/निश्चित झाल्यानंतरच क्षमता राखीव होते.',
    'controlled by Mahalakshmi Water Plant': 'महालक्ष्मी वॉटर प्लांटने ठरवलेला',
    'A compact water supply pack for small celebrations and gatherings.':
        'लहान समारंभ आणि कार्यक्रमांसाठी पाण्याचा कॉम्पॅक्ट पॅक.',
    'A balanced event pack with enough drinking water for medium gatherings.':
        'मध्यम कार्यक्रमांसाठी पुरेसे पाणी असलेला संतुलित पॅक.',
    'Reliable bulk water supply designed for busy full-day celebrations.':
        'मोठ्या दिवसभराच्या कार्यक्रमांसाठी विश्वासार्ह मोठ्या प्रमाणातील पाणी पुरवठा.',
    'Our largest ready pack for high-attendance events and celebrations.':
        'खूप पाहुणे असलेल्या कार्यक्रमांसाठी आमचा सर्वात मोठा तयार पॅक.',
    'Choose the exact number of cans needed for your unique event.':
        'तुमच्या कार्यक्रमासाठी आवश्यक कॅनची अचूक संख्या निवडा.',
    'Small functions, family events and intimate celebrations':
        'लहान कार्यक्रम, कौटुंबिक समारंभ आणि खास उत्सव',
    'Birthdays, community functions and medium-size events':
        'वाढदिवस, सामुदायिक कार्यक्रम आणि मध्यम समारंभ',
    'Weddings, receptions and large public functions':
        'लग्न, रिसेप्शन आणि मोठे सार्वजनिक कार्यक्रम',
    'Large weddings, festivals and major community events':
        'मोठी लग्ने, उत्सव आणि प्रमुख सामुदायिक कार्यक्रम',
    'Any event requiring a personalised water quantity':
        'स्वतःच्या गरजेनुसार पाण्याची संख्या लागणारा कोणताही कार्यक्रम',
    'Logout': 'लॉग आउट',
  };
}

String tr(String english) => LanguageService.instance.tr(english);
