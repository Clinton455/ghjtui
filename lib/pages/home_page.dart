import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:async';
import 'dart:math';
import 'login.dart';
import 'package:shared_preferences/shared_preferences.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _supabase = Supabase.instance.client;

  String staffName = 'Staff';
  String carwashName = 'Car Wash';
  bool _isScanning = false;
  bool _isProcessing = false;
  String _scannedCode = '';
  Map<String, dynamic>? _customerData;
  final MobileScannerController _scannerController = MobileScannerController();
  Timer? _refreshTimer;
  Timer? _hideCustomerCardTimer;
  bool _isRefreshing = false;

  // Safety feature variables
  bool _isWashAddingLocked = false;
  String _lastProcessedCustomerId = '';
  DateTime? _lockUntilTime;

  // List of possible wait times in minutes
  final List<int> _waitTimeOptions = [1, 2];

  @override
  void initState() {
    super.initState();
    _loadStaffData();
    _setupRefreshTimer();
    _checkWashAddingLock();
  }

  @override
  void dispose() {
    _scannerController.dispose();
    _refreshTimer?.cancel();
    _hideCustomerCardTimer?.cancel();
    super.dispose();
  }

  Future<void> _recordWashLog(bool isFreeWashRedemption) async {
    if (_customerData == null) return;

    // Don't record wash logs if customer is not from the same car wash
    if (_customerData!['carwash_name'] != carwashName) {
      print('Skipping wash log - customer from different car wash');
      return;
    }

    try {
      await _supabase.from('wash_logs').insert({
        'staff_username': staffName,
        'customer_unique_code': _customerData!['unique_code'],
        'carwash_name': carwashName,
        'current_wash': _customerData!['current_washes'],
        'required_wash': _customerData!['required_washes'],
        'is_free_wash_redemption': isFreeWashRedemption,
      });
    } catch (error) {
      // Silently handle errors - we don't want to disrupt the main flow if logging fails
      print('Failed to record wash log: $error');
    }
  }

  // Load the lock status when app starts
  Future<void> _checkWashAddingLock() async {
    final prefs = await SharedPreferences.getInstance();
    final lockUntilTimeStamp = prefs.getInt('wash_lock_until');
    final lastProcessedId = prefs.getString('last_processed_customer_id') ?? '';

    if (lockUntilTimeStamp != null) {
      final lockUntil = DateTime.fromMillisecondsSinceEpoch(lockUntilTimeStamp);

      if (lockUntil.isAfter(DateTime.now())) {
        // Lock is still active
        if (mounted) {
          setState(() {
            _isWashAddingLocked = true;
            _lockUntilTime = lockUntil;
            _lastProcessedCustomerId = lastProcessedId;
          });
        }

        // Setup a timer to unlock when the time expires
        final remainingTime = lockUntil.difference(DateTime.now());
        Timer(remainingTime, () {
          if (mounted) {
            setState(() {
              _isWashAddingLocked = false;
              _lockUntilTime = null;
            });
          }
        });
      } else {
        // Lock has expired, clear it
        await prefs.remove('wash_lock_until');
        await prefs.remove('last_processed_customer_id');
      }
    }
  }

  // Set a new lock after processing a wash
  Future<void> _setWashAddingLock(String customerId) async {
    // Get random wait time from options
    final random = Random();
    final waitMinutes =
        _waitTimeOptions[random.nextInt(_waitTimeOptions.length)];

    // Calculate unlock time
    final now = DateTime.now();
    final unlockTime = now.add(Duration(minutes: waitMinutes));

    // Save to shared preferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('wash_lock_until', unlockTime.millisecondsSinceEpoch);
    await prefs.setString('last_processed_customer_id', customerId);

    if (mounted) {
      setState(() {
        _isWashAddingLocked = true;
        _lockUntilTime = unlockTime;
        _lastProcessedCustomerId = customerId;
      });
    }

    // Setup a timer to automatically unlock
    Timer(Duration(minutes: waitMinutes), () {
      if (mounted) {
        setState(() {
          _isWashAddingLocked = false;
          _lockUntilTime = null;
        });
      }
    });
  }

  void _setupRefreshTimer() {
    // Refresh every 2 seconds
    _refreshTimer = Timer.periodic(const Duration(seconds: 2), (timer) {
      _refreshData();
    });
  }

  Future<void> _refreshData() async {
    // Refresh both staff data and customer data if available
    await _refreshStaffData();
    if (_scannedCode.isNotEmpty) {
      await _refreshCustomerData();
    }
  }

  Future<void> _loadStaffData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('last_username');

      if (username == null) {
        throw Exception('No username found');
      }

      final response =
          await _supabase
              .from('staff_profiles')
              .select('username, carwash_name')
              .eq('username', username)
              .single();

      if (mounted) {
        setState(() {
          staffName = response['username'] ?? 'Staff';
          carwashName = response['carwash_name'] ?? 'Car Wash';
        });
      }
    } catch (error) {
      // existing error handling
    }
  }

  Future<void> _refreshStaffData() async {
    if (_isRefreshing) return;

    setState(() {
      _isRefreshing = true;
    });

    try {
      final prefs = await SharedPreferences.getInstance();
      final username = prefs.getString('last_username');

      if (username == null) {
        throw Exception('No username found');
      }

      final response =
          await _supabase
              .from('staff_profiles')
              .select('username, carwash_name')
              .eq('username', username)
              .single();

      if (mounted) {
        setState(() {
          staffName = response['username'] ?? 'Staff';
          carwashName = response['carwash_name'] ?? 'Car Wash';
        });
      }
    } catch (error) {
      // Optional: Add error handling or logging
    } finally {
      if (mounted) {
        setState(() {
          _isRefreshing = false;
        });
      }
    }
  }

  Future<void> _refreshCustomerData() async {
    if (_scannedCode.isEmpty || _isProcessing) return;

    try {
      // Fetch latest customer data based on the scanned code
      final response =
          await _supabase
              .from('profiles')
              .select(
                'id, username, current_washes, required_washes, unique_code, created_at, car_name, car_color, carwash_name',
              )
              .eq('unique_code', _scannedCode)
              .single();

      // Verify that customer still belongs to the same carwash
      if (response['carwash_name'] != carwashName) {
        if (mounted) {
          setState(() {
            _customerData = null;
            _scannedCode = '';
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'This customer belongs to a different car wash location',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        return;
      }

      if (mounted) {
        setState(() {
          _customerData = response;
        });
      }
    } catch (error) {
      // Silently handle errors during refresh
    }
  }

  Future<void> _handleLogout() async {
    await _supabase.auth.signOut();
    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => const LoginPage()),
      );
    }
  }

  Future<void> _processCustomerCode(String code) async {
    if (_isProcessing) return;

    // Cancel any existing hide timer when processing a new code
    _hideCustomerCardTimer?.cancel();

    setState(() {
      _isProcessing = true;
      _scannedCode = code;
    });

    try {
      // Fetch customer data based on unique code
      final response =
          await _supabase
              .from('profiles')
              .select(
                'id, username, current_washes, required_washes, unique_code, created_at, car_name, car_color, carwash_name',
              )
              .eq('unique_code', code)
              .single();

      // Check if customer belongs to the same carwash as staff
      if (response['carwash_name'] != carwashName) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'This customer belongs to a different car wash location',
              ),
              backgroundColor: Colors.orange,
            ),
          );
        }
        setState(() {
          _isProcessing = false;
          _customerData = null;
          _scannedCode = '';
        });
        return;
      }

      setState(() {
        _customerData = response;
        _isProcessing = false;
      });

      // Check if this customer was the last one processed and if system is locked
      if (_isWashAddingLocked && _lastProcessedCustomerId == response['id']) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'You have recently added the wash. Please try again later',
              ),
              backgroundColor: Colors.orange,
              duration: Duration(seconds: 3),
            ),
          );
        }
      }
    } catch (error) {
      setState(() {
        _isProcessing = false;
        _customerData = null;
        _scannedCode = ''; // Clear the scanned code on error
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Customer not found, check your internet or contact the Manager',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _incrementCustomerWash() async {
    if (_customerData == null || _isProcessing) return;

    // Check if system is locked for this customer
    if (_isWashAddingLocked &&
        _lastProcessedCustomerId == _customerData!['id']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please try again tomorrow. System maintenance in progress.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final currentWashes = _customerData!['current_washes'] as int;
      final requiredWashes = _customerData!['required_washes'] as int;

      // Check if customer has earned a free wash
      if (currentWashes >= requiredWashes) {
        // Reset wash count after using free wash
        await _supabase
            .from('profiles')
            .update({'current_washes': 1})
            .eq('id', _customerData!['id']);

        // Log the free wash redemption
        await _recordWashLog(true);

        // Update local state immediately
        if (mounted) {
          setState(() {
            _customerData = {..._customerData!, 'current_washes': 1};
          });

          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Free wash redeemed!'),
              backgroundColor: Colors.green,
            ),
          );

          // Set timer to hide customer card after 5 seconds
          _hideCustomerCardTimer?.cancel();
          _hideCustomerCardTimer = Timer(
            const Duration(seconds: 5),
            _clearCustomerCard,
          );
        }
      } else {
        // Increment wash count
        final newWashCount = currentWashes + 1;
        await _supabase
            .from('profiles')
            .update({'current_washes': newWashCount})
            .eq('id', _customerData!['id']);

        // Update customer data for the log
        _customerData = {..._customerData!, 'current_washes': newWashCount};

        // Log the regular wash addition
        await _recordWashLog(false);

        // Update local state immediately
        if (mounted) {
          setState(() {
            // already updated _customerData above
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Wash count updated to $newWashCount/$requiredWashes',
              ),
              backgroundColor: Colors.green,
            ),
          );

          // Set timer to hide customer card after 5 seconds
          _hideCustomerCardTimer?.cancel();
          _hideCustomerCardTimer = Timer(
            const Duration(seconds: 5),
            _clearCustomerCard,
          );
        }
      }

      // Set the wash adding lock after successful update
      await _setWashAddingLock(_customerData!['id']);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to update wash count, check your internet or contact the Manager',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Always refresh from database to ensure data consistency
      await _refreshCustomerData();

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  Future<void> _useCustomerFreeWash() async {
    if (_customerData == null || _isProcessing) return;

    // Check if system is locked for this customer
    if (_isWashAddingLocked &&
        _lastProcessedCustomerId == _customerData!['id']) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Please try again tomorrow. System maintenance in progress.',
            ),
            backgroundColor: Colors.orange,
            duration: Duration(seconds: 3),
          ),
        );
      }
      return;
    }

    final currentWashes = _customerData!['current_washes'] as int;
    final requiredWashes = _customerData!['required_washes'] as int;

    if (currentWashes < requiredWashes) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer has not earned a free wash yet'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      // Reset wash count after using free wash
      await _supabase
          .from('profiles')
          .update({'current_washes': 0})
          .eq('id', _customerData!['id']);

      // Update customer data for the log
      _customerData = {..._customerData!, 'current_washes': 0};

      // Log the free wash redemption
      await _recordWashLog(true);

      // Update local state immediately
      if (mounted) {
        setState(() {
          // already updated _customerData above
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Free wash redeemed! Count reset to 0'),
            backgroundColor: Colors.green,
          ),
        );

        // Set timer to hide customer card after 5 seconds
        _hideCustomerCardTimer?.cancel();
        _hideCustomerCardTimer = Timer(
          const Duration(seconds: 5),
          _clearCustomerCard,
        );
      }

      // Set the wash adding lock after successful update
      await _setWashAddingLock(_customerData!['id']);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to redeem free wash, check your internet or contact the Manager',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      // Always refresh from database to ensure data consistency
      await _refreshCustomerData();

      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _toggleScanner() {
    setState(() {
      _isScanning = !_isScanning;
      if (!_isScanning) {
        _customerData = null;
        _scannedCode = '';
        _scannerController.stop();
      } else {
        _scannerController.start();
      }
    });

    // Cancel any existing hide timer when toggling scanner
    _hideCustomerCardTimer?.cancel();
  }

  void _manualCodeEntry() {
    // Cancel any existing hide timer when starting manual entry
    _hideCustomerCardTimer?.cancel();

    TextEditingController codeController = TextEditingController();

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: const Text('Enter Customer Code'),
            content: TextField(
              controller: codeController,
              decoration: const InputDecoration(
                hintText: 'Enter the customer\'s unique code',
                border: OutlineInputBorder(),
              ),
              autofocus: true,
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () {
                  if (codeController.text.isNotEmpty) {
                    Navigator.pop(context);
                    _processCustomerCode(codeController.text);
                  }
                },
                child: const Text('Submit'),
              ),
            ],
          ),
    );
  }

  Widget _buildScanner() {
    return Container(
      height: 300,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade300, width: 2),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: MobileScanner(
          controller: _scannerController,
          onDetect: (capture) {
            final List<Barcode> barcodes = capture.barcodes;
            if (barcodes.isNotEmpty && mounted) {
              final Barcode barcode = barcodes.first;
              if (barcode.rawValue != null) {
                // Don't stop the scanner here, just process the code
                _processCustomerCode(barcode.rawValue!);

                // We'll temporarily pause scanning while processing
                setState(() {
                  _isScanning = false;
                });
                _scannerController.stop();

                // Add a timer to restart scanning after processing is complete
                Timer(const Duration(seconds: 7), () {
                  if (mounted && _customerData == null) {
                    setState(() {
                      _isScanning = true;
                    });
                    _scannerController.start();
                  }
                });
              }
            }
          },
        ),
      ),
    );
  }

  // Add this new method to clear data and restart scanning
  void _clearAndRestartScanner() {
    setState(() {
      _customerData = null;
      _scannedCode = '';
      _isScanning = true;
    });
    _scannerController.start();
  }

  // Modify _clearCustomerCard to restart scanning when appropriate
  void _clearCustomerCard() {
    if (mounted) {
      setState(() {
        _customerData = null;
        _scannedCode = '';

        // Restart scanning if we were in scanning mode
        if (_isScanning) {
          _scannerController.start();
        }
      });
    }
  }

  Widget _buildCustomerCard() {
    if (_customerData == null) return const SizedBox.shrink();

    final currentWashes = _customerData!['current_washes'] as int;
    final requiredWashes = _customerData!['required_washes'] as int;
    final username = _customerData!['username'] as String;
    final hasFreeWash = currentWashes >= requiredWashes;

    // Check if this customer is locked
    final isCustomerLocked =
        _isWashAddingLocked && _lastProcessedCustomerId == _customerData!['id'];

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              const Icon(CupertinoIcons.person_circle_fill, size: 40),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      username,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Code: ${_customerData!['unique_code']}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    Text(
                      'Car: ${_customerData!['car_name'] ?? 'Not specified'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    Text(
                      'Color: ${_customerData!['car_color'] ?? 'Not specified'}',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Wash Progress',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    Text(
                      '$currentWashes/$requiredWashes',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: hasFreeWash ? Colors.green : Colors.black,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: currentWashes / requiredWashes,
                    minHeight: 10,
                    backgroundColor: Colors.grey.shade200,
                    color: hasFreeWash ? Colors.green : const Color(0xFF36F4B5),
                  ),
                ),
                if (hasFreeWash)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green.shade200),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.gift_fill,
                          color: Colors.green,
                          size: 16,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Free Wash Available!',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ],
                    ),
                  ),

                // Show system maintenance message if this customer is locked
                if (isCustomerLocked)
                  Container(
                    margin: const EdgeInsets.only(top: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          CupertinoIcons.exclamationmark_triangle,
                          color: Colors.orange,
                          size: 16,
                        ),
                        SizedBox(width: 5),
                        Text(
                          'Recently added wash',
                          style: TextStyle(
                            color: Colors.orange,
                            fontWeight: FontWeight.bold,
                            fontFamily: 'Montserrat',
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      _isProcessing || hasFreeWash || isCustomerLocked
                          ? null
                          : _incrementCustomerWash,
                  icon: const Icon(CupertinoIcons.add_circled_solid),
                  label: const Text('Add Wash'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF36F4B5),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                ),
              ),

              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed:
                      _isProcessing || !hasFreeWash || isCustomerLocked
                          ? null
                          : _useCustomerFreeWash,
                  icon: const Icon(CupertinoIcons.gift_fill),
                  label: const Text('Redeem Free'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    disabledBackgroundColor: Colors.grey.shade300,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFEFF1F3),
      appBar: AppBar(
        title: Text(
          carwashName,
          style: const TextStyle(
            fontFamily: 'Montserrat',
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          if (_isRefreshing)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  color: Color(0xFF36F4B5),
                  strokeWidth: 2,
                ),
              ),
            ),
          IconButton(
            icon: const Icon(CupertinoIcons.square_arrow_left),
            onPressed: _handleLogout,
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 10,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Text(
                      'Welcome, $staffName',
                      style: const TextStyle(
                        fontSize: 20,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Scan customer code or enter manually',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.black54,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: ElevatedButton.icon(
                            onPressed: _toggleScanner,
                            icon: Icon(
                              _isScanning
                                  ? CupertinoIcons.stop_fill
                                  : CupertinoIcons.qrcode_viewfinder,
                            ),
                            label: Text(
                              _isScanning ? 'Stop' : 'Scan QR Code',
                              style: const TextStyle(fontSize: 14),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  _isScanning
                                      ? Colors.red.shade100
                                      : const Color(0xFF36F4B5),
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 1,
                          child: ElevatedButton.icon(
                            onPressed: _manualCodeEntry,
                            icon: const Icon(CupertinoIcons.keyboard),
                            label: const Text(
                              'Manual',
                              style: TextStyle(fontSize: 14),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.grey.shade200,
                              foregroundColor: Colors.black,
                              padding: const EdgeInsets.symmetric(
                                vertical: 12,
                                horizontal: 8,
                              ),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_isScanning)
                Column(children: [const SizedBox(height: 20), _buildScanner()]),
              if (!_isScanning && _customerData != null) _buildCustomerCard(),
              if (_isProcessing)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(color: Color(0xFF36F4B5)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
