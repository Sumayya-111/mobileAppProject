import 'package:flutter/material.dart';
import '../data/dummy_data.dart' show categories;
import 'restaurant_detail_screen.dart';

class CategoryScreen extends StatefulWidget {
  final List<Map<String, dynamic>> restaurants;
  final String? selectedCategory; // optional — passed from home
  const CategoryScreen({
    super.key,
    required this.restaurants,
    this.selectedCategory,
  });

  @override
  State<CategoryScreen> createState() => _CategoryScreenState();
}

class _CategoryScreenState extends State<CategoryScreen> {
  late String _selected;

  @override
  void initState() {
    super.initState();
    // Use passed category or default to first one
    _selected = widget.selectedCategory ?? categories[0]['name'];
  }

  // Filter restaurants by selected category
  List<Map<String, dynamic>> get _filteredRestaurants {
    return widget.restaurants.where((r) => r['category'] == _selected).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text('Categories',
            style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        centerTitle: true,
        leading: widget.selectedCategory != null
            ? IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        )
            : null,
      ),
      body: Column(
        children: [
          // Horizontal scrollable category tabs
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: categories.map((cat) {
                  final isSelected = _selected == cat['name'];
                  return GestureDetector(
                    onTap: () => setState(() => _selected = cat['name']),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.only(right: 10),
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 10),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? Color(cat['color'])
                            : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(30),
                      ),
                      child: Row(
                        children: [
                          Text(cat['icon'],
                              style: const TextStyle(fontSize: 18)),
                          const SizedBox(width: 6),
                          Text(
                            cat['name'],
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : Colors.black87,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),

          const SizedBox(height: 12),

          // Restaurants list
          Expanded(
            child: _filteredRestaurants.isEmpty
                ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('😔', style: TextStyle(fontSize: 60)),
                  const SizedBox(height: 16),
                  const Text('No restaurants found',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Text('Try another category',
                      style: TextStyle(color: Colors.grey.shade500)),
                ],
              ),
            )
                : ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _filteredRestaurants.length,
              itemBuilder: (context, index) {
                final r = _filteredRestaurants[index];
                return GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (_) =>
                            RestaurantDetailScreen(restaurant: r)),
                  ),
                  child: Container(
                    margin: const EdgeInsets.only(bottom: 14),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.06),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        )
                      ],
                    ),
                    child: ListTile(
                      contentPadding: const EdgeInsets.all(14),
                      leading: ClipRRect(
                        borderRadius: BorderRadius.circular(12),
                        child: Image.network(
                          r['image'] ?? '',
                          width: 60,
                          height: 60,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: Color(r['color']).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(Icons.restaurant, color: Colors.grey),
                          ),
                        ),
                      ),
                      title: Text(r['name'],
                          style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16)),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 4),
                          Text(r['description'],
                              style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey)),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              const Icon(Icons.star,
                                  color: Colors.amber, size: 14),
                              Text(' ${r['rating']}  •  ',
                                  style: const TextStyle(
                                      fontSize: 12)),
                              const Icon(Icons.access_time,
                                  color: Colors.grey, size: 13),
                              Text(' ${r['deliveryTime']}',
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey)),
                            ],
                          ),
                        ],
                      ),
                      trailing: const Icon(
                          Icons.arrow_forward_ios,
                          size: 16,
                          color: Colors.grey),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
