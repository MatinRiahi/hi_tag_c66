import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// 👇 مسیر این فایل‌ها رو در پروژه خودت چک کن
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../views/store/product_detail.dart'; // فایل جزئیات محصول خودت

class StoreScreen extends StatefulWidget {
  const StoreScreen({super.key});

  @override
  State<StoreScreen> createState() => _StoreScreenState();
}

class _StoreScreenState extends State<StoreScreen> {
  // کلید اسکفولد برای باز و بسته کردن کشوی فیلترها
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // --- متغیرهای API ---
  late String _baseUrl;
  late String _productListUrl;
  bool _isLoading = true;

  // --- متغیرهای فیلتر ---
  bool _weightFilterEnabled = false;
  RangeValues _weightRange = const RangeValues(0.5, 30);

  bool _priceFilterEnabled = false;
  RangeValues _priceRange = const RangeValues(1000000, 200000000);

  final TextEditingController _searchController = TextEditingController();
  String? _selectedCategory;

  String _lastUpdate = "-";
  String _mazane = "-";

  final List<String> _categories = [
    "همه دسته‌ها",
    "انگشتر",
    "گردنبند",
    "دستبند",
    "گوشواره",
    "سرویس کامل",
    "نیم ست",
  ];

  // --- لیست سبد خرید ---
  final List<Map<String, dynamic>> _cartItems = [];

  // --- لیست محصولات ---
  List<Map<String, dynamic>> _products = [];
  List<Map<String, dynamic>> _allProductsFromServer = [];

  @override
  void initState() {
    super.initState();
    // تنظیم آدرس‌ها با آدرس داینامیک لاگین
    _baseUrl = AppConstants.baseUrl;
    _productListUrl = "$_baseUrl/product_list_json/";

    _fetchProducts();
  }

  Future<void> _fetchProducts() async {
    setState(() => _isLoading = true);

    try {
      final response = await http.get(Uri.parse(_productListUrl));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(
          utf8.decode(response.bodyBytes),
        );

        if (data.containsKey('products')) {
          final List<dynamic> serverProducts = data['products'];

          setState(() {
            _lastUpdate = data['last_update'] ?? "-";

            if (data['mazane'] != null) {
              double rawVal = double.tryParse(data['mazane'].toString()) ?? 0;
              double mazaneVal = rawVal / 10;
              _mazane = _formatCurrency(mazaneVal).replaceAll("ریال", "");
            }

            _allProductsFromServer = serverProducts.map((item) {
              String imageUrl = "";
              if (item['picture'] != null) {
                imageUrl = item['picture'].toString().startsWith('/')
                    ? "$_baseUrl${item['picture']}"
                    : "$_baseUrl/${item['picture']}";
              }

              return {
                "name": item['name'] ?? "بدون نام",
                "id": item['code'] ?? item['id'].toString(),
                "weight": (item['gold_weight'] ?? item['weight'] ?? 0.0)
                    .toDouble(),
                "price": (item['price'] ?? 0).toDouble() / 10,
                "image": imageUrl,
                "is_mojod": item['is_mojod'] ?? false,
                "stone_price": (item['stone_price'] ?? 0).toDouble() / 10,
                "ojrat": (item['ojrat'] ?? 0).toDouble(),
                "category": "همه دسته‌ها",
              };
            }).toList();

            _products = List.from(_allProductsFromServer);
            _isLoading = false;
          });
        }
      } else {
        _showError("خطا در دریافت لیست: ${response.statusCode}");
        setState(() => _isLoading = false);
      }
    } catch (e) {
      _showError("خطا در اتصال به سرور: $e");
      setState(() => _isLoading = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: TextStyle(
            fontFamily: 'Peyda',
            color: Theme.of(context).colorScheme.onError,
          ),
        ),
        backgroundColor: Theme.of(context).colorScheme.error,
      ),
    );
  }

  Future<void> _applyFilters() async {
    // بستن کشوی فیلترها به صورت خودکار
    _scaffoldKey.currentState?.closeEndDrawer();

    setState(() => _isLoading = true);

    try {
      String minWeight = "-";
      String maxWeight = "-";
      String minPrice = "-";
      String maxPrice = "-";
      String category = "";

      if (_weightFilterEnabled) {
        minWeight = _weightRange.start.toString();
        maxWeight = _weightRange.end.toString();
      }

      if (_priceFilterEnabled) {
        minPrice = (_priceRange.start * 10).toStringAsFixed(0);
        maxPrice = (_priceRange.end * 10).toStringAsFixed(0);
      }

      final url = Uri.parse('$_baseUrl/filter_product/');
      final body = jsonEncode({
        "min_weight": minWeight,
        "max_weight": maxWeight,
        "min_price": minPrice,
        "max_price": maxPrice,
        "category": category,
      });

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(
          utf8.decode(response.bodyBytes),
        );

        if (data.containsKey('filter_product')) {
          final List<dynamic> serverResults = data['filter_product'];

          List<Map<String, dynamic>> processedResults = serverResults.map((
            item,
          ) {
            String imageUrl = "";
            if (item['picture'] != null) {
              imageUrl = item['picture'].toString().startsWith('/')
                  ? "$_baseUrl${item['picture']}"
                  : "$_baseUrl/${item['picture']}";
            }

            return {
              "name": item['name'] ?? "بدون نام",
              "id": item['code'] ?? item['id'].toString(),
              "weight": (item['gold_weight'] ?? item['weight'] ?? 0.0)
                  .toDouble(),
              "price": (item['price'] ?? 0).toDouble() / 10,
              "image": imageUrl,
              "is_mojod": item['is_mojod'] ?? true,
              "category": "همه دسته‌ها",
            };
          }).toList();

          if (_searchController.text.isNotEmpty) {
            final query = _searchController.text.toLowerCase();
            processedResults = processedResults.where((product) {
              final name = product['name'].toString().toLowerCase();
              final id = product['id'].toString().toLowerCase();
              return name.contains(query) || id.contains(query);
            }).toList();
          }

          setState(() {
            _products = processedResults;
            _isLoading = false;
          });
        } else {
          setState(() {
            _products = [];
            _isLoading = false;
          });
        }
      } else {
        setState(() => _isLoading = false);
      }
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  void _removeFilters() {
    _scaffoldKey.currentState?.closeEndDrawer(); // بستن کشو
    setState(() {
      _searchController.clear();
      _weightFilterEnabled = false;
      _priceFilterEnabled = false;
      _weightRange = const RangeValues(0.5, 30);
      _priceRange = const RangeValues(1000000, 200000000);
    });
    _fetchProducts();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey, // کلید برای مدیریت منوی کشویی
      endDrawer: _buildFilterDrawer(), // 👈 کشوی فیلترها (سمت راست)
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).scaffoldBackgroundColor,
              Theme.of(context).colorScheme.surface,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              _buildHeader(), // هدر بالایی
              // لیست محصولات
              Expanded(
                child: _isLoading
                    ? const Center(
                        child: CircularProgressIndicator(
                          color: AppTheme.primaryGold,
                        ),
                      )
                    : _products.isEmpty
                    ? Center(
                        child: Text(
                          "محصولی یافت نشد",
                          style: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.54),
                            fontFamily: 'Peyda',
                          ),
                        ),
                      )
                    : Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 10,
                        ),
                        child: GridView.builder(
                          // 👈 برای 5.5 اینچ 2 ستونه عالیه
                          gridDelegate:
                              const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                childAspectRatio:
                                    0.58, // تنظیم نسبت برای جا شدن دکمه و متن
                                crossAxisSpacing: 16,
                                mainAxisSpacing: 16,
                              ),
                          itemCount: _products.length,
                          itemBuilder: (context, index) {
                            final product = _products[index];
                            final bool isInCart = _cartItems.any(
                              (item) => item['id'] == product['id'],
                            );
                            return _buildProductCard(
                              product: product,
                              isInCart: isInCart,
                              onAddToCart: () {
                                if (!isInCart) {
                                  setState(() {
                                    _cartItems.add(product);
                                  });
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        "${product['name']} به سبد اضافه شد",
                                        style: const TextStyle(
                                          fontFamily: 'Peyda',
                                        ),
                                      ),
                                      backgroundColor: AppTheme.primaryGold,
                                      duration: const Duration(seconds: 1),
                                    ),
                                  );
                                }
                              },
                            );
                          },
                        ),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Header ────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // دکمه بک
          IconButton(
            onPressed: () => Navigator.pop(context),
            icon: Icon(
              Icons.arrow_back_ios,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),

          // اطلاعات مظنه و آپدیت
          Expanded(
            child: Column(
              children: [
                const Text(
                  "HI-STORE",
                  style: TextStyle(
                    fontFamily: 'Peyda',
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: AppTheme.primaryGold,
                  ),
                ),
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    "مظنه: $_mazane",
                    style: TextStyle(
                      fontFamily: 'Peyda',
                      fontSize: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
                // 🔥 تاریخ آپدیت رو هم اینجا اضافه کردیم که از متغیرش استفاده بشه
                Directionality(
                  textDirection: TextDirection.rtl,
                  child: Text(
                    "آپدیت: $_lastUpdate",
                    style: TextStyle(
                      fontFamily: 'Peyda',
                      fontSize: 10,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.4),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // دکمه سبد خرید و فیلتر
          Row(
            children: [
              // دکمه سبد خرید
              Stack(
                alignment: Alignment.topRight,
                children: [
                  IconButton(
                    onPressed: _showCartModal,
                    icon: const Icon(
                      Icons.shopping_bag_outlined,
                      color: AppTheme.primaryGold,
                      size: 26,
                    ),
                  ),
                  if (_cartItems.isNotEmpty)
                    Positioned(
                      right: 8,
                      top: 8,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: const BoxDecoration(
                          color: Colors.redAccent,
                          shape: BoxShape.circle,
                        ),
                        child: Text(
                          '${_cartItems.length}',
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
              // دکمه باز کردن منوی فیلترها
              IconButton(
                onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
                icon: Icon(
                  Icons.filter_list,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ─── Filter Drawer (منوی کشویی فیلترها) ──────────────────────────────
  Widget _buildFilterDrawer() {
    return Drawer(
      backgroundColor: Theme.of(context).colorScheme.surface,
      child: SafeArea(
        child: Column(
          children: [
            // هدر دراور
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.close,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.7),
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                  Text(
                    "فیلتر محصولات",
                    style: TextStyle(
                      fontFamily: 'Peyda',
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            Divider(
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
              height: 1,
            ),

            // محتوای فیلترها
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildRangeFilterSection(
                      title: "فیلتر وزن (گرم)",
                      isEnabled: _weightFilterEnabled,
                      rangeValues: _weightRange,
                      min: 0.5,
                      max: 30,
                      divisions: 24,
                      onToggle: (val) =>
                          setState(() => _weightFilterEnabled = val),
                      onRangeChanged: (val) =>
                          setState(() => _weightRange = val),
                      labelFormatter: (val) => "${val.toStringAsFixed(1)} گرم",
                    ),
                    const SizedBox(height: 24),
                    _buildRangeFilterSection(
                      title: "فیلتر قیمت (تومان)",
                      isEnabled: _priceFilterEnabled,
                      rangeValues: _priceRange,
                      min: 1000000,
                      max: 200000000,
                      divisions: 100,
                      onToggle: (val) =>
                          setState(() => _priceFilterEnabled = val),
                      onRangeChanged: (val) =>
                          setState(() => _priceRange = val),
                      labelFormatter: (val) => _formatCurrency(val),
                    ),
                    const SizedBox(height: 24),
                    Divider(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.1),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      "جستجوی محصول",
                      style: TextStyle(
                        fontFamily: 'Peyda',
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.12),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                        decoration: InputDecoration(
                          hintText: "نام کار یا کد...",
                          hintStyle: TextStyle(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.24),
                            fontSize: 13,
                          ),
                          prefixIcon: const Icon(
                            Icons.search,
                            color: AppTheme.primaryGold,
                          ),
                          border: InputBorder.none,
                          contentPadding: const EdgeInsets.symmetric(
                            vertical: 12,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      "دسته‌بندی",
                      style: TextStyle(
                        fontFamily: 'Peyda',
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      decoration: BoxDecoration(
                        color: Theme.of(
                          context,
                        ).colorScheme.surface.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.12),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _selectedCategory,
                          hint: Text(
                            "انتخاب کنید...",
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.38),
                            ),
                          ),
                          dropdownColor: Theme.of(context).colorScheme.surface,
                          icon: const Icon(
                            Icons.keyboard_arrow_down,
                            color: AppTheme.primaryGold,
                          ),
                          isExpanded: true,
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontFamily: 'Peyda',
                          ),
                          items: _categories.map((String category) {
                            return DropdownMenuItem<String>(
                              value: category,
                              child: Text(category),
                            );
                          }).toList(),
                          onChanged: (newValue) =>
                              setState(() => _selectedCategory = newValue),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // دکمه‌های اعمال و حذف فیلتر (پایین دراور)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: ElevatedButton(
                      onPressed: _applyFilters,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGold,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        "اعمال فیلتر",
                        style: TextStyle(
                          fontFamily: 'Peyda',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 45,
                    child: OutlinedButton.icon(
                      onPressed: _removeFilters,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text(
                        "حذف فیلترها",
                        style: TextStyle(
                          fontFamily: 'Peyda',
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.redAccent,
                        side: const BorderSide(
                          color: Colors.redAccent,
                          width: 1.5,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // بقیه متدهای شما (بدون تغییر لاجیک، فقط بهینه‌سازی سایز برای ۵.۵ اینچ)
  Widget _buildProductCard({
    required Map<String, dynamic> product,
    required VoidCallback onAddToCart,
    required bool isInCart,
  }) {
    final String imageUrl = product['image'] ?? "";
    final bool hasImage = imageUrl.isNotEmpty && !imageUrl.endsWith("null");

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.05),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Directionality(
        textDirection: TextDirection.rtl,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: InkWell(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      settings: const RouteSettings(name: 'StoreRoot'),
                      builder: (context) => ProductDetailScreen(
                        product: product,
                        cartItems: _cartItems,
                        onAddToCart: (newProduct) {
                          setState(() {
                            if (!_cartItems.any(
                              (item) => item['id'] == newProduct['id'],
                            )) {
                              _cartItems.add(newProduct);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    "${newProduct['name']} به سبد اضافه شد",
                                    style: const TextStyle(fontFamily: 'Peyda'),
                                  ),
                                  backgroundColor: AppTheme.primaryGold,
                                  duration: const Duration(seconds: 1),
                                ),
                              );
                            }
                          });
                        },
                      ),
                    ),
                  ).then((_) => setState(() {}));
                },
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // عکس
                    Expanded(
                      flex: 5,
                      child: ClipRRect(
                        borderRadius: const BorderRadius.vertical(
                          top: Radius.circular(15),
                        ),
                        child: hasImage
                            ? Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (c, e, s) => const Icon(
                                  Icons.image_not_supported,
                                  size: 30,
                                ),
                              )
                            : Icon(
                                Icons.diamond_outlined,
                                size: 40,
                                color: AppTheme.primaryGold.withOpacity(0.5),
                              ),
                      ),
                    ),
                    // متن
                    Expanded(
                      flex: 4,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 6,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Text(
                              product['name'],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontFamily: 'Peyda',
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).colorScheme.onSurface,
                              ),
                            ),
                            Text(
                              "کد: ${product['id']}",
                              style: TextStyle(
                                fontFamily: 'Peyda',
                                fontSize: 10,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.5),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "${product['weight']} گرم",
                                  style: const TextStyle(
                                    fontFamily: 'Peyda',
                                    fontSize: 11,
                                    color: AppTheme.primaryGold,
                                  ),
                                ),
                                Expanded(
                                  child: Text(
                                    _formatCurrency(product['price']),
                                    textAlign: TextAlign.left,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontFamily: 'Peyda',
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: AppTheme.primaryGold,
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
              ),
            ),
            // دکمه سبد
            Padding(
              padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
              child: SizedBox(
                height: 32,
                child: ElevatedButton(
                  onPressed: isInCart ? null : onAddToCart,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surface.withOpacity(0.1),
                    foregroundColor: isInCart
                        ? Colors.redAccent
                        : AppTheme.primaryGold,
                    side: BorderSide(
                      color: isInCart ? Colors.redAccent : AppTheme.primaryGold,
                      width: 1,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    padding: EdgeInsets.zero,
                  ),
                  child: Text(
                    isInCart ? "به سبد اضافه شد" : "افزودن به سبد",
                    style: const TextStyle(
                      fontFamily: 'Peyda',
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── مدال سبد خرید ──────────────────────────────────────────────────
  void _showCartModal() {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true, // برای اینکه تو موبایل‌های کوچیک بهتر جا بشه
      builder: (context) {
        return StatefulBuilder(
          builder: (BuildContext context, StateSetter setModalState) {
            return Container(
              height:
                  MediaQuery.of(context).size.height *
                  0.75, // گرفتن 75 درصد از صفحه
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                borderRadius: const BorderRadius.vertical(
                  top: Radius.circular(25),
                ),
              ),
              child: Column(
                children: [
                  const SizedBox(height: 10),
                  Container(
                    width: 50,
                    height: 5,
                    decoration: BoxDecoration(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.24),
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      textDirection: TextDirection.rtl,
                      children: [
                        Text(
                          "سبد خرید شما",
                          style: TextStyle(
                            fontFamily: 'Peyda',
                            fontSize: 18,
                            color: Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${_cartItems.length} کالا",
                          style: const TextStyle(
                            fontFamily: 'Peyda',
                            color: AppTheme.primaryGold,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Expanded(
                    child: _cartItems.isEmpty
                        ? Center(
                            child: Text(
                              "سبد خرید خالی است",
                              style: TextStyle(
                                fontFamily: 'Peyda',
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.54),
                              ),
                            ),
                          )
                        : ListView.builder(
                            itemCount: _cartItems.length,
                            itemBuilder: (context, index) {
                              final item = _cartItems[index];
                              return Directionality(
                                textDirection: TextDirection.rtl,
                                child: Container(
                                  margin: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 4,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.surface.withOpacity(0.5),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                      color: Theme.of(
                                        context,
                                      ).colorScheme.onSurface.withOpacity(0.05),
                                    ),
                                  ),
                                  child: ListTile(
                                    leading: item['image'] != ""
                                        ? ClipRRect(
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            child: Image.network(
                                              item['image'],
                                              width: 45,
                                              height: 45,
                                              fit: BoxFit.cover,
                                            ),
                                          )
                                        : const Icon(
                                            Icons.diamond_outlined,
                                            color: AppTheme.primaryGold,
                                            size: 30,
                                          ),
                                    title: Text(
                                      item['name'],
                                      style: TextStyle(
                                        fontFamily: 'Peyda',
                                        fontSize: 14,
                                        color: Theme.of(
                                          context,
                                        ).colorScheme.onSurface,
                                      ),
                                    ),
                                    subtitle: Text(
                                      _formatCurrency(item['price']),
                                      style: TextStyle(
                                        fontFamily: 'Peyda',
                                        fontSize: 12,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withOpacity(0.54),
                                      ),
                                    ),
                                    trailing: IconButton(
                                      icon: const Icon(
                                        Icons.delete_outline,
                                        color: Colors.redAccent,
                                      ),
                                      onPressed: () {
                                        setState(
                                          () => _cartItems.removeAt(index),
                                        );
                                        setModalState(() {});
                                      },
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                  ),
                  if (_cartItems.isNotEmpty)
                    SafeArea(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: SizedBox(
                          width: double.infinity,
                          height: 48,
                          child: ElevatedButton(
                            onPressed: _finalizeSale,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGold,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                            child: const Text(
                              "تکمیل خرید و ثبت",
                              style: TextStyle(
                                fontFamily: 'Peyda',
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  // ─── ابزارهای فیلتر و فرمت قیمت ────────────────────────────────────
  Widget _buildRangeFilterSection({
    required String title,
    required bool isEnabled,
    required RangeValues rangeValues,
    required double min,
    required double max,
    required Function(bool) onToggle,
    required Function(RangeValues) onRangeChanged,
    required String Function(double) labelFormatter,
    int? divisions,
  }) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title,
              style: TextStyle(
                fontFamily: 'Peyda',
                fontSize: 14,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            Transform.scale(
              scale: 0.7,
              child: CupertinoSwitch(
                value: isEnabled,
                onChanged: onToggle,
                activeColor: AppTheme.primaryGold,
                trackColor: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.24),
              ),
            ),
          ],
        ),
        if (isEnabled) ...[
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                labelFormatter(rangeValues.start),
                style: const TextStyle(
                  color: AppTheme.primaryGold,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
              Text(
                labelFormatter(rangeValues.end),
                style: const TextStyle(
                  color: AppTheme.primaryGold,
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          RangeSlider(
            values: rangeValues,
            min: min,
            max: max,
            divisions: divisions,
            activeColor: AppTheme.primaryGold,
            inactiveColor: Theme.of(
              context,
            ).colorScheme.onSurface.withOpacity(0.1),
            onChanged: onRangeChanged,
          ),
        ],
      ],
    );
  }

  String _formatCurrency(double value) {
    String priceStr = value.toInt().toString();
    String result = "";
    int count = 0;
    for (int i = priceStr.length - 1; i >= 0; i--) {
      count++;
      result = priceStr[i] + result;
      if (count == 3 && i > 0) {
        result = ",$result";
        count = 0;
      }
    }
    return "$result تومان";
  }

  // ─── مراحل نهایی کردن خرید (مثل قبل) ──────────────────────────────
  Map<String, dynamic>? _foundCustomer;
  bool _isCheckingCustomer = false;

  Future<void> _finalizeSale() async {
    if (_cartItems.isEmpty) return;
    _foundCustomer = null;
    final phoneController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Directionality(
              textDirection: TextDirection.rtl,
              child: AlertDialog(
                backgroundColor: Theme.of(context).colorScheme.surface,
                title: Text(
                  "اطلاعات مشتری",
                  style: TextStyle(
                    fontFamily: 'Peyda',
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (_foundCustomer == null) ...[
                        Text(
                          "لطفاً شماره موبایل مشتری را وارد کنید:",
                          style: TextStyle(
                            fontFamily: 'Peyda',
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextField(
                          controller: phoneController,
                          keyboardType: TextInputType.phone,
                          autofocus: true,
                          style: TextStyle(
                            fontFamily: 'Peyda',
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          decoration: InputDecoration(
                            hintText: "مثلاً: 09123456789",
                            hintStyle: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.3),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(10),
                              borderSide: const BorderSide(
                                color: AppTheme.primaryGold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        if (_isCheckingCustomer)
                          const CircularProgressIndicator(
                            color: AppTheme.primaryGold,
                          ),
                      ] else ...[
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: Colors.green),
                          ),
                          child: Column(
                            children: [
                              const Icon(
                                Icons.check_circle,
                                color: Colors.green,
                                size: 40,
                              ),
                              const SizedBox(height: 10),
                              Text(
                                "مشتری شناسایی شد:",
                                style: TextStyle(
                                  fontFamily: 'Peyda',
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface,
                                ),
                              ),
                              const SizedBox(height: 5),
                              Text(
                                "${_foundCustomer!['name']} ${_foundCustomer!['family'] ?? ''}",
                                style: const TextStyle(
                                  fontFamily: 'Peyda',
                                  fontWeight: FontWeight.bold,
                                  fontSize: 18,
                                ),
                              ),
                              Text(
                                "کد اشتراک: ${_foundCustomer!['code']}",
                                style: TextStyle(
                                  fontFamily: 'Peyda',
                                  color: Theme.of(
                                    context,
                                  ).colorScheme.onSurface.withOpacity(0.6),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 20),
                        Text(
                          "آیا فاکتور برای این مشتری صادر شود؟",
                          style: TextStyle(
                            fontFamily: 'Peyda',
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx),
                    child: Text(
                      "لغو",
                      style: TextStyle(
                        fontFamily: 'Peyda',
                        color: Theme.of(
                          ctx,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
                  if (_foundCustomer == null)
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryGold,
                      ),
                      onPressed: _isCheckingCustomer
                          ? null
                          : () => _checkCustomer(
                              phoneController.text,
                              setStateDialog,
                            ),
                      child: const Text(
                        "بررسی مشتری",
                        style: TextStyle(
                          fontFamily: 'Peyda',
                          color: Colors.black87,
                        ),
                      ),
                    )
                  else
                    ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                      ),
                      onPressed: () {
                        Navigator.pop(ctx);
                        _sendSaleRequest(_foundCustomer!['code'].toString());
                      },
                      child: const Text(
                        "تایید و ثبت فروش",
                        style: TextStyle(
                          fontFamily: 'Peyda',
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Future<void> _checkCustomer(String phone, StateSetter setStateDialog) async {
    if (phone.length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "شماره موبایل باید ۱۱ رقم باشد",
            style: TextStyle(fontFamily: 'Peyda'),
          ),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setStateDialog(() => _isCheckingCustomer = true);

    try {
      final url = Uri.parse("$_baseUrl/check_Customer/");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phone": phone}),
      );

      setStateDialog(() => _isCheckingCustomer = false);

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data.containsKey('cusotmer_data') &&
            data['cusotmer_data'] != null) {
          setStateDialog(() => _foundCustomer = data['cusotmer_data']);
        } else if (data.containsKey('error')) {
          Navigator.pop(context);
          _showCreateAccountDialog(phone);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "پاسخ سرور نامشخص است",
                style: TextStyle(fontFamily: 'Peyda'),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        Navigator.pop(context);
        _showCreateAccountDialog(phone);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "خطای ارتباط با سرور",
            style: const TextStyle(fontFamily: 'Peyda'),
          ),
          backgroundColor: Colors.red,
        ),
      );
      setStateDialog(() => _isCheckingCustomer = false);
    }
  }

  void _showCreateAccountDialog(String phone) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController(text: phone);
    final addressController = TextEditingController();
    final meliCodeController = TextEditingController();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Theme.of(ctx).colorScheme.surface,
          title: const Row(
            children: [
              Icon(Icons.person_add_alt_1, color: AppTheme.primaryGold),
              SizedBox(width: 10),
              Text("ایجاد مشتری جدید", style: TextStyle(fontFamily: 'Peyda')),
            ],
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    autofocus: true,
                    style: const TextStyle(fontFamily: 'Peyda'),
                    decoration: const InputDecoration(
                      labelText: "نام و نام خانوادگی*",
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? "وارد کردن نام اجباری است"
                        : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    style: const TextStyle(fontFamily: 'Peyda'),
                    decoration: const InputDecoration(
                      labelText: "شماره موبایل*",
                      prefixIcon: Icon(Icons.phone_android),
                    ),
                    validator: (v) => (v == null || v.length != 11)
                        ? "شماره موبایل باید ۱۱ رقم باشد"
                        : null,
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: addressController,
                    style: const TextStyle(fontFamily: 'Peyda'),
                    decoration: const InputDecoration(
                      labelText: "آدرس (اختیاری)",
                      prefixIcon: Icon(Icons.location_on),
                    ),
                  ),
                  const SizedBox(height: 15),
                  TextFormField(
                    controller: meliCodeController,
                    keyboardType: TextInputType.number,
                    style: const TextStyle(fontFamily: 'Peyda'),
                    decoration: const InputDecoration(
                      labelText: "کد ملی (اختیاری)",
                      prefixIcon: Icon(Icons.badge),
                    ),
                  ),
                ],
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "انصراف",
                style: TextStyle(
                  fontFamily: 'Peyda',
                  color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primaryGold,
              ),
              onPressed: () {
                if (formKey.currentState!.validate()) {
                  _registerAndSell(
                    name: nameController.text,
                    phone: phoneController.text,
                    address: addressController.text,
                    meliCode: meliCodeController.text,
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text(
                "ثبت و ادامه فروش",
                style: TextStyle(fontFamily: 'Peyda', color: Colors.black87),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _registerAndSell({
    required String name,
    required String phone,
    String address = "",
    String meliCode = "",
  }) async {
    try {
      final url = Uri.parse("$_baseUrl/add_new_customer/");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "phone_number": phone,
          "address": address,
          "code_meli": meliCode,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data.containsKey('data') && data['data']['ok'] != null) {
          final newCustomerId = data['data']['ok'].toString();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                "مشتری '$name' ثبت شد",
                style: const TextStyle(fontFamily: 'Peyda'),
              ),
              backgroundColor: Colors.green,
            ),
          );
          _sendSaleRequest(newCustomerId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                "پاسخ سرور نامعتبر است",
                style: TextStyle(fontFamily: 'Peyda'),
              ),
              backgroundColor: Colors.red,
            ),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "خطا در ثبت مشتری",
              style: TextStyle(fontFamily: 'Peyda'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("خطای ارتباط", style: TextStyle(fontFamily: 'Peyda')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _sendSaleRequest(String customerId) async {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          "در حال ثبت سفارش...",
          style: TextStyle(fontFamily: 'Peyda'),
        ),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      List<String> productCodes = _cartItems
          .map((item) => item['id'].toString())
          .toList();
      final url = Uri.parse("$_baseUrl/sale/");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"Code": productCodes, "Customer": customerId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        Navigator.maybePop(context);
        setState(() => _cartItems.clear());
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              "سفارش با موفقیت ثبت شد",
              style: TextStyle(fontFamily: 'Peyda'),
            ),
            backgroundColor: Colors.green,
          ),
        );
        await _fetchProducts();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "خطا در ثبت سفارش: ${response.statusCode}",
              style: const TextStyle(fontFamily: 'Peyda'),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            "خطای ارتباط با سرور",
            style: TextStyle(fontFamily: 'Peyda'),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
