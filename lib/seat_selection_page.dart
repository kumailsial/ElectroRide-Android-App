import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'booking_confirmation_page.dart';

class SeatSelectionPage extends StatefulWidget {
  final Map<String, dynamic> rideDetails;
  const SeatSelectionPage({super.key, required this.rideDetails});

  @override
  State<SeatSelectionPage> createState() => _SeatSelectionPageState();
}

class _SeatSelectionPageState extends State<SeatSelectionPage> {
  final int totalSeats = 40;
  final List<int> selectedSeats = [];
  List<int> reservedSeats = [];
  bool isLoadingSeats = true;

  double get seatPrice => (widget.rideDetails['price'] as num?)?.toDouble() ?? 20.00;
  String get departureTime => widget.rideDetails['departure_time'] as String? ?? 'N/A';
  String get origin => widget.rideDetails['origin_city'] as String? ?? 'Origin';
  String get destination => widget.rideDetails['destination_city'] as String? ?? 'Destination';
  String get rideId => widget.rideDetails['id'].toString();

  @override
  void initState() {
    super.initState();
    _fetchReservedSeats();
  }

  // ✅ FETCH ALL BOOKED SEATS (Now works with the updated (true) policy)
  Future<void> _fetchReservedSeats() async {
    try {
      final List<dynamic> response = await Supabase.instance.client
          .from('bookings')
          .select('seats_booked')
          .eq('ride_id', rideId);

      List<int> booked = [];
      for (var row in response) {
        String? seatsStr = row['seats_booked']?.toString();
        if (seatsStr != null && seatsStr.isNotEmpty) {

          List<int> seatsList = seatsStr
              .split(',')
              .where((s) => s.trim().isNotEmpty)
              .map((s) => int.parse(s.trim()))
              .toList();
          booked.addAll(seatsList);
        }
      }

      if (mounted) {
        setState(() {
          reservedSeats = booked;
          isLoadingSeats = false;
        });
      }
    } catch (e) {
      debugPrint("Error fetching seats: $e");
      if (mounted) setState(() => isLoadingSeats = false);
    }
  }

  void _toggleSeat(int seatNumber) {
    if (reservedSeats.contains(seatNumber)) return;
    setState(() {
      if (selectedSeats.contains(seatNumber)) {
        selectedSeats.remove(seatNumber);
      } else {
        selectedSeats.add(seatNumber);
      }
    });
  }

  void _proceedToCheckout() {
    if (selectedSeats.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Please select at least one seat.")));
      return;
    }
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BookingConfirmationPage(
          rideDetails: widget.rideDetails,
          selectedSeats: selectedSeats,
        ),
      ),
    );
  }

  Widget _buildSeat(int seatNumber) {
    bool isReserved = reservedSeats.contains(seatNumber);
    bool isSelected = selectedSeats.contains(seatNumber);

    Color seatColor;
    if (isReserved) {
      seatColor = Colors.grey.shade400;
    } else if (isSelected) {
      seatColor = Colors.lightGreen;
    } else {
      seatColor = Colors.green.shade50;
    }

    return GestureDetector(
      onTap: () => _toggleSeat(seatNumber),
      child: Container(
        height: 40, width: 40,
        margin: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: seatColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.green.shade700, width: 1.5),
        ),
        child: Center(
          child: Text(
            seatNumber.toString(),
            style: TextStyle(
              color: isReserved ? Colors.black54 : Colors.green.shade900,
              fontWeight: FontWeight.bold, fontSize: 12,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSeatMap() {
    if (isLoadingSeats) return const Center(child: CircularProgressIndicator());

    List<Widget> rows = [];
    int seatIndex = 1;
    for (int row = 1; row <= 10; row++) {
      List<Widget> seatsInRow = [
        _buildSeat(seatIndex++),
        _buildSeat(seatIndex++),
        const SizedBox(width: 25), // Aisle
        _buildSeat(seatIndex++),
        _buildSeat(seatIndex++),
      ];
      rows.add(Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: seatsInRow),
      ));
    }
    return Column(children: rows);
  }

  @override
  Widget build(BuildContext context) {
    final totalPrice = selectedSeats.length * seatPrice;
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text("Select Your Seat", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green.shade700,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildRideInfoCard(),
            const SizedBox(height: 10),
            _buildBusLayoutArea(),
            const SizedBox(height: 20),
            _buildLegend(),
            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: _buildCheckoutBar(totalPrice),
    );
  }

  Widget _buildRideInfoCard() {
    return Container(
      width: double.infinity, padding: const EdgeInsets.all(16), margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15), boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 6, offset: Offset(0, 3))]),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text("$origin → $destination", style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        Text("Departure Time: $departureTime", style: TextStyle(fontSize: 16, color: Colors.grey.shade700)),
        const SizedBox(height: 4),
        Text("Price per seat: Rs. ${seatPrice.toStringAsFixed(2)}", style: const TextStyle(fontSize: 16, color: Colors.blue)),
      ]),
    );
  }

  Widget _buildBusLayoutArea() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20), border: Border.all(color: Colors.green.shade300, width: 2)),
        child: Column(children: [
          const Icon(Icons.drive_eta, color: Colors.blueGrey, size: 35),
          const Divider(indent: 30, endIndent: 30, thickness: 1),
          const SizedBox(height: 10),
          _buildSeatMap(),
        ]),
      ),
    );
  }

  Widget _buildLegend() {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceEvenly, children: [
      _legendItem(Colors.green.shade50, "Available"),
      _legendItem(Colors.lightGreen, "Selected"),
      _legendItem(Colors.grey.shade400, "Reserved"),
    ]);
  }

  Widget _legendItem(Color color, String label) {
    return Row(children: [
      Container(width: 18, height: 18, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4), border: Border.all(color: Colors.black12))),
      const SizedBox(width: 6), Text(label, style: const TextStyle(fontSize: 13)),
    ]);
  }

  Widget _buildCheckoutBar(double totalPrice) {
    return Container(
      padding: const EdgeInsets.all(15), height: 80, color: Colors.white,
      child: Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text("${selectedSeats.length} Seats", style: const TextStyle(color: Colors.grey)),
          Text("Rs. ${totalPrice.toStringAsFixed(2)}", style: const TextStyle(fontSize: 19, fontWeight: FontWeight.bold, color: Colors.red)),
        ]),
        ElevatedButton(
          onPressed: _proceedToCheckout,
          style: ElevatedButton.styleFrom(backgroundColor: Colors.red.shade900, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
          child: const Text("Proceed to Pay", style: TextStyle(color: Colors.white, fontSize: 16)),
        ),
      ]),
    );
  }
}