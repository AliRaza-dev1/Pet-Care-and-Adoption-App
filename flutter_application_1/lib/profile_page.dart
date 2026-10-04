import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'manage_account_page.dart';
import 'favorites_page.dart';
import 'database_helper.dart';

class ProfilePage extends StatefulWidget {
  @override
  _ProfilePageState createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _dbHelper = DatabaseHelper();

  String _userName = 'User';
  String _userEmail = '';
  bool _isLoading = true;
  int _myPetsCount = 0;
  int _favoritesCount = 0;

  // Orange color matching login page
  final Color primaryOrange = Color(0xFFFF6B35);

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    try {
      final user = _auth.currentUser;
      if (user != null) {
        // Get user info from Firestore
        final doc = await _firestore.collection('users').doc(user.uid).get();

        // Get pets count
        final pets = await _dbHelper.getPetsByUserId(user.uid);

        // Get favorites count
        final favCount = await _dbHelper.getFavoritesCount(user.uid);

        if (mounted) {
          setState(() {
            _userName = doc.data()?['name'] ?? 'User';
            _userEmail = user.email ?? '';
            _myPetsCount = pets.length;
            _favoritesCount = favCount;
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

  // Refresh data when returning from other pages
  Future<void> _refreshData() async {
    await _loadUserData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        color: Colors.white,
        child: SafeArea(
          child: _isLoading
              ? Center(
                  child: CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(primaryOrange),
                  ),
                )
              : Column(
                  children: [
                    // Header
                    Container(
                      color: Colors.white,
                      padding: EdgeInsets.all(20),
                      child: Row(
                        children: [
                          IconButton(
                            icon: Icon(
                              Icons.arrow_back_rounded,
                              color: primaryOrange,
                            ),
                            onPressed: () => Navigator.pop(context),
                          ),
                          Text(
                            'Profile',
                            style: TextStyle(
                              color: primaryOrange,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),

                    Expanded(
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(25),
                        child: Column(
                          children: [
                            // Profile Avatar with orange theme
                            Container(
                              padding: EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: primaryOrange,
                                boxShadow: [
                                  BoxShadow(
                                    color: primaryOrange.withOpacity(0.4),
                                    blurRadius: 20,
                                    offset: Offset(0, 10),
                                  ),
                                ],
                              ),
                              child: CircleAvatar(
                                radius: 50,
                                backgroundColor: Colors.white,
                                child: Icon(
                                  Icons.person_rounded,
                                  size: 50,
                                  color: primaryOrange,
                                ),
                              ),
                            ),

                            SizedBox(height: 20),

                            // User Name
                            Text(
                              _userName,
                              style: TextStyle(
                                fontSize: 26,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3748),
                              ),
                            ),

                            SizedBox(height: 8),

                            // User Email
                            Text(
                              _userEmail,
                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey[600],
                              ),
                            ),

                            SizedBox(height: 30),

                            // Stats Cards
                            Row(
                              children: [
                                Expanded(
                                  child: _buildStatCard(
                                    icon: Icons.pets_rounded,
                                    label: 'My Pets',
                                    value: '$_myPetsCount',
                                  ),
                                ),
                                SizedBox(width: 15),
                                Expanded(
                                  child: _buildStatCard(
                                    icon: Icons.favorite_rounded,
                                    label: 'Favorites',
                                    value: '$_favoritesCount',
                                  ),
                                ),
                              ],
                            ),

                            SizedBox(height: 30),

                            // Main Action Buttons
                            _buildActionButton(
                              icon: Icons.settings_rounded,
                              title: 'Manage Account',
                              subtitle: 'Edit profile & account settings',
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ManageAccountPage(),
                                  ),
                                );
                                _refreshData(); // Refresh after returning
                              },
                            ),

                            SizedBox(height: 15),

                            _buildActionButton(
                              icon: Icons.favorite_rounded,
                              title: 'My Favorites',
                              subtitle: 'View all your favorite pets',
                              onTap: () async {
                                await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => FavoritesPage(),
                                  ),
                                );
                                _refreshData(); // Refresh after returning
                              },
                            ),

                            SizedBox(height: 30),

                            // Account Info Section
                            Container(
                              padding: EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(20),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.grey.withOpacity(0.2),
                                    blurRadius: 15,
                                    offset: Offset(0, 8),
                                  ),
                                ],
                                border: Border.all(
                                  color: Colors.grey[200]!,
                                  width: 1,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Account Information',
                                    style: TextStyle(
                                      fontSize: 18,
                                      fontWeight: FontWeight.bold,
                                      color: Color(0xFF2D3748),
                                    ),
                                  ),
                                  SizedBox(height: 15),
                                  _buildInfoRow(
                                    Icons.email_rounded,
                                    'Email',
                                    _userEmail,
                                  ),
                                  SizedBox(height: 10),
                                  _buildInfoRow(
                                    Icons.verified_user_rounded,
                                    'Verified',
                                    _auth.currentUser?.emailVerified == true
                                        ? 'Yes'
                                        : 'No',
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

  Widget _buildStatCard({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: primaryOrange.withOpacity(0.2),
            blurRadius: 15,
            offset: Offset(0, 8),
          ),
        ],
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Column(
        children: [
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryOrange.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: primaryOrange, size: 30),
          ),
          SizedBox(height: 10),
          Text(
            value,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: 5),
          Text(label, style: TextStyle(fontSize: 13, color: Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.2),
              blurRadius: 15,
              offset: Offset(0, 8),
            ),
          ],
          border: Border.all(color: Colors.grey[200]!, width: 1),
        ),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: primaryOrange.withOpacity(0.1),
                borderRadius: BorderRadius.circular(15),
              ),
              child: Icon(icon, color: primaryOrange, size: 28),
            ),
            SizedBox(width: 15),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF2D3748),
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios_rounded,
              color: primaryOrange,
              size: 18,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, color: primaryOrange, size: 20),
        SizedBox(width: 10),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Color(0xFF4A5568),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(fontSize: 14, color: Color(0xFF718096)),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}
