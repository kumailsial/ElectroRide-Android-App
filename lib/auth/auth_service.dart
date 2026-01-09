import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class AuthService {
  final SupabaseClient _supabase = Supabase.instance.client;
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  User? get currentUser => _supabase.auth.currentUser;

  final FlutterLocalNotificationsPlugin _notificationsPlugin = FlutterLocalNotificationsPlugin();


  Future<User?> signUp({required String email, required String password, required String username}) async {
    final res = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {'username': username},
    );
    return res.user;
  }

  Future<User?> signIn({required String email, required String password}) async {
    final res = await _supabase.auth.signInWithPassword(email: email, password: password);
    return res.user;
  }


  Future<void> signInWithSocial(OAuthProvider provider) async {
    await _supabase.auth.signInWithOAuth(
      provider,
      redirectTo: 'io.supabase.flutter://login-callback/',
    );
  }

  Future<void> signOut() async => await _supabase.auth.signOut();


  Future<void> deleteAccount() async {
    await _supabase.auth.signOut();
  }


  Future<Map<String, dynamic>?> getProfile() async {
    if (currentUser == null) return null;
    return await _supabase.from('profiles').select().eq('id', currentUser!.id).maybeSingle();
  }

  Future<void> updateProfile({required String userId, required String username, required String phone}) async {
    await _supabase.from('profiles').update({'username': username, 'phone': phone}).eq('id', userId);
  }

  Future<void> deleteBooking({required String bookingId, required String rideId, required int seatsCount}) async {
    await _supabase.from('bookings').delete().eq('id', bookingId);
    final rideData = await _supabase.from('rides').select('available_seats').eq('id', rideId).maybeSingle();
    if (rideData != null) {
      await _supabase.from('rides').update({'available_seats': (rideData['available_seats'] as int) + seatsCount}).eq('id', rideId);
    }
  }

  Future<void> markNotificationRead(String id) async {
    await _supabase.from('notifications').update({'is_read': true}).eq('id', id);
  }

  Future<void> createBookingExternal({
    required String userId,
    required String rideId,
    required List<int> seats,
    required double totalPrice,
    required String paymentStatus
  }) async {
    final seatsString = seats.join(', ');
    try {
      await _supabase.from('bookings').insert({
        'user_id': userId,
        'ride_id': rideId,
        'seats_booked': seats.map((s) => s.toString()).join(','),
        'total_fare': totalPrice,
        'booking_status': paymentStatus,
      });

      final rideData = await _supabase.from('rides').select('available_seats').eq('id', rideId).maybeSingle();
      if (rideData != null) {
        int currentSeats = rideData['available_seats'] as int;
        await _supabase.from('rides').update({
          'available_seats': currentSeats - seats.length
        }).eq('id', rideId);
      }

      String msg = "Your ticket for Seat No: $seatsString has been successfully booked.";
      await _supabase.from('notifications').insert({
        'user_id': userId,
        'title': "Booking Confirmed ✅",
        'message': msg,
        'is_read': false
      });

      await pushImmediateNotification("Booking Confirmed ✅", msg);
    } catch (e) {
      rethrow;
    }
  }

  Future<void> pushImmediateNotification(String title, String body) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'booking_alerts_channel',
      'Booking Alerts',
      channelDescription: 'Pop-up alerts for ticket bookings',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );
    const NotificationDetails platformDetails = NotificationDetails(android: androidDetails);
    await _notificationsPlugin.show(
      DateTime.now().millisecond,
      title,
      body,
      platformDetails,
    );
  }
}