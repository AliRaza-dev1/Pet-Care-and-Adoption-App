import 'package:flutter/material.dart';
import 'database_helper.dart';

class DatabaseViewerPage extends StatefulWidget {
  @override
  _DatabaseViewerPageState createState() => _DatabaseViewerPageState();
}

class _DatabaseViewerPageState extends State<DatabaseViewerPage> {
  List<Map<String, dynamic>> _pets = [];
  List<Map<String, dynamic>> _favorites = [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final dbHelper = DatabaseHelper();

      // CRITICAL FIX: Initialize database first
      await dbHelper.database;

      final pets = await dbHelper.getAllPets();
      final db = await dbHelper.database;
      final favorites = await db.query('favorites');

      if (mounted) {
        // Check if widget is still mounted
        setState(() {
          _pets = pets;
          _favorites = favorites;
          _isLoading = false;
        });
      }
    } catch (e) {
      print('Error loading data: $e');
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SQLite Database Viewer'),
        backgroundColor: Color(0xFFFF6B35),
        foregroundColor: Colors.white,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Color(0xFFFF6B35),
                    ),
                  ),
                  SizedBox(height: 20),
                  Text('Loading database...'),
                ],
              ),
            )
          : _errorMessage != null
          ? Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.error_outline, size: 60, color: Colors.red),
                    SizedBox(height: 20),
                    Text(
                      'Error Loading Database',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 10),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.red),
                    ),
                    SizedBox(height: 20),
                    ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _isLoading = true;
                          _errorMessage = null;
                        });
                        _loadData();
                      },
                      child: Text('Retry'),
                    ),
                  ],
                ),
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // PETS TABLE
                  _buildTableHeader('PETS TABLE (${_pets.length} records)'),
                  SizedBox(height: 10),
                  if (_pets.isEmpty)
                    _buildEmptyMessage('No pets in database')
                  else
                    ..._pets.map((pet) => _buildPetCard(pet)).toList(),

                  SizedBox(height: 30),

                  // FAVORITES TABLE
                  _buildTableHeader(
                    'FAVORITES TABLE (${_favorites.length} records)',
                  ),
                  SizedBox(height: 10),
                  if (_favorites.isEmpty)
                    _buildEmptyMessage('No favorites in database')
                  else
                    ..._favorites
                        .map((fav) => _buildFavoriteCard(fav))
                        .toList(),
                ],
              ),
            ),
    );
  }

  Widget _buildTableHeader(String title) {
    return Container(
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Color(0xFFFF6B35),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(Icons.storage, color: Colors.white),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyMessage(String message) {
    return Container(
      padding: EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Center(
        child: Text(message, style: TextStyle(color: Colors.grey[600])),
      ),
    );
  }

  Widget _buildPetCard(Map<String, dynamic> pet) {
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ID: ${pet['id'] ?? 'N/A'}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            SizedBox(height: 4),
            Text('Pet Name: ${pet['petName'] ?? 'N/A'}'),
            Text(
              'Type: ${pet['petType'] ?? 'N/A'} | Breed: ${pet['breed'] ?? 'N/A'}',
            ),
            Text(
              'Owner: ${pet['ownerName'] ?? 'N/A'} (${pet['ownerEmail'] ?? 'N/A'})',
            ),
            Text(
              'Age: ${pet['ageString'] ?? 'N/A'} | Weight: ${pet['weight'] ?? 'N/A'} kg',
            ),
            Text('Location: ${pet['location'] ?? 'N/A'}'),
            Text('Adopted: ${pet['isAdopted'] == 1 ? 'Yes' : 'No'}'),
            if (pet['createdAt'] != null)
              Text(
                'Created: ${pet['createdAt']}',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFavoriteCard(Map<String, dynamic> fav) {
    return Card(
      margin: EdgeInsets.only(bottom: 10),
      color: Colors.pink[50],
      elevation: 2,
      child: Padding(
        padding: EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'ID: ${fav['id'] ?? 'N/A'}',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            SizedBox(height: 4),
            Text('User ID: ${fav['userId'] ?? 'N/A'}'),
            Text('Pet ID: ${fav['petId'] ?? 'N/A'}'),
            if (fav['addedAt'] != null)
              Text(
                'Added: ${fav['addedAt']}',
                style: TextStyle(fontSize: 11, color: Colors.grey),
              ),
          ],
        ),
      ),
    );
  }
}
