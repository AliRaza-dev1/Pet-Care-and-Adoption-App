import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class DatabaseHelper {
  static final DatabaseHelper _instance = DatabaseHelper._internal();
  static Database? _database;

  factory DatabaseHelper() {
    return _instance;
  }

  DatabaseHelper._internal();

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String path = join(await getDatabasesPath(), 'pet_care.db');
    return await openDatabase(
      path,
      version: 2, // ← VERSION 2 (clears version 1 data)
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  Future<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Delete ALL old data and recreate tables from scratch
    print('Upgrading database from v$oldVersion to v$newVersion');

    // Drop all existing tables
    await db.execute('DROP TABLE IF EXISTS pets');
    await db.execute('DROP TABLE IF EXISTS favorites');

    // Recreate all tables with fresh structure
    await _onCreate(db, newVersion);

    print('Database upgrade complete - all old data cleared');
  }

  Future<void> _onCreate(Database db, int version) async {
    print('Creating database tables...');

    // Create pets table (REMOVED: size, isNeutered, isTrained, goodWithKids)
    await db.execute('''
      CREATE TABLE pets(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        ownerName TEXT NOT NULL,
        ownerEmail TEXT NOT NULL,
        ownerContact TEXT NOT NULL,
        petName TEXT NOT NULL,
        petType TEXT NOT NULL,
        breed TEXT NOT NULL,
        gender TEXT NOT NULL,
        ageYears INTEGER NOT NULL,
        ageMonths INTEGER NOT NULL,
        ageString TEXT NOT NULL,
        weight REAL NOT NULL,
        description TEXT NOT NULL,
        location TEXT NOT NULL,
        adoptionFee REAL NOT NULL,
        isVaccinated INTEGER NOT NULL,
        imagePath TEXT NOT NULL,
        isAdopted INTEGER NOT NULL,
        createdAt TEXT NOT NULL,
        views INTEGER DEFAULT 0,
        favorites INTEGER DEFAULT 0
      )
    ''');

    // Create favorites table
    await db.execute('''
      CREATE TABLE favorites(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userId TEXT NOT NULL,
        petId INTEGER NOT NULL,
        addedAt TEXT NOT NULL,
        UNIQUE(userId, petId)
      )
    ''');

    print('Database tables created successfully');
  }

  // ========== PET OPERATIONS ==========

  Future<int> insertPet(Map<String, dynamic> pet) async {
    Database db = await database;
    return await db.insert('pets', pet);
  }

  Future<List<Map<String, dynamic>>> getAllPets() async {
    Database db = await database;
    return await db.query('pets', orderBy: 'createdAt DESC');
  }

  Future<List<Map<String, dynamic>>> getPetsByUserId(String userId) async {
    Database db = await database;
    return await db.query(
      'pets',
      where: 'userId = ?',
      whereArgs: [userId],
      orderBy: 'createdAt DESC',
    );
  }

  Future<int> updatePet(int id, Map<String, dynamic> pet) async {
    final db = await database;
    return await db.update('pets', pet, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> deletePet(int id) async {
    Database db = await database;
    return await db.delete('pets', where: 'id = ?', whereArgs: [id]);
  }

  // ========== FAVORITES OPERATIONS ==========

  // Add pet to favorites
  Future<bool> addToFavorites(String userId, int petId) async {
    try {
      Database db = await database;
      await db.insert('favorites', {
        'userId': userId,
        'petId': petId,
        'addedAt': DateTime.now().toIso8601String(),
      }, conflictAlgorithm: ConflictAlgorithm.replace);
      return true;
    } catch (e) {
      print('Error adding to favorites: $e');
      return false;
    }
  }

  // Remove pet from favorites
  Future<bool> removeFromFavorites(String userId, int petId) async {
    try {
      Database db = await database;
      await db.delete(
        'favorites',
        where: 'userId = ? AND petId = ?',
        whereArgs: [userId, petId],
      );
      return true;
    } catch (e) {
      print('Error removing from favorites: $e');
      return false;
    }
  }

  // Check if pet is in favorites
  Future<bool> isFavorite(String userId, int petId) async {
    try {
      Database db = await database;
      final result = await db.query(
        'favorites',
        where: 'userId = ? AND petId = ?',
        whereArgs: [userId, petId],
      );
      return result.isNotEmpty;
    } catch (e) {
      print('Error checking favorite: $e');
      return false;
    }
  }

  // Get all favorite pets for a user
  Future<List<Map<String, dynamic>>> getFavoritePets(String userId) async {
    try {
      Database db = await database;
      final result = await db.rawQuery(
        '''
        SELECT pets.* FROM pets
        INNER JOIN favorites ON pets.id = favorites.petId
        WHERE favorites.userId = ?
        ORDER BY favorites.addedAt DESC
      ''',
        [userId],
      );
      return result;
    } catch (e) {
      print('Error getting favorite pets: $e');
      return [];
    }
  }

  // Get count of favorites for a user
  Future<int> getFavoritesCount(String userId) async {
    try {
      Database db = await database;
      final result = await db.rawQuery(
        'SELECT COUNT(*) as count FROM favorites WHERE userId = ?',
        [userId],
      );
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('Error getting favorites count: $e');
      return 0;
    }
  }

  // ========== UTILITY OPERATIONS ==========

  // Manually clear all data (for debugging)
  Future<void> clearAllData() async {
    try {
      Database db = await database;
      await db.delete('pets');
      await db.delete('favorites');
      print('All data cleared successfully');
    } catch (e) {
      print('Error clearing data: $e');
    }
  }

  // Get total pet count
  Future<int> getTotalPetCount() async {
    try {
      Database db = await database;
      final result = await db.rawQuery('SELECT COUNT(*) as count FROM pets');
      return Sqflite.firstIntValue(result) ?? 0;
    } catch (e) {
      print('Error getting pet count: $e');
      return 0;
    }
  }

  // Close database
  Future<void> close() async {
    Database db = await database;
    db.close();
  }
}
