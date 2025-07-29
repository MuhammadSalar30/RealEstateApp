import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:project/screens/favourites.dart';
import 'package:project/screens/profilepage.dart';
import 'package:project/screens/propertydetailpage.dart';
import 'package:project/screens/homepage.dart';

class PropertyListings extends StatefulWidget {
  const PropertyListings({super.key});

  @override
  State<PropertyListings> createState() => _PropertyListingsState();
}

class _PropertyListingsState extends State<PropertyListings> {
  String selectedMode = 'All';
  String selectedType = 'All';
  String selectedBedrooms = 'All';
  String selectedLocation = 'All';
  int navBarIndex = 1;

  final List<String> types = [
    'All',
    'Bungalow',
    'Villa',
    'Apartment',
    'Plot',
    'Portion',
  ];

  final List<String> bedrooms = ['All', '1', '2', '3', '4', '5+'];

  final List<String> locations = [
    'All',
    'Scheme 33',
    'North Nazimabad',
    'Gulshan-e-Iqbal',
    'DHA Karachi',
    'Clifton',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Property Listings'),
        backgroundColor: Colors.blue.shade700,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(200),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildDropdown(
                      'Mode',
                      ['All', 'Rent', 'Buy'],
                      selectedMode,
                      (v) => setState(() => selectedMode = v!),
                    ),
                    _buildDropdown(
                      'Type',
                      types,
                      selectedType,
                      (v) => setState(() => selectedType = v!),
                    ),
                  ],
                ),
                Row(
                  children: [
                    _buildDropdown(
                      'Bedrooms',
                      bedrooms,
                      selectedBedrooms,
                      (v) => setState(() => selectedBedrooms = v!),
                    ),
                    _buildDropdown(
                      'Area',
                      locations,
                      selectedLocation,
                      (v) => setState(() => selectedLocation = v!),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance.collection('properties').snapshots(),
        builder: (ctx, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final all = snap.data!.docs
              .map((d) => d.data() as Map<String, dynamic>)
              .toList();

          final filtered = all.where((p) {
            if (selectedMode != 'All' &&
                (p['mode']?.toString().toLowerCase() ?? '') !=
                    selectedMode.toLowerCase())
              return false;

            if (selectedType != 'All' &&
                (p['type']?.toString().toLowerCase() ?? '') !=
                    selectedType.toLowerCase())
              return false;

            if (selectedBedrooms != 'All') {
              final br = p['bedrooms']?.toString() ?? '';
              if (selectedBedrooms == '5+') {
                if (int.tryParse(br) == null || int.parse(br) < 5) {
                  return false;
                }
              } else if (br != selectedBedrooms) {
                return false;
              }
            }

            if (selectedLocation != 'All' &&
                (p['location']?.toString().toLowerCase() ?? '') !=
                    selectedLocation.toLowerCase())
              return false;

            return true;
          }).toList();

          if (filtered.isEmpty) {
            return const Center(child: Text('No properties found.'));
          }

          return Padding(
            padding: const EdgeInsets.all(8.0),
            child: GridView.builder(
              itemCount: filtered.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 0.6,
              ),
              itemBuilder: (ctx, i) {
                final p = filtered[i];

                return GestureDetector(
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PropertyDetailPage(data: p),
                      ),
                    );
                  },
                  child: Card(
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(8),
                            ),
                            child: Container(
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: Colors.grey[200],
                              ),
                              child:
                                  p['image'] != null &&
                                      p['image'].toString().startsWith('http')
                                  ? Image.network(
                                      p['image'],
                                      fit: BoxFit.cover,
                                      errorBuilder: (_, __, ___) =>
                                          const Center(
                                            child: Icon(
                                              Icons.broken_image,
                                              size: 40,
                                            ),
                                          ),
                                    )
                                  : const Center(
                                      child: Icon(Icons.home, size: 40),
                                    ),
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.all(4),
                          child: Text(
                            p['type'] ?? '',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            'Rs ${p['price']}',
                            style: const TextStyle(
                              color: Colors.green,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 4),
                          child: Text(
                            p['mode'] ?? '',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.blue.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: navBarIndex,
        selectedItemColor: Colors.blue.shade700,
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => navBarIndex = index);
          if (index == 0) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const HomePage()),
            );
          } else if (index == 2) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const FavoritesPage()),
            );
          } else if (index == 3) {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const ProfilePage()),
            );
          }
        },
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: "Home"),
          BottomNavigationBarItem(
            icon: Icon(Icons.apartment),
            label: "Properties",
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.favorite),
            label: "Favourites",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profile"),
        ],
      ),
    );
  }

  Widget _buildDropdown(
    String label,
    List<String> items,
    String current,
    ValueChanged<String?> onChanged,
  ) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        child: InputDecorator(
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: current,
              items: items
                  .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                  .toList(),
              onChanged: onChanged,
              isExpanded: true,
            ),
          ),
        ),
      ),
    );
  }
}
