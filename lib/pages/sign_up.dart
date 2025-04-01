import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:fresh_car/pages/login.dart';
//import 'package:fresh_car/config/supabase_config.dart';

// Color option class to store color data
class ColorOption {
  final String name;
  final Color color;

  ColorOption(this.name, this.color);
}

// Custom Expandable Color Selection Grid Widget
class ExpandableColorSelectionGrid extends StatefulWidget {
  final List<ColorOption> colors;
  final String? selectedColor;
  final Function(String) onColorSelected;

  const ExpandableColorSelectionGrid({
    Key? key,
    required this.colors,
    required this.selectedColor,
    required this.onColorSelected,
  }) : super(key: key);

  @override
  State<ExpandableColorSelectionGrid> createState() =>
      _ExpandableColorSelectionGridState();
}

class _ExpandableColorSelectionGridState
    extends State<ExpandableColorSelectionGrid> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with expand/collapse functionality
          GestureDetector(
            onTap: () {
              setState(() {
                _isExpanded = !_isExpanded;
              });
            },
            child: Row(
              children: [
                const Icon(CupertinoIcons.color_filter, size: 20),
                const SizedBox(width: 8),
                Text(
                  'Car Color',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Colors.black.withOpacity(0.8),
                  ),
                ),
                const Spacer(),
                // If a color is selected, show a preview
                if (widget.selectedColor != null && !_isExpanded)
                  Row(
                    children: [
                      Text(
                        widget.selectedColor!,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        width: 20,
                        height: 20,
                        decoration: BoxDecoration(
                          color:
                              widget.colors
                                  .firstWhere(
                                    (c) => c.name == widget.selectedColor,
                                    orElse:
                                        () =>
                                            ColorOption('White', Colors.white),
                                  )
                                  .color,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.black.withOpacity(0.2),
                          ),
                        ),
                      ),
                    ],
                  ),
                const SizedBox(width: 4),
                Icon(
                  _isExpanded
                      ? CupertinoIcons.chevron_up
                      : CupertinoIcons.chevron_down,
                  size: 16,
                ),
              ],
            ),
          ),

          // Expanded content
          if (_isExpanded) ...[
            const SizedBox(height: 12),
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 4,
                childAspectRatio: 1,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
              ),
              itemCount: widget.colors.length,
              itemBuilder: (context, index) {
                final color = widget.colors[index];
                final isSelected = color.name == widget.selectedColor;

                return GestureDetector(
                  onTap: () {
                    widget.onColorSelected(color.name);
                    // Optionally close the grid after selection
                    // setState(() {
                    //   _isExpanded = false;
                    // });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    decoration: BoxDecoration(
                      color: color.color,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: isSelected ? Colors.black : Colors.transparent,
                        width: 2,
                      ),
                      boxShadow:
                          isSelected
                              ? [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.1),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ]
                              : null,
                    ),
                    child:
                        isSelected
                            ? Center(
                              child: Container(
                                padding: const EdgeInsets.all(2),
                                decoration: BoxDecoration(
                                  color: Colors.white.withOpacity(0.8),
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.check,
                                  size: 16,
                                  color: Colors.black,
                                ),
                              ),
                            )
                            : null,
                  ),
                );
              },
            ),
            if (widget.selectedColor != null)
              Padding(
                padding: const EdgeInsets.only(top: 12),
                child: Text(
                  'Selected: ${widget.selectedColor}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.black.withOpacity(0.6),
                  ),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralController = TextEditingController();
  final _carNameController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _isLoading = false;

  // Car details variables
  String? _selectedColor;
  String? _selectedCarwash;
  String? _selectedCarwashMapLink;

  // Color options with visual representation
  final List<ColorOption> _colorOptions = [
    ColorOption('White', Colors.white),
    ColorOption('Black', Colors.black),
    ColorOption('Gray', Colors.grey),
    ColorOption('Silver', Color(0xFFC0C0C0)),
    ColorOption('Red', Colors.red),
    ColorOption('Blue', Colors.blue),
    ColorOption('Green', Colors.green),
    ColorOption('Yellow', Colors.yellow),
    ColorOption('Orange', Colors.orange),
    ColorOption('Purple', Colors.purple),
    ColorOption('Brown', Colors.brown),
    ColorOption('Gold', Color(0xFFFFD700)),
  ];

  // List to store carwash data
  List<Map<String, dynamic>> _carwashes = [];

  final supabase = Supabase.instance.client;

  @override
  void initState() {
    super.initState();
    _fetchCarwashes();
  }

  // Fetch carwashes from the database
  Future<void> _fetchCarwashes() async {
    try {
      final response = await supabase
          .from('carwash')
          .select('carwash_name, map_link');

      if (mounted) {
        setState(() {
          _carwashes = List<Map<String, dynamic>>.from(response);

          // If carwashes are available, set the first one as default
          if (_carwashes.isNotEmpty) {
            _selectedCarwash = _carwashes[0]['carwash_name'];
            _selectedCarwashMapLink = _carwashes[0]['map_link'];
          }
        });
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please check your internet connection'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralController.dispose();
    _carNameController.dispose();
    super.dispose();
  }

  // Handle sign up with all required validations
  void _handleSignUp() async {
    if (_formKey.currentState!.validate() && _selectedColor != null) {
      setState(() {
        _isLoading = true;
      });

      try {
        // First auth signup
        final AuthResponse res = await supabase.auth.signUp(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          data: {'username': _nameController.text.trim()},
          emailRedirectTo: null,
        );

        if (mounted && res.user != null) {
          try {
            // Then profiles insertion with specific error handling
            final profileResponse =
                await supabase.from('profiles').insert({
                  'id': res.user!.id,
                  'username': _nameController.text.trim(),
                  'email': _emailController.text.trim(),
                  'created_at': DateTime.now().toIso8601String(),
                  'password': _passwordController.text,
                  'status': 'Paid',
                  'car_name': _carNameController.text.trim(),
                  'car_color': _selectedColor,
                  'carwash_name': _selectedCarwash,
                  'map_link': _selectedCarwashMapLink,
                }).select();

            print('Profile insertion successful: $profileResponse');

            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Sign up successful! Please login to access your account',
                ),
                backgroundColor: Colors.green,
              ),
            );

            // Navigate to login page
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginPage()),
            );
          } catch (profileError) {
            print('Profile insertion error: $profileError');
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Please check your internet connection'),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
      } on AuthException catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(''), backgroundColor: Colors.red),
          );
          print('Auth Error: ${error.toString()}');
        }
      } catch (error) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Please check your internet connection'),
              backgroundColor: Colors.red,
            ),
          );
          print('Unexpected error: $error');
        }
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    } else if (_selectedColor == null) {
      // Add validation for color selection
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a car color'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFEFF1F3),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(CupertinoIcons.back, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Text(
                  'Create Account',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'Montserrat',
                  ),
                ),
                const SizedBox(height: 40),

                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          hintText: 'Username',
                          prefixIcon: const Icon(CupertinoIcons.person),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.black,
                              width: 1,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your username';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          hintText: 'Email',
                          prefixIcon: const Icon(CupertinoIcons.mail),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.black,
                              width: 1,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!value.contains('@') || !value.contains('.')) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: !_isPasswordVisible,
                        decoration: InputDecoration(
                          hintText: 'Password',
                          prefixIcon: const Icon(CupertinoIcons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isPasswordVisible
                                  ? CupertinoIcons.eye_slash
                                  : CupertinoIcons.eye,
                            ),
                            onPressed: () {
                              setState(() {
                                _isPasswordVisible = !_isPasswordVisible;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.black,
                              width: 1,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter a password';
                          }
                          if (value.length < 6) {
                            return 'Password must be at least 6 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: !_isConfirmPasswordVisible,
                        decoration: InputDecoration(
                          hintText: 'Confirm Password',
                          prefixIcon: const Icon(CupertinoIcons.lock),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _isConfirmPasswordVisible
                                  ? CupertinoIcons.eye_slash
                                  : CupertinoIcons.eye,
                            ),
                            onPressed: () {
                              setState(() {
                                _isConfirmPasswordVisible =
                                    !_isConfirmPasswordVisible;
                              });
                            },
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.black,
                              width: 1,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please confirm your password';
                          }
                          if (value != _passwordController.text) {
                            return 'Passwords do not match';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Car Name Field
                      TextFormField(
                        controller: _carNameController,
                        decoration: InputDecoration(
                          hintText: 'Car Name (e.g., VW Polo)',
                          prefixIcon: const Icon(CupertinoIcons.car),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide.none,
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Colors.black,
                              width: 1,
                            ),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your car name';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Enhanced Color Selection Grid
                      // Expandable Color Selection Grid
                      ExpandableColorSelectionGrid(
                        colors: _colorOptions,
                        selectedColor: _selectedColor,
                        onColorSelected: (color) {
                          setState(() {
                            _selectedColor = color;
                          });
                        },
                      ),
                      const SizedBox(height: 16),

                      // Carwash Name Dropdown
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: DropdownButtonFormField<String>(
                          decoration: const InputDecoration(
                            prefixIcon: Icon(CupertinoIcons.location),
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                          ),
                          hint: const Text('Select Carwash'),
                          value: _selectedCarwash,
                          isExpanded: true,
                          icon: const Icon(Icons.arrow_drop_down),
                          items:
                              _carwashes.map<DropdownMenuItem<String>>((
                                Map<String, dynamic> carwash,
                              ) {
                                return DropdownMenuItem<String>(
                                  value: carwash['carwash_name'],
                                  child: Text(carwash['carwash_name']),
                                );
                              }).toList(),
                          onChanged: (String? newValue) {
                            setState(() {
                              _selectedCarwash = newValue;
                              // Find the map_link that corresponds to the selected carwash
                              final selectedCarwashData = _carwashes.firstWhere(
                                (carwash) =>
                                    carwash['carwash_name'] == newValue,
                                orElse: () => {'map_link': ''},
                              );
                              _selectedCarwashMapLink =
                                  selectedCarwashData['map_link'];
                            });
                          },
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please select a carwash';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 32),

                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSignUp,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child:
                              _isLoading
                                  ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      fontFamily: 'Montserrat',
                                    ),
                                  ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Text(
                      "Already have an account? ",
                      style: TextStyle(
                        color: Colors.black54,
                        fontFamily: 'Montserrat',
                      ),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      child: const Text(
                        'Login',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.bold,
                          fontFamily: 'Montserrat',
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
