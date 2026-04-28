import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LanguageProvider with ChangeNotifier {
  Locale _currentLocale = const Locale('en');
  static const String _langKey = 'selected_language';

  LanguageProvider() {
    _loadSavedLanguage();
  }

  Locale get currentLocale => _currentLocale;

  bool get isSomali => _currentLocale.languageCode == 'so';

  Future<void> _loadSavedLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final savedLang = prefs.getString(_langKey);
    if (savedLang != null) {
      _currentLocale = Locale(savedLang);
      notifyListeners();
    }
  }

  Future<void> setLanguage(String languageCode) async {
    _currentLocale = Locale(languageCode);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_langKey, languageCode);
    notifyListeners();
  }

  String translate(String key) {
    return _translations[_currentLocale.languageCode]?[key] ?? key;
  }

  static final Map<String, Map<String, String>> _translations = {
    'en': {
      'profile': 'My Profile',
      'edit_profile': 'Edit Profile',
      'notifications': 'Notifications',
      'security': 'Security',
      'help_support': 'Help & Support',
      'language': 'Language',
      'dark_mode': 'Dark Mode',
      'logout': 'Logout',
      'home': 'Home',
      'search': 'Search',
      'saved': 'Saved',
      'search_properties': 'Search Properties',
      'discover': 'Discover',
      'elite_sanctuary': 'Elite Sanctuary',
      'no_properties': 'No properties found in this category',
      'no_saved': 'No saved properties yet',
      'property_unavailable': 'Property No Longer Available',
      'search_hint': 'City, neighborhood...',
      'return_listings': 'Return to Listings',
      'contact_support': 'Contact Customer Care',
      'verify_email': 'Verify Email',
      'save_changes': 'SAVE CHANGES',
      'verify_code': 'VERIFY CODE',
      'no_properties_now': 'No properties available right now.',
      'full_name': 'Full Name',
      'email_address': 'Email Address',
      'phone_number': 'Phone Number',
      'login_title': 'Welcome Back',
      'login_subtitle': 'Sign in to access your elite sanctuary',
      'signup_title': 'Create Account',
      'signup_subtitle': 'Join our elite real estate network',
      'email_label': 'Email',
      'password_label': 'Password',
      'confirm_password': 'Confirm Password',
      'forgot_password': 'Forgot Password?',
      'login_btn': 'SIGN IN',
      'signup_btn': 'CREATE ACCOUNT',
      'no_account': "Don't have an account? ",
      'have_account': 'Already have an account? ',
      'switch_signup': 'Sign Up',
      'switch_login': 'Sign In',
      'verify_email_msg':
          'We sent a 6-digit code to your new email. Please enter it below to confirm the change.',
      'lock': 'Lock',
      'edit': 'Edit',
      'property_deleted_desc': 'This property may have been leased, sold, or recently removed from our elite portfolio. Please return to the listings to explore other opportunities.',
      'beds': 'Beds',
      'or': 'or',
      'login_error': 'Invalid email or password. Please try again.',
    },
    'so': {
      'profile': 'Profile-kayga',
      'edit_profile': 'Wax ka beddel Profile-ka',
      'notifications': 'Ogeysiisyada',
      'security': 'Amniga',
      'help_support': 'Caawinaad & Taageero',
      'language': 'Luuqadda',
      'dark_mode': 'Habka Habeenka',
      'logout': 'Ka bax',
      'home': 'Hoyga',
      'search': 'Raadi',
      'saved': 'Kaydsan',
      'search_properties': 'Raadi Guryaha',
      'discover': 'Baadh',
      'elite_sanctuary': 'Hoyga rasmiga ah',
      'no_properties': 'Guryo lama helin qaybtan',
      'no_saved': 'Weli ma jiraan guryo kuu kaydsan',
      'property_unavailable': 'Gurigan hadda ma bannaana',
      'search_hint': 'Magaalada, xaafadda...',
      'return_listings': 'Ku laabo liiska',
      'contact_support': 'La xidhiidh adeegga macaamiisha',
      'verify_email': 'Xaqiiji iimaylka',
      'save_changes': 'KAYDI ISBEDDELKA',
      'verify_code': 'XAQIIJI CODE-KA',
      'no_properties_now': 'Hadda majiraan guryo diyaar ah.',
      'full_name': 'Magaca oo buuxa',
      'email_address': 'Cinwaanka iimaylka',
      'phone_number': 'Lambarka telefoonka',
      'login_title': 'Kuso dhawaaw mar kale',
      'login_subtitle': 'Soo gal si aad u gasho hoygaaga rasmiga ah',
      'signup_title': 'Sameyso Akoon',
      'signup_subtitle': 'Ku soo biir shabakadayada guryaha rasmiga ah',
      'email_label': 'Iimaylka',
      'password_label': 'Furaha',
      'confirm_password': 'Hubi Furaha',
      'forgot_password': 'Ma ilawday furaha?',
      'login_btn': 'SOO GAL',
      'signup_btn': 'SAMEYSO AKOON',
      'no_account': "Ma leedahay akoon? ",
      'have_account': 'Horay ma u lahayd akoon? ',
      'switch_signup': 'Isku qor',
      'switch_login': 'Soo gal',
      'verify_email_msg':
          'Waxaan u dirnay koodh 6-god ah iimaylkaaga cusub. Fadlan geli hoos si aad u xaqiijiso isbeddelka.',
      'lock': 'Quful',
      'edit': 'Beddel',
      'property_deleted_desc': 'Waan ka xunnahay, hantidan aad fiirinayso hadda looma helayo si degdeg ah. Waxaa laga yaabaa in la kireeyay ama laga saaray nidaamka. Fadlan dib ugu laabo liiska hantida si aad u hesho fursado kale.',
      'beds': 'Qol',
      'or': 'ama',
      'login_error': 'Fadlan hubi iimaylka iyo furo sireedka, markale isku day',
    },
  };
}
