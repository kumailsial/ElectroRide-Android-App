

import 'package:flutter/material.dart';

class PaymentMethodsPage extends StatelessWidget {

  const PaymentMethodsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Payment Methods", style: TextStyle(color: Colors.white)),
        backgroundColor: Colors.green,
        elevation: 0,
      ),

      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [


          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Wallet Balance",
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                    const SizedBox(height: 6),
                     Text("PKR 0.00",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
                const Icon(Icons.account_balance_wallet, size: 40, color: Colors.green),
              ],
            ),
          ),

          const SizedBox(height: 20),

          const Text("External Payment Options", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const Divider(),


          _paymentTile(
            icon: Icons.account_balance,
            title: "Easypaisa (Checkout)",
            onTap: () {
              _showInfoDialog(context, "Easypaisa",
                  "Payment via Easypaisa is handled at the final booking confirmation step.");
            },
          ),


          _paymentTile(
            icon: Icons.payment,
            title: "JazzCash (Checkout)",
            onTap: () {
              _showInfoDialog(context, "JazzCash",
                  "Payment via JazzCash is handled at the final booking confirmation step.");
            },
          ),


          _paymentTile(
            icon: Icons.credit_card,
            title: "Debit/Credit Card (Checkout)",
            onTap: () {
              _showInfoDialog(context, "Card Payment",
                  "Card payment is handled at the final booking confirmation step.");
            },
          ),


        ],
      ),
    );
  }


  Widget _paymentTile({required IconData icon, required String title, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        boxShadow: const [
          BoxShadow(
            blurRadius: 4,
            color: Colors.black12,
            offset: Offset(0, 3),
          )
        ],
      ),
      child: ListTile(
        leading: Icon(icon, color: Colors.green),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
        onTap: onTap,
      ),
    );
  }


  void _showInfoDialog(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(message),
          actions: [
            TextButton(
              child: const Text("OK", style: TextStyle(color: Colors.green)),
              onPressed: () => Navigator.pop(context),
            )
          ],
        );
      },
    );
  }
}