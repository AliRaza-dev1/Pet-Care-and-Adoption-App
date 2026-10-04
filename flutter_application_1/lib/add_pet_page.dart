import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'database_helper.dart';
import 'dart:typed_data';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'dart:io';

class AddPetPage extends StatefulWidget {
  final Map<String, dynamic>? petToEdit;

  AddPetPage({this.petToEdit});

  @override
  _AddPetPageState createState() => _AddPetPageState();
}

class _AddPetPageState extends State<AddPetPage>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _auth = FirebaseAuth.instance;
  final _firestore = FirebaseFirestore.instance;
  final _dbHelper = DatabaseHelper();
  final _imagePicker = ImagePicker();

  // Controllers
  final _petNameController = TextEditingController();
  final _breedController = TextEditingController();
  int _selectedAgeYears = 0;
  int _selectedAgeMonths = 0;
  final _weightController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _locationController = TextEditingController();
  final _adoptionFeeController = TextEditingController();
  final _contactController = TextEditingController();

  // Image state
  XFile? _selectedImageFile;

  // Form state
  String _selectedPetType = 'Dog';
  String _selectedGender = 'Male';
  bool _isVaccinated = false;
  bool _isLoading = false;
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  final List<String> _petTypes = [
    'Dog',
    'Cat',
    'Bird',
    'Rabbit',
    'Hamster',
    'Other',
  ];
  final List<String> _genders = ['Male', 'Female'];
  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: Duration(milliseconds: 800),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );
    _slideAnimation = Tween<Offset>(begin: Offset(0, 0.3), end: Offset.zero)
        .animate(
          CurvedAnimation(parent: _animationController, curve: Curves.easeOut),
        );
    _animationController.forward();

    // Populate fields if editing
    if (widget.petToEdit != null) {
      final pet = widget.petToEdit!;
      _petNameController.text = pet['petName'] ?? '';
      _breedController.text = pet['breed'] ?? '';
      _selectedAgeYears = pet['ageYears'] ?? 0;
      _selectedAgeMonths = pet['ageMonths'] ?? 0;
      _weightController.text = pet['weight']?.toString() ?? '';
      _descriptionController.text = pet['description'] ?? '';
      _locationController.text = pet['location'] ?? '';
      _adoptionFeeController.text = pet['adoptionFee']?.toString() ?? '';
      _contactController.text = pet['ownerContact'] ?? '';
      _selectedPetType = pet['petType'] ?? 'Dog';
      _selectedGender = pet['gender'] ?? 'Male';
      _isVaccinated = (pet['isVaccinated'] == 1);

      // Set existing image
      if (pet['imagePath'] != null && pet['imagePath'].isNotEmpty) {
        _selectedImageFile = XFile(pet['imagePath']);
      }
    }
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 20,
        fontWeight: FontWeight.bold,
        color: Color(0xFFFF7043),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(fontSize: 16),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Color(0xFFFF7043)),
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Icon(icon, color: Color(0xFFFF7043)),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Color(0xFFFF7043), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }

  Widget _buildTextArea({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      maxLines: 4,
      style: TextStyle(fontSize: 16),
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        labelStyle: TextStyle(color: Color(0xFFFF7043)),
        hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
        prefixIcon: Padding(
          padding: EdgeInsets.only(bottom: 70),
          child: Icon(icon, color: Color(0xFFFF7043)),
        ),
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.grey[200]!, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Color(0xFFFF7043), width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.red, width: 1),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Colors.red, width: 2),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 18),
      ),
    );
  }

  Widget _buildDropdownField({
    required String label,
    required String value,
    required List<String> items,
    required IconData icon,
    required void Function(String?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      padding: EdgeInsets.symmetric(horizontal: 15, vertical: 5),
      child: Row(
        children: [
          Icon(icon, color: Color(0xFFFF7043)),
          SizedBox(width: 10),
          Expanded(
            child: DropdownButtonFormField<String>(
              value: value,
              decoration: InputDecoration(
                labelText: label,
                labelStyle: TextStyle(color: Color(0xFFFF7043), fontSize: 14),
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              dropdownColor: Colors.white,
              icon: Icon(Icons.arrow_drop_down, color: Color(0xFFFF7043)),
              items: items.map((String item) {
                return DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: TextStyle(fontSize: 15, color: Colors.black87),
                  ),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckboxTile({
    required String title,
    required String subtitle,
    required bool value,
    required IconData icon,
    required void Function(bool?) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: value ? Color(0xFFFF7043).withOpacity(0.3) : Colors.grey[200]!,
          width: 1.5,
        ),
      ),
      child: CheckboxListTile(
        title: Row(
          children: [
            Icon(icon, color: Color(0xFFFF7043), size: 22),
            SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFFF7043),
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: EdgeInsets.only(left: 32, top: 4),
          child: Text(
            subtitle,
            style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          ),
        ),
        value: value,
        onChanged: onChanged,
        activeColor: Color(0xFFFF7043),
        checkColor: Colors.white,
        contentPadding: EdgeInsets.symmetric(horizontal: 15, vertical: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    _petNameController.dispose();
    _breedController.dispose();
    _weightController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _adoptionFeeController.dispose();
    _contactController.dispose();
    super.dispose();
  }

  // Image Picker Functions
  Future<void> _pickImageFromGallery() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = pickedFile;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error picking image: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1920,
        maxHeight: 1920,
        imageQuality: 85,
      );

      if (pickedFile != null) {
        setState(() {
          _selectedImageFile = pickedFile;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error taking photo: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _showImageSourceDialog() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(25),
            topRight: Radius.circular(25),
          ),
        ),
        padding: EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 50,
              height: 5,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            SizedBox(height: 20),
            Text(
              'Choose Image Source',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Color(0xFFFF7043),
              ),
            ),
            SizedBox(height: 20),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(0xFFFF7043).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.photo_library, color: Color(0xFFFF7043)),
              ),
              title: Text(
                'Gallery',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('Choose from your photos'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromGallery();
              },
            ),
            ListTile(
              leading: Container(
                padding: EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Color(0xFFFF5722).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.camera_alt, color: Color(0xFFFF7043)),
              ),
              title: Text(
                'Camera',
                style: TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text('Take a new photo'),
              onTap: () {
                Navigator.pop(context);
                _pickImageFromCamera();
              },
            ),
            SizedBox(height: 10),
          ],
        ),
      ),
    );
  }

  Future<String?> _saveImageLocally() async {
    if (_selectedImageFile == null) return null;

    try {
      // Get app's permanent storage directory
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String imagePath = '${appDir.path}/$fileName';

      // Copy image to permanent location
      final Uint8List bytes = await _selectedImageFile!.readAsBytes();
      final File newImage = File(imagePath);
      await newImage.writeAsBytes(bytes);

      return imagePath;
    } catch (e) {
      throw Exception('Failed to save image: ${e.toString()}');
    }
  }

  Future<void> _savePet() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Please fill all required fields correctly'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    // Check if image is selected (only for new pets)
    if (widget.petToEdit == null && _selectedImageFile == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(Icons.warning, color: Colors.white),
              SizedBox(width: 10),
              Expanded(child: Text('Please select a photo of your pet')),
            ],
          ),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 3),
        ),
      );
      return;
    }

    // Check if pet is newly born (only for new pets)
    if (widget.petToEdit == null) {
      int totalMonths = (_selectedAgeYears * 12) + _selectedAgeMonths;
      if (totalMonths == 0) {
        bool? confirmPost = await showDialog<bool>(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              title: Row(
                children: [
                  Icon(
                    Icons.warning_amber_rounded,
                    color: Colors.orange,
                    size: 28,
                  ),
                  SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Newly Born Pet',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFFFF7043),
                      ),
                    ),
                  ),
                ],
              ),
              content: Text(
                'Are you sure you want to post a newly born pet (0 months old)?',
                style: TextStyle(fontSize: 16, color: Color(0xFFFF7043)),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  child: Text(
                    'No',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                ElevatedButton(
                  onPressed: () => Navigator.of(context).pop(true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Color(0xFFFF7043),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                  ),
                  child: Text(
                    'Yes, Post',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            );
          },
        );

        if (confirmPost != true) return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not logged in');

      // Handle image
      String? imagePath;

      if (widget.petToEdit != null) {
        // EDIT MODE
        if (_selectedImageFile != null) {
          final newPath = _selectedImageFile!.path;
          final oldPath = widget.petToEdit!['imagePath'];

          if (newPath == oldPath) {
            imagePath = oldPath;
          } else {
            imagePath = await _saveImageLocally();
          }
        } else {
          imagePath = widget.petToEdit!['imagePath'];
        }
      } else {
        // ADD MODE
        if (_selectedImageFile != null) {
          imagePath = await _saveImageLocally();
        }
      }

      if (imagePath == null) throw Exception('Failed to save image');

      // Get user data
      final userDoc = await _firestore.collection('users').doc(user.uid).get();
      final userName = userDoc.data()?['name'] ?? 'Unknown';

      // Create pet data
      Map<String, dynamic> petData = {
        'userId': user.uid,
        'ownerName': userName,
        'ownerEmail': user.email ?? '',
        'ownerContact': _contactController.text.trim(),
        'petName': _petNameController.text.trim(),
        'petType': _selectedPetType,
        'breed': _breedController.text.trim(),
        'gender': _selectedGender,
        'ageYears': _selectedAgeYears,
        'ageMonths': _selectedAgeMonths,
        'ageString': _selectedAgeYears == 0
            ? '$_selectedAgeMonths months'
            : _selectedAgeMonths == 0
            ? '$_selectedAgeYears ${_selectedAgeYears == 1 ? 'year' : 'years'}'
            : '$_selectedAgeYears ${_selectedAgeYears == 1 ? 'year' : 'years'} $_selectedAgeMonths ${_selectedAgeMonths == 1 ? 'month' : 'months'}',
        'weight': double.parse(_weightController.text.trim()),
        'description': _descriptionController.text.trim(),
        'location': _locationController.text.trim(),
        'adoptionFee': double.parse(_adoptionFeeController.text.trim()),
        'isVaccinated': _isVaccinated ? 1 : 0,
        'imagePath': imagePath,
      };

      if (widget.petToEdit == null) {
        // ADD MODE
        petData['isAdopted'] = 0;
        petData['createdAt'] = DateTime.now().toIso8601String();
        petData['views'] = 0;
        petData['favorites'] = 0;
        await _dbHelper.insertPet(petData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text('Pet posted for adoption successfully!')),
              ],
            ),
            backgroundColor: Color(0xFFFF7043),
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else {
        // EDIT MODE
        await _dbHelper.updatePet(widget.petToEdit!['id'], petData);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.white),
                SizedBox(width: 10),
                Expanded(child: Text('Pet updated successfully!')),
              ],
            ),
            backgroundColor: Color(0xFFFF7043),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      Navigator.pop(context, true);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFFFF7043), Color(0xFFFF5722)],
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
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.petToEdit == null
                                ? 'Post Pet for Adoption'
                                : 'Edit Pet Details',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          Text(
                            widget.petToEdit == null
                                ? 'Help your pet find a loving home'
                                : 'Update pet information',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Form Container
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
                  child: FadeTransition(
                    opacity: _fadeAnimation,
                    child: SlideTransition(
                      position: _slideAnimation,
                      child: SingleChildScrollView(
                        padding: EdgeInsets.all(25),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(height: 10),

                              // Image Upload Section
                              _buildSectionTitle('Pet Photo'),
                              SizedBox(height: 15),
                              _buildImageUploadWidget(),
                              SizedBox(height: 30),

                              // Pet Information Section
                              _buildSectionTitle('Pet Information'),
                              SizedBox(height: 15),
                              _buildTextField(
                                controller: _petNameController,
                                label: 'Pet Name',
                                hint: 'e.g., Max, Bella, Luna',
                                icon: Icons.pets,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter pet name';
                                  }
                                  if (value.trim().length < 2) {
                                    return 'Name must be at least 2 characters';
                                  }
                                  if (!RegExp(
                                    r'^[a-zA-Z\s]+$',
                                  ).hasMatch(value.trim())) {
                                    return 'Name should only contain letters';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 20),

                              // Pet Type & Gender Row
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDropdownField(
                                      label: 'Pet Type',
                                      value: _selectedPetType,
                                      items: _petTypes,
                                      icon: Icons.category,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedPetType = value!;
                                        });
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 15),
                                  Expanded(
                                    child: _buildDropdownField(
                                      label: 'Gender',
                                      value: _selectedGender,
                                      items: _genders,
                                      icon: Icons.wc,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedGender = value!;
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),

                              // Breed Field
                              _buildTextField(
                                controller: _breedController,
                                label: 'Breed',
                                hint: 'e.g., Golden Retriever, Persian Cat',
                                icon: Icons.list_alt,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter breed';
                                  }
                                  if (value.trim().length < 2) {
                                    return 'Breed must be at least 2 characters';
                                  }
                                  if (!RegExp(
                                    r'^[a-zA-Z\s\-]+$',
                                  ).hasMatch(value.trim())) {
                                    return 'Breed should only contain letters';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 20),

                              // Age Row
                              Row(
                                children: [
                                  Expanded(
                                    child: _buildDropdownField(
                                      label: 'Years',
                                      value: _selectedAgeYears.toString(),
                                      items: List.generate(
                                        21,
                                        (i) => i.toString(),
                                      ),
                                      icon: Icons.cake,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedAgeYears = int.parse(value!);
                                        });
                                      },
                                    ),
                                  ),
                                  SizedBox(width: 10),
                                  Expanded(
                                    child: _buildDropdownField(
                                      label: 'Months',
                                      value: _selectedAgeMonths.toString(),
                                      items: List.generate(
                                        12,
                                        (i) => i.toString(),
                                      ),
                                      icon: Icons.calendar_today,
                                      onChanged: (value) {
                                        setState(() {
                                          _selectedAgeMonths = int.parse(
                                            value!,
                                          );
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(height: 20),

                              // Weight field
                              _buildTextField(
                                controller: _weightController,
                                label: 'Weight (kg)',
                                hint: 'e.g., 15',
                                icon: Icons.monitor_weight,
                                keyboardType: TextInputType.numberWithOptions(
                                  decimal: true,
                                ),
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Weight required';
                                  }
                                  final weight = double.tryParse(value);
                                  if (weight == null || weight <= 0) {
                                    return 'Enter valid weight';
                                  }
                                  if (weight > 500) {
                                    return 'Weight too high';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 20),

                              // Description Section
                              _buildSectionTitle('Pet Description'),
                              SizedBox(height: 15),
                              _buildTextArea(
                                controller: _descriptionController,
                                label: 'Description',
                                hint:
                                    'Describe your pet\'s personality, behavior, habits, likes, dislikes...',
                                icon: Icons.description,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please describe your pet';
                                  }
                                  if (value.trim().length < 20) {
                                    return 'Description must be at least 20 characters';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 30),

                              // Health & Behavior Section
                              _buildSectionTitle('Health & Behavior'),
                              SizedBox(height: 15),
                              _buildCheckboxTile(
                                title: 'Vaccinated',
                                subtitle:
                                    'Pet has received all required vaccinations',
                                value: _isVaccinated,
                                icon: Icons.vaccines,
                                onChanged: (value) {
                                  setState(() {
                                    _isVaccinated = value!;
                                  });
                                },
                              ),
                              SizedBox(height: 10),

                              // Adoption Details Section
                              _buildSectionTitle('Adoption Details'),
                              SizedBox(height: 15),
                              _buildTextField(
                                controller: _locationController,
                                label: 'Location',
                                hint: 'e.g., Lahore, Karachi, Islamabad',
                                icon: Icons.location_on,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter your location';
                                  }
                                  if (value.trim().length < 3) {
                                    return 'Location must be at least 3 characters';
                                  }
                                  if (!RegExp(
                                    r'^[a-zA-Z\s,]+$',
                                  ).hasMatch(value.trim())) {
                                    return 'Invalid location format';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 20),
                              _buildTextField(
                                controller: _adoptionFeeController,
                                label: 'Adoption Fee (Rs.)',
                                hint: 'e.g., 2000 (to cover vaccine costs)',
                                icon: Icons.payments,
                                keyboardType: TextInputType.number,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Enter fee (0 for free)';
                                  }
                                  final fee = double.tryParse(value);
                                  if (fee == null || fee < 0) {
                                    return 'Invalid amount';
                                  }
                                  if (fee > 100000) {
                                    return 'Fee too high';
                                  }
                                  return null;
                                },
                              ),
                              SizedBox(height: 20),
                              _buildTextField(
                                controller: _contactController,
                                label: 'Contact Number',
                                hint: 'e.g., 03046588102',
                                icon: Icons.phone,
                                keyboardType: TextInputType.phone,
                                validator: (value) {
                                  if (value == null || value.trim().isEmpty) {
                                    return 'Please enter contact number';
                                  }
                                  String cleaned = value.trim().replaceAll(
                                    RegExp(r'[\s\-]'),
                                    '',
                                  );

                                  if (!RegExp(r'^[0-9]+$').hasMatch(cleaned)) {
                                    return 'Only numbers allowed';
                                  }

                                  if (cleaned.length != 11) {
                                    return 'Must be 11 digits (03001234567)';
                                  }

                                  if (!cleaned.startsWith('03')) {
                                    return 'Must start with 03';
                                  }

                                  return null;
                                },
                              ),
                              SizedBox(height: 20),

                              // Info Box
                              Container(
                                padding: EdgeInsets.all(15),
                                decoration: BoxDecoration(
                                  color: Color(0xFFFF7043).withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: Color(0xFFFF7043).withOpacity(0.3),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.info_outline,
                                      color: Color(0xFFFF7043),
                                      size: 24,
                                    ),
                                    SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Your contact info will be shared with interested adopters only.',
                                        style: TextStyle(
                                          fontSize: 13,
                                          color: Color(0xFFFF7043),
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 40),

                              // Submit Button
                              _isLoading
                                  ? Center(
                                      child: Column(
                                        children: [
                                          CircularProgressIndicator(
                                            valueColor:
                                                AlwaysStoppedAnimation<Color>(
                                                  Color(0xFFFF7043),
                                                ),
                                          ),
                                          SizedBox(height: 15),
                                          Text(
                                            'Saving pet...',
                                            style: TextStyle(
                                              color: Color(0xFFFF7043),
                                              fontSize: 14,
                                            ),
                                          ),
                                        ],
                                      ),
                                    )
                                  : Container(
                                      width: double.infinity,
                                      height: 60,
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Color(0xFFFF7043),
                                            Color(0xFFFF5722),
                                          ],
                                        ),
                                        borderRadius: BorderRadius.circular(15),
                                        boxShadow: [
                                          BoxShadow(
                                            color: Color(
                                              0xFFFF7043,
                                            ).withOpacity(0.4),
                                            blurRadius: 15,
                                            offset: Offset(0, 8),
                                          ),
                                        ],
                                      ),
                                      child: ElevatedButton(
                                        onPressed: _savePet,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.transparent,
                                          shadowColor: Colors.transparent,
                                          shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(
                                              15,
                                            ),
                                          ),
                                        ),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Icon(Icons.check_circle, size: 24),
                                            SizedBox(width: 10),
                                            Text(
                                              widget.petToEdit == null
                                                  ? 'Post for Adoption'
                                                  : 'Save Changes',
                                              style: TextStyle(
                                                fontSize: 18,
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                                letterSpacing: 1.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                              SizedBox(height: 20),
                            ],
                          ),
                        ),
                      ),
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

  Widget _buildImageUploadWidget() {
    return GestureDetector(
      onTap: _showImageSourceDialog,
      child: Container(
        height: 220,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: _selectedImageFile != null
                ? Color(0xFFFF7043).withOpacity(0.5)
                : Colors.grey[300]!,
            width: 2,
          ),
        ),
        child: _selectedImageFile != null
            ? Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(18),
                    child: FutureBuilder<Uint8List>(
                      future: _selectedImageFile!.readAsBytes(),
                      builder: (context, snapshot) {
                        if (snapshot.hasData) {
                          return Image.memory(
                            snapshot.data!,
                            width: double.infinity,
                            height: double.infinity,
                            fit: BoxFit.cover,
                          );
                        }
                        return Center(child: CircularProgressIndicator());
                      },
                    ),
                  ),
                  Positioned(
                    top: 10,
                    right: 10,
                    child: Row(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 8),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(Icons.edit, color: Color(0xFFFF7043)),
                            onPressed: _showImageSourceDialog,
                            tooltip: 'Change photo',
                          ),
                        ),
                        SizedBox(width: 8),
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(color: Colors.black26, blurRadius: 8),
                            ],
                          ),
                          child: IconButton(
                            icon: Icon(Icons.close, color: Colors.red),
                            onPressed: () {
                              setState(() {
                                _selectedImageFile = null;
                              });
                            },
                            tooltip: 'Remove photo',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              )
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: Color(0xFFFF7043).withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.add_photo_alternate,
                      size: 50,
                      color: Color(0xFFFF7043),
                    ),
                  ),
                  SizedBox(height: 15),
                  Text(
                    'Add Pet Photo',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFF7043),
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Tap to upload from gallery or camera',
                    style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                  ),
                  SizedBox(height: 15),
                  Container(
                    padding: EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xFFFF7043), Color(0xFFFF5722)],
                      ),
                      borderRadius: BorderRadius.circular(25),
                    ),
                    child: Text(
                      'Choose Photo',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
