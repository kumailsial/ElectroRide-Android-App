

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'seat_selection_page.dart';

class BusResultsPage extends StatelessWidget {

  final List<Map<String, dynamic>> results;
  final String origin;
  final String destination;
  final DateTime searchDate;

  const BusResultsPage({
    super.key,
    required this.results,
    required this.origin,
    required this.destination,
    required this.searchDate,
  });

  @override
  Widget build(BuildContext context) {

    final formattedDate = DateFormat('EEE, MMM d, yyyy').format(searchDate);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: Text("$origin → $destination", style: const TextStyle(color: Colors.white)),
        backgroundColor: Colors.green.shade700,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(30.0),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Text(
              formattedDate,
              style: const TextStyle(color: Colors.white70, fontSize: 16),
            ),
          ),
        ),
      ),
      body: results.isEmpty
          ? const Center(
        child: Text("No buses found for this route.", style: TextStyle(fontSize: 18)),
      )
          : ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: results.length,
        itemBuilder: (context, index) {
          final ride = results[index];
          return _buildBusCard(context, ride);
        },
      ),
    );
  }

  Widget _buildBusCard(BuildContext context, Map<String, dynamic> ride) {

    final departureTime = ride['departure_time'] as String;
    final busNumber = ride['bus_number'] as String? ?? 'N/A';

    final price = (ride['price'] as num?)?.toStringAsFixed(0) ?? '0';
    final availableSeats = ride['available_seats'] as int? ?? 0;

    return Card(
      elevation: 4,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Departure: $departureTime",
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade800,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    busNumber,
                    style: TextStyle(color: Colors.blue.shade700, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const Divider(height: 25),


            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Price (PKR)", style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Text(
                      "Rs. $price",
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Available Seats", style: TextStyle(color: Colors.grey.shade600)),
                    const SizedBox(height: 4),
                    Text(
                      availableSeats.toString(),
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                        color: availableSeats > 10 ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 15),


            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: availableSeats > 0 ? () {

                  Navigator.push(
                    context,
                    MaterialPageRoute(

                      builder: (context) => SeatSelectionPage(rideDetails: ride),
                    ),
                  );

                } : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                child: Text(
                  availableSeats > 0 ? "Book Now" : "Sold Out",
                  style: const TextStyle(fontSize: 16, color: Colors.white, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}