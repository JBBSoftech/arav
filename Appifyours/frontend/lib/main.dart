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
    if (priceString.contains('â‚¹')) return 'â‚¹';
    if (priceString.contains('$')) return '$';
    if (priceString.contains('â‚¬')) return 'â‚¬';
    if (priceString.contains('Â£')) return 'Â£';
    if (priceString.contains('Â¥')) return 'Â¥';
    if (priceString.contains('â‚©')) return 'â‚©';
    if (priceString.contains('â‚½')) return 'â‚½';
    if (priceString.contains('â‚¦')) return 'â‚¦';
    if (priceString.contains('â‚¨')) return 'â‚¨';
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
    'productName': 'Burgur',
    'imageAsset': 'data:image/png;base64,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',
    'price': '200',
    'discountPrice': '50%',
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
                          'jee',
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
                            hintText: 'Search products by name or price',
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
                                              ? (product['imageAsset'] != null && product['imageAsset'].isNotEmpty
                                              ? (product['imageAsset'].startsWith('data:image/')
                                                  ? Image.memory(
                                                      base64Decode(product['imageAsset'].split(',')[1]),
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) => Container(
                                                        color: Colors.grey[300],
                                                        child: const Icon(Icons.image, size: 40, color: Colors.grey),
                                                      ),
                                                    )
                                                  : Image.network(
                                                      product['imageAsset'],
                                                      width: double.infinity,
                                                      height: double.infinity,
                                                      fit: BoxFit.cover,
                                                      errorBuilder: (context, error, stackTrace) => Container(
                                                        color: Colors.grey[300],
                                                        child: const Icon(Icons.image, size: 40, color: Colors.grey),
                                                      ),
                                                    ))
                                              : Container(
                                                  color: Colors.grey[300],
                                                  child: const Icon(Icons.image, size: 40, color: Colors.grey),
                                                ))
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
                                          const SizedBox(height: 8),
                                          SizedBox(
                                            width: double.infinity,
                                            child: ElevatedButton(
                                              onPressed: () {
                                                final cartItem = CartItem(
                                                  id: productId,
                                                  name: product['productName'] ?? 'Product',
                                                  price:                                                   product['discountPrice'] != null && product['discountPrice'].isNotEmpty
                                                      ? double.tryParse(product['discountPrice'].replaceAll('$', '')) ?? 0.0
                                                      : double.tryParse(product['price']?.replaceAll('$', '') ?? '0') ?? 0.0
                                                  ,
                                                  discountPrice:                                                   product['discountPrice'] != null && product['discountPrice'].isNotEmpty
                                                      ? double.tryParse(product['discountPrice'].replaceAll('$', '')) ?? 0.0
                                                      : 0.0
                                                  ,
                                                  image: product['imageAsset'],
                                                );
                                                _cartManager.addItem(cartItem);
                                                ScaffoldMessenger.of(context).showSnackBar(
                                                  const SnackBar(content: Text('Added to cart')),
                                                );
                                              },
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor: Colors.blue,
                                                foregroundColor: Colors.white,
                                                elevation: 0,
                                                padding: const EdgeInsets.symmetric(vertical: 8),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                ),
                                              ),
                                              child: const Text(
                                                'Add to Cart',
                                                style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                                              ),
                                            ),
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [            // Default Profile Content
            CircleAvatar(
              radius: 50,
              backgroundColor: Colors.blue,
              child: const Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 16),
            const Text(
              'User Profile',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            TextField(
              decoration: InputDecoration(
                labelText: 'Full Name',
                hintText: 'Enter your name',
                prefixIcon: const Icon(Icons.person_outline),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              decoration: InputDecoration(
                labelText: 'Phone',
                hintText: 'Enter your phone',
                prefixIcon: const Icon(Icons.phone_outlined),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                filled: true,
                fillColor: Colors.grey.shade50,
              ),
            ),
            const SizedBox(height: 24),
            const Divider(),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.refresh, color: Colors.white),
                label: const Text('Request Refund', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.logout, color: Colors.white),
                label: const Text('Logout', style: TextStyle(color: Colors.white)),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: Colors.red,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
              ),
            ),          ],
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
                                                Icon(_getIconData(home),
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
                            Icon(_getIconData(shopping_cart),
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
                                                Icon(_getIconData(favorite),
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
                                                Icon(_getIconData(person),
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