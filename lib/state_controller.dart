import 'dart:math';
import 'package:flutter/material.dart';

enum OrderState { placed, preparing, readyForPickup, enRoute, delivered, cancelled }

class VendorSession {
  static String? currentVendorId;
  static String? currentVendorName;

  static void clear() {
    currentVendorId = null;
    currentVendorName = null;
  }
}

class AddOn {
  final String name;
  final double price;
  final String emoji;

  const AddOn({
    required this.name,
    required this.price,
    required this.emoji,
  });
}

class Vendor {
  final String id;
  final String name;
  final String category;
  final String emoji;
  final String? imagePath; 
  final double rating;
  final String etaRange;
  final double deliveryFee;
  final String location;
  final double mapX;
  final double mapY;

  const Vendor({
    required this.id,
    required this.name,
    required this.category,
    required this.emoji,
    this.imagePath,
    required this.rating,
    required this.etaRange,
    required this.deliveryFee,
    required this.location,
    required this.mapX,
    required this.mapY,
  });
}

class CentralFoodItem {
  final String id;
  final String vendorId;
  final String name;
  final String vendor;
  final double price;
  final String emoji;
  final String? imagePath; // Added to support pictures for individual foods
  final String category;
  final String description;
  List<AddOn> selectedAddOns;

  CentralFoodItem({
    required this.id,
    required this.vendorId,
    required this.name,
    required this.vendor,
    required this.price,
    required this.emoji,
    this.imagePath, 
    required this.category,
    this.description = '',
    List<AddOn>? selectedAddOns,
  }) : selectedAddOns = selectedAddOns ?? [];

  double get totalPrice => price + selectedAddOns.fold(0.0, (sum, addon) => sum + addon.price);

  CentralFoodItem copy() {
    return CentralFoodItem(
      id: id,
      vendorId: vendorId,
      name: name,
      vendor: vendor,
      price: price,
      emoji: emoji,
      imagePath: imagePath, 
      category: category,
      description: description,
      selectedAddOns: List.from(selectedAddOns),
    );
  }
}

class CentralOrder {
  final String id;
  final String vendorId;
  final List<CentralFoodItem> items;
  OrderState status;
  final DateTime placedAt;
  final double total;
  final String vendorName;
  final String pickupLocation;
  final String dropoffLocation;
  final double vendorMapX;
  final double vendorMapY;
  final double dropMapX;
  final double dropMapY;
  final String paymentMethod;
  String? assignedRider;
  String riderRating;
  String calculatedPrep;

  CentralOrder({
    required this.id,
    required this.vendorId,
    required this.items,
    required this.status,
    required this.placedAt,
    required this.total,
    required this.vendorName,
    required this.pickupLocation,
    required this.dropoffLocation,
    required this.vendorMapX,
    required this.vendorMapY,
    required this.dropMapX,
    required this.dropMapY,
    this.paymentMethod = 'Cash',
    this.assignedRider,
    this.riderRating = '4.9 ★',
    this.calculatedPrep = '15 mins',
  });
}

class DropChopStateController extends ChangeNotifier {
  static final DropChopStateController _instance = DropChopStateController._internal();
  factory DropChopStateController() => _instance;
  DropChopStateController._internal();

  final Random _rng = Random();

  final List<Vendor> vendors = [
    const Vendor(
      id: 'v1',
      name: 'Juljones',
      category: 'Local & Rice Dishes',
      emoji: '🍛',
      imagePath: 'images/Juljones.jpeg', 
      rating: 4.8,
      etaRange: '15-25 min',
      deliveryFee: 10.0,
      location: 'Juljones Kitchen, Legon Campus',
      mapX: 0.18,
      mapY: 0.22,
    ),
    const Vendor(
      id: 'v2',
      name: 'Chillings Fast Food',
      category: 'Fast Food & Grills',
      emoji: '🍔',
      imagePath: 'images/chillings.jpeg', 
      rating: 4.5,
      etaRange: '20-30 min',
      deliveryFee: 12.0,
      location: 'Chillings Fast Food, East Legon',
      mapX: 0.78,
      mapY: 0.30,
    ),
    const Vendor(
      id: 'v3',
      name: 'Marks Slurp',
      category: 'Drinks & Smoothies',
      emoji: '🥤',
      imagePath: 'images/marks.png',
      rating: 4.9,
      etaRange: '10-15 min',
      deliveryFee: 8.0,
      location: 'Marks Slurp Drink Shop, Campus Walkway',
      mapX: 0.55,
      mapY: 0.72,
    ),
  ];

  late final List<CentralFoodItem> foodMenu = [
    // --- Juljones Menu ---
    CentralFoodItem(id: 'j1', vendorId: 'v1', name: 'Juljones Fried Rice', vendor: 'Juljones', price: 45.00, emoji: '🍛', imagePath: 'images/food/Juljones_fried_rice.jpeg', category: 'Rice', description: 'Classic wok-fried rice served with spiced grilled chicken'),
    CentralFoodItem(id: 'j2', vendorId: 'v1', name: 'Juljones Jollof Rice', vendor: 'Juljones', price: 45.00, emoji: '🍛', imagePath: 'images/food/juljones_jollof.png', category: 'Rice', description: 'Smoky, authentic Ghanaian Jollof rice with chicken'),
    CentralFoodItem(id: 'j3', vendorId: 'v1', name: 'Plain Rice & Stew', vendor: 'Juljones', price: 40.00, emoji: '🍚', imagePath: 'images/food/plain_rice.png', category: 'Rice', description: 'Steamed white rice served with spicy tomato-fish stew'),
    CentralFoodItem(id: 'j4', vendorId: 'v1', name: 'Yam & Stew', vendor: 'Juljones', price: 35.00, emoji: '🍢', imagePath: 'images/food/yam_stew.png', category: 'Local', description: 'Boiled sweet yam paired with aromatic garden egg or palmoil stew'),
    CentralFoodItem(id: 'j5', vendorId: 'v1', name: 'Fufu & Light Soup', vendor: 'Juljones', price: 55.00, emoji: '🥣', imagePath: 'images/food/fufu_light_soup.png', category: 'Local', description: 'Smooth fufu served in rich, hot light soup with goat meat'),
    CentralFoodItem(id: 'j6', vendorId: 'v1', name: 'Banku & Okro Stew', vendor: 'Juljones', price: 50.00, emoji: '🍲', imagePath: 'images/food/banku_okro_stew.png', category: 'Local', description: 'Warm fermented corn and cassava dough with savory seafood okro'),
    CentralFoodItem(id: 'j7', vendorId: 'v1', name: 'Banku & Tilapia', vendor: 'Juljones', price: 65.00, emoji: '🐟', imagePath: 'images/food/banku_tilapia.png', category: 'Local', description: 'Freshly grilled whole tilapia accompanied by banku and pepper'),

    // --- Chillings Fast Food Menu ---
    CentralFoodItem(id: 'c1', vendorId: 'v2', name: 'Chillings Cheeseburger', vendor: 'Chillings Fast Food', price: 55.00, emoji: '🍔', imagePath: 'images/food/chillings_burger.png', category: 'Burgers', description: 'Flayer-grilled beef patty, cheddar cheese, cool lettuce, burger sauce'),
    CentralFoodItem(id: 'c2', vendorId: 'v2', name: 'Spicy Chicken Wrap', vendor: 'Chillings Fast Food', price: 40.00, emoji: '🌯', imagePath: 'images/food/chillings_wrap.png', category: 'Wraps', description: 'Crispy spicy chicken strips, ranch sauce in a soft tortilla'),
    CentralFoodItem(id: 'c3', vendorId: 'v2', name: 'Crispy Loaded Fries', vendor: 'Chillings Fast Food', price: 30.00, emoji: '🍟', imagePath: 'images/food/loaded_fries.png', category: 'Sides', description: 'Golden French fries topped with creamy cheese sauce and crispy bits'),
    CentralFoodItem(id: 'c4', vendorId: 'v2', name: 'Hot Chicken Wings', vendor: 'Chillings Fast Food', price: 45.00, emoji: '🍗', imagePath: 'images/food/chicken_wings.png', category: 'Chicken', description: '6 pieces of buffalo style crispy glazed wings'),

    // --- Marks Slurp Menu ---
    CentralFoodItem(id: 's1', vendorId: 'v3', name: 'Classic Sobolo Slurp', vendor: 'Marks Slurp', price: 15.00, emoji: '🍷', imagePath: 'images/food/sobolo.png', category: 'Local', description: 'Sweet hibiscus ginger infusion, perfectly chilled'),
    CentralFoodItem(id: 's2', vendorId: 'v3', name: 'Oreo Milkshake Slurp', vendor: 'Marks Slurp', price: 30.00, emoji: '🥤', imagePath: 'images/food/oreo_shake.png', category: 'Shakes', description: 'Thick, creamy vanilla soft-serve blended with Oreo biscuits'),
    CentralFoodItem(id: 's3', vendorId: 'v3', name: 'Mango Fresh Juice', vendor: 'Marks Slurp', price: 20.00, emoji: '🍹', imagePath: 'images/food/mango_juice.png', category: 'Juices', description: '100% freshly pressed organic local mangoes'),
    CentralFoodItem(id: 's4', vendorId: 'v3', name: 'Brown Sugar Bubble Tea', vendor: 'Marks Slurp', price: 35.00, emoji: '🧋', imagePath: 'images/food/bubble_tea.png', category: 'Specialty', description: 'Creamy milk tea with sweet caramelized tapioca pearls'),
  ];

  List<CentralFoodItem> menuForVendor(String vendorId) =>
      foodMenu.where((item) => item.vendorId == vendorId).toList();

  Vendor? vendorById(String id) {
    try {
      return vendors.firstWhere((v) => v.id == id);
    } catch (_) {
      return null;
    }
  }

  final List<CentralOrder> _orders = [];
  List<CentralOrder> get orders => _orders;

  List<CentralOrder> ordersForVendor(String vendorId) =>
      _orders.where((o) => o.vendorId == vendorId).toList();

  double dailyEarnings = 0.0;
  int completedTrips = 0;

  void placeOrder(List<CentralFoodItem> items, double total, String clientDropoff, {String paymentMethod = 'Cash'}) {
    if (items.isEmpty) return;

    final String vendorId = items.first.vendorId;
    final Vendor? vendor = vendorById(vendorId);
    final String vendorName = vendor?.name ?? items.first.vendor;
    final String pickup = vendor?.location ?? 'Accra';

    final double dropX = (0.15 + _rng.nextDouble() * 0.7).clamp(0.05, 0.95);
    final double dropY = (0.15 + _rng.nextDouble() * 0.7).clamp(0.05, 0.95);

    final String newId = (2000 + _orders.length + 1).toString();

    final newOrder = CentralOrder(
      id: newId,
      vendorId: vendorId,
      items: List.from(items),
      status: OrderState.placed,
      placedAt: DateTime.now(),
      total: total,
      vendorName: vendorName,
      pickupLocation: pickup,
      dropoffLocation: clientDropoff,
      vendorMapX: vendor?.mapX ?? 0.5,
      vendorMapY: vendor?.mapY ?? 0.5,
      dropMapX: dropX,
      dropMapY: dropY,
      paymentMethod: paymentMethod,
    );

    _orders.insert(0, newOrder);
    notifyListeners();
  }

  void advanceVendorStatus(String orderId) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      final current = _orders[index].status;
      if (current == OrderState.placed) {
        _orders[index].status = OrderState.preparing;
      } else if (current == OrderState.preparing) {
        _orders[index].status = OrderState.readyForPickup;
      }
      notifyListeners();
    }
  }

  void assignRiderToOrder(String orderId, String riderName) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index].assignedRider = riderName;
      _orders[index].status = OrderState.enRoute;
      notifyListeners();
    }
  }

  void completeOrder(String orderId, double payout) {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index != -1) {
      _orders[index].status = OrderState.delivered;
      dailyEarnings += payout;
      completedTrips += 1;
      notifyListeners();
    }
  }
}