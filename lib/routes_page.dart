

import 'package:flutter/material.dart';
import 'timings_page.dart';

class RoutesPage extends StatelessWidget {
  final List<String> tehsils = [
    "Bhalwal",
    "Shahpur",
    "Sillanwali",
    "Sahiwal",
    "Kot Momin",
    "Bhera",
  ];

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,

        childAspectRatio: 1.1,
      ),
      itemCount: tehsils.length,
      itemBuilder: (context, index) {
        String tehsil = tehsils[index];

        return GestureDetector(
          onTap: () {


            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => TimingsPage(from: "Sargodha", to: tehsil),
              ),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                const BoxShadow(
                  color: Colors.black12,
                  blurRadius: 4,
                  offset: Offset(0, 2),
                ),
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.directions_bus, size: 40, color: Colors.green),
                const SizedBox(height: 10),
                Text(
                  tehsil,
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  "View Route",
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black54,
                  ),
                )
              ],
            ),
          ),
        );
      },
    );
  }
}