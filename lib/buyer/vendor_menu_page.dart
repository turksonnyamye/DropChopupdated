import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../state_controller.dart';

class VendorMenuPage extends StatefulWidget {
  final Vendor vendor;
  final List<CentralFoodItem> cart;
  final void Function(CentralFoodItem item) onAddToCart;
  final void Function(CentralFoodItem item) onRemoveOneFromCart;
  final VoidCallback onViewCart;

  const VendorMenuPage({
    super.key,
    required this.vendor,
    required this.cart,
    required this.onAddToCart,
    required this.onRemoveOneFromCart,
    required this.onViewCart,
  });

  @override
  State<VendorMenuPage> createState() => _VendorMenuPageState();
}

class _VendorMenuPageState extends State<VendorMenuPage> {
  static const Color brandGreen = Color(0xFF32BB78);
  final DropChopStateController _controller = DropChopStateController();
  String _activeCategory = 'All';

  int _quantityOf(String itemId) =>
      widget.cart.where((i) => i.id == itemId).length;

  int get _cartCount => widget.cart.length;
  double get _cartTotal => widget.cart.fold(0.0, (sum, item) => sum + item.totalPrice);

  // Generates unique optional add-ons depending on vendor domain
  List<AddOn> _getAvailableAddOns() {
    switch (widget.vendor.id) {
      case 'v1': // Juljones (Local dishes)
        return const [
          AddOn(name: 'Fried Egg', price: 5.0, emoji: '🍳'),
          AddOn(name: 'Spiced Chicken Piece', price: 15.0, emoji: '🍗'),
          AddOn(name: 'Warm Kelewele', price: 10.0, emoji: '🍢'),
          AddOn(name: 'Homemade Shito Pepper', price: 3.0, emoji: '🌶️'),
        ];
      case 'v2': // Chillings Fast Food
        return const [
          AddOn(name: 'Double Cheddar Cheese', price: 6.0, emoji: '🧀'),
          AddOn(name: 'Crispy Turkey Bacon', price: 12.0, emoji: '🥓'),
          AddOn(name: 'Smashed Avocado', price: 8.0, emoji: '🥑'),
          AddOn(name: 'Jalapeño Slices', price: 4.0, emoji: '🌶️'),
        ];
      case 'v3': // Marks Slurp
        return const [
          AddOn(name: 'Tapioca Boba Pearls', price: 5.0, emoji: '🧋'),
          AddOn(name: 'Whipped Cream Topping', price: 4.0, emoji: '🧁'),
          AddOn(name: 'Crushed Oreo Crumbs', price: 6.0, emoji: '🍪'),
          AddOn(name: 'Organic Chia Seeds', price: 3.0, emoji: '🌱'),
        ];
      default:
        return [];
    }
  }

  // Reusable helper: shows the food item's image if it has one, else falls back to emoji
  Widget _foodThumbnail(CentralFoodItem item, {double size = 72, double emojiSize = 34, double radius = 16}) {
    return Container(
      width: size,
      height: size,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: const Color(0xFFF5F6F8),
        borderRadius: BorderRadius.circular(radius),
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

  void _showAddOnBottomSheet(CentralFoodItem baseItem) {
    final List<AddOn> options = _getAvailableAddOns();
    final List<AddOn> selectedAddOns = [];

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            double customTotal = baseItem.price +
                selectedAddOns.fold(0.0, (sum, addOn) => sum + addOn.price);

            return Container(
              decoration: const BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 40,
                      height: 5,
                      decoration: BoxDecoration(
                        color: Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      _foodThumbnail(baseItem, size: 56, emojiSize: 28, radius: 14),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              baseItem.name,
                              style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 18),
                            ),
                            Text(
                              'GHS ${baseItem.price.toStringAsFixed(2)}',
                              style: GoogleFonts.inter(color: Colors.grey.shade600, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    baseItem.description,
                    style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 13),
                  ),
                  if (options.isNotEmpty) ...[
                    const Divider(height: 32),
                    Text(
                      'Customize your order:',
                      style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14),
                    ),
                    const SizedBox(height: 12),
                    ConstrainedBox(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(context).size.height * 0.3,
                      ),
                      child: ListView.builder(
                        shrinkWrap: true,
                        physics: const BouncingScrollPhysics(),
                        itemCount: options.length,
                        itemBuilder: (context, index) {
                          final addOn = options[index];
                          final isSelected = selectedAddOns.contains(addOn);

                          return Container(
                            margin: const EdgeInsets.only(bottom: 8),
                            decoration: BoxDecoration(
                              color: isSelected ? brandGreen.withOpacity(0.05) : const Color(0xFFF5F6F8),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: isSelected ? brandGreen : Colors.transparent,
                                width: 1.5,
                              ),
                            ),
                            child: CheckboxListTile(
                              value: isSelected,
                              activeColor: brandGreen,
                              title: Row(
                                children: [
                                  Text(addOn.emoji, style: const TextStyle(fontSize: 18)),
                                  const SizedBox(width: 8),
                                  Text(
                                    addOn.name,
                                    style: GoogleFonts.inter(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 13.5,
                                      color: isSelected ? brandGreen : Colors.black87,
                                    ),
                                  ),
                                ],
                              ),
                              subtitle: Text(
                                '+ GHS ${addOn.price.toStringAsFixed(2)}',
                                style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500),
                              ),
                              onChanged: (bool? checked) {
                                setSheetState(() {
                                  if (checked == true) {
                                    selectedAddOns.add(addOn);
                                  } else {
                                    selectedAddOns.remove(addOn);
                                  }
                                });
                              },
                              controlAffinity: ListTileControlAffinity.trailing,
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: () {
                        // Use item copy method to customize this specific food container item
                        final CentralFoodItem customizedItem = baseItem.copy();
                        customizedItem.selectedAddOns = selectedAddOns;

                        widget.onAddToCart(customizedItem);
                        Navigator.pop(context);
                        setState(() {});
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: brandGreen,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: Text(
                        'Add to Bag — GHS ${customTotal.toStringAsFixed(2)}',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w900, color: Colors.white, fontSize: 16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final List<CentralFoodItem> menu = _controller.menuForVendor(widget.vendor.id);
    final List<String> categories = ['All', ...{for (final item in menu) item.category}];
    final List<CentralFoodItem> visibleMenu =
        _activeCategory == 'All' ? menu : menu.where((i) => i.category == _activeCategory).toList();

    return Scaffold(
      backgroundColor: const Color(0xFFF4F6F8),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            expandedHeight: 190,
            pinned: true,
            backgroundColor: brandGreen,
            iconTheme: const IconThemeData(color: Colors.white),
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [brandGreen, brandGreen.withOpacity(0.75)],
                  ),
                ),
                child: Stack(
                  children: [
                    if (widget.vendor.imagePath != null)
                      Positioned.fill(
                        child: Image.asset(
                          widget.vendor.imagePath!,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
                        ),
                      ),
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.bottomCenter,
                            end: Alignment.topCenter,
                            colors: [Colors.black.withOpacity(0.65), Colors.black.withOpacity(0.1)],
                          ),
                        ),
                      ),
                    ),
                    Positioned(
                      right: 12,
                      bottom: 12,
                      child: Text(widget.vendor.emoji, style: const TextStyle(fontSize: 48, color: Colors.white54)),
                    ),
                    Positioned(
                      left: 20,
                      right: 20,
                      bottom: 18,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(widget.vendor.name, style: GoogleFonts.inter(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                          const SizedBox(height: 6),
                          Text(widget.vendor.category, style: GoogleFonts.inter(color: Colors.white70, fontSize: 13, fontWeight: FontWeight.w600)),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              _pill(Icons.star_rounded, '${widget.vendor.rating}'),
                              const SizedBox(width: 8),
                              _pill(Icons.schedule_rounded, widget.vendor.etaRange),
                              const SizedBox(width: 8),
                              _pill(Icons.delivery_dining_rounded, 'GHS ${widget.vendor.deliveryFee.toStringAsFixed(0)}'),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: SizedBox(
                height: 38,
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
                        padding: const EdgeInsets.symmetric(horizontal: 18),
                        alignment: Alignment.center,
                        decoration: BoxDecoration(
                          color: selected ? brandGreen : Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: selected ? brandGreen : Colors.grey.shade300),
                        ),
                        child: Text(
                          cat,
                          style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: 13, color: selected ? Colors.white : Colors.black87),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, idx) {
                  final item = visibleMenu[idx];
                  final int qty = _quantityOf(item.id);
                  return Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20),
                      boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 10, offset: const Offset(0, 4))],
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _foodThumbnail(item),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(item.name, style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14)),
                              const SizedBox(height: 4),
                              Text(item.description, style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 11.5), maxLines: 2, overflow: TextOverflow.ellipsis),
                              const SizedBox(height: 8),
                              Text('GHS ${item.price.toStringAsFixed(2)}', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 14, color: brandGreen)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        qty == 0
                            ? _addButton(item)
                            : _stepper(item, qty),
                      ],
                    ),
                  );
                },
                childCount: visibleMenu.length,
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: _cartCount == 0
          ? null
          : SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                child: GestureDetector(
                  onTap: widget.onViewCart,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    decoration: BoxDecoration(
                      color: brandGreen,
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [BoxShadow(color: brandGreen.withOpacity(0.35), blurRadius: 16, offset: const Offset(0, 6))],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: Colors.white.withOpacity(0.25), borderRadius: BorderRadius.circular(10)),
                              child: Text('$_cartCount', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900)),
                            ),
                            const SizedBox(width: 12),
                            Text('View Cart', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15)),
                          ],
                        ),
                        Text('GHS ${_cartTotal.toStringAsFixed(2)}', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 15)),
                      ],
                    ),
                  ),
                ),
              ),
            ),
    );
  }

  Widget _pill(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(10)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 4),
          Text(label, style: GoogleFonts.inter(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }

  Widget _addButton(CentralFoodItem item) {
    return GestureDetector(
      onTap: () => _showAddOnBottomSheet(item),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(color: brandGreen, borderRadius: BorderRadius.circular(12)),
        child: Text('Add', style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.white, fontSize: 12.5)),
      ),
    );
  }

  Widget _stepper(CentralFoodItem item, int qty) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      decoration: BoxDecoration(color: brandGreen, borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => widget.onRemoveOneFromCart(item)),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Icon(Icons.remove_rounded, color: Colors.white, size: 16),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text('$qty', style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w900, fontSize: 13)),
          ),
          GestureDetector(
            onTap: () => _showAddOnBottomSheet(item),
            child: const Padding(
              padding: EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              child: Icon(Icons.add_rounded, color: Colors.white, size: 16),
            ),
          ),
        ],
      ),
    );
  }
}