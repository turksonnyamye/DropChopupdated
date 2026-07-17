import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../state_controller.dart';
import 'screens/rider_dashboard.dart';
import 'screens/available_orders.dart';
import 'screens/rider_profile.dart';
import 'screens/rider_live_map.dart';
import 'widgets/vendor_details_sheet.dart';

class RiderHomePage extends StatefulWidget {
  const RiderHomePage({super.key});

  @override
  State<RiderHomePage> createState() => _RiderHomePageState();
}

class _RiderHomePageState extends State<RiderHomePage> {
  int _currentIndex = 1; // Opens default Map view
  final DropChopStateController _stateController = DropChopStateController();
  CentralOrder? _activeTripData;

  @override
  void initState() {
    super.initState();
    _stateController.addListener(() {
      if (mounted) setState(() {});
    });
  }

  void _acceptOfferConfirmation(CentralOrder job) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => VendorDetailsSheet(
        job: {
          'id': job.id,
          'pickup': job.pickupLocation,
          'drop': job.dropoffLocation,
          'payout': (job.total * 0.15).toStringAsFixed(2),
          'vendorName': job.vendorName,
          'vendorRating': job.riderRating,
          'items': job.items.map((i) => i.name).toList(),
        },
        onConfirmPickup: () {
          Navigator.pop(context);
          setState(() {
            _activeTripData = job;
            _stateController.assignRiderToOrder(job.id, 'Alex Rider Fleet');
          });
          _openLiveMap(job);
        },
      ),
    );
  }

  void _openLiveMap(CentralOrder job) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => RiderLiveMapScreen(
          trip: job,
          onCompleteOrder: _completeActiveOrder,
        ),
      ),
    ).then((_) {
      // If the rider backs out of the map without finishing, keep the trip
      // tracked so they can jump back in from the dashboard/available tab.
      if (mounted) setState(() {});
    });
  }

  void _completeActiveOrder(String orderId, double payout) {
    _stateController.completeOrder(orderId, payout);

    setState(() {
      _activeTripData = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Payout and delivery statistics synchronized successfully!'),
        backgroundColor: Color(0xFF32BB78),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Collect ready orders from controller
    final availableJobs = _stateController.orders
        .where((o) => o.status == OrderState.readyForPickup && o.assignedRider == null)
        .toList();

    final activeHistory = _stateController.orders
        .where((o) => o.status == OrderState.delivered)
        .map((o) => {
          'id': o.id,
          'vendorName': o.vendorName,
          'payout': (o.total * 0.15).toStringAsFixed(2)
        }).toList();

    final List<Widget> screens = [
      RiderDashboardScreen(
        activeOrders: _activeTripData != null ? [{
          'id': _activeTripData!.id,
          'pickup': _activeTripData!.pickupLocation,
          'drop': _activeTripData!.dropoffLocation,
          'payout': (_activeTripData!.total * 0.15).toStringAsFixed(2),
          'vendorName': _activeTripData!.vendorName,
        }] : [],
        completedHistory: activeHistory,
        dailyEarnings: _stateController.dailyEarnings,
        completedTrips: _stateController.completedTrips,
        onCompleteOrder: (orderId) {
          if (_activeTripData != null && _activeTripData!.id == orderId) {
            final double payout = double.parse((_activeTripData!.total * 0.15).toStringAsFixed(2));
            _completeActiveOrder(orderId, payout);
          }
        },
      ),
      AvailableOrdersScreen(
        availableJobs: availableJobs.map((o) => {
          'id': o.id,
          'pickup': o.pickupLocation,
          'drop': o.dropoffLocation,
          'payout': (o.total * 0.15).toStringAsFixed(2),
          'vendorName': o.vendorName,
          'vendorRating': o.riderRating
        }).toList(),
        ongoingJob: _activeTripData != null ? {
          'id': _activeTripData!.id,
          'pickup': _activeTripData!.pickupLocation,
          'drop': _activeTripData!.dropoffLocation,
          'payout': (_activeTripData!.total * 0.15).toStringAsFixed(2),
          'vendorName': _activeTripData!.vendorName,
        } : null,
        onAcceptJob: (jobMap) {
          final matchedOrder = _stateController.orders.firstWhere((o) => o.id == jobMap['id']);
          _acceptOfferConfirmation(matchedOrder);
        },
        onResumeTrip: _activeTripData != null ? () => _openLiveMap(_activeTripData!) : null,
      ),
      const RiderProfileScreen(),
    ];

    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Text('DropChop Dispatch', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w900, fontSize: 18)),
        centerTitle: true,
      ),
      body: SafeArea(child: screens[_currentIndex]),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        selectedItemColor: const Color(0xFF32BB78),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.analytics_rounded), label: 'Analytics'),
          BottomNavigationBarItem(icon: Icon(Icons.explore_rounded), label: 'Map Run'),
          BottomNavigationBarItem(icon: Icon(Icons.sports_motorsports_rounded), label: 'Profile'),
        ],
      ),
    );
  }
}
