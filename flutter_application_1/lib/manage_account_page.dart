import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'edit_profile_page.dart';
import 'login_page.dart';
import 'database_helper.dart';

class ManageAccountPage extends StatelessWidget {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _dbHelper = DatabaseHelper();

  Future<void> _deleteAccount(BuildContext context) async {
    // Show confirmation dialog
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          title: Row(
            children: [
              Icon(Icons.warning, color: Colors.red, size: 30),
              SizedBox(width: 10),
              Text('Delete Account?'),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'This action cannot be undone. All your data will be permanently deleted:',
                style: TextStyle(fontSize: 15),
              ),
              SizedBox(height: 15),
              _buildWarningItem('• Your profile and account'),
              _buildWarningItem('• All pets you\'ve added'),
              _buildWarningItem('• Your favorites list'),
              _buildWarningItem('• All associated data'),
              SizedBox(height: 15),
              Text(
                'Are you absolutely sure?',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: Text('Delete Forever'),
            ),
          ],
        );
      },
    );

    if (confirmed == true) {
      _performAccountDeletion(context);
    }
  }

  Future<void> _performAccountDeletion(BuildContext context) async {
    // Show loading dialog
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Center(
          child: Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(15),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(color: Colors.red),
                SizedBox(height: 20),
                Text('Deleting account...', style: TextStyle(fontSize: 16)),
              ],
            ),
          ),
        );
      },
    );

    try {
      final user = _auth.currentUser;
      if (user == null) {
        Navigator.pop(context); // Close loading dialog
        _showError(context, 'No user found');
        return;
      }

      // 1. Delete user's pets from SQLite
      final pets = await _dbHelper.getPetsByUserId(user.uid);
      for (var pet in pets) {
        await _dbHelper.deletePet(pet['id']);
      }

      // 2. Delete user's favorites from SQLite
      final favorites = await _dbHelper.getFavoritePets(user.uid);
      for (var favorite in favorites) {
        await _dbHelper.removeFromFavorites(user.uid, favorite['id']);
      }

      // 3. Delete user document from Firestore
      await _firestore.collection('users').doc(user.uid).delete();

      // 4. Delete Firebase Auth account
      await user.delete();

      // Close loading dialog
      Navigator.pop(context);

      // Show success message
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Account deleted successfully'),
          backgroundColor: Colors.green,
        ),
      );

      // Navigate to login page
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginPage()),
        (route) => false,
      );
    } on FirebaseAuthException catch (e) {
      Navigator.pop(context); // Close loading dialog

      if (e.code == 'requires-recent-login') {
        _showError(
          context,
          'For security, please log out and log in again before deleting your account.',
        );
      } else {
        _showError(context, 'Failed to delete account: ${e.message}');
      }
    } catch (e) {
      Navigator.pop(context); // Close loading dialog
      print('Error deleting account: $e');
      _showError(context, 'Failed to delete account. Please try again.');
    }
  }

  Widget _buildWarningItem(String text) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Text(text, style: TextStyle(fontSize: 14, color: Colors.red[700])),
    );
  }

  void _showError(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
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
                      'Manage Account',
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

              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.all(25),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 20),

                      // Edit Profile Button
                      _buildOptionCard(
                        context: context,
                        icon: Icons.edit,
                        title: 'Edit Profile',
                        subtitle: 'Update your name and password',
                        color: Color(0xFFFF6B35),
                        onTap: () async {
                          final result = await Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (context) => EditProfilePage(),
                            ),
                          );
                          if (result == true) {
                            // Profile updated, refresh if needed
                            Navigator.pop(context, true);
                          }
                        },
                      ),

                      SizedBox(height: 20),

                      // Delete Account Button
                      _buildOptionCard(
                        context: context,
                        icon: Icons.delete_forever,
                        title: 'Delete Account',
                        subtitle: 'Permanently delete your account and data',
                        color: Colors.red,
                        onTap: () => _deleteAccount(context),
                      ),

                      SizedBox(height: 30),

                      // Warning Info Card with orange theme
                      Container(
                        padding: EdgeInsets.all(20),
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
                              Icons.warning_amber,
                              color: Color(0xFFFF6B35),
                              size: 28,
                            ),
                            SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'Deleting your account is permanent and cannot be undone. Please make sure you want to proceed.',
                                style: TextStyle(
                                  fontSize: 14,
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
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(15),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(15),
          border: Border.all(color: Colors.grey[200]!, width: 1),
          boxShadow: [
            BoxShadow(
              color: color.withOpacity(0.2),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(15),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 30),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, color: Colors.grey[400], size: 18),
          ],
        ),
      ),
    );
  }
}
