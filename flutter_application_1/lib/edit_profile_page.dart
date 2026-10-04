import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class EditProfilePage extends StatefulWidget {
  @override
  _EditProfilePageState createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;

  final _nameController = TextEditingController();
  final _currentPasswordController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _isLoading = true;
  bool _isSaving = false;
  bool _showPasswordFields = false;
  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;

  // Password validation states
  bool _hasMinLength = false;
  bool _hasUppercase = false;
  bool _hasLowercase = false;
  bool _hasDigit = false;
  bool _hasSpecialChar = false;

  @override
  void initState() {
    super.initState();
    _loadUserData();
    _newPasswordController.addListener(_validatePassword);
  }

  void _validatePassword() {
    final password = _newPasswordController.text;
    setState(() {
      _hasMinLength = password.length >= 8;
      _hasUppercase = password.contains(RegExp(r'[A-Z]'));
      _hasLowercase = password.contains(RegExp(r'[a-z]'));
      _hasDigit = password.contains(RegExp(r'[0-9]'));
      _hasSpecialChar = password.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));
    });
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        final doc = await _firestore.collection('users').doc(user.uid).get();
        if (doc.exists && mounted) {
          setState(() {
            _nameController.text = doc.data()?['name'] ?? '';
            _isLoading = false;
          });
        }
      }
    } catch (e) {
      print('Error loading user data: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final user = _auth.currentUser;
      if (user == null) {
        _showError('User not found');
        return;
      }

      // Update name in Firestore
      await _firestore.collection('users').doc(user.uid).update({
        'name': _nameController.text.trim(),
      });

      // Update password if provided
      if (_showPasswordFields && _newPasswordController.text.isNotEmpty) {
        // Re-authenticate user before changing password
        final credential = EmailAuthProvider.credential(
          email: user.email!,
          password: _currentPasswordController.text,
        );

        await user.reauthenticateWithCredential(credential);
        await user.updatePassword(_newPasswordController.text);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Text('Profile updated successfully!'),
              ],
            ),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        Navigator.pop(context, true);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage = 'Failed to update profile';
      if (e.code == 'wrong-password') {
        errorMessage = 'Current password is incorrect';
      } else if (e.code == 'weak-password') {
        errorMessage = 'New password is too weak';
      } else if (e.code == 'requires-recent-login') {
        errorMessage = 'Please log out and log in again to change password';
      }
      _showError(errorMessage);
    } catch (e) {
      print('Error saving changes: $e');
      _showError('Failed to update profile');
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildPasswordRequirement(String text, bool isMet) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(
            isMet ? Icons.check_circle : Icons.cancel,
            color: isMet ? Colors.green : Colors.red,
            size: 20,
          ),
          SizedBox(width: 12),
          Text(text, style: TextStyle(fontSize: 14, color: Colors.grey[700])),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _currentPasswordController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(color: Colors.white),
        child: SafeArea(
          child: Column(
            children: [
              // Header with orange theme
              Container(
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFFFF6B35),
                  boxShadow: [
                    BoxShadow(
                      color: Color(0xFFFF6B35).withOpacity(0.3),
                      blurRadius: 15,
                      offset: Offset(0, 5),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Text(
                      'Edit Profile',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        letterSpacing: 1,
                      ),
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: _isLoading
                    ? Center(
                        child: CircularProgressIndicator(
                          color: Color(0xFFFF6B35),
                        ),
                      )
                    : SingleChildScrollView(
                        padding: EdgeInsets.all(25),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 20),

                              // Name Field
                              Text(
                                'Full Name',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.black,
                                ),
                              ),
                              SizedBox(height: 10),
                              TextFormField(
                                controller: _nameController,
                                decoration: InputDecoration(
                                  hintText: 'Enter your name',
                                  prefixIcon: Icon(
                                    Icons.person,
                                    color: Color(0xFFFF6B35),
                                  ),
                                  filled: true,
                                  fillColor: Colors.grey[50],
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide.none,
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(15),
                                    borderSide: BorderSide(
                                      color: Color(0xFFFF6B35),
                                      width: 2,
                                    ),
                                  ),
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your name';
                                  }
                                  return null;
                                },
                              ),

                              SizedBox(height: 30),

                              // Change Password Toggle
                              InkWell(
                                onTap: () {
                                  setState(() {
                                    _showPasswordFields = !_showPasswordFields;
                                  });
                                },
                                child: Container(
                                  padding: EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: Colors.grey[50],
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                      width: 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.lock,
                                        color: Color(0xFFFF6B35),
                                      ),
                                      SizedBox(width: 15),
                                      Expanded(
                                        child: Text(
                                          'Change Password',
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Icon(
                                        _showPasswordFields
                                            ? Icons.expand_less
                                            : Icons.expand_more,
                                        color: Colors.grey[600],
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              // Password Fields
                              if (_showPasswordFields) ...[
                                SizedBox(height: 20),

                                // Current Password
                                Text(
                                  'Current Password',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextFormField(
                                  controller: _currentPasswordController,
                                  obscureText: _obscureCurrentPassword,
                                  decoration: InputDecoration(
                                    hintText: 'Enter current password',
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color: Color(0xFFFF6B35),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureCurrentPassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Color(0xFFFF6B35),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureCurrentPassword =
                                              !_obscureCurrentPassword;
                                        });
                                      },
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide(
                                        color: Color(0xFFFF6B35),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (_showPasswordFields &&
                                        (value == null || value.isEmpty)) {
                                      return 'Please enter current password';
                                    }
                                    return null;
                                  },
                                ),

                                SizedBox(height: 15),

                                // New Password
                                Text(
                                  'New Password',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextFormField(
                                  controller: _newPasswordController,
                                  obscureText: _obscureNewPassword,
                                  decoration: InputDecoration(
                                    hintText: 'Enter new password',
                                    prefixIcon: Icon(
                                      Icons.lock,
                                      color: Color(0xFFFF6B35),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureNewPassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Color(0xFFFF6B35),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureNewPassword =
                                              !_obscureNewPassword;
                                        });
                                      },
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide(
                                        color: Color(0xFFFF6B35),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (_showPasswordFields &&
                                        (value == null || value.isEmpty)) {
                                      return 'Please enter new password';
                                    }
                                    if (_showPasswordFields &&
                                        (!_hasMinLength ||
                                            !_hasUppercase ||
                                            !_hasLowercase ||
                                            !_hasDigit ||
                                            !_hasSpecialChar)) {
                                      return 'Password does not meet requirements';
                                    }
                                    return null;
                                  },
                                ),

                                SizedBox(height: 12),

                                // Password Requirements
                                Container(
                                  padding: EdgeInsets.all(15),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(15),
                                    border: Border.all(
                                      color: Colors.grey[200]!,
                                      width: 1,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.grey.withOpacity(0.1),
                                        blurRadius: 10,
                                        offset: Offset(0, 5),
                                      ),
                                    ],
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Password must contain:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          color: Colors.black,
                                          fontSize: 14,
                                        ),
                                      ),
                                      SizedBox(height: 8),
                                      _buildPasswordRequirement(
                                        'At least 8 characters',
                                        _hasMinLength,
                                      ),
                                      _buildPasswordRequirement(
                                        'One uppercase letter (A-Z)',
                                        _hasUppercase,
                                      ),
                                      _buildPasswordRequirement(
                                        'One lowercase letter (a-z)',
                                        _hasLowercase,
                                      ),
                                      _buildPasswordRequirement(
                                        'One digit (0-9)',
                                        _hasDigit,
                                      ),
                                      _buildPasswordRequirement(
                                        'One special character (!@#\$%^&*)',
                                        _hasSpecialChar,
                                      ),
                                    ],
                                  ),
                                ),

                                SizedBox(height: 15),

                                // Confirm Password
                                Text(
                                  'Confirm New Password',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(height: 8),
                                TextFormField(
                                  controller: _confirmPasswordController,
                                  obscureText: _obscureConfirmPassword,
                                  decoration: InputDecoration(
                                    hintText: 'Confirm new password',
                                    prefixIcon: Icon(
                                      Icons.lock_outline,
                                      color: Color(0xFFFF6B35),
                                    ),
                                    suffixIcon: IconButton(
                                      icon: Icon(
                                        _obscureConfirmPassword
                                            ? Icons.visibility_off
                                            : Icons.visibility,
                                        color: Color(0xFFFF6B35),
                                      ),
                                      onPressed: () {
                                        setState(() {
                                          _obscureConfirmPassword =
                                              !_obscureConfirmPassword;
                                        });
                                      },
                                    ),
                                    filled: true,
                                    fillColor: Colors.grey[50],
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide.none,
                                    ),
                                    focusedBorder: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(15),
                                      borderSide: BorderSide(
                                        color: Color(0xFFFF6B35),
                                        width: 2,
                                      ),
                                    ),
                                  ),
                                  validator: (value) {
                                    if (_showPasswordFields &&
                                        value != _newPasswordController.text) {
                                      return 'Passwords do not match';
                                    }
                                    return null;
                                  },
                                ),
                              ],

                              SizedBox(height: 40),

                              // Save Button with orange theme
                              Container(
                                width: double.infinity,
                                height: 55,
                                decoration: BoxDecoration(
                                  color: Color(0xFFFF6B35),
                                  borderRadius: BorderRadius.circular(15),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Color(0xFFFF6B35).withOpacity(0.4),
                                      blurRadius: 15,
                                      offset: Offset(0, 8),
                                    ),
                                  ],
                                ),
                                child: ElevatedButton(
                                  onPressed: _isSaving ? null : _saveChanges,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.transparent,
                                    foregroundColor: Colors.white,
                                    shadowColor: Colors.transparent,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                  child: _isSaving
                                      ? SizedBox(
                                          height: 20,
                                          width: 20,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : Text(
                                          'Save Changes',
                                          style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold,
                                            letterSpacing: 1.5,
                                          ),
                                        ),
                                ),
                              ),

                              SizedBox(height: 20),

                              // Info Box with orange theme
                              Container(
                                padding: EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(15),
                                  border: Border.all(
                                    color: Color(0xFFFF6B35).withOpacity(0.3),
                                    width: 1,
                                  ),
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.grey.withOpacity(0.1),
                                      blurRadius: 10,
                                      offset: Offset(0, 5),
                                    ),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Color(0xFFFF6B35),
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Your changes will be saved to your account and synced across all devices.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Colors.grey[700],
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
