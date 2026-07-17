import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

enum _MomoStage { prompting, waiting, success, failed }

class MomoCheckoutPage extends StatefulWidget {
  final double amount;
  final String network;
  final String phoneNumber;
  final String deliveryAddress;

  const MomoCheckoutPage({
    super.key,
    required this.amount,
    required this.network,
    required this.phoneNumber,
    required this.deliveryAddress,
  });

  @override
  State<MomoCheckoutPage> createState() => _MomoCheckoutPageState();
}

class _MomoCheckoutPageState extends State<MomoCheckoutPage> {
  static const Color brandGreen = Color(0xFF32BB78);

  _MomoStage _stage = _MomoStage.prompting;

  Color get _networkColor {
    switch (widget.network) {
      case 'MTN':
        return const Color(0xFFFFCB05);
      case 'Telecel':
        return const Color(0xFFE30613);
      case 'AirtelTigo':
        return const Color(0xFF0072BC);
      default:
        return brandGreen;
    }
  }

  Future<void> _startPayment() async {
    setState(() => _stage = _MomoStage.waiting);

    // Simulates the time it takes for a real MoMo "Approve on phone" prompt.
    await Future.delayed(const Duration(seconds: 3));

    if (!mounted) return;
    setState(() => _stage = _MomoStage.success);

    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF7F9FC),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: _stage == _MomoStage.waiting
            ? const SizedBox.shrink()
            : IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.black),
                onPressed: () => Navigator.of(context).pop(false),
              ),
        title: Text('MoMo Payment', style: GoogleFonts.inter(color: Colors.black, fontWeight: FontWeight.w800)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              _buildAmountCard(),
              const SizedBox(height: 24),
              Expanded(child: _buildStageContent()),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAmountCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(color: _networkColor, borderRadius: BorderRadius.circular(10)),
                child: const Icon(Icons.phone_android_rounded, color: Colors.white, size: 22),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('${widget.network} Mobile Money', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 14)),
                  Text(widget.phoneNumber, style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13)),
                ],
              ),
            ],
          ),
          const Divider(height: 32),
          Text('Amount to Pay', style: GoogleFonts.inter(color: Colors.grey.shade500, fontSize: 12, fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
          Text('GHS ${widget.amount.toStringAsFixed(2)}', style: GoogleFonts.inter(fontSize: 30, fontWeight: FontWeight.w900, color: brandGreen)),
        ],
      ),
    );
  }

  Widget _buildStageContent() {
    switch (_stage) {
      case _MomoStage.prompting:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet_rounded, size: 64, color: brandGreen.withOpacity(0.5)),
            const SizedBox(height: 20),
            Text(
              "We'll send a payment prompt to ${widget.phoneNumber}. Approve it to complete your order.",
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: _startPayment,
                style: ElevatedButton.styleFrom(
                  backgroundColor: brandGreen,
                  elevation: 0,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                child: Text(
                  'Send Payment Prompt',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16, color: Colors.white),
                ),
              ),
            ),
          ],
        );

      case _MomoStage.waiting:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(
              width: 60,
              height: 60,
              child: CircularProgressIndicator(strokeWidth: 4, color: brandGreen),
            ),
            const SizedBox(height: 24),
            Text('Waiting for approval...', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16)),
            const SizedBox(height: 8),
            Text(
              'Check your phone and enter your MoMo PIN to confirm.',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13),
            ),
          ],
        );

      case _MomoStage.success:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 84,
              height: 84,
              decoration: BoxDecoration(color: brandGreen.withOpacity(0.12), shape: BoxShape.circle),
              child: const Icon(Icons.check_rounded, color: brandGreen, size: 48),
            ),
            const SizedBox(height: 20),
            Text('Payment Successful', style: GoogleFonts.inter(fontWeight: FontWeight.w900, fontSize: 18)),
            const SizedBox(height: 6),
            Text('Placing your order...', style: GoogleFonts.inter(color: Colors.grey.shade600, fontSize: 13)),
          ],
        );

      case _MomoStage.failed:
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.close_rounded, color: Colors.redAccent, size: 56),
            const SizedBox(height: 16),
            Text('Payment Failed', style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16)),
          ],
        );
    }
  }
}
