import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Generated E-commerce App',
    theme: ThemeData(
        primarySwatch: Colors.blue,
        useMaterial3: true,
        brightness: Brightness.light,
        appBarTheme: const AppBarTheme(
            elevation: 4, shadowColor: Colors.black38, color: Colors.blue, foregroundColor: Colors.white),
        cardTheme: CardThemeData(
            elevation: 3, shadowColor: Colors.black12,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
        elevatedButtonTheme: ElevatedButtonThemeData(
            style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                backgroundColor: Colors.blue)),
        inputDecorationTheme: InputDecorationTheme(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            filled: true, fillColor: Colors.grey.shade50,
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16))),
    home: const HomePage(),
    debugShowCheckedModeBanner: false,
  );
}

class Product {
  final String id;
  final String name;
  final String description;
  final double originalPrice;
  final double? discountPercentage;
  final String imageUrl;
  bool isInWishlist;
  int quantity;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.originalPrice,
    this.discountPercentage,
    required this.imageUrl,
    this.isInWishlist = false,
    this.quantity = 1,
  });

  double get discountedPrice {
    if (discountPercentage != null) {
      return originalPrice * (1 - discountPercentage! / 100);
    }
    return originalPrice;
  }

  factory Product.fromJson(Map<String, dynamic> json) {
    return Product(
      id: json['_id'],
      name: json['name'],
      description: json['description'],
      originalPrice: json['originalPrice'].toDouble(),
      discountPercentage: json['discountPercentage']?.toDouble(),
      imageUrl: json['imageUrl'],
      isInWishlist: json['isInWishlist'] ?? false,
      quantity: json['quantity'] ?? 1,
    );
  }
}

class ProductService {
  static Future<List<Product>> fetchProducts() async {
    final response = await http.get(Uri.parse('http://localhost:5000/api/products'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<Product> products = body.map((dynamic item) => Product.fromJson(item)).toList();
      return products;
    } else {
      throw Exception('Failed to load products');
    }
  }
}

class WishlistService {
  static Future<void> addToWishlist(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? 'default_user';

    final response = await http.post(
      Uri.parse('http://localhost:5000/api/wishlist'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'productId': productId}),
    );

    if (response.statusCode != 201) {
      throw Exception('Failed to add to wishlist');
    }
  }

  static Future<void> removeFromWishlist(String productId) async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? 'default_user';

    final response = await http.delete(
      Uri.parse('http://localhost:5000/api/wishlist'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'userId': userId, 'productId': productId}),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to remove from wishlist');
    }
  }

  static Future<List<Product>> getWishlist() async {
    final prefs = await SharedPreferences.getInstance();
    final userId = prefs.getString('userId') ?? 'default_user';

    final response = await http.get(Uri.parse('http://localhost:5000/api/wishlist/$userId'));
    if (response.statusCode == 200) {
      List<dynamic> body = jsonDecode(response.body);
      List<Product> products = body.map((dynamic item) => Product.fromJson(item)).toList();
      return products;
    } else {
      throw Exception('Failed to load wishlist');
    }
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _searchTerm = '';
  late Future<List<Product>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = ProductService.fetchProducts();
  }

  void _updateSearchTerm(String term) {
    setState(() {
      _searchTerm = term;
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: FutureBuilder<List<Product>>(
      future: _productsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const Center(child: Text('No products found'));
        } else {
          List<Product> filteredProducts = snapshot.data!.where((product) {
            final name = product.name.toLowerCase();
            final description = product.description.toLowerCase();
            return name.contains(_searchTerm.toLowerCase()) || 
                   description.contains(_searchTerm.toLowerCase());
          }).toList();
          
          return SingleChildScrollView(
            child: Column(
              children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Search products',
              prefixIcon: const Icon(Icons.search),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
              ),
            ),
            onChanged: (value) async {
              if (value.isNotEmpty) {
                final searchResults = await ProductService.fetchProducts(search: value);
                setState(() {
                  products = searchResults;
                });
              } else {
                _loadProducts();
              }
            },
          ),
        ),
                Container(
          padding: const EdgeInsets.all(16.0),
          color: Colors.grey[200],
          child: const Text('Widget: ProductGridWidget'),
        ),
                Container(
          padding: const EdgeInsets.all(16.0),
          color: Colors.grey[200],
          child: const Text('Widget: ImageSliderWidget'),
        ),
                        ProductGridWidget(
                  products: filteredProducts,
                  searchTerm: _searchTerm,
                  onSearchChanged: _updateSearchTerm,
                ),
              ],
            ),
          );
        }
      },
    ),
  );
}

class ProductGridWidget extends StatelessWidget {
  final List<Product> products;
  final String searchTerm;
  final Function(String) onSearchChanged;

  const ProductGridWidget({
    super.key,
    required this.products,
    required this.searchTerm,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'All Products',
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          if (products.isEmpty)
            const Center(child: Text('No products found'))
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 0.55,
              ),
              itemCount: products.length,
              itemBuilder: (context, index) {
                final product = products[index];
                return Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(
                        height: 120,
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                              child: Image.network(
                                product.imageUrl,
                                width: double.infinity,
                                height: 120,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) => Container(
                                  color: Colors.grey[300],
                                  child: const Icon(Icons.image, size: 40),
                                ),
                              ),
                            ),
                            if (product.discountPercentage != null)
                              Positioned(
                                top: 6,
                                left: 6,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  child: Text(
                                    '${product.discountPercentage}% OFF',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                            Positioned(
                              top: 6,
                              right: 6,
                              child: GestureDetector(
                                onTap: () async {
                                  if (product.isInWishlist) {
                                    await WishlistService.removeFromWishlist(product.id);
                                  } else {
                                    await WishlistService.addToWishlist(product.id);
                                  }
                                },
                                child: Container(
                                  padding: const EdgeInsets.all(3),
                                  decoration: BoxDecoration(
                                    color: Colors.white.withOpacity(0.7),
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    product.isInWishlist ? Icons.favorite : Icons.favorite_border,
                                    color: Colors.red,
                                    size: 16,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(6.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                product.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 12,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 3),
                              Text(
                                product.description,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.grey.shade600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 6),
                              Row(
                                children: [
                                  Text(
                                    '\$${product.discountedPrice.toStringAsFixed(2)}',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: product.discountPercentage != null ? Colors.blue : Colors.black,
                                    ),
                                  ),
                                  if (product.originalPrice != product.discountedPrice)
                                    Padding(
                                      padding: const EdgeInsets.only(left: 6.0),
                                      child: Text(
                                        '\$${product.originalPrice.toStringAsFixed(2)}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          decoration: TextDecoration.lineThrough,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
                                    ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}
