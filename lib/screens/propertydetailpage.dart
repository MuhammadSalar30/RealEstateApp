import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PropertyDetailPage extends StatefulWidget {
  final Map<String, dynamic> data;
  const PropertyDetailPage({super.key, required this.data});
  @override
  State<PropertyDetailPage> createState() => _PropertyDetailPageState();
}

class _PropertyDetailPageState extends State<PropertyDetailPage> {
  bool isFavorited = false;
  @override
  void initState() {
    super.initState();
    checkFavoriteStatus();
  }

  Future<void> checkFavoriteStatus() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final snapshot = await FirebaseFirestore.instance
        .collection('favorites')
        .where('userId', isEqualTo: currentUser.uid)
        .where('propertyId', isEqualTo: widget.data['id'])
        .get();

    if (snapshot.docs.isNotEmpty) {
      setState(() {
        isFavorited = true;
      });
    }
  }

  void _toggleFavorite() async {
    final currentUser = FirebaseAuth.instance.currentUser;
    if (currentUser == null) return;

    final favoritesRef = FirebaseFirestore.instance.collection('favorites');
    final propertyId = widget.data['id'];

    final snapshot = await favoritesRef
        .where('userId', isEqualTo: currentUser.uid)
        .where('propertyId', isEqualTo: propertyId)
        .get();

    if (snapshot.docs.isNotEmpty) {
      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }
      setState(() => isFavorited = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Removed from Favorites')));
    } else {
      await favoritesRef.add({
        'userId': currentUser.uid,
        'propertyId': propertyId,
        'title': widget.data['title'] ?? '',
        'type': widget.data['type'] ?? '',
        'location': widget.data['location'] ?? '',
        'image': widget.data['image'] ?? '',
        'addedAt': FieldValue.serverTimestamp(),
      });
      setState(() => isFavorited = true);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Added to Favorites')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = widget.data['image']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.data['type'] ?? 'Property Details'),
        backgroundColor: Colors.blue.shade700,
        actions: [
          IconButton(
            icon: Icon(
              isFavorited ? Icons.favorite : Icons.favorite_border,
              color: Colors.red,
            ),
            onPressed: _toggleFavorite,
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Property Image
            Container(
              height: 220,
              width: double.infinity,
              decoration: BoxDecoration(color: Colors.grey[200]),
              child: imageUrl.isNotEmpty
                  ? Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (context, error, stackTrace) =>
                          const Center(
                            child: Icon(Icons.broken_image, size: 60),
                          ),
                    )
                  : const Center(child: Icon(Icons.home, size: 60)),
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      _buildDetailRow(
                        Icons.category,
                        'Type',
                        widget.data['type'],
                      ),
                      _buildDetailRow(
                        Icons.attach_money,
                        'Price',
                        'Rs. ${widget.data['price']}',
                      ),
                      _buildDetailRow(
                        Icons.assignment,
                        'Mode',
                        widget.data['mode'],
                      ),
                      _buildDetailRow(
                        Icons.location_on,
                        'Location',
                        widget.data['location'],
                      ),
                      if (widget.data['bedrooms'] != null)
                        _buildDetailRow(
                          Icons.bed,
                          'Bedrooms',
                          widget.data['bedrooms'].toString(),
                        ),
                      if (widget.data['address'] != null)
                        _buildDetailRow(
                          Icons.map,
                          'Address',
                          widget.data['address'],
                        ),
                      if (widget.data['contactNumber'] != null)
                        _buildDetailRow(
                          Icons.phone,
                          'Contact',
                          widget.data['contactNumber'],
                        ),
                      const SizedBox(height: 12),
                      if (widget.data['description'] != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Description',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              widget.data['description'],
                              style: const TextStyle(
                                fontSize: 15,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue.shade700,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 12,
                  ),
                ),
                icon: const Icon(Icons.calendar_today),
                label: const Text("Schedule a Visit"),
                onPressed: () {
                  _showScheduleDialog(context);
                },
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(IconData icon, String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.blue.shade700),
          const SizedBox(width: 8),
          Text('$label:', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              value ?? '-',
              style: const TextStyle(fontSize: 15),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  void _showScheduleDialog(BuildContext context) {
    DateTime? selectedDate;
    String selectedSlot = '10:00 AM - 11:00 AM';
    String contactNumber = '';
    final slots = [
      '10:00 AM - 11:00 AM',
      '12:00 PM - 1:00 PM',
      '2:00 PM - 3:00 PM',
      '4:00 PM - 5:00 PM',
      '6:00 PM - 7:00 PM',
    ];

    showDialog(
      context: context,
      builder: (_) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: const Text('Schedule Visit'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('Select Date:'),
                const SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () async {
                    final pickedDate = await showDatePicker(
                      context: context,
                      firstDate: DateTime.now(),
                      lastDate: DateTime.now().add(const Duration(days: 30)),
                      initialDate: DateTime.now(),
                    );
                    if (pickedDate != null) {
                      setState(() {
                        selectedDate = pickedDate;
                      });
                    }
                  },
                  child: Text(
                    selectedDate == null
                        ? 'Pick Date'
                        : DateFormat('yyyy-MM-dd').format(selectedDate!),
                  ),
                ),
                const SizedBox(height: 12),
                const Text('Select Time Slot:'),
                DropdownButton<String>(
                  value: selectedSlot,
                  isExpanded: true,
                  items: slots.map((slot) {
                    return DropdownMenuItem(value: slot, child: Text(slot));
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => selectedSlot = value);
                    }
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  decoration: const InputDecoration(
                    labelText: 'Contact Number',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.phone,
                  onChanged: (value) => contactNumber = value,
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (selectedDate != null) {
                    final currentUser = FirebaseAuth.instance.currentUser;
                    await FirebaseFirestore.instance
                        .collection('scheduled_visits')
                        .add({
                          'propertyId': widget.data['id'] ?? '',
                          'propertyTitle':
                              widget.data['title'] ?? widget.data['type'] ?? '',
                          'propertyType': widget.data['type'] ?? '',
                          'propertyLocation': widget.data['location'] ?? '',
                          'visitDate': DateFormat(
                            'yyyy-MM-dd',
                          ).format(selectedDate!),
                          'timeSlot': selectedSlot,
                          'contactNumber': contactNumber,
                          'scheduledAt': FieldValue.serverTimestamp(),
                          'userId': currentUser?.uid ?? 'anonymous',
                        });
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Visit scheduled for ${DateFormat('yyyy-MM-dd').format(selectedDate!)} at $selectedSlot',
                        ),
                      ),
                    );
                  }
                },
                child: const Text('Confirm'),
              ),
            ],
          ),
        );
      },
    );
  }
}
