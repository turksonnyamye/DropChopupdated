import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../state_controller.dart';

class VendorCouriersScreen extends StatefulWidget {
  const VendorCouriersScreen({super.key});

  @override
  State<VendorCouriersScreen> createState() => _VendorCouriersScreenState();
}

class _VendorCouriersScreenState extends State<VendorCouriersScreen> {
  static const Color accent = Color(0xFF0EA37A);

  final DropChopStateController _controller = DropChopStateController();
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onUpdate);
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    super.dispose();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final textPrimary = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white54 : Colors.black54;

    final String? vendorId = VendorSession.currentVendorId;
    final vendorOrders = vendorId != null ? _controller.ordersForVendor(vendorId) : _controller.orders;

    final List<CentralOrder> withRiders = vendorOrders
        .where((o) => o.assignedRider != null && o.status != OrderState.delivered && o.status != OrderState.cancelled)
        .toList();

    final filtered = searchQuery.isEmpty
        ? withRiders
        : withRiders.where((o) =>
            (o.assignedRider ?? '').toLowerCase().contains(searchQuery.toLowerCase()) ||
            o.id.toLowerCase().contains(searchQuery.toLowerCase())).toList();

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF07080A) : const Color(0xFFF3F5F7),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Couriers Tracking', style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: textPrimary)),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: TextField(
                onChanged: (v) => setState(() => searchQuery = v),
                decoration: InputDecoration(
                  hintText: 'Search rider name or order ID...',
                  prefixIcon: const Icon(Icons.search, size: 20),
                  fillColor: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
                  filled: true,
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Text(
                          'No riders assigned yet.\nOnce you mark an order ready, riders nearby can pick it up here.',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.inter(color: textSecondary),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: filtered.length,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemBuilder: (context, i) {
                        final order = filtered[i];
                        return _buildRiderCard(order, isDark, textPrimary, textSecondary);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRiderCard(CentralOrder order, bool isDark, Color textPrimary, Color textSecondary) {
    final String statusLabel = order.status == OrderState.enRoute ? 'En Route to Client' : 'Heading to Store';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : Colors.white,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: accent,
                child: Icon(Icons.sports_motorsports_rounded, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(order.assignedRider ?? 'Unassigned', style: GoogleFonts.inter(fontWeight: FontWeight.w800, color: textPrimary)),
                    Text('Status: $statusLabel', style: GoogleFonts.inter(color: accent, fontSize: 12, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text('Order #${order.id}', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: textPrimary)),
                  Text(order.riderRating, style: GoogleFonts.inter(color: Colors.amber.shade700, fontSize: 12, fontWeight: FontWeight.bold)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Calling ${order.assignedRider}...'), behavior: SnackBarBehavior.floating),
                    );
                  },
                  icon: const Icon(Icons.phone_rounded, size: 18, color: Colors.white),
                  label: const Text('Call Rider', style: TextStyle(color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Message thread opened.'), behavior: SnackBarBehavior.floating),
                    );
                  },
                  icon: Icon(Icons.chat_bubble_outline_rounded, size: 18, color: textPrimary),
                  label: Text('Message', style: GoogleFonts.inter(color: textPrimary)),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
