

import 'package:electroride/auth/auth_service.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class BookingHistoryPage extends StatefulWidget {
  const BookingHistoryPage({super.key});

  @override
  State<BookingHistoryPage> createState() => _BookingHistoryPageState();
}

class _BookingHistoryPageState extends State<BookingHistoryPage> {
  final AuthService _authService = AuthService();
  List<Map<String, dynamic>> _bookings = [];
  bool _isLoading = true;
  String _errorMessage = '';

  @override
  void initState() {
    super.initState();
    _fetchBookings();
  }

  Future<void> _fetchBookings() async {
    final userId = _authService.currentUser?.id;

    if (userId == null) {
      setState(() {
        _errorMessage = "You must be logged in to view history.";
        _isLoading = false;
      });
      return;
    }

    try {

      final List<Map<String, dynamic>> data = await Supabase.instance.client
          .from('bookings')
          .select('*, ride_id(id, origin_city, destination_city, date, departure_time, bus_number, price)') // Added ride_id(id) for cancellation
          .eq('user_id', userId)
          .order('created_at', ascending: false) as List<Map<String, dynamic>>;

      if (mounted) {
        setState(() {
          _bookings = data;
        });
      }
    } on PostgrestException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Database Error: Failed to fetch bookings. Check RLS.";
          print("BOOKING FETCH POSTGREST ERROR: ${e.message}");
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "An unexpected error occurred.";
          print("BOOKING FETCH UNEXPECTED ERROR: $e");
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("My Bookings", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green.shade700,
        centerTitle: true,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text(_errorMessage, style: TextStyle(color: Colors.red.shade700, fontSize: 16)),
        ),
      );
    }

    if (_bookings.isEmpty) {
      return const Center(
        child: Text("You have no booking history yet.", style: TextStyle(fontSize: 18, color: Colors.grey)),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _bookings.length,
      itemBuilder: (context, index) {
        final booking = _bookings[index];
        return _buildBookingCard(booking);
      },
    );
  }

  Widget _buildBookingCard(Map<String, dynamic> booking) {

    final rideDetails = booking['ride_id'] as Map<String, dynamic>?;


    final totalFare = (booking['total_fare'] as num?)?.toStringAsFixed(2) ?? 'N/A';

    final seatsBooked = booking['seats_booked'] as String? ?? 'N/A';
    final bookingDate = DateTime.parse(booking['created_at'] as String);


    if (rideDetails == null) {
      return const SizedBox.shrink();
    }

    final origin = rideDetails['origin_city'] as String? ?? 'Unknown';
    final destination = rideDetails['destination_city'] as String? ?? 'Unknown';
    final departureTime = rideDetails['departure_time'] as String? ?? 'N/A';
    final travelDate = rideDetails['date'] as String? ?? 'N/A';
    final busNumber = rideDetails['bus_number'] as String? ?? 'N/A';


    final isConfirmed = booking['booking_status']?.toString().toLowerCase().contains('confirmed') ?? false;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Flexible(
                  child: Text(
                    "$origin → $destination",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.green.shade800),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text(
                  "Rs. $totalFare",
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                ),
              ],
            ),
            const Divider(height: 20),


            _detailRow(Icons.calendar_today, "Travel Date", DateFormat('MMM dd, yyyy').format(DateTime.parse(travelDate))),
            _detailRow(Icons.schedule, "Departure Time", departureTime),
            _detailRow(Icons.confirmation_number, "Seats Booked", seatsBooked),
            _detailRow(Icons.bus_alert, "Bus No.", busNumber),

            const Divider(height: 20),


            Text("Booking Time: ${DateFormat('MMM dd, HH:mm').format(bookingDate)}",
              style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
            ),

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text("Status: ${booking['booking_status']}",
                  style: const TextStyle(fontSize: 14, color: Colors.blue, fontWeight: FontWeight.w600),
                ),


                if (isConfirmed)
                  TextButton.icon(
                    icon: const Icon(Icons.delete_forever, color: Colors.red),
                    label: const Text("Cancel", style: TextStyle(color: Colors.red)),
                    onPressed: () => _confirmAndDelete(booking),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: [
          Icon(icon, size: 18, color: Colors.grey.shade600),
          const SizedBox(width: 5),
          Text("$label:", style: TextStyle(fontSize: 14, color: Colors.grey.shade700)),
          const SizedBox(width: 5),
          Expanded(child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500))),
        ],
      ),
    );
  }


  void _confirmAndDelete(Map<String, dynamic> booking) async {
    final bookingId = booking['id'] as String?;


    final rideDetails = booking['ride_id'] as Map<String, dynamic>?;
    final rideId = rideDetails?['id'] as String?;


    final seatsBookedString = booking['seats_booked'] as String?;
    final seatsCount = seatsBookedString?.split(',').length ?? 0;


    if (bookingId == null || rideId == null || seatsCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Cancellation failed: Missing booking details.'), backgroundColor: Colors.red),
      );
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Cancel Booking"),
        content: Text("Are you sure you want to cancel your booking for $seatsCount seat(s)? This action cannot be undone."),
        actions: [
          TextButton(onPressed: () => Navigator.of(context).pop(false), child: const Text("No")),
          TextButton(onPressed: () => Navigator.of(context).pop(true), child: const Text("Yes, Cancel")),
        ],
      ),
    ) ?? false;

    if (confirmed) {
      try {

        setState(() => _isLoading = true);

        await _authService.deleteBooking(
          bookingId: bookingId,
          rideId: rideId,
          seatsCount: seatsCount,
        );


        await _fetchBookings();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Booking successfully cancelled.'), backgroundColor: Colors.green),
        );
      } catch (e) {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Cancellation failed: ${e.toString().split(':').last.trim()}'), backgroundColor: Colors.red),
        );
      }
    }
  }
}