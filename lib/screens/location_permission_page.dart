import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LocationPermissionPage extends StatefulWidget {
  const LocationPermissionPage({super.key});

  @override
  State<LocationPermissionPage> createState() => _LocationPermissionPageState();
}

class _LocationPermissionPageState extends State<LocationPermissionPage> {
  static const Color brandGreen = Color(0xFF32BB78);
  static const Color background = Color(0xFFF7F9FC);

  bool _isRequesting = false;

  Future<void> _goToBuyerHome() async {
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/buyerHome');
    }
  }

  Future<void> _handleAllowLocation() async {
    setState(() => _isRequesting = true);

    bool locationEnabled = false;

    // Check if location services (GPS) are turned on at all.
    final bool serviceEnabled = await Geolocator.isLocationServiceEnabled();

    if (serviceEnabled) {
      LocationPermission permission = await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      locationEnabled = permission == LocationPermission.always ||
          permission == LocationPermission.whileInUse;
    }

    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('locationEnabled', locationEnabled);
    await prefs.setBool('hasSeenLocationPrompt', true);

    setState(() => _isRequesting = false);

    if (!mounted) return;

    if (!serviceEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Turn on location services in your phone settings for the best experience.')),
      );
    } else if (!locationEnabled) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Location permission denied. You can turn it on later in Settings.')),
      );
    }

    _goToBuyerHome();
  }

  Future<void> _handleSkip() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setBool('locationEnabled', false);
    await prefs.setBool('hasSeenLocationPrompt', true);
    _goToBuyerHome();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            children: [
              const Spacer(flex: 2),
              Container(
                width: 140,
                height: 140,
                decoration: BoxDecoration(
                  color: brandGreen.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.location_on_rounded,
                  color: brandGreen,
                  size: 70,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Enable Location',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'DropChop uses your location to show vendors near you and get your order delivered faster and more accurately.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: Colors.grey.shade600,
                  height: 1.5,
                ),
              ),
              const Spacer(flex: 3),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: _isRequesting ? null : _handleAllowLocation,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: brandGreen,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isRequesting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.5,
                          ),
                        )
                      : Text(
                          'Allow Location Access',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                            color: Colors.white,
                          ),
                        ),
                ),
              ),
              const SizedBox(height: 14),
              TextButton(
                onPressed: _isRequesting ? null : _handleSkip,
                child: Text(
                  'Not Now',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                    color: Colors.grey.shade600,
                  ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }
}
