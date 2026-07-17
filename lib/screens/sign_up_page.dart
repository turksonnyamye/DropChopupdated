import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'sign_in_page.dart'; // Import your SignInPage file

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  // Text controllers to capture user input
  final TextEditingController _firstNameController = TextEditingController();
  final TextEditingController _lastNameController = TextEditingController();
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  
  bool _agreeToTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  // Design Constants
  static const Color brandGreen = Color(0xFF32BB78); 
  static const Color textDark = Colors.black;
  static const Color textLight = Colors.white;
  static const Color inputBackground = Color(0xFFF5F5F5);

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _handleSignUp() async {
    final String firstName = _firstNameController.text.trim();
    final String lastName = _lastNameController.text.trim();
    final String email = _emailController.text.trim();
    final String password = _passwordController.text.trim();
    final String confirmPassword = _confirmPasswordController.text.trim();

    // 1. Validation: Check if any fields are left blank
    if (firstName.isEmpty || lastName.isEmpty || email.isEmpty || password.isEmpty || confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill out all fields'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // 2. Validation: Check if password inputs match
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Passwords do not match'),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    // 3. Validation: Verify terms agreement box is checked
    if (!_agreeToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must agree to the Terms & Privacy Policy to proceed'),
          backgroundColor: Colors.orangeAccent,
        ),
      );
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // 4. Create a user in Firebase Auth
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      // 5. Save profile data locally (Leaving 'isLoggedIn' false so they must log in on the Sign In page)
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      await prefs.setBool('isLoggedIn', false); 
      await prefs.setString('userName', '$firstName $lastName');
      await prefs.setString('userEmail', email);
      
      if (mounted) {
        // Display success confirmation message
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Account created successfully! Please sign in.'),
            backgroundColor: brandGreen,
          ),
        );

        // 6. REDIRECT: Send the user straight to the Sign In page and clear the navigation stack
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => const SignInPage()),
          (Route<dynamic> route) => false, // This removes all previous screens (like this register screen) from history
        );
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'An error occurred. Please try again.';
      if (e.code == 'weak-password') {
        errorMessage = 'The password provided is too weak.';
      } else if (e.code == 'email-already-in-use') {
        errorMessage = 'The account already exists for that email.';
      } else if (e.code == 'invalid-email') {
        errorMessage = 'Please enter a valid email address.';
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.redAccent),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.redAccent),
        );
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
    final double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // 1. Hero Food Image (Top 35% of Screen)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.35,
            child: Image.asset(
              'images/fried_rice.png',
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      colors: [brandGreen, Color(0xFF1F7A4D)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Icon(Icons.restaurant_rounded, color: Colors.white70, size: 60),
                  ),
                );
              },
            ),
          ),
          
          // Header Contrast Overlay
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.35,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.black.withOpacity(0.4), Colors.transparent],
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                ),
              ),
            ),
          ),

          // 2. Main Scrollable Container
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              child: Column(
                children: [
                  SizedBox(height: screenHeight * 0.28),
                  
                  // Input Fields White Card
                  Container(
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(32),
                        topRight: Radius.circular(32),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black12,
                          blurRadius: 15,
                          offset: Offset(0, -5),
                        )
                      ]
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Create Account',
                          style: GoogleFonts.inter(
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: textDark,
                            letterSpacing: -1.0,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Register now to access local food delivery or manage stores.',
                          style: GoogleFonts.inter(
                            fontSize: 15,
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),
                        const SizedBox(height: 24),
                        
                        // Row for First Name and Last Name
                        Row(
                          children: [
                            Expanded(
                              child: TextField(
                                controller: _firstNameController,
                                enabled: !_isLoading,
                                decoration: InputDecoration(
                                  hintText: 'First Name',
                                  hintStyle: GoogleFonts.inter(color: Colors.grey.shade500),
                                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 22, color: Colors.grey),
                                  fillColor: inputBackground,
                                  filled: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: TextField(
                                controller: _lastNameController,
                                enabled: !_isLoading,
                                decoration: InputDecoration(
                                  hintText: 'Last Name',
                                  hintStyle: GoogleFonts.inter(color: Colors.grey.shade500),
                                  prefixIcon: const Icon(Icons.person_outline_rounded, size: 22, color: Colors.grey),
                                  fillColor: inputBackground,
                                  filled: true,
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        
                        // Email Input Field
                        TextField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            hintText: 'Email Address',
                            hintStyle: GoogleFonts.inter(color: Colors.grey.shade500),
                            prefixIcon: const Icon(Icons.mail_outline_rounded, size: 22, color: Colors.grey),
                            fillColor: inputBackground,
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Password Input Field
                        TextField(
                          controller: _passwordController,
                          obscureText: _obscurePassword,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            hintText: 'Password',
                            hintStyle: GoogleFonts.inter(color: Colors.grey.shade500),
                            prefixIcon: const Icon(Icons.lock_outline_rounded, size: 22, color: Colors.grey),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 22, color: Colors.grey),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                            fillColor: inputBackground,
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 16),
                        
                        // Confirm Password Input Field
                        TextField(
                          controller: _confirmPasswordController,
                          obscureText: _obscureConfirmPassword,
                          enabled: !_isLoading,
                          decoration: InputDecoration(
                            hintText: 'Confirm Password',
                            hintStyle: GoogleFonts.inter(color: Colors.grey.shade500),
                            prefixIcon: const Icon(Icons.lock_reset_rounded, size: 22, color: Colors.grey),
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirmPassword ? Icons.visibility_off_outlined : Icons.visibility_outlined, size: 22, color: Colors.grey),
                              onPressed: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                            ),
                            fillColor: inputBackground,
                            filled: true,
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
                          ),
                        ),
                        const SizedBox(height: 18),
                        
                        // Agreement Checkbox
                        Row(
                          children: [
                            Checkbox(
                              value: _agreeToTerms,
                              activeColor: brandGreen,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4)),
                              onChanged: _isLoading ? null : (val) => setState(() => _agreeToTerms = val ?? false),
                            ),
                            Expanded(
                              child: Text(
                                'I agree to the Terms of Service & Privacy Policy',
                                style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: textDark.withOpacity(0.7)),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),
                        
                        // Submit Registration Button
                        SizedBox(
                          width: double.infinity,
                          child: TextButton(
                            onPressed: (_agreeToTerms && !_isLoading) ? _handleSignUp : null,
                            style: TextButton.styleFrom(
                              backgroundColor: brandGreen,
                              foregroundColor: textLight,
                              disabledBackgroundColor: brandGreen.withOpacity(0.4),
                              disabledForegroundColor: textLight.withOpacity(0.6),
                              padding: const EdgeInsets.symmetric(vertical: 18),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                            ),
                            child: _isLoading 
                              ? const SizedBox(
                                  height: 22,
                                  width: 22,
                                  child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                                )
                              : const Text('Sign Up', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          // 3. Interactive Transparent AppBar (Guaranteed to be clickable over background stack items)
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: AppBar(
              backgroundColor: Colors.transparent,
              elevation: 0,
              forceMaterialTransparency: true,
              leading: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        ],
      ),
    );
  }
}