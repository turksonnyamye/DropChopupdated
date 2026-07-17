import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart'; // Re-added Firebase Core
import 'firebase_options.dart'; // Re-added Firebase Options config file

import 'screens/welcome_page.dart'; 
import 'screens/sign_in_page.dart';
import 'screens/sign_up_page.dart'; 
import 'screens/user_selection_page.dart';
import 'screens/location_permission_page.dart';
import 'screens/vendor_selection_page.dart';
import 'state_controller.dart';
import 'rider/rider_home.dart';
import 'vendor/vendor_home.dart';
import 'buyer/buyer_page.dart'; 

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Re-added Firebase Initialization
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent, 
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  ));

  final SharedPreferences prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.getBool('isLoggedIn') ?? false;
  final String? savedRole = prefs.getString('userRole');
  final String? savedVendorId = prefs.getString('vendorId');

  if (savedVendorId != null) {
    VendorSession.currentVendorId = savedVendorId;
    final vendor = DropChopStateController().vendorById(savedVendorId);
    VendorSession.currentVendorName = vendor?.name;
  }

  String initialRoute = '/welcome';

  if (isLoggedIn) {
    switch (savedRole) {
      case 'buyer':
        initialRoute = '/buyerHome';
        break;
      case 'rider':
        initialRoute = '/riderHome';
        break;
      case 'vendor':
        initialRoute = savedVendorId != null ? '/vendorHome' : '/vendorSelect';
        break;
      default:
        initialRoute = '/selectUser';
    }
  }

  runApp(DropchopApp(initialRoute: initialRoute));
}

class DropchopApp extends StatelessWidget {
  final String initialRoute;
  const DropchopApp({super.key, required this.initialRoute});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'DropChop',
      theme: ThemeData(
        useMaterial3: true,
        primaryColor: const Color(0xFF32BB78),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF32BB78),
          primary: const Color(0xFF32BB78),
        ),
      ),
      initialRoute: initialRoute,
      routes: {
        '/welcome': (context) => const WelcomePage(),
        '/signin': (context) => const SignInPage(),
        '/signup': (context) => const SignUpPage(),
        '/selectUser': (context) => const UserSelectionPage(),
        '/locationPermission': (context) => const LocationPermissionPage(),
        '/vendorSelect': (context) => const VendorSelectionPage(),
        '/buyerHome': (context) => const BuyerPage(),
        '/riderHome': (context) => const RiderHomePage(),
        '/vendorHome': (context) => const VendorHomePage(),
      },
    );
  }
}