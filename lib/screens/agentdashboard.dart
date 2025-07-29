import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;

class AgentDashboard extends StatefulWidget {
  const AgentDashboard({super.key});

  @override
  State<AgentDashboard> createState() => _AgentDashboardState();
}

class _AgentDashboardState extends State<AgentDashboard> {
  final _formKey = GlobalKey<FormState>();
  final TextEditingController _addressController = TextEditingController();
  final TextEditingController _contactNumberController =
      TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _priceController = TextEditingController();

  String? _selectedType;
  String? _selectedBedrooms;
  String? _selectedLocation;
  String _selectedMode = 'Rent';

  dynamic _selectedImage;

  String? _uploadedImageUrl;

  final List<String> _types = [
    'Bungalow',
    'Apartment',
    'Plot',
    'Portion',
    'Villa',
  ];
  final List<String> _bedroomOptions = ['1', '2', '3', '4', '5+'];
  final List<String> _locations = [
    'Scheme 33',
    'North Nazimabad',
    'Gulshan-e-Iqbal',
    'DHA Karachi',
    'Clifton',
  ];
  final List<String> _modeOptions = ['Rent', 'Buy'];

  final picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    return Scaffold(
      appBar: AppBar(title: const Text('Agent Dashboard')),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            const DrawerHeader(
              decoration: BoxDecoration(color: Colors.blue),
              child: Text(
                'Menu',
                style: TextStyle(color: Colors.white, fontSize: 24),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add Property'),
              onTap: () {
                Navigator.pop(context);
                _showAddPropertyDialog(context, user?.uid ?? '');
              },
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          const SizedBox(height: 12),
          const Divider(thickness: 1),
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Your Listed Properties',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('properties')
                  .where('agentId', isEqualTo: user?.uid ?? '')
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData)
                  return const Center(child: CircularProgressIndicator());

                final docs = snapshot.data!.docs;
                if (docs.isEmpty)
                  return const Center(child: Text('No properties added yet.'));

                return ListView.builder(
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    final data = docs[index].data() as Map<String, dynamic>;
                    final docId = docs[index].id;

                    return Card(
                      margin: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      child: ListTile(
                        leading:
                            data['image'] != null &&
                                data['image'].toString().isNotEmpty
                            ? Image.network(
                                data['image'],
                                width: 60,
                                height: 60,
                                fit: BoxFit.cover,
                              )
                            : const Icon(Icons.home),
                        title: Text(data['type'] ?? ''),
                        subtitle: Text(
                          '${data['mode']} - Rs. ${data['price']}',
                        ),
                        trailing: IconButton(
                          icon: const Icon(Icons.delete, color: Colors.red),
                          onPressed: () => _deleteProperty(docId),
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _showAddPropertyDialog(BuildContext context, String agentId) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Add Property'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                _buildDropdown(
                  'Type',
                  _types,
                  _selectedType,
                  (v) => setState(() => _selectedType = v),
                ),
                _buildDropdown(
                  'Bedrooms',
                  _bedroomOptions,
                  _selectedBedrooms,
                  (v) => setState(() => _selectedBedrooms = v),
                ),
                _buildDropdown(
                  'Location',
                  _locations,
                  _selectedLocation,
                  (v) => setState(() => _selectedLocation = v),
                ),
                _buildDropdown(
                  'Mode',
                  _modeOptions,
                  _selectedMode,
                  (v) => setState(() => _selectedMode = v ?? 'Rent'),
                ),
                _buildTextField(_priceController, 'Price', isNumber: true),
                const SizedBox(height: 10),
                _selectedImage != null
                    ? Image.file(_selectedImage!, height: 100)
                    : const Text("No image selected"),
                ElevatedButton.icon(
                  icon: const Icon(Icons.image),
                  label: const Text("Select Image"),
                  onPressed: _pickImage,
                ),
                _buildTextField(_addressController, 'Address'),
                _buildTextField(_contactNumberController, 'Contact Number'),
                _buildTextField(
                  _descriptionController,
                  'Description',
                  maxLines: 3,
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => _submitProperty(agentId),
            child: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Future<void> _pickImage() async {
    if (kIsWeb) {
      // For Web
      final fromWeb = await ImagePickerWeb.getImageAsBytes();
      if (fromWeb != null) {
        setState(() {
          _selectedImage = File.fromRawPath(
            fromWeb,
          ); // Used for Firebase upload
          _uploadedImageUrl = null;
        });
      }
    } else {
      // For Mobile
      final picked = await picker.pickImage(source: ImageSource.gallery);
      if (picked != null) {
        setState(() {
          _selectedImage = File(picked.path);
          _uploadedImageUrl = null;
        });
      }
    }
  }

  Future<void> _submitProperty(String agentId) async {
    if (!_formKey.currentState!.validate()) return;

    String imageUrl = '';
    if (_selectedImage != null) {
      final fileName =
          'properties/${DateTime.now().millisecondsSinceEpoch}.jpg';
      final storageRef = FirebaseStorage.instance.ref().child(fileName);
      UploadTask uploadTask;

      if (kIsWeb) {
        final webImage = await _selectedImage!.readAsBytes();
        uploadTask = storageRef.putData(webImage);
      } else {
        uploadTask = storageRef.putFile(_selectedImage!);
      }

      final snapshot = await uploadTask;
      imageUrl = await snapshot.ref.getDownloadURL();
    }

    final propertyData = {
      'type': _selectedType,
      'bedrooms': _selectedBedrooms,
      'location': _selectedLocation,
      'mode': _selectedMode,
      'price': int.tryParse(_priceController.text) ?? 0,
      'image': imageUrl,
      'address': _addressController.text.trim(),
      'contactNumber': _contactNumberController.text.trim(),
      'description': _descriptionController.text.trim(),
      'agentId': agentId,
      'createdAt': Timestamp.now(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('properties')
          .add(propertyData);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Property added successfully')),
        );
      }
      _clearForm();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error adding property: $e')));
      }
    }
  }

  Future<void> _deleteProperty(String docId) async {
    try {
      await FirebaseFirestore.instance
          .collection('properties')
          .doc(docId)
          .delete();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Property deleted')));
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error deleting property: $e')));
    }
  }

  void _clearForm() {
    _addressController.clear();
    _contactNumberController.clear();
    _descriptionController.clear();
    _priceController.clear();
    _selectedType = null;
    _selectedBedrooms = null;
    _selectedLocation = null;
    _selectedMode = 'Rent';
    _selectedImage = null;
    setState(() {});
  }
}
