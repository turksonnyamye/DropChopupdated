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
          onPressed: () => Navigator.pop(context),
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
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 14, offset: const Offset(0, 6))],
        ),
        child: Row(
          children: [
            Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(color: accent.withOpacity(0.12), borderRadius: BorderRadius.circular(16)),
              child: Center(child: Text(vendor.emoji, style: const TextStyle(fontSize: 28))),
            ),
            const SizedBox(width: 16),
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
    );
  }
}
