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
    'Logout': 'लॉग आउट',
  };
}

String tr(String english) => LanguageService.instance.tr(english);
