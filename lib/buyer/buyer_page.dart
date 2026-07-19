import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../state_controller.dart';
import 'momo_checkout_page.dart';
import 'vendor_menu_page.dart';

class BuyerPage extends StatefulWidget {
  const BuyerPage({super.key});

  @override
  State<BuyerPage> createState() => _BuyerPageState();
}

class _BuyerPageState extends State<BuyerPage> {
  static const Color brandGreen = Color(0xFF32BB78);

  int _currentIndex = 0;
  final List<CentralFoodItem> _cart = [];
  final DropChopStateController _stateController = DropChopStateController();

  String _deliveryAddress = 'Set Delivery Location';
  bool _locatingAddress = true;

  String _paymentMethod = 'MoMo'; // 'MoMo' or 'Cash'
  String _momoNetwork = 'MTN';
  final TextEditingController _momoNumberController = TextEditingController();

  String _activeCategory = 'All';
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  String _userName = '';
  String _userEmail = '';

  @override
  void initState() {
    super.initState();
    _stateController.addListener(() {
      if (mounted) setState(() {});
    });
    _loadCurrentLocation();
    _loadUserProfile();
  }

  Future<void> _loadUserProfile() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    setState(() {
      _userName = prefs.getString('userName') ?? 'DropChop User';
      _userEmail = prefs.getString('userEmail') ?? '';
    });
  }

  @override
  void dispose() {
    _momoNumberController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCurrentLocation() async {
    setState(() => _locatingAddress = true);

    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final bool locationEnabled = prefs.getBool('locationEnabled') ?? false;

      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      LocationPermission permission = await Geolocator.checkPermission();

      if (!locationEnabled &&
          (permission == LocationPermission.denied ||
              permission == LocationPermission.deniedForever)) {
        setState(() {
          _deliveryAddress = 'Set Delivery Location';
          _locatingAddress = false;
        });
        return;
      }

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (!serviceEnabled ||
          permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        setState(() {
          _deliveryAddress = 'Set Delivery Location';
          _locatingAddress = false;
        });
        return;
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.high),
      );

      final List<Placemark> placemarks =
          await placemarkFromCoordinates(position.latitude, position.longitude);

      if (placemarks.isNotEmpty) {
        final Placemark place = placemarks.first;
        final String area = (place.subLocality != null && place.subLocality!.isNotEmpty)
            ? place.subLocality!
            : (place.locality ?? 'Accra');
        final String region = place.administrativeArea ?? 'Ghana';

        setState(() {
          _deliveryAddress = '$area, $region';
          _locatingAddress = false;
        });
      } else {
        setState(() {
          _deliveryAddress = 'Set Delivery Location';
          _locatingAddress = false;
        });
      }

      await prefs.setBool('locationEnabled', true);
    } catch (e) {
      setState(() {
        _deliveryAddress = 'Set Delivery Location';
        _locatingAddress = false;
      });
    }
  }

  // --- Cart helpers -------------------------------------------------------

  void _addToCart(CentralFoodItem item) {
    if (_cart.isNotEmpty && _cart.first.vendorId != item.vendorId) {
      _confirmSwitchVendor(item);
      return;
    }
    setState(() => _cart.add(item));
  }

  void _removeOneFromCart(CentralFoodItem item) {
    final idx = _cart.indexWhere((i) => i.id == item.id);
    if (idx != -1) {
      setState(() => _cart.removeAt(idx));
    }
  }

  void _confirmSwitchVendor(CentralFoodItem newItem) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Start a new bag?', style: GoogleFonts.inter(fontWeight: FontWeight.w800)),
        content: Text(
          'Your bag has items from another vendor. Adding this item will clear your current bag.',
          style: GoogleFonts.inter(color: Colors.grey.shade700, fontSize: 13.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel', style: GoogleFonts.inter(color: Colors.grey.shade600, fontWeight: FontWeight.w700)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: brandGreen,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () {
              setState(() {
                _cart.clear();
                _cart.add(newItem);
              });
              Navigator.pop(context);
            },
            child: Text('Start New Bag', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  void _openVendor(Vendor vendor) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => VendorMenuPage(
          vendor: vendor,
          cart: _cart,
          onAddToCart: _addToCart,
          onRemoveOneFromCart: _removeOneFromCart,
          onViewCart: () {
            Navigator.pop(context);
            setState(() => _currentIndex = 1);
          },
        ),
      ),
    );
  }

  // Reusable helper: shows the food item's image if it has one, else falls back to emoji
  Widget _foodThumbnail(CentralFoodItem item, {double emojiSize = 34, BorderRadius? radius}) {
    return Container(
      height: 66,
      width: double.infinity,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: radius ?? BorderRadius.circular(14),
      ),
      child: item.imagePath != null
          ? Image.asset(
              item.imagePath!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Center(child: Text(item.emoji, style: TextStyle(fontSize: emojiSize))),
            )
          : Center(child: Text(item.emoji, style: TextStyle(fontSize: emojiSize))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<Widget> pages = [
      _buildHomeTab(),
      _buildCartTab(),
      _buildOrdersTab(),
      _buildProfileTab(),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: SafeArea(child: pages[_currentIndex]),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 20, offset: const Offset(0, -4)),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          selectedItemColor: brandGreen,
          unselectedItemColor: Colors.grey.shade400,
          elevation: 0,
          backgroundColor: Colors.white,
          type: BottomNavigationBarType.fixed,
          selectedLabelStyle: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 11),
          unselectedLabelStyle: GoogleFonts.inter(fontSize: 11),
          items: const [
            BottomNavigationBarItem(icon: Icon(Icons.restaurant_rounded), label: 'Explore'),
            BottomNavigationBarItem(icon: Icon(Icons.shopping_bag_outlined), label: 'Bag'),
            BottomNavigationBarItem(icon: Icon(Icons.receipt_long_rounded), label: 'Live Orders'),
            BottomNavigationBarItem(icon: Icon(Icons.person_outline_rounded), label: 'Profile'),
          ],
        ),
      ),
    );
  }

  // --- Home / Explore tab ---------------------------------------------

  Widget _buildHomeTab() {
    final List<String> categories = ['All', ...{for (final v in _stateController.vendors) v.category}];

    final List<Vendor> filteredVendors = _stateController.vendors.where((v) {
      final matchesCategory = _activeCategory == 'All' || v.category == _activeCategory;
      final matchesSearch = _searchQuery.isEmpty || v.name.toLowerCase().contains(_searchQuery.toLowerCase());
      return matchesCategory && matchesSearch;
    }).toList();

    final List<CentralFoodItem> popularPicks = _stateController.foodMenu.take(6).toList();

    return ListView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.only(bottom: 24),
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('DELIVER TO', style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 10, fontWeight: FontWeight.w900, letterSpacing: 1.2)),
                  GestureDetector(
                    onTap: _locatingAddress ? null : _loadCurrentLocation,
                    child: Row(
                      children: [
                        const Icon(Icons.location_on_rounded, color: brandGreen, size: 18),
                        const SizedBox(width: 4),
                        if (_locatingAddress)
                          Row(
                            children: [
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(strokeWidth: 2, color: brandGreen),
                              ),
                              const SizedBox(width: 8),
                              Text('Locating you...', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                            ],
                          )
                        else ...[
                          Text(_deliveryAddress, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)),
                          const SizedBox(width: 4),
                          Icon(Icons.refresh_rounded, size: 16, color: Colors.grey.shade400),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12), border: Border.all(color: Colors.grey.shade200)),
                child: const Icon(Icons.notifications_none_rounded, color: Colors.black),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
            child: TextField(
              controller: _searchController,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Search vendors on campus...',
                hintStyle: GoogleFonts.inter(color: Colors.grey.shade400, fontSize: 13),
                prefixIcon: Icon(Icons.search_rounded, color: Colors.grey.shade400),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ),
        ),
        const SizedBox(height: 22),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text("Accra's Finest\nGastronomy", style: GoogleFonts.inter(fontSize: 26, fontWeight: FontWeight.w900, height: 1.2)),
        ),
        const SizedBox(height: 18),
        SizedBox(
          height: 36,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, idx) {
              final cat = categories[idx];
              final bool selected = cat == _activeCategory;
              return GestureDetector(
                onTap: () => setState(() => _activeCategory = cat),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: selected ? brandGreen : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: selected ? brandGreen : Colors.grey.shade300),
                  ),
                  child: Text(cat, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 12.5, color: selected ? Colors.white : Colors.black87)),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 26),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('Popular Right Now', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16)),
        ),
        const SizedBox(height: 14),
        SizedBox(
          height: 168,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 20),
            itemCount: popularPicks.length,
            separatorBuilder: (_, __) => const SizedBox(width: 14),
            itemBuilder: (context, idx) {
              final item = popularPicks[idx];
              final vendor = _stateController.vendorById(item.vendorId);
              return GestureDetector(
                onTap: () {
                  if (vendor != null) _openVendor(vendor);
                },
                child: Container(
                  width: 140,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))]),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _foodThumbnail(item, radius: BorderRadius.circular(14)),
                      const SizedBox(height: 8),
                      Text(item.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 12.5)),
                      const SizedBox(height: 2),
                      Text('GHS ${item.price.toStringAsFixed(0)}', style: GoogleFonts.inter(color: brandGreen, fontWeight: FontWeight.w900, fontSize: 12.5)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 26),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Text('Vendors Near You', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16)),
        ),
        const SizedBox(height: 14),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            children: filteredVendors.map((vendor) => _buildVendorCard(vendor)).toList(),
          ),
        ),
      ],
    );
  }

  Widget _buildVendorCard(Vendor vendor) {
    return GestureDetector(
      onTap: () => _openVendor(vendor),
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
                gradient: LinearGradient(colors: [brandGreen.withOpacity(0.9), brandGreen.withOpacity(0.55)]),
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
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(vendor.name, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text(vendor.category, style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.schedule_rounded, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(vendor.etaRange, style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
                      const SizedBox(width: 14),
                      Icon(Icons.delivery_dining_rounded, size: 14, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text('GHS ${vendor.deliveryFee.toStringAsFixed(0)} delivery', style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- Cart / Checkout tab ---------------------------------------------

  Widget _buildCartTab() {
    double subtotal = _cart.fold(0.0, (sum, item) => sum + item.totalPrice);
    double deliveryFee = _cart.isEmpty ? 0.0 : (_stateController.vendorById(_cart.first.vendorId)?.deliveryFee ?? 12.0);
    double total = subtotal + deliveryFee;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text('My Checkout Bag', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          Expanded(
            child: _cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey.shade300),
                        const SizedBox(height: 16),
                        Text('Your bag is empty', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                        const SizedBox(height: 4),
                        Text('Explore vendors to start an order', style: GoogleFonts.inter(fontSize: 13, color: Colors.grey.shade400)),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: _cart.length,
                    itemBuilder: (context, idx) {
                      final item = _cart[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16)),
                        child: Row(
  children: [
    Container(
      width: 44,
      height: 44,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(12),
      ),
      child: item.imagePath != null
          ? Image.asset(
              item.imagePath!,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) =>
                  Center(child: Text(item.emoji, style: const TextStyle(fontSize: 22))),
            )
          : Center(child: Text(item.emoji, style: const TextStyle(fontSize: 22))),
    ),
    const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(item.name, style: GoogleFonts.inter(fontWeight: FontWeight.bold)),
                                  if (item.selectedAddOns.isNotEmpty)
                                    Padding(
                                      padding: const EdgeInsets.only(top: 2, bottom: 4),
                                      child: Text(
                                        item.selectedAddOns.map((a) => '${a.emoji} ${a.name} (+GHS ${a.price.toStringAsFixed(0)})').join(', '),
                                        style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 11),
                                      ),
                                    ),
                                  Text('GHS ${item.totalPrice.toStringAsFixed(2)}', style: GoogleFonts.inter(color: brandGreen, fontSize: 12, fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, color: Colors.redAccent),
                              onPressed: () => setState(() => _cart.removeAt(idx)),
                            )
                          ],
                        ),
                      );
                    },
                  ),
          ),
          if (_cart.isNotEmpty) ...[
            _buildPaymentMethodCard(),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
              child: Column(
                children: [
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Subtotal', style: GoogleFonts.inter(color: Colors.grey)), Text('GHS ${subtotal.toStringAsFixed(2)}', style: GoogleFonts.inter(fontWeight: FontWeight.bold))]),
                  const SizedBox(height: 8),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Delivery Fee', style: GoogleFonts.inter(color: Colors.grey)), Text('GHS ${deliveryFee.toStringAsFixed(2)}', style: GoogleFonts.inter(fontWeight: FontWeight.bold))]),
                  const Divider(height: 24),
                  Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [Text('Total Amount', style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 16)), Text('GHS ${total.toStringAsFixed(2)}', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 18, color: brandGreen))]),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () => _handleCheckout(total),
                      style: ElevatedButton.styleFrom(backgroundColor: brandGreen, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16))),
                      child: Text(
                        _paymentMethod == 'MoMo' ? 'Pay with MoMo & Checkout' : 'Confirm & Checkout',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16),
                      ),
                    ),
                  )
                ],
              ),
            ),
            const SizedBox(height: 16),
          ]
        ],
      ),
    );
  }

  Widget _buildPaymentMethodCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Payment Method', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 15)),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _buildPaymentOption(
                  label: 'MoMo Pay',
                  icon: Icons.phone_android_rounded,
                  value: 'MoMo',
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildPaymentOption(
                  label: 'Cash',
                  icon: Icons.payments_outlined,
                  value: 'Cash',
                ),
              ),
            ],
          ),
          if (_paymentMethod == 'MoMo') ...[
            const SizedBox(height: 18),
            Text('Network', style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 12, fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Row(
              children: ['MTN', 'Telecel', 'AirtelTigo'].map((network) {
                final bool selected = _momoNetwork == network;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: ChoiceChip(
                    label: Text(network, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w700, color: selected ? Colors.white : Colors.black87)),
                    selected: selected,
                    selectedColor: brandGreen,
                    backgroundColor: const Color(0xFFF5F6F8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide.none),
                    onSelected: (_) => setState(() => _momoNetwork = network),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _momoNumberController,
              keyboardType: TextInputType.phone,
              style: GoogleFonts.inter(fontSize: 14),
              decoration: InputDecoration(
                hintText: 'MoMo Number e.g. 024 123 4567',
                hintStyle: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
                prefixIcon: const Icon(Icons.sim_card_outlined, size: 20, color: Colors.grey),
                filled: true,
                fillColor: const Color(0xFFF5F6F8),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPaymentOption({required String label, required IconData icon, required String value}) {
    final bool selected = _paymentMethod == value;
    return GestureDetector(
      onTap: () => setState(() => _paymentMethod = value),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: selected ? brandGreen.withOpacity(0.1) : const Color(0xFFF5F6F8),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: selected ? brandGreen : Colors.transparent, width: 1.5),
        ),
        child: Column(
          children: [
            Icon(icon, color: selected ? brandGreen : Colors.grey.shade500, size: 22),
            const SizedBox(height: 6),
            Text(label, style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: selected ? brandGreen : Colors.grey.shade600)),
          ],
        ),
      ),
    );
  }

  Future<void> _handleCheckout(double total) async {
    final String deliverTo = _deliveryAddress == 'Set Delivery Location' ? 'Hostel Block C, Legon Campus' : _deliveryAddress;

    if (_paymentMethod == 'Cash') {
      _stateController.placeOrder(_cart, total, deliverTo, paymentMethod: 'Cash');
      setState(() {
        _cart.clear();
        _currentIndex = 2; // Route to Orders Status Tab
      });
      return;
    }

    final String momoNumber = _momoNumberController.text.trim();
    if (momoNumber.length < 9) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Enter a valid MoMo number to continue.')),
      );
      return;
    }

    final bool? paymentSuccess = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) => MomoCheckoutPage(
          amount: total,
          network: _momoNetwork,
          phoneNumber: momoNumber,
          deliveryAddress: deliverTo,
        ),
      ),
    );

    if (paymentSuccess == true) {
      _stateController.placeOrder(_cart, total, deliverTo, paymentMethod: 'MoMo ($_momoNetwork)');
      setState(() {
        _cart.clear();
        _currentIndex = 2; // Route to Orders Status Tab
      });
    }
  }

  // --- Live orders tab ---------------------------------------------------

  Widget _buildOrdersTab() {
    final activeOrders = _stateController.orders;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 20),
          Text('Live Food Pipelines', style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w900)),
          const SizedBox(height: 20),
          Expanded(
            child: activeOrders.isEmpty
                ? Center(child: Text('No ongoing orders.', style: GoogleFonts.inter(color: Colors.grey)))
                : ListView.builder(
                    itemCount: activeOrders.length,
                    itemBuilder: (context, idx) {
                      final order = activeOrders[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Order #${order.id}', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 15)),
                                _buildStatusBadge(order.status),
                              ],
                            ),
                            const Divider(height: 24),
                            Text(order.vendorName, style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14)),
                            const SizedBox(height: 6),
                            ...order.items.map((it) {
                              final addOnsText = it.selectedAddOns.isNotEmpty 
                                  ? ' (${it.selectedAddOns.map((a) => a.name).join(', ')})' 
                                  : '';
                              return Text('• ${it.name}$addOnsText', style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13));
                            }),
                            const Divider(height: 24),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total Paid', style: GoogleFonts.inter(color: Colors.grey, fontSize: 13)),
                                Text('GHS ${order.total.toStringAsFixed(2)}', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 16, color: brandGreen)),
                              ],
                            )
                          ],
                        ),
                      );
                    },
                  ),
          )
        ],
      ),
    );
  }

  Widget _buildStatusBadge(OrderState status) {
    Color bg;
    Color text;
    String label;

    switch (status) {
      case OrderState.placed:
        bg = Colors.amber.shade50;
        text = Colors.amber.shade800;
        label = 'PLACED';
        break;
      case OrderState.preparing:
        bg = Colors.blue.shade50;
        text = Colors.blue.shade800;
        label = 'KITCHEN';
        break;
      case OrderState.readyForPickup:
        bg = Colors.purple.shade50;
        text = Colors.purple.shade800;
        label = 'READY';
        break;
      case OrderState.enRoute:
        bg = Colors.orange.shade50;
        text = Colors.orange.shade800;
        label = 'DELIVERING';
        break;
      case OrderState.delivered:
        bg = Colors.green.shade50;
        text = Colors.green.shade800;
        label = 'ARRIVED';
        break;
      case OrderState.cancelled:
        bg = Colors.red.shade50;
        text = Colors.red.shade800;
        label = 'CANCELLED';
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
      child: Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w900, color: text)),
    );
  }

  Widget _buildProfileTab() {
    return ListView(
      padding: const EdgeInsets.all(24.0),
      children: [
        Center(
          child: Column(
            children: [
              const CircleAvatar(radius: 46, backgroundColor: brandGreen, child: Icon(Icons.person, size: 46, color: Colors.white)),
              const SizedBox(height: 12),
              Text(_userName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
              Text(_userEmail, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
        const SizedBox(height: 32),
        ListTile(
          leading: const Icon(Icons.help_outline, color: brandGreen),
          title: const Text('Help & Support'),
          onTap: () {},
        ),
        ListTile(
          leading: const Icon(Icons.logout, color: Colors.red),
          title: const Text('Sign Out'),
          onTap: () async {
            final SharedPreferences prefs = await SharedPreferences.getInstance();
            await prefs.setBool('isLoggedIn', false);
            await prefs.remove('userRole');
            if (context.mounted) {
              Navigator.of(context).pushReplacementNamed('/welcome');
            }
          },
        ),
      ],
    );
  }
}