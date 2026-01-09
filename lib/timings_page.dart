import 'package:flutter/material.dart';

class TimingsPage extends StatelessWidget {
  final String from;
  final String to;

  TimingsPage({required this.from, required this.to});

  final List<String> forwardTimings = [
    "7:00 AM",
    "9:00 AM",
    "12:00 PM",
    "3:00 PM",
    "6:00 PM",
  ];

  final List<String> backwardTimings = [
    "8:00 AM",
    "11:00 AM",
    "1:30 PM",
    "4:30 PM",
    "7:00 PM",
  ];

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.grey.shade100,
        appBar: AppBar(
          title: Text("$from ↔ $to"),
          centerTitle: true,
          backgroundColor: Colors.green,
          bottom: TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            tabs: [
              Tab(text: "$from → $to"),
              Tab(text: "$to → $from"),
            ],
          ),
        ),

        body: TabBarView(
          children: [
            _buildTimingList(forwardTimings),
            _buildTimingList(backwardTimings),
          ],
        ),
      ),
    );
  }


  Widget _buildTimingList(List<String> timings) {
    return ListView(
      padding: EdgeInsets.all(16),
      children: timings.map((time) => _timeCard(time)).toList(),
    );
  }

  Widget _timeCard(String time) {
    return Container(
      margin: EdgeInsets.only(bottom: 14),
      padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2)),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            time,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.green.shade600,
            ),
          ),
          Icon(Icons.directions_bus, color: Colors.green, size: 26),
        ],
      ),
    );
  }
}
