import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

// Define PriceUtils class
class PriceUtils {
  static String formatPrice(double price, {String currency = '\$'}) {
    return '$currency\${price.toStringAsFixed(2)}';
  }
  
  // Extract numeric value from price string with any currency symbol
  static double parsePrice(String priceString) {
    if (priceString.isEmpty) return 0.0;
    // Remove all currency symbols and non-numeric characters except decimal point
    String numericString = priceString.replaceAll(RegExp(r'[^\\d.]'), '');
    return double.tryParse(numericString) ?? 0.0;
  }
  
  // Detect currency symbol from price string
  static String detectCurrency(String priceString) {
    if (priceString.contains('₹')) return '₹';
    if (priceString.contains('\$')) return '\$';
    if (priceString.contains('€')) return '€';
    if (priceString.contains('£')) return '£';
    if (priceString.contains('¥')) return '¥';
    if (priceString.contains('₩')) return '₩';
    if (priceString.contains('₽')) return '₽';
    if (priceString.contains('₦')) return '₦';
    if (priceString.contains('₨')) return '₨';
    return '\$'; // Default to dollar
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

// Cart item model
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

// Cart manager
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

// Wishlist item model
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

// Wishlist manager
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
    'productName': 'Burgurss',
    'imageAsset': 'data:image/png;base64,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',
    'price': '\$299',
    'discountPrice': '\$190',
  },
  {
    'productName': 'mohanburgur',
    'imageAsset': 'data:image/png;base64,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',
    'price': '50',
    'discountPrice': '10%',
  }
];


void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Generated E-commerce App',
    theme: ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorSchemeSeed: Colors.blue,
      appBarTheme: const AppBarTheme(
        elevation: 4,
        shadowColor: Colors.black38,
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      cardTheme: const CardThemeData(
        elevation: 3,
        shadowColor: Colors.black12,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.all(Radius.circular(8)),
          ),
        ),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(8)),
        ),
        filled: true,
        fillColor: Colors.grey,
        contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      ),
    ),
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
    _pageController.jumpToPage(index);
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
          return productName.contains(searchLower) || price.contains(searchLower) || discountPrice.contains(searchLower);
        }).toList();
      }
    });
  }

  IconData _getIconData(String iconName) {
    switch (iconName) {
      case 'home':
        return Icons.home;
      case 'shopping_cart':
        return Icons.shopping_cart;
      case 'favorite':
        return Icons.favorite;
      case 'person':
        return Icons.person;
      default:
        return Icons.error;
    }
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
                            // Search functionality for filtering products
                            setState(() {
                              // This would filter the product grid based on search query
                              // Searching by product name (case-insensitive) or price
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
                                'Search by product name or price (e.g., "Product Name" or "\$299")',
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
                                                  price: double.tryParse(product['price']?.replaceAll('\$','') ?? '0') ?? 0.0,
                                                  discountPrice: product['discountPrice'] != null && product['discountPrice'].isNotEmpty
                                                      ? double.tryParse(product['discountPrice'].replaceAll('\$','') ?? '0') ?? 0.0
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
                                                      : PriceUtils.detectCurrency(product['price'] ?? '\$0')
                                                  
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
                                                    PriceUtils.formatPrice(PriceUtils.parsePrice(product['price'] ?? '0'), currency: PriceUtils.detectCurrency(product['price'] ?? '\$0')),
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
                                                      ? double.tryParse(product['discountPrice'].replaceAll('\$', '')) ?? 0.0
                                                      : double.tryParse(product['price']?.replaceAll('\$', '') ?? '0') ?? 0.0
                                                  ,
                                                  discountPrice:                                                   product['discountPrice'] != null && product['discountPrice'].isNotEmpty
                                                      ? double.tryParse(product['discountPrice'].replaceAll('\$', '')) ?? 0.0
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
                        ),
                      ],
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
                                child: item.image != null && item.image!.isNotEmpty
                                    ? (item.image!.startsWith('data:image/')
                                    ? Image.memory(
                                  base64Decode(item.image!.split(',')[1]),
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                                )
                                    : Image.network(
                                  item.image!,
                                  width: 60,
                                  height: 60,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                                ))
                                    : const Icon(Icons.image),
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
                      child: item.image != null && item.image!.isNotEmpty
                          ? (item.image!.startsWith('data:image/')
                          ? Image.memory(
                        base64Decode(item.image!.split(',')[1]),
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                      )
                          : Image.network(
                        item.image!,
                        width: 50,
                        height: 50,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(Icons.image),
                      ))
                          : const Icon(Icons.image),
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
          children: [            const Text(
              'User Profile',
              style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Name',
                hintText: 'Enter your name',
              ),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Email',
                hintText: 'Enter your email',
              ),
            ),
            const SizedBox(height: 12),
            const TextField(
              decoration: InputDecoration(
                labelText: 'Phone',
                hintText: 'Enter your phone number',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Profile saved')),
                );
              },
              child: const Text('Save Profile'),
            ),          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentPageIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: 'Cart',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite),
          label: 'Wishlist',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
}
  Widget _buildBottomNavigationBar() {
    return BottomNavigationBar(
      currentIndex: _currentPageIndex,
      onTap: _onItemTapped,
      type: BottomNavigationBarType.fixed,
      selectedItemColor: Colors.blue,
      unselectedItemColor: Colors.grey,
      items: const [
        BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: 'Cart',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.favorite),
          label: 'Wishlist',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ],
    );
  }
