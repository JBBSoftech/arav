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
    'price': '299',
    'discountPrice': '199',
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
                          itemCount: 1,
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