

import 'package:electroride/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class BookingConfirmationPage extends StatefulWidget {
  final Map<String, dynamic> rideDetails;
  final List<int> selectedSeats;

  const BookingConfirmationPage({
    super.key,
    required this.rideDetails,
    required this.selectedSeats,
  });

  @override
  State<BookingConfirmationPage> createState() => _BookingConfirmationPageState();
}

class _BookingConfirmationPageState extends State<BookingConfirmationPage> {
  final AuthService _authService = AuthService();
  String _loadingMethod = '';
  String _errorMessage = '';

  String get rideId => widget.rideDetails['id'] as String;
  double get seatPrice => (widget.rideDetails['price'] as num?)?.toDouble() ?? 20.00;
  double get totalPrice => widget.selectedSeats.length * seatPrice;
  String get origin => widget.rideDetails['origin_city'] as String;
  String get destination => widget.rideDetails['destination_city'] as String;
  String get departureTime => widget.rideDetails['departure_time'] as String;
  String get departureDate {
    final date = widget.rideDetails['date'] is String
        ? DateTime.parse(widget.rideDetails['date'])
        : widget.rideDetails['date'] as DateTime;
    return DateFormat('EEE, MMM d').format(date);
  }


  Future<void> _placeBooking({required String paymentMethod}) async {
    setState(() {
      _loadingMethod = paymentMethod;
      _errorMessage = '';
    });

    final userId = _authService.currentUser?.id;
    if (userId == null) {
      setState(() => _errorMessage = 'User not logged in.');
      return;
    }


    final paymentStatus = 'confirmed via $paymentMethod';

    try {

      await _authService.createBookingExternal(
        userId: userId,
        rideId: rideId,
        seats: widget.selectedSeats,
        totalPrice: totalPrice,
        paymentStatus: paymentStatus,
      );


      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Booking Confirmed via $paymentMethod!'), backgroundColor: Colors.green),
        );
        Navigator.popUntil(context, (route) => route.isFirst);
      }

    } catch (e) {
      print("BOOKING ERROR: $e");
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().split(':').last.trim();
        });
      }
    } finally {
      if (mounted) setState(() => _loadingMethod = '');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Confirm Booking", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green.shade700,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSummaryCard(),
            const SizedBox(height: 20),

            const Text(
                "Select Payment Method",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)
            ),
            const SizedBox(height: 10),

            _buildPaymentMethodButtons(),
            const SizedBox(height: 20),

            if (_errorMessage.isNotEmpty)
              _buildErrorBox(_errorMessage),
          ],
        ),
      ),
    );
  }



  Widget _buildSummaryCard() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Ride Details", style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
            const Divider(),
            _detailRow("Route", "$origin → $destination"),
            _detailRow("Date", departureDate),
            _detailRow("Time", departureTime),
            _detailRow("Seats", widget.selectedSeats.join(', ')),
            _detailRow("Total Seats", widget.selectedSeats.length.toString()),
            const Divider(),
            _detailRow("Price per Seat", "Rs. ${seatPrice.toStringAsFixed(2)}"),
            _detailRow("Total Fare", "Rs. ${totalPrice.toStringAsFixed(2)}", isTotal: true),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 16, color: Colors.grey.shade600)),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              color: isTotal ? Colors.red.shade900 : Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorBox(String message) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.red.shade100,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red.shade400),
      ),
      child: Text(
        message,
        style: TextStyle(color: Colors.red.shade800, fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _buildPaymentMethodButtons() {
    return Column(
      children: [
        _paymentButton(
          title: "Pay via Easypaisa",
          icon: Icons.account_balance,
          methodName: "Easypaisa",
          color: Colors.green,
        ),
        const SizedBox(height: 10),
        _paymentButton(
          title: "Pay via JazzCash",
          icon: Icons.payments,
          methodName: "JazzCash",
          color: Colors.red.shade700,
        ),
        const SizedBox(height: 10),
        _paymentButton(
          title: "Pay via Debit/Credit Card",
          icon: Icons.credit_card,
          methodName: "Card",
          color: Colors.blue.shade700,
        ),
      ],
    );
  }

  Widget _paymentButton({
    required String title,
    required IconData icon,
    required String methodName,
    required Color color,
  }) {
    final bool isLoading = _loadingMethod == methodName;
    final bool isAnyOtherLoading = _loadingMethod.isNotEmpty && _loadingMethod != methodName;

    return SizedBox(
      width: double.infinity,
      height: 55,
      child: ElevatedButton.icon(

        onPressed: (isLoading || isAnyOtherLoading) ? null : () => _placeBooking(paymentMethod: methodName),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        icon: isLoading
            ? const SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
          ),
        )
            : Icon(icon, color: Colors.white),
        label: Text(
          isLoading ? "Processing..." : title,
          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}