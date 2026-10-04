import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'database_helper.dart';
import 'dart:io';

class PetDetailsPage extends StatefulWidget {
  final Map<String, dynamic> pet;

  const PetDetailsPage({Key? key, required this.pet}) : super(key: key);

  @override
  State<PetDetailsPage> createState() => _PetDetailsPageState();
}

class _PetDetailsPageState extends State<PetDetailsPage> {
  final _dbHelper = DatabaseHelper();
  final _auth = FirebaseAuth.instance;
  bool isFavorite = false;
  bool _isCheckingFavorite = true;

  @override
  void initState() {
    super.initState();
    _checkIfFavorite();
  }

  Future<void> _checkIfFavorite() async {
    try {
      final user = _auth.currentUser;
      if (user != null && widget.pet['id'] != null) {
        final result = await _dbHelper.isFavorite(user.uid, widget.pet['id']);
        if (mounted) {
          setState(() {
            isFavorite = result;
            _isCheckingFavorite = false;
          });
        }
      }
    } catch (e) {
      print('Error checking favorite: $e');
      if (mounted) {
        setState(() {
          _isCheckingFavorite = false;
        });
      }
    }
  }

  Future<void> _toggleFavorite() async {
    final user = _auth.currentUser;
    if (user == null || widget.pet['id'] == null) {
      _showErrorSnackbar('Unable to update favorites');
      return;
    }

    try {
      bool success;
      if (isFavorite) {
        success = await _dbHelper.removeFromFavorites(
          user.uid,
          widget.pet['id'],
        );
      } else {
        success = await _dbHelper.addToFavorites(user.uid, widget.pet['id']);
      }

      if (success && mounted) {
        setState(() {
          isFavorite = !isFavorite;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(
                  isFavorite ? Icons.favorite : Icons.heart_broken,
                  color: Colors.white,
                ),
                SizedBox(width: 10),
                Text(
                  isFavorite ? 'Added to favorites!' : 'Removed from favorites',
                  style: TextStyle(fontSize: 16),
                ),
              ],
            ),
            backgroundColor: isFavorite ? Colors.green : Color(0xFFFF6B35),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      print('Error toggling favorite: $e');
      _showErrorSnackbar('Failed to update favorites');
    }
  }

  Future<void> _makePhoneCall(String phone) async {
    final Uri url = Uri.parse('tel:$phone');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _showErrorSnackbar('Cannot make phone call');
    }
  }

  Future<void> _sendSMS(String phone) async {
    String cleanPhone = phone.replaceAll(RegExp(r'[^\d+]'), '');
    final Uri url = Uri.parse(
      'sms:$cleanPhone?body=Hi, I am interested in adopting ${widget.pet['petName']}',
    );

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url);
      } else {
        _showErrorSnackbar('Cannot open messaging app');
      }
    } catch (e) {
      _showErrorSnackbar('Failed to open messaging app');
    }
  }

  Future<void> _sendEmail(String email) async {
    final Uri url = Uri.parse(
      'mailto:$email?subject=Interested in ${widget.pet['petName']}',
    );
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      _showErrorSnackbar('Cannot send email');
    }
  }

  void _showErrorSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isAdopted =
        widget.pet['status']?.toLowerCase() == 'adopted' ||
        widget.pet['isAdopted'] == 1;

    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: CustomScrollView(
        slivers: [
          // App Bar with Image
          SliverAppBar(
            expandedHeight: 350,
            pinned: true,
            backgroundColor: Color(0xFFFF6B35),
            leading: Container(
              margin: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 8,
                  ),
                ],
              ),
              child: IconButton(
                icon: Icon(Icons.arrow_back, color: Color(0xFFFF6B35)),
                onPressed: () => Navigator.pop(context),
              ),
            ),
            actions: [
              Container(
                margin: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 8,
                    ),
                  ],
                ),
                child: _isCheckingFavorite
                    ? Padding(
                        padding: const EdgeInsets.all(12),
                        child: SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFFFF6B35),
                          ),
                        ),
                      )
                    : IconButton(
                        icon: Icon(
                          isFavorite ? Icons.favorite : Icons.favorite_border,
                          color: isFavorite ? Colors.red : Color(0xFFFF6B35),
                        ),
                        onPressed: _toggleFavorite,
                      ),
              ),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  // Pet Image
                  widget.pet['imagePath'] != null ||
                          widget.pet['petImage'] != null
                      ? Image.file(
                          File(
                            widget.pet['imagePath'] ?? widget.pet['petImage'],
                          ),
                          fit: BoxFit.cover,
                        )
                      : Container(
                          color: Colors.grey[300],
                          child: const Icon(
                            Icons.pets,
                            size: 100,
                            color: Colors.white,
                          ),
                        ),
                  // Gradient Overlay
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                  // Status Badge
                  if (isAdopted)
                    Positioned(
                      top: 100,
                      right: 16,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        decoration: BoxDecoration(
                          color: Color(0xFFFF6B35),
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.3),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Text(
                          'ADOPTED',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Content
          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Pet Name & Price
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              widget.pet['petName'] ?? 'Unknown',
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF1F2937),
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 8,
                            ),
                            decoration: BoxDecoration(
                              color: Color(0xFFFF6B35).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              widget.pet['adoptionFee'] == 0 ||
                                      widget.pet['adoptionFee'] == null
                                  ? 'FREE'
                                  : 'Rs. ${widget.pet['adoptionFee']}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFFF6B35),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.pets, size: 18, color: Colors.grey[600]),
                          const SizedBox(width: 6),
                          Text(
                            widget.pet['breed'] ??
                                widget.pet['petBreed'] ??
                                'Unknown Breed',
                            style: TextStyle(
                              fontSize: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Quick Info Cards (Age, Gender, Weight)
                Container(
                  color: Colors.white,
                  padding: const EdgeInsets.all(20),
                  child: Row(
                    children: [
                      _buildInfoCard(
                        Icons.calendar_today,
                        'Age',
                        widget.pet['ageString'] ??
                            '${widget.pet['petAge'] ?? '?'} months',
                        Color(0xFFFF6B35),
                      ),
                      const SizedBox(width: 12),
                      _buildInfoCard(
                        widget.pet['gender']?.toLowerCase() == 'male' ||
                                widget.pet['petGender']?.toLowerCase() == 'male'
                            ? Icons.male
                            : Icons.female,
                        'Gender',
                        widget.pet['gender'] ??
                            widget.pet['petGender'] ??
                            'Unknown',
                        widget.pet['gender']?.toLowerCase() == 'male' ||
                                widget.pet['petGender']?.toLowerCase() == 'male'
                            ? Color(0xFFFF6B35)
                            : Colors.pink,
                      ),
                      const SizedBox(width: 12),
                      _buildInfoCard(
                        Icons.monitor_weight,
                        'Weight',
                        widget.pet['weight'] != null
                            ? '${widget.pet['weight']} kg'
                            : 'N/A',
                        Color(0xFFFF8C61),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // Pet Details Section (Only fields from Add Pet)
                _buildSection('Pet Details', [
                  _buildDetailRow(
                    'Type',
                    widget.pet['petType'],
                    Icons.category,
                  ),
                  _buildDetailRow('Breed', widget.pet['breed'], Icons.pets),
                  if (widget.pet['isVaccinated'] != null)
                    _buildDetailRow(
                      'Vaccinated',
                      widget.pet['isVaccinated'] == 1 ? 'Yes' : 'No',
                      Icons.vaccines,
                    ),
                  _buildDetailRow(
                    'Location',
                    widget.pet['location'],
                    Icons.location_on,
                  ),
                ]),

                const SizedBox(height: 8),

                // Description Section
                _buildSection('About ${widget.pet['petName']}', [
                  Text(
                    widget.pet['description'] ?? 'No description available.',
                    style: TextStyle(
                      fontSize: 15,
                      height: 1.6,
                      color: Colors.grey[700],
                    ),
                  ),
                ]),

                const SizedBox(height: 8),

                // Owner Information Section
                _buildSection('Owner Information', [
                  _buildDetailRow(
                    'Name',
                    widget.pet['ownerName'],
                    Icons.person,
                  ),
                  _buildDetailRow(
                    'Phone',
                    widget.pet['ownerPhone'] ?? widget.pet['ownerContact'],
                    Icons.phone,
                  ),
                  _buildDetailRow(
                    'Email',
                    widget.pet['ownerEmail'],
                    Icons.email,
                  ),
                ]),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),

      // Bottom Contact Bar
      bottomNavigationBar: !isAdopted
          ? Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 10,
                    offset: const Offset(0, -5),
                  ),
                ],
              ),
              child: Row(
                children: [
                  _buildContactButton(
                    icon: Icons.phone,
                    color: Colors.green,
                    onPressed: () => _makePhoneCall(
                      widget.pet['ownerPhone'] ??
                          widget.pet['ownerContact'] ??
                          '',
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildContactButton(
                    icon: Icons.message,
                    color: Color(0xFF2196F3),
                    onPressed: () => _sendSMS(
                      widget.pet['ownerPhone'] ??
                          widget.pet['ownerContact'] ??
                          '',
                    ),
                  ),
                  const SizedBox(width: 12),
                  _buildContactButton(
                    icon: Icons.email,
                    color: Color(0xFFFF6B35),
                    onPressed: () => _sendEmail(widget.pet['ownerEmail'] ?? ''),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () => _makePhoneCall(
                        widget.pet['ownerPhone'] ??
                            widget.pet['ownerContact'] ??
                            '',
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Color(0xFFFF6B35),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      child: const Text(
                        'Contact Owner',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            )
          : Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Color(0xFFFFF5F0),
                border: Border(
                  top: BorderSide(color: Color(0xFFFFE5D9), width: 2),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.check_circle, color: Color(0xFFFF6B35)),
                  const SizedBox(width: 8),
                  Text(
                    'This pet has been adopted',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF6B35),
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoCard(
    IconData icon,
    String label,
    String value,
    Color color,
  ) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: color,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Color(0xFF1F2937),
            ),
          ),
          const SizedBox(height: 16),
          ...children,
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String? value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Color(0xFFFF6B35).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: 20, color: Color(0xFFFF6B35)),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 2),
                Text(
                  value ?? 'Not specified',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF1F2937),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildContactButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: IconButton(
        icon: Icon(icon, color: color),
        onPressed: onPressed,
      ),
    );
  }
}
