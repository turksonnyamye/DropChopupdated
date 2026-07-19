import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../state_controller.dart';

class VendorSelectionPage extends StatelessWidget {
  const VendorSelectionPage({super.key});

  static const Color accent = Color(0xFF0EA37A);
  static const Color background = Color(0xFFF7F9FC);

  Future<void> _selectVendor(BuildContext context, Vendor vendor) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('vendorId', vendor.id);
    VendorSession.currentVendorId = vendor.id;
    VendorSession.currentVendorName = vendor.name;

    if (context.mounted) {
      Navigator.pushReplacementNamed(context, '/vendorHome');
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendors = DropChopStateController().vendors;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black, size: 20),
          onPressed: () {
            if (Navigator.canPop(context)) {
              Navigator.pop(context);
            } else {
              // Nothing left on the stack (e.g. this page was the app's
              // starting route) — send them to the role picker instead
              // of trying to pop into nothing.
              Navigator.pushReplacementNamed(context, '/selectUser');
            }
          },
        ),
        centerTitle: true,
        title: Text('DropChop Merchant', style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.black)),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
          children: [
            Text('Sign in as which shop?', style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w800, color: Colors.black87)),
            const SizedBox(height: 8),
            Text(
              'Each vendor account only sees orders placed with their own store.',
              style: GoogleFonts.inter(fontSize: 13.5, fontWeight: FontWeight.w500, color: Colors.grey.shade500),
            ),
            const SizedBox(height: 26),
            ...vendors.map((vendor) => _buildVendorTile(context, vendor)),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorTile(BuildContext context, Vendor vendor) {
    return GestureDetector(
      onTap: () => _selectVendor(context, vendor),
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 100,
              width: double.infinity,
              decoration: BoxDecoration(
                gradient: LinearGradient(colors: [accent.withOpacity(0.9), accent.withOpacity(0.55)]),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
              ),
              child: Stack(
                children: [
                  if (vendor.imagePath != null)
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                        child: Image.asset(
                          vendor.imagePath!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                        ),
                      ),
                    ),
                  if (vendor.imagePath != null)
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black.withOpacity(0.5), Colors.transparent],
                          ),
                          borderRadius: const BorderRadius.only(topLeft: Radius.circular(24), topRight: Radius.circular(24)),
                        ),
                      ),
                    ),
                  Positioned(right: 12, bottom: -4, child: Text(vendor.emoji, style: const TextStyle(fontSize: 48, color: Colors.white38))),
                  Positioned(
                    top: 12,
                    right: 12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.star_rounded, size: 14, color: Colors.amber),
                          const SizedBox(width: 2),
                          Text('${vendor.rating}', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 11.5)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(vendor.name, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.black87)),
                        const SizedBox(height: 3),
                        Text(vendor.category, style: GoogleFonts.inter(fontSize: 12, color: Colors.grey.shade500, fontWeight: FontWeight.w500)),
                      ],
                    ),
                  ),
                  Icon(Icons.arrow_forward_ios_rounded, size: 16, color: Colors.grey.shade400),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}