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
  
  double get totalDiscount {
    return _items.fold(0.0, (sum, item) => 
      sum + ((item.price - item.effectivePrice) * item.quantity));
  }
  
  double get gstAmount {
    return PriceUtils.calculateTax(subtotal, 18.0); // 18% GST
  }
  
  double get finalTotal {
    return subtotal + gstAmount;
  }
  
  double get finalTotalWithShipping {
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
                                                Container(
                          width: 32,
                          height: 32,
                          child: Image.memory(
                                base64Decode('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'),
                                width: 32,
                                height: 32,
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) => const Icon(Icons.store, size: 32, color: Colors.white),
                              ),
                        ),
                        
                        const SizedBox(width: 8),
                        Text(
                          'Gym',
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
        Expanded(
          child: SingleChildScrollView(
            child: Column(
              children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        CarouselSlider(
                          options: CarouselOptions(
                            height: 200,
                            autoPlay: true,
                            autoPlayInterval: Duration(seconds: 3),
                            autoPlayAnimationDuration: const Duration(milliseconds: 800),
                            autoPlayCurve: Curves.fastOutSlowIn,
                            enlargeCenterPage: true,
                            scrollDirection: Axis.horizontal,
                            enableInfiniteScroll: true,
                            viewportFraction: 0.8,
                            enlargeFactor: 0.3,
                          ),
                          items: [
                            Builder(
                              builder: (BuildContext context) => Container(
                                width: 300,
                                margin: const EdgeInsets.symmetric(horizontal: 5.0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.memory(
                                    base64Decode('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'),
                                    width: 300,
                                    height: 200,
                                    fit: BoxFit.cover,
                                    errorBuilder: (context, error, stackTrace) => Container(
                                      color: Colors.grey[300],
                                      child: const Center(child: Icon(Icons.image, size: 40, color: Colors.grey)),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                                                const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(width: 6.0, height: 6.0, margin: EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0), decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.blue.withOpacity(0.4))),
                          ],
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
      body: ListenableBuilder(
        listenable: _cartManager,
        builder: (context, child) {
          return _cartManager.items.isEmpty
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
                                    // Show current price (effective price)
                                    Text(
                                      PriceUtils.formatPrice(item.effectivePrice),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    // Show original price if there's a discount
                                    if (item.discountPrice > 0 && item.price != item.discountPrice)
                                      Text(
                                        PriceUtils.formatPrice(item.price),
                                        style: TextStyle(
                                          fontSize: 14,
                                          decoration: TextDecoration.lineThrough,
                                          color: Colors.grey.shade600,
                                        ),
                                      ),
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
                // Bill Summary Section
                Container(
                  margin: const EdgeInsets.all(16),
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey[50],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey[300]!),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Bill Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Subtotal', style: TextStyle(fontSize: 14, color: Colors.grey)),
                            Text(PriceUtils.formatPrice(_cartManager.subtotal), style: const TextStyle(fontSize: 14, color: Colors.grey)),
                          ],
                        ),
                      ),
                      if (_cartManager.totalDiscount > 0)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Discount', style: TextStyle(fontSize: 14, color: Colors.grey)),
                              Text('-$0.00', style: const TextStyle(fontSize: 14, color: Colors.green)),
                            ],
                          ),
                        ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('GST (18%)', style: TextStyle(fontSize: 14, color: Colors.grey)),
                            Text(PriceUtils.formatPrice(_cartManager.gstAmount), style: const TextStyle(fontSize: 14, color: Colors.grey)),
                          ],
                        ),
                      ),
                      const Divider(thickness: 1),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text('Total', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                            Text(PriceUtils.formatPrice(_cartManager.finalTotal), style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.black)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            );
        },
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
          children: [            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey,
                    child: Icon(Icons.person, size: 60, color: Colors.white),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    'John Doe',
                    style: TextStyle(
                      fontSize: 26,
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(250, 50),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      // Refund button action
                    },
                    child: const Text(
                      'Refund',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ),
                  const SizedBox(height: 15),
                  OutlinedButton(
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size(250, 50),
                      side: const BorderSide(color: Colors.grey),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: () {
                      // Log Out button action
                    },
                    child: const Text(
                      'Log Out',
                      style: TextStyle(fontSize: 18, color: Colors.black),
                    ),
                  ),
                ],
              ),
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
      items: [
        const BottomNavigationBarItem(
          icon: Icon(Icons.home),
          label: 'Home',
        ),
        BottomNavigationBarItem(
          icon: Badge(
            label: Text('${_cartManager.items.length}'),
            isLabelVisible: _cartManager.items.length > 0,
            child: const Icon(Icons.shopping_cart),
          ),
          label: 'Cart',
        ),
        BottomNavigationBarItem(
          icon: Badge(
            label: Text('${_wishlistManager.items.length}'),
            isLabelVisible: _wishlistManager.items.length > 0,
            child: const Icon(Icons.favorite),
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
