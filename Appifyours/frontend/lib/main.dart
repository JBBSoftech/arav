import 'package:flutter/material.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
class AdminConfig {
  static const String adminId = '68e506e5be2e1b6030ae584f';
  static const String shopName = 'Arav';
  static const String backendUrl = 'https://appifyours-backend.onrender.com';
  static Future<void> storeUserData(Map<String, dynamic> userData) async {
    try {
      await http.post(
        Uri.parse('$backendUrl/api/store-user-data'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'adminId': adminId,
          'shopName': shopName,
          'userData': userData,
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      print('Error storing user data: $e');
    }
  }
  static Future<void> storeUserOrder({
    required String userId,
    required String orderId,
    required List<Map<String, dynamic>> products,
    required double totalOrderValue,
    required int totalQuantity,
    String? paymentMethod,
    String? paymentStatus,
    Map<String, dynamic>? shippingAddress,
    String? notes,
  }) async {
    try {
      await http.post(
        Uri.parse('$backendUrl/api/store-user-order'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'adminId': adminId,
          'userId': userId,
          'orderData': {
            'orderId': orderId,
            'products': products,
            'totalOrderValue': totalOrderValue,
            'totalQuantity': totalQuantity,
            'paymentMethod': paymentMethod,
            'paymentStatus': paymentStatus,
            'shippingAddress': shippingAddress,
            'notes': notes,
          },
        }),
      );
    } catch (e) {
      print('Error storing user order: $e');
    }
  }
  static Future<void> updateUserCart({
    required String userId,
    required List<Map<String, dynamic>> cartItems,
  }) async {
    try {
      await http.post(
        Uri.parse('$backendUrl/api/update-user-cart'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'adminId': adminId,
          'userId': userId,
          'cartItems': cartItems,
        }),
      );
    } catch (e) {
      print('Error updating user cart: $e');
    }
  }
  static Future<void> trackUserInteraction({
    required String userId,
    required String interactionType,
    String? target,
    Map<String, dynamic>? details,
  }) async {
    try {
      await storeUserData({
        'userId': userId,
        'interactions': [{
          'type': interactionType,
          'target': target,
          'details': details,
          'timestamp': DateTime.now().toIso8601String(),
        }],
      });
    } catch (e) {
      print('Error tracking user interaction: $e');
    }
  }
  static Future<void> registerUser({
    required String userId,
    required String name,
    required String email,
    String? phone,
    Map<String, dynamic>? address,
  }) async {
    try {
      await http.post(
        Uri.parse('$backendUrl/api/store-user-data'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'adminId': adminId,
          'shopName': shopName,
          'userData': {
            'userId': userId,
            'userInfo': {
              'name': name,
              'email': email,
              'phone': phone ?? '',
              'address': address ?? {},
              'preferences': {}
            },
            'orders': [],
            'cartItems': [],
            'wishlistItems': [],
            'interactions': [],
          },
          'timestamp': DateTime.now().toIso8601String(),
        }),
      );
    } catch (e) {
      print('Error registering user: $e');
    }
  }
  static Future<Map<String, dynamic>?> getDynamicConfig() async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/get-admin-config/$adminId'),
      );
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
    } catch (e) {
      print('Error getting dynamic config: $e');
    }
    return null;
  }
}
class PriceUtils {
  static String formatPrice(double price, {String currency = '$'}) {
    return '$currency${price.toStringAsFixed(2)}';
  }
  static double parsePrice(String priceString) {
    if (priceString.isEmpty) return 0.0;
    String numericString = priceString.replaceAll(RegExp(r'[^d.]'), '');
    return double.tryParse(numericString) ?? 0.0;
  }
  static String detectCurrency(String priceString) {
    if (priceString.contains('₹')) return '₹';
    if (priceString.contains('$')) return '$';
    if (priceString.contains('€')) return '€';
    if (priceString.contains('£')) return '£';
    if (priceString.contains('¥')) return '¥';
    if (priceString.contains('₩')) return '₩';
    if (priceString.contains('₽')) return '₽';
    if (priceString.contains('₦')) return '₦';
    if (priceString.contains('₨')) return '₨';
    return '$'; // Default to dollar
  }
  static double calculateDiscountPrice(double originalPrice, double discountPercentage) {
    return originalPrice * (1 - discountPercentage / 100);
  }
  static double calculateTotal(List<double> prices) {
    return prices.fold(0.0, (sum, price) => sum + price);
  }
  static double calculateTax(double subtotal, double taxRate) {
    return subtotal * (taxRate / 100);
  }
  static double applyShipping(double total, double shippingFee, {double freeShippingThreshold = 100.0}) {
    return total >= freeShippingThreshold ? total : total + shippingFee;
  }
}
class CartItem {
  final String id;
  final String name;
  final double price;
  final double discountPrice;
  int quantity;
  final String? image;
  CartItem({
    required this.id,
    required this.name,
    required this.price,
    this.discountPrice = 0.0,
    this.quantity = 1,
    this.image,
  });
  double get effectivePrice => discountPrice > 0 ? discountPrice : price;
  double get totalPrice => effectivePrice * quantity;
}
class CartManager extends ChangeNotifier {
  final List<CartItem> _items = [];
  List<CartItem> get items => List.unmodifiable(_items);
  void addItem(CartItem item) {
    final existingIndex = _items.indexWhere((i) => i.id == item.id);
    if (existingIndex >= 0) {
      _items[existingIndex].quantity += item.quantity;
    } else {
      _items.add(item);
    }
    notifyListeners();
  }
  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }
  void updateQuantity(String id, int quantity) {
    final item = _items.firstWhere((i) => i.id == id);
    item.quantity = quantity;
    notifyListeners();
  }
  void clear() {
    _items.clear();
    notifyListeners();
  }
  double get subtotal {
    return _items.fold(0.0, (sum, item) => sum + item.totalPrice);
  }
  double get totalWithTax {
    final tax = PriceUtils.calculateTax(subtotal, 8.0); // 8% tax
    return subtotal + tax;
  }
  double get finalTotal {
    return PriceUtils.applyShipping(totalWithTax, 5.99); // $5.99 shipping
  }
}
class WishlistItem {
  final String id;
  final String name;
  final double price;
  final double discountPrice;
  final String? image;
  WishlistItem({
    required this.id,
    required this.name,
    required this.price,
    this.discountPrice = 0.0,
    this.image,
  });
  double get effectivePrice => discountPrice > 0 ? discountPrice : price;
}
class WishlistManager extends ChangeNotifier {
  final List<WishlistItem> _items = [];
  List<WishlistItem> get items => List.unmodifiable(_items);
  void addItem(WishlistItem item) {
    if (!_items.any((i) => i.id == item.id)) {
      _items.add(item);
      notifyListeners();
    }
  }
  void removeItem(String id) {
    _items.removeWhere((item) => item.id == id);
    notifyListeners();
  }
  void clear() {
    _items.clear();
    notifyListeners();
  }
  bool isInWishlist(String id) {
    return _items.any((item) => item.id == id);
  }
}
final List<Map<String, dynamic>> productCards = [
  {
    'productName': 'Product Name',
    'imageAsset': 'data:image/png;base64,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',
    'price': '$299',
    'discountPrice': '$199',
  },
  {
    'productName': 'superburgur',
    'imageAsset': 'data:image/png;base64,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',
    'price': '250',
    'discountPrice': '60',
  }
];
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
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8))),
      inputDecorationTheme: InputDecorationTheme(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        filled: true, fillColor: Colors.grey.shade50,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16))),
    home: const HomePage(),
    debugShowCheckedModeBanner: false,
  );
}
class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}
class _HomePageState extends State<HomePage> {
  late PageController _pageController;
  int _currentPageIndex = 0;
  final CartManager _cartManager = CartManager();
  final WishlistManager _wishlistManager = WishlistManager();
  String _searchQuery = '';
  List<Map<String, dynamic>> _filteredProducts = [];
  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
    _filteredProducts = List.from(productCards);
  }
  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }
  void _onPageChanged(int index) => setState(() => _currentPageIndex = index);
  void _onItemTapped(int index) {
    setState(() => _currentPageIndex = index);
  }
  void _filterProducts(String query) {
    setState(() {
      _searchQuery = query;
      if (query.isEmpty) {
        _filteredProducts = List.from(productCards);
      } else {
        _filteredProducts = productCards.where((product) {
          final productName = (product['productName'] ?? '').toString().toLowerCase();
          final price = (product['price'] ?? '').toString().toLowerCase();
          final discountPrice = (product['discountPrice'] ?? '').toString().toLowerCase();
          final searchLower = query.toLowerCase();
          return productName.contains(searchLower) || 
                 price.contains(searchLower) || 
                 discountPrice.contains(searchLower);
        }).toList();
      }
    });
  }
  @override
  Widget build(BuildContext context) => Scaffold(
    body: IndexedStack(
      index: _currentPageIndex,
      children: [
        _buildHomePage(),
        _buildCartPage(),
        _buildWishlistPage(),
        _buildProfilePage(),
      ],
    ),
    bottomNavigationBar: _buildBottomNavigationBar(),
  );
  Widget _buildHomePage() {
    return Column(
      children: [
                  Container(
                    color: Color(0xff2196f3),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      children: [
                        const Icon(Icons.store, size: 32, color: Colors.white),
                        const SizedBox(width: 8),
                        Text(
                          'Appifyours',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 16,
                          ),
                        ),
                        const Spacer(),
                        Stack(
                          children: [
                            const Icon(Icons.shopping_cart, color: Colors.white, size: 20),
                            if (_cartManager.items.isNotEmpty)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '${_cartManager.items.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(width: 16),
                        Stack(
                          children: [
                            const Icon(Icons.favorite, color: Colors.white, size: 20),
                            if (_wishlistManager.items.isNotEmpty)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: const BoxDecoration(
                                    color: Colors.red,
                                    shape: BoxShape.circle,
                                  ),
                                  constraints: const BoxConstraints(
                                    minWidth: 16,
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '${_wishlistManager.items.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                    ),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      children: [
                        TextField(
                          onChanged: (searchQuery) {
                            setState(() {
                            });
                          },
                          decoration: InputDecoration(
                            hintText: 'search',
                            prefixIcon: const Icon(Icons.search),
                            suffixIcon: const Icon(Icons.filter_list),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(20),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade100,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            const Icon(Icons.info_outline, size: 16, color: Colors.grey),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                'Search by product name or price (e.g., "Product Name" or "$299")',
                                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                  Container(
                    height: 160,
                    child: Stack(
                      children: [
                        Container(color: Color(0xFFBDBDBD)),
                        Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'create your own app',
                                style: const TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                  shadows: [
                                    Shadow(
                                      blurRadius: 4.0,
                                      color: Colors.black,
                                      offset: Offset(1.0, 1.0),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton(
                                onPressed: () {},
                                style: ElevatedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                ),
                                child: Text('Creact now', style: const TextStyle(fontSize: 12)),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.all(12),
                    color: Color(0xFFFFFFFF),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 8),
                        GridView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: 2,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.75,
                          ),
                          itemCount: 2,
                          itemBuilder: (context, index) {
                            final product = productCards[index];
                            final productId = 'product_$index';
                            final isInWishlist = _wishlistManager.isInWishlist(productId);
                            return Card(
                              elevation: 3,
                              color: Color(0xFFFFFFFF),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: Stack(
                                      children: [
                                        Container(
                                          width: double.infinity,
                                          decoration: BoxDecoration(
                                            borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                                          ),
                                          child:                                           product['imageAsset'] != null
                                              ? Image.network(
                                                  product['imageAsset'],
                                                  width: double.infinity,
                                                  height: double.infinity,
                                                  fit: BoxFit.cover,
                                                )
                                              : Container(
                                            color: Colors.grey[300],
                                            child: const Icon(Icons.image, size: 40),
                                          )
                                          ,
                                        ),
                                        Positioned(
                                          top: 8,
                                          right: 8,
                                          child: IconButton(
                                            onPressed: () {
                                              if (isInWishlist) {
                                                _wishlistManager.removeItem(productId);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Removed from wishlist')),
                                                );
                                              } else {
                                                final wishlistItem = WishlistItem(
                                                  id: productId,
                                                  name: product['productName'] ?? 'Product',
                                                  price: double.tryParse(product['price']?.replaceAll('$', '') ?? '0') ?? 0.0,
                                                  discountPrice: product['discountPrice'] != null && product['discountPrice'].isNotEmpty
                                                      ? double.tryParse(product['discountPrice'].replaceAll('$', '')) ?? 0.0
                                                      : 0.0,
                                                  image: product['imageAsset'],
                                                );
                                                _wishlistManager.addItem(wishlistItem);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Added to wishlist')),
                                                );
                                              }
                                            },
                                            icon: Icon(
                                              isInWishlist ? Icons.favorite : Icons.favorite_border,
                                              color: isInWishlist ? Colors.red : Colors.grey,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            product['productName'] ?? 'Product Name',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 14,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              Text(
                                                PriceUtils.formatPrice(
                                                                                                    product['discountPrice'] != null && product['discountPrice'].isNotEmpty
                                                      ? PriceUtils.parsePrice(product['discountPrice'])
                                                      : PriceUtils.parsePrice(product['price'] ?? '0')
                                                  ,
                                                  currency:                                                   product['discountPrice'] != null && product['discountPrice'].isNotEmpty
                                                      ? PriceUtils.detectCurrency(product['discountPrice'])
                                                      : PriceUtils.detectCurrency(product['price'] ?? '$0')
                                                ),
                                                style: TextStyle(
                                                  fontSize: 14,
                                                  fontWeight: FontWeight.bold,
                                                  color: product['discountPrice'] != null ? Colors.blue : Colors.black,
                                                ),
                                              ),
                                                                                            if (product['discountPrice'] != null && product['price'] != null)
                                                Padding(
                                                  padding: const EdgeInsets.only(left: 6.0),
                                                  child: Text(
                                                    PriceUtils.formatPrice(PriceUtils.parsePrice(product['price'] ?? '0'), currency: PriceUtils.detectCurrency(product['price'] ?? '$0')),
                                                    style: TextStyle(
                                                      fontSize: 12,
                                                      decoration: TextDecoration.lineThrough,
                                                      color: Colors.grey.shade600,
                                                    ),
                                                  ),
                                                ),
                                            ],
                                          ),
                                          const SizedBox(height: 8),
                                          Row(
                                            children: [
                                              Icon(Icons.star, color: Colors.amber, size: 14),
                                              Icon(Icons.star, color: Colors.amber, size: 14),
                                              Icon(Icons.star, color: Colors.amber, size: 14),
                                              Icon(Icons.star, color: Colors.amber, size: 14),
                                              Icon(Icons.star_border, color: Colors.amber, size: 14),
                                              const SizedBox(width: 4),
                                              Text(
                                                product['rating'] ?? '4.0',
                                                style: const TextStyle(fontSize: 12),
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
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
  Widget _buildCartPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Shopping Cart'),
        automaticallyImplyLeading: false,
      ),
      body: _cartManager.items.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Your cart is empty', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    itemCount: _cartManager.items.length,
                    itemBuilder: (context, index) {
                      final item = _cartManager.items[index];
                      return Card(
                        margin: const EdgeInsets.all(8),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 60,
                                height: 60,
                                color: Colors.grey[300],
                                child: const Icon(Icons.image),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(item.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                                    Text(PriceUtils.formatPrice(item.effectivePrice)),
                                  ],
                                ),
                              ),
                              Row(
                                children: [
                                  IconButton(
                                    onPressed: () {
                                      if (item.quantity > 1) {
                                        _cartManager.updateQuantity(item.id, item.quantity - 1);
                                      } else {
                                        _cartManager.removeItem(item.id);
                                      }
                                    },
                                    icon: const Icon(Icons.remove),
                                  ),
                                  Text('${item.quantity}', style: const TextStyle(fontSize: 16)),
                                  IconButton(
                                    onPressed: () {
                                      _cartManager.updateQuantity(item.id, item.quantity + 1);
                                    },
                                    icon: const Icon(Icons.add),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    border: const Border(top: BorderSide(color: Colors.grey)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Subtotal:', style: TextStyle(fontSize: 16)),
                          Text(PriceUtils.formatPrice(_cartManager.subtotal), style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Tax (8%):', style: TextStyle(fontSize: 16)),
                          Text(PriceUtils.formatPrice(PriceUtils.calculateTax(_cartManager.subtotal, 8.0)), style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Shipping:', style: TextStyle(fontSize: 16)),
                          Text(PriceUtils.formatPrice(5.99), style: const TextStyle(fontSize: 16)),
                        ],
                      ),
                      const Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text('Total:', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                          Text(PriceUtils.formatPrice(_cartManager.finalTotal), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: () {},
                          child: const Text('Checkout'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }
  Widget _buildWishlistPage() {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Wishlist'),
        automaticallyImplyLeading: false,
      ),
      body: _wishlistManager.items.isEmpty
          ? const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.favorite_border, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('Your wishlist is empty', style: TextStyle(fontSize: 18, color: Colors.grey)),
                ],
              ),
            )
          : ListView.builder(
              itemCount: _wishlistManager.items.length,
              itemBuilder: (context, index) {
                final item = _wishlistManager.items[index];
                return Card(
                  margin: const EdgeInsets.all(8),
                  child: ListTile(
                    leading: Container(
                      width: 50,
                      height: 50,
                      color: Colors.grey[300],
                      child: const Icon(Icons.image),
                    ),
                    title: Text(item.name),
                    subtitle: Text(PriceUtils.formatPrice(item.effectivePrice)),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          onPressed: () {
                            final cartItem = CartItem(
                              id: item.id,
                              name: item.name,
                              price: item.price,
                              discountPrice: item.discountPrice,
                              image: item.image,
                            );
                            _cartManager.addItem(cartItem);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Added to cart')),
                            );
                          },
                          icon: const Icon(Icons.shopping_cart),
                        ),
                        IconButton(
                          onPressed: () {
                            _wishlistManager.removeItem(item.id);
                          },
                          icon: const Icon(Icons.delete, color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
  Widget _buildProfilePage() {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text('Profile Page', style: TextStyle(fontSize: 18)),
          ],
        ),
      ),
    );
  }
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      type: BottomNavigationBarType.fixed,
      currentIndex: _currentPageIndex,
      onTap: _onItemTapped,
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              const Icon(Icons.shopping_cart),
              if (_cartManager.items.isNotEmpty)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_cartManager.items.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          label: 'Cart',
        ),
        BottomNavigationBarItem(
          icon: Stack(
            children: [
              const Icon(Icons.favorite),
              if (_wishlistManager.items.isNotEmpty)
                Positioned(
                  right: 0,
                  top: 0,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    child: Text(
                      '${_wishlistManager.items.length}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          label: 'Wishlist',
        ),
        const BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
  Widget _buildBottomNavigationBar() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -1),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
                                GestureDetector(
                    onTap: () => _onItemTapped(0),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                                                Icon(
                          Icons.home,
                          color: _currentPageIndex == 0 ? Colors.blue : Colors.grey,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Home',
                          style: TextStyle(
                            color: _currentPageIndex == 0 ? Colors.blue : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _onItemTapped(1),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                                                Stack(
                          children: [
                            Icon(
                              Icons.shopping_cart,
                              color: _currentPageIndex == 1 ? Colors.blue : Colors.grey,
                            ),
                            if (_cartManager.items.isNotEmpty)
                              Positioned(
                                right: 0,
                                top: 0,
                                child: Container(
                                  padding: const EdgeInsets.all(2),
                                  decoration: BoxDecoration(
                                    color: Colors.red,
                                    borderRadius: BorderRadius.circular(10),
                                    minHeight: 16,
                                  ),
                                  child: Text(
                                    '${_cartManager.items.length}',
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Cart',
                          style: TextStyle(
                            color: _currentPageIndex == 1 ? Colors.blue : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _onItemTapped(2),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                                                Icon(
                          Icons.favorite,
                          color: _currentPageIndex == 2 ? Colors.blue : Colors.grey,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Wishlist',
                          style: TextStyle(
                            color: _currentPageIndex == 2 ? Colors.blue : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: () => _onItemTapped(3),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                                                Icon(
                          Icons.person,
                          color: _currentPageIndex == 3 ? Colors.blue : Colors.grey,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Profile',
                          style: TextStyle(
                            color: _currentPageIndex == 3 ? Colors.blue : Colors.grey,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
            ],
          ),
        ),
      ),
    );
  }