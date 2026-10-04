import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'database_helper.dart';
import 'add_pet_page.dart';
import 'dart:io';

class MyPetsPage extends StatefulWidget {
  @override
  _MyPetsPageState createState() => _MyPetsPageState();
}

class _MyPetsPageState extends State<MyPetsPage> {
  final _auth = FirebaseAuth.instance;
  final _dbHelper = DatabaseHelper();
  List<Map<String, dynamic>> _myPets = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadMyPets();
  }

  Future<void> _loadMyPets() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = _auth.currentUser;
      if (user != null) {
        final pets = await _dbHelper.getPetsByUserId(user.uid);
        setState(() {
          _myPets = pets;
          _isLoading = false;
        });
      } else {
        setState(() {
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading pets: $e');
      setState(() {
        _isLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error loading pets: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _deletePet(int petId, String petName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Delete Pet'),
        content: Text(
          'Are you sure you want to remove "$petName" from adoption list?',
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _dbHelper.deletePet(petId);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Pet removed successfully'),
            backgroundColor: Color(0xFFFF7F50),
            behavior: SnackBarBehavior.floating,
          ),
        );
        _loadMyPets(); // Reload the list
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${e.toString()}'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  Future<void> _markAsAdopted(
    int petId,
    String petName,
    bool currentStatus,
  ) async {
    try {
      await _dbHelper.updatePet(petId, {'isAdopted': currentStatus ? 0 : 1});

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            !currentStatus ? 'Marked as adopted!' : 'Marked as available',
          ),
          backgroundColor: Color(0xFFFF7F50),
          behavior: SnackBarBehavior.floating,
        ),
      );
      _loadMyPets(); // Reload the list
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Color(0xFFFF7F50), Color(0xFFFF6347)],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Header
              Padding(
                padding: EdgeInsets.all(20),
                child: Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: Colors.white,
                        size: 28,
                      ),
                      onPressed: () => Navigator.pop(context),
                      tooltip: 'Go back',
                    ),
                    SizedBox(width: 10),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'My Pets',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          'Manage your posted pets',
                          style: TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              // Pets List
              Expanded(
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(40),
                      topRight: Radius.circular(40),
                    ),
                  ),
                  child: _isLoading
                      ? Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Color(0xFFFF7F50),
                            ),
                          ),
                        )
                      : _myPets.isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                Icons.pets,
                                size: 100,
                                color: Colors.grey[300],
                              ),
                              SizedBox(height: 20),
                              Text(
                                'No Pets Posted Yet',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.grey[700],
                                ),
                              ),
                              SizedBox(height: 10),
                              Text(
                                'Post your first pet for adoption',
                                style: TextStyle(
                                  fontSize: 16,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : RefreshIndicator(
                          onRefresh: _loadMyPets,
                          color: Color(0xFFFF7F50),
                          child: ListView.builder(
                            padding: EdgeInsets.all(20),
                            itemCount: _myPets.length,
                            itemBuilder: (context, index) {
                              final pet = _myPets[index];
                              return _buildPetCard(
                                petId: pet['id'],
                                petName: pet['petName'] ?? 'Unknown',
                                petType: pet['petType'] ?? 'Pet',
                                breed: pet['breed'] ?? 'Unknown',
                                ageString: pet['ageString'] ?? '0 months',
                                location: pet['location'] ?? 'Unknown',
                                adoptionFee: pet['adoptionFee'] ?? 0.0,
                                isAdopted: pet['isAdopted'] == 1,
                                gender: pet['gender'] ?? 'Unknown',
                                isVaccinated: pet['isVaccinated'] == 1,
                                imagePath: pet['imagePath'],
                              );
                            },
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

  Widget _buildPetCard({
    required int petId,
    required String petName,
    required String petType,
    required String breed,
    required String ageString,
    required String location,
    required double adoptionFee,
    required bool isAdopted,
    required String gender,
    required bool isVaccinated,
    String? imagePath,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            blurRadius: 10,
            offset: Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        children: [
          // Pet Info
          Padding(
            padding: EdgeInsets.all(20),
            child: Row(
              children: [
                // Pet Image
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(15),
                    child: _buildPetImage(petId),
                  ),
                ),
                SizedBox(width: 15),

                // Pet Details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              petName,
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF2D3748),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (isAdopted)
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: Color(0xFFFF7F50),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                'ADOPTED',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                        ],
                      ),
                      SizedBox(height: 4),
                      Text(
                        '$petType • $breed',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      SizedBox(height: 8),

                      // FIXED: Wrap chips to prevent overflow
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          _buildInfoChip(
                            Icons.cake,
                            ageString,
                            Color(0xFFFF7F50),
                          ),
                          _buildInfoChip(
                            gender == 'Male' ? Icons.male : Icons.female,
                            gender,
                            Color(0xFFFF7F50),
                          ),
                          if (isVaccinated)
                            _buildInfoChip(
                              Icons.vaccines,
                              'Vaccinated',
                              Color(0xFFFF7F50),
                            ),
                        ],
                      ),

                      SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(
                            Icons.location_on,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.grey[600],
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          SizedBox(width: 8),
                          Text(
                            adoptionFee == 0
                                ? 'FREE'
                                : 'Rs. ${adoptionFee.toStringAsFixed(0)}',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFFFF7F50),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Action Buttons
          Container(
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(20),
                bottomRight: Radius.circular(20),
              ),
            ),
            padding: EdgeInsets.all(12),
            child: Row(
              children: [
                // EDIT BUTTON - NEW
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () async {
                      final pet = _myPets.firstWhere((p) => p['id'] == petId);
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => AddPetPage(petToEdit: pet),
                        ),
                      );
                      if (result == true) {
                        _loadMyPets(); // Refresh the list
                      }
                    },
                    icon: Icon(Icons.edit, size: 18),
                    label: Text('Edit', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFFFF6B35),
                      side: BorderSide(color: Color(0xFFFF6B35)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                // MARK ADOPTED BUTTON
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _markAsAdopted(petId, petName, isAdopted),
                    icon: Icon(
                      isAdopted ? Icons.undo : Icons.check_circle,
                      size: 18,
                    ),
                    label: Text(
                      isAdopted ? 'Available' : 'Adopted',
                      style: TextStyle(fontSize: 12),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Color(0xFFFF7F50),
                      side: BorderSide(color: Color(0xFFFF7F50)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
                SizedBox(width: 10),
                // DELETE BUTTON
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _deletePet(petId, petName),
                    icon: Icon(Icons.delete_outline, size: 18),
                    label: Text('Delete', style: TextStyle(fontSize: 13)),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red,
                      side: BorderSide(color: Colors.red),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      padding: EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoChip(IconData icon, String label, Color color) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          SizedBox(width: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPetImage(int petId) {
    // Find the pet in the list
    final pet = _myPets.firstWhere((p) => p['id'] == petId, orElse: () => {});

    final String? imagePath = pet['imagePath'];

    if (imagePath == null || imagePath.isEmpty) {
      // Show placeholder if no image
      return Container(
        color: Color(0xFFFF7F50).withOpacity(0.1),
        child: Icon(Icons.pets, size: 40, color: Color(0xFFFF7F50)),
      );
    }

    // Check if file exists and display it
    final imageFile = File(imagePath);
    if (imageFile.existsSync()) {
      return Image.file(
        imageFile,
        width: 80,
        height: 80,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            color: Color(0xFFFF7F50).withOpacity(0.1),
            child: Icon(Icons.pets, size: 40, color: Color(0xFFFF7F50)),
          );
        },
      );
    } else {
      // File doesn't exist, show placeholder
      return Container(
        color: Color(0xFFFF7F50).withOpacity(0.1),
        child: Icon(Icons.pets, size: 40, color: Color(0xFFFF7F50)),
      );
    }
  }
}
