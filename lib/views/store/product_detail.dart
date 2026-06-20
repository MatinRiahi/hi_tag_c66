import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';

// 👇 مسیر فایل‌ها رو چک کن
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';

class ProductDetailScreen extends StatefulWidget {
  final Map<String, dynamic> product;
  final Function(Map<String, dynamic> product) onAddToCart;
  final List<Map<String, dynamic>> cartItems;

  const ProductDetailScreen({
    super.key,
    required this.product,
    required this.onAddToCart,
    required this.cartItems,
  });

  @override
  State<ProductDetailScreen> createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen> {
  List<Map<String, dynamic>> _similarProducts = [];
  bool _isLoading = true;
  late String _baseUrl;

  @override
  void initState() {
    super.initState();
    // استفاده از آدرس داینامیک
    _baseUrl = AppConstants.baseUrl;
    _fetchSimilarProducts();
  }

  Future<void> _fetchSimilarProducts() async {
    try {
      final url = Uri.parse("$_baseUrl/similar_product/");
      final body = jsonEncode({"code": widget.product['id']});

      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: body,
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(
          utf8.decode(response.bodyBytes),
        );

        if (data.containsKey('similar_product')) {
          final List<dynamic> rawList = data['similar_product'];

          setState(() {
            _similarProducts = rawList.map((item) {
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
                "stone_price": (item['stone_price'] ?? 0).toDouble() / 10,
                "ojrat": (item['ojrat'] ?? 0).toDouble(),
                "image": imageUrl,
                "is_mojod": true,
              };
            }).toList();
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

  @override
  Widget build(BuildContext context) {
    bool isMainProductInCart = widget.cartItems.any(
      (item) => item['id'] == widget.product['id'],
    );
    final String imageUrl = widget.product['image'] ?? "";
    final bool hasImage = imageUrl.isNotEmpty && !imageUrl.endsWith("null");

    return Directionality(
      textDirection: TextDirection.rtl, // کل صفحه راست‌چین
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,

        // ─── نوار پایینی ثابت (قیمت و دکمه خرید) ───
        bottomNavigationBar: _buildBottomBar(isMainProductInCart),

        body: CustomScrollView(
          slivers: [
            // ─── عکس بزرگ بالای صفحه (SliverAppBar) ───
            SliverAppBar(
              expandedHeight: 320.0,
              pinned: true,
              backgroundColor: Theme.of(context).colorScheme.surface,
              elevation: 0,
              leading: Padding(
                padding: const EdgeInsets.all(8.0),
                child: CircleAvatar(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surface.withOpacity(0.7),
                  child: IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: Theme.of(context).colorScheme.onSurface,
                      size: 20,
                    ),
                    onPressed: () => Navigator.pop(context),
                  ),
                ),
              ),
              actions: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircleAvatar(
                    backgroundColor: Theme.of(
                      context,
                    ).colorScheme.surface.withOpacity(0.7),
                    child: IconButton(
                      icon: const Icon(
                        Icons.store_outlined,
                        color: AppTheme.primaryGold,
                      ),
                      onPressed: () {
                        // 👈 حالا فلاتر می‌گرده تا برسه به اون اسمی که بالا تعریف کردیم
                        Navigator.of(
                          context,
                        ).popUntil(ModalRoute.withName('StoreRoot'));
                      },
                      tooltip: 'بازگشت به فروشگاه',
                    ),
                  ),
                ),
              ],
              flexibleSpace: FlexibleSpaceBar(
                background: hasImage
                    ? Image.network(imageUrl, fit: BoxFit.cover)
                    : Container(
                        color: Theme.of(context).colorScheme.surface,
                        child: Center(
                          child: Icon(
                            Icons.diamond_outlined,
                            size: 80,
                            color: AppTheme.primaryGold.withOpacity(0.3),
                          ),
                        ),
                      ),
              ),
            ),

            // ─── محتوای جزئیات محصول ───
            SliverToBoxAdapter(
              child: Container(
                decoration: BoxDecoration(
                  color: Theme.of(context).scaffoldBackgroundColor,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                ),
                transform: Matrix4.translationValues(
                  0.0,
                  -20.0,
                  0.0,
                ), // بالا کشیدن کارت روی عکس
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // نام و کد
                      Text(
                        widget.product['name'] ?? "بدون نام",
                        style: TextStyle(
                          fontFamily: 'Peyda',
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "کد کالا: ${widget.product['id']}",
                        style: TextStyle(
                          fontFamily: 'Peyda',
                          fontSize: 13,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.5),
                        ),
                      ),

                      const SizedBox(height: 24),
                      Divider(
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.1),
                      ),
                      const SizedBox(height: 16),

                      // مشخصات کالا
                      Text(
                        "مشخصات کالا",
                        style: TextStyle(
                          fontFamily: 'Peyda',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // جدول مشخصات
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.surface,
                          borderRadius: BorderRadius.circular(15),
                          border: Border.all(
                            color: Theme.of(
                              context,
                            ).colorScheme.onSurface.withOpacity(0.05),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildDetailRow(
                              "وزن",
                              "${widget.product['weight']} گرم",
                            ),
                            const Divider(height: 20),
                            _buildDetailRow(
                              "اجرت",
                              "${widget.product['ojrat']} %",
                            ),
                            const Divider(height: 20),
                            _buildDetailRow(
                              "قیمت سنگ",
                              _formatCurrency(
                                widget.product['stone_price'] ?? 0,
                              ),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 30),

                      // تیتر محصولات مشابه
                      Row(
                        children: [
                          Container(
                            width: 4,
                            height: 20,
                            decoration: BoxDecoration(
                              color: AppTheme.primaryGold,
                              borderRadius: BorderRadius.circular(5),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            "محصولات مشابه",
                            style: TextStyle(
                              fontFamily: 'Peyda',
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                    ],
                  ),
                ),
              ),
            ),

            // ─── لیست محصولات مشابه (گرید 2 ستونه) ───
            if (_isLoading)
              const SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: EdgeInsets.all(20.0),
                    child: CircularProgressIndicator(
                      color: AppTheme.primaryGold,
                    ),
                  ),
                ),
              )
            else if (_similarProducts.isEmpty)
              SliverToBoxAdapter(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      "محصول مشابهی یافت نشد.",
                      style: TextStyle(
                        fontFamily: 'Peyda',
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    ),
                  ),
                ),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                sliver: SliverGrid(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2, // 👈 برای 5.5 اینچ عالیه
                    childAspectRatio: 0.58, // 👈 نسبت مناسب عکس و متن
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                  ),
                  delegate: SliverChildBuilderDelegate(
                    (context, index) =>
                        _buildSimilarProductCard(_similarProducts[index]),
                    childCount: _similarProducts.length,
                  ),
                ),
              ),

            // فاصله برای اسکرول تا زیر نوار پایینی
            const SliverToBoxAdapter(child: SizedBox(height: 40)),
          ],
        ),
      ),
    );
  }

  // ─── نوار پایینی ثابت (Bottom Bar) ───
  Widget _buildBottomBar(bool isMainProductInCart) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            // قیمت کل
            Expanded(
              flex: 2,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "قیمت نهایی:",
                    style: TextStyle(
                      fontFamily: 'Peyda',
                      fontSize: 11,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.5),
                    ),
                  ),
                  Text(
                    _formatCurrency(widget.product['price']),
                    style: const TextStyle(
                      fontFamily: 'Peyda',
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppTheme.primaryGold,
                    ),
                  ),
                ],
              ),
            ),

            // دکمه افزودن
            Expanded(
              flex: 3,
              child: SizedBox(
                height: 48,
                child: ElevatedButton(
                  onPressed: isMainProductInCart
                      ? null
                      : () {
                          widget.onAddToCart(widget.product);
                          setState(() {});
                        },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGold,
                    foregroundColor: Colors.black87,
                    disabledBackgroundColor: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(15),
                    ),
                    elevation: 0,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        isMainProductInCart
                            ? Icons.check
                            : Icons.shopping_bag_outlined,
                        size: 20,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        isMainProductInCart ? "موجود در سبد" : "افزودن به سبد",
                        style: const TextStyle(
                          fontFamily: 'Peyda',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── ردیف جدول مشخصات ───
  Widget _buildDetailRow(String title, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Peyda',
            fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontFamily: 'Peyda',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  // ─── کارت محصولات مشابه ───
  Widget _buildSimilarProductCard(Map<String, dynamic> item) {
    bool isInCart = widget.cartItems.any(
      (cartItem) => cartItem['id'] == item['id'],
    );
    final String imageUrl = item['image'] ?? "";
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
            color: Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: InkWell(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => ProductDetailScreen(
                      product: item,
                      onAddToCart: widget.onAddToCart,
                      cartItems: widget.cartItems,
                    ),
                  ),
                ).then((_) => setState(() {})); // آپدیت صفحه موقع برگشت
              },
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                              errorBuilder: (c, e, s) =>
                                  const Icon(Icons.image_not_supported),
                            )
                          : Icon(
                              Icons.diamond_outlined,
                              size: 40,
                              color: AppTheme.primaryGold.withOpacity(0.5),
                            ),
                    ),
                  ),
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
                            item['name'],
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontFamily: 'Peyda',
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${item['weight']} گرم",
                                style: const TextStyle(
                                  fontFamily: 'Peyda',
                                  fontSize: 10,
                                  color: AppTheme.primaryGold,
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  _formatCurrency(item['price']),
                                  textAlign: TextAlign.left,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontFamily: 'Peyda',
                                    fontSize: 11,
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
          Padding(
            padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
            child: SizedBox(
              height: 30,
              child: ElevatedButton(
                onPressed: isInCart
                    ? null
                    : () {
                        widget.onAddToCart(item);
                        setState(() {});
                      },
                style: ElevatedButton.styleFrom(
                  backgroundColor: Theme.of(
                    context,
                  ).colorScheme.surface.withOpacity(0.1),
                  foregroundColor: isInCart
                      ? Colors.redAccent
                      : AppTheme.primaryGold,
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  side: BorderSide(
                    color: isInCart ? Colors.redAccent : AppTheme.primaryGold,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isInCart ? Icons.check : Icons.add_shopping_cart,
                      size: 14,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      isInCart ? "موجود" : "افزودن به سبد",
                      style: const TextStyle(
                        fontFamily: 'Peyda',
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
