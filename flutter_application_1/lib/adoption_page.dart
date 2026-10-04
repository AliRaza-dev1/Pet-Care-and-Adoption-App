import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'database_helper.dart';
import 'PetDetailsPage.dart';
import 'dart:io';

class AdoptionPage extends StatefulWidget {
  @override
  _AdoptionPageState createState() => _AdoptionPageState();
}

class _AdoptionPageState extends State<AdoptionPage> {
  final _dbHelper = DatabaseHelper();
  final _auth = FirebaseAuth.instance;
  List<Map<String, dynamic>> _allPets = [];
  List<Map<String, dynamic>> _filteredPets = [];
  Set<int> _favoritePetIds = {};
  bool _isLoading = true;
  String _selectedFilter = 'All';
  String _searchQuery = '';
  String _sortBy = 'Newest';

  @override
  void initState() {
    super.initState();
    _loadPets();
  }

  Future<void> _loadPets() async {
    try {
      final pets = await _dbHelper.getAllPets();
      final user = _auth.currentUser;

      Set<int> favoriteIds = {};
      if (user != null) {
        final favorites = await _dbHelper.getFavoritePets(user.uid);
        favoriteIds = favorites.map((pet) => pet['id'] as int).toSet();
      }

      if (mounted) {
        setState(() {
          _allPets = pets;
          _filteredPets = pets;
          _favoritePetIds = favoriteIds;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading pets: $e');
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  void _applyFilters() {
    List<Map<String, dynamic>> filtered = List.from(_allPets);

    if (_selectedFilter != 'All') {
      filtered = filtered.where((pet) {
        return pet['petType']?.toLowerCase() == _selectedFilter.toLowerCase();
      }).toList();
    }

    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((pet) {
        final name = pet['petName']?.toLowerCase() ?? '';
        final breed = pet['breed']?.toLowerCase() ?? '';
        final location = pet['location']?.toLowerCase() ?? '';
        final query = _searchQuery.toLowerCase();
        return name.contains(query) ||
            breed.contains(query) ||
            location.contains(query);
      }).toList();
    }

    if (_sortBy == 'Newest') {
      filtered.sort(
        (a, b) => (b['createdAt'] ?? '').compareTo(a['createdAt'] ?? ''),
      );
    } else if (_sortBy == 'Lowest Fee') {
      filtered.sort(
        (a, b) => (a['adoptionFee'] ?? 0).compareTo(b['adoptionFee'] ?? 0),
      );
    }

    setState(() {
      _filteredPets = filtered;
    });
  }

  Future<void> _toggleFavorite(int petId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      bool success;
      bool isFavorite = _favoritePetIds.contains(petId);

      if (isFavorite) {
        success = await _dbHelper.removeFromFavorites(user.uid, petId);
        if (success) {
          setState(() {
            _favoritePetIds.remove(petId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('💔 Removed from favorites'),
              backgroundColor: Color(0xFFFF6B35),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 1),
            ),
          );
        }
      } else {
        success = await _dbHelper.addToFavorites(user.uid, petId);
        if (success) {
          setState(() {
            _favoritePetIds.add(petId);
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❤️ Added to favorites!'),
              backgroundColor: Color(0xFFFF6B35),
              behavior: SnackBarBehavior.floating,
              duration: Duration(seconds: 1),
            ),
          );
        }
      }
    } catch (e) {
      print('Error toggling favorite: $e');
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
            colors: [Color(0xFFFF6B35), Color(0xFFFF8C61)],
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
                      icon: Icon(Icons.arrow_back, color: Colors.white),
                      onPressed: () => Navigator.pop(context),
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Find Your Pet',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            'Browse available pets for adoption',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.refresh, color: Colors.white),
                      onPressed: _loadPets,
                    ),
                  ],
                ),
              ),

              // Content
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(30),
                      topRight: Radius.circular(30),
                    ),
                  ),
                  child: Column(
                    children: [
                      SizedBox(height: 20),

                      // Search Bar
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: TextField(
                          onChanged: (value) {
                            setState(() {
                              _searchQuery = value;
                            });
                            _applyFilters();
                          },
                          decoration: InputDecoration(
                            hintText: 'Search by name, breed, or location...',
                            prefixIcon: Icon(
                              Icons.search,
                              color: Color(0xFFFF6B35),
                            ),
                            filled: true,
                            fillColor: Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(15),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 20,
                              vertical: 15,
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 15),

                      // Filter Chips
                      SizedBox(
                        height: 50,
                        child: ListView(
                          scrollDirection: Axis.horizontal,
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          children: [
                            _buildFilterChip('All'),
                            SizedBox(width: 10),
                            _buildFilterChip('Dog'),
                            SizedBox(width: 10),
                            _buildFilterChip('Cat'),
                            SizedBox(width: 10),
                            _buildFilterChip('Bird'),
                            SizedBox(width: 10),
                            _buildFilterChip('Rabbit'),
                            SizedBox(width: 10),
                            _buildFilterChip('Hamster'),
                            SizedBox(width: 10),
                            _buildFilterChip('Other'),
                          ],
                        ),
                      ),

                      SizedBox(height: 15),

                      // Sort Dropdown
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Icon(Icons.sort, color: Colors.grey[700]),
                            SizedBox(width: 10),
                            Text(
                              'Sort by:',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.symmetric(horizontal: 15),
                                decoration: BoxDecoration(
                                  color: Colors.grey[50],
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: DropdownButtonHideUnderline(
                                  child: DropdownButton<String>(
                                    value: _sortBy,
                                    isExpanded: true,
                                    icon: Icon(
                                      Icons.arrow_drop_down,
                                      color: Color(0xFFFF6B35),
                                    ),
                                    items: ['Newest', 'Lowest Fee'].map((
                                      String value,
                                    ) {
                                      return DropdownMenuItem<String>(
                                        value: value,
                                        child: Text(value),
                                      );
                                    }).toList(),
                                    onChanged: (String? newValue) {
                                      setState(() {
                                        _sortBy = newValue ?? 'Newest';
                                      });
                                      _applyFilters();
                                    },
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      SizedBox(height: 15),

                      // Pet Count
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 20),
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(
                            '${_filteredPets.length} pet${_filteredPets.length == 1 ? '' : 's'} available',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF2D3748),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(height: 15),

                      // Pet Grid - FIXED
                      Expanded(
                        child: _isLoading
                            ? Center(
                                child: CircularProgressIndicator(
                                  color: Color(0xFFFF6B35),
                                ),
                              )
                            : _filteredPets.isEmpty
                            ? _buildEmptyState()
                            : RefreshIndicator(
                                onRefresh: _loadPets,
                                color: Color(0xFFFF6B35),
                                child: GridView.builder(
                                  padding: EdgeInsets.only(
                                    left: 20,
                                    right: 20,
                                    top: 10,
                                    bottom: 20,
                                  ),
                                  gridDelegate:
                                      SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: 2,
                                        crossAxisSpacing: 15,
                                        mainAxisSpacing: 15,
                                        childAspectRatio:
                                            0.68, // FIXED: Increased height for cards
                                      ),
                                  itemCount: _filteredPets.length,
                                  itemBuilder: (context, index) {
                                    return _buildPetCard(_filteredPets[index]);
                                  },
                                ),
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

  Widget _buildFilterChip(String label) {
    bool isSelected = _selectedFilter == label;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedFilter = label;
        });
        _applyFilters();
      },
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? Color(0xFFFF6B35) : Colors.grey[50],
          borderRadius: BorderRadius.circular(25),
          border: Border.all(
            color: isSelected ? Color(0xFFFF6B35) : Colors.grey[300]!,
          ),
        ),
        child: Row(
          children: [
            if (isSelected) Icon(Icons.check, color: Colors.white, size: 18),
            if (isSelected) SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPetCard(Map<String, dynamic> pet) {
    bool isFavorite = _favoritePetIds.contains(pet['id']);
    bool isAdopted = pet['isAdopted'] == 1;
    double adoptionFee = pet['adoptionFee'] ?? 0.0;

    return GestureDetector(
      onTap: () async {
        await Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PetDetailsPage(pet: pet)),
        );
        _loadPets();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.grey.withOpacity(0.15),
              blurRadius: 10,
              offset: Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Pet Image with Favorite Button
            Stack(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(20),
                    topRight: Radius.circular(20),
                  ),
                  child: pet['imagePath'] != null
                      ? Image.file(
                          File(pet['imagePath']),
                          height: 120, // FIXED: Reduced image height
                          width: double.infinity,
                          fit: BoxFit.cover,
                        )
                      : Container(
                          height: 120,
                          width: double.infinity,
                          color: Colors.grey[300],
                          child: Icon(
                            Icons.pets,
                            size: 50,
                            color: Colors.white,
                          ),
                        ),
                ),
                // Favorite Button
                Positioned(
                  top: 8,
                  right: 8,
                  child: GestureDetector(
                    onTap: () => _toggleFavorite(pet['id']),
                    child: Container(
                      padding: EdgeInsets.all(6),
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
                      child: Icon(
                        isFavorite ? Icons.favorite : Icons.favorite_border,
                        color: isFavorite
                            ? Color(0xFFFF6B35)
                            : Colors.grey[600],
                        size: 20,
                      ),
                    ),
                  ),
                ),
                // Adopted Badge
                if (isAdopted)
                  Positioned(
                    top: 8,
                    left: 8,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Color(0xFFFF6B35),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'ADOPTED',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),

            // Pet Info - FIXED: Better spacing
            Expanded(
              child: Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          pet['petName'] ?? 'Unknown',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2D3748),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 3),
                        Text(
                          pet['breed'] ?? 'Unknown Breed',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(
                              Icons.location_on,
                              size: 12,
                              color: Colors.grey[600],
                            ),
                            SizedBox(width: 2),
                            Expanded(
                              child: Text(
                                pet['location'] ?? 'Unknown',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey[600],
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    // Price - FIXED: Now visible
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      decoration: BoxDecoration(
                        color: Color(0xFFFF6B35).withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        adoptionFee == 0
                            ? 'FREE'
                            : 'Rs. ${adoptionFee.toStringAsFixed(0)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Color(0xFFFF6B35),
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.pets, size: 80, color: Colors.grey[300]),
          SizedBox(height: 20),
          Text(
            'No Pets Found',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Color(0xFF2D3748),
            ),
          ),
          SizedBox(height: 10),
          Text(
            'Try adjusting your filters',
            style: TextStyle(fontSize: 16, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }
}
