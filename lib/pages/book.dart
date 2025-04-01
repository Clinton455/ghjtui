import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:fresh_car/pages/choose.dart';
import 'package:fresh_car/pages/login.dart';
import 'dart:async'; // Import for Timer

class BookPage extends StatefulWidget {
  const BookPage({super.key});

  @override
  State<BookPage> createState() => _BookPageState();
}

class _BookPageState extends State<BookPage> {
  final supabase = Supabase.instance.client;
  bool _isLoading = true;
  bool _isPaid = false;
  bool _isRefreshing = false;
  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _checkUserStatus();
    _setupRefreshTimer();
    _setupRealtimeSubscription();
  }

  void _setupRefreshTimer() {
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _refreshData();
    });
  }

  void _setupRealtimeSubscription() {
    supabase
        .channel('Book_auth_changes')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'auth',
          table: 'users',
          callback: (payload) {
            print("Auth changes detected in BookPage: ${payload.toString()}");
            _refreshData();
          },
        )
        .subscribe();

    supabase
        .channel('Book_profiles')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'profiles',
          callback: (payload) {
            print(
              "Profile changes detected in BookPage: ${payload.toString()}",
            );
            _refreshData();
          },
        )
        .subscribe();
  }

  Future<void> _refreshData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        if (mounted) {
          setState(() {
            _isRefreshing = false;
            _isPaid = false;
          });
        }
        return;
      }

      final userData =
          await supabase
              .from('profiles')
              .select('status')
              .eq('id', currentUser.id)
              .single();

      if (mounted) {
        setState(() {
          _isRefreshing = false;
          _isPaid = userData['status'] == 'Paid';
        });
      }
    } catch (error) {
      print('Refresh error: ${error.toString()}');
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _checkUserStatus() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final currentUser = supabase.auth.currentUser;
      if (currentUser == null) {
        setState(() {
          _isLoading = false;
          _isPaid = false;
        });
        return;
      }

      final userData =
          await supabase
              .from('profiles')
              .select('status')
              .eq('id', currentUser.id)
              .single();

      setState(() {
        _isLoading = false;
        _isPaid = userData['status'] == 'Paid';
      });
    } catch (error) {
      print('Error checking user status: ${error.toString()}');
      setState(() {
        _isLoading = false;
        _isPaid = false;
      });
    }
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF1F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(8),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  offset: const Offset(0, 4),
                  blurRadius: 4,
                ),
              ],
            ),
            padding: const EdgeInsets.all(8),
            child: const Icon(CupertinoIcons.back, color: Colors.black),
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: const Text(
          'Book Car Wash',
          style: TextStyle(
            color: Colors.black,
            fontFamily: 'Montserrat',
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child:
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _buildBookContent(),
      ),
    );
  }

  Widget _buildBookContent() {
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Feature Coming Soon!',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                fontFamily: 'Montserrat',
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Virtual Queuing System minimises your waiting time and eliminates your need to physically queue at the car wash. ',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontFamily: 'Montserrat',
              ),
            ),
            SizedBox(height: 180),
            Text(
              'Powered by',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
                fontFamily: 'Montserrat',
              ),
            ),
            Image(
              image: AssetImage('assets/icons/qp.png'),
              width: 150,
              height: 100,
            ),
          ],
        ),
      ),
    );
  }
}
