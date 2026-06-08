import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../viewmodels/hi_tab_viewmodel.dart';

class HiTabScreen extends StatefulWidget {
  final List<Map<String, dynamic>>? savedList;
  const HiTabScreen({super.key, this.savedList});

  @override
  State<HiTabScreen> createState() => _HiTabScreenState();
}

class _HiTabScreenState extends State<HiTabScreen> {
  // کنترلرها
  final FocusNode _focusNode = FocusNode();
  final ScrollController _scrollController = ScrollController();
  String _scannedEpcBuffer = '';

  // برای مدیریت لودینگ ثبت نهایی (چون لودینگ اسکنر تو ویومدل هست)
  bool _isProcessingSale = false;

  @override
  void initState() {
    super.initState();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _focusNode.requestFocus();

      // راه‌اندازی لیست و ریدر از طریق ویومدل
      final viewModel = Provider.of<HiTabViewModel>(context, listen: false);
      viewModel.initList(widget.savedList);
      viewModel.startScanning();
    });
  }

  @override
  void dispose() {
    // توقف ریدر موقع خروج
    final viewModel = Provider.of<HiTabViewModel>(context, listen: false);
    viewModel.stopScanning();

    _focusNode.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  // ─── منطق ثبت فروش و بررسی مشتری (همون کدهای قبلی خودت) ───────────────
  Map<String, dynamic>? _foundCustomer;
  bool _isCheckingCustomer = false;

  Future<void> _finalizeSale(HiTabViewModel viewModel) async {
    if (viewModel.invoiceList.isEmpty) return;
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
                                "${_foundCustomer!['name']}",
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
                              viewModel,
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
                        _sendSaleRequest(
                          _foundCustomer!['code'].toString(),
                          viewModel,
                        );
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

  Future<void> _checkCustomer(
    String phone,
    StateSetter setStateDialog,
    HiTabViewModel viewModel,
  ) async {
    if (phone.length < 10) {
      _showSnackBar("شماره موبایل باید ۱۱ رقم باشد", Colors.orange);
      return;
    }
    setStateDialog(() => _isCheckingCustomer = true);
    try {
      final url = Uri.parse("${AppConstants.baseUrl}/check_Customer/");
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
          _showCreateAccountDialog(phone, viewModel);
        }
      } else {
        Navigator.pop(context);
        _showCreateAccountDialog(phone, viewModel);
      }
    } catch (e) {
      _showSnackBar("خطای ارتباط با سرور", Colors.red);
      setStateDialog(() => _isCheckingCustomer = false);
    }
  }

  void _showCreateAccountDialog(String phone, HiTabViewModel viewModel) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final phoneController = TextEditingController(text: phone);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Theme.of(ctx).colorScheme.surface,
          title: const Text(
            "ایجاد مشتری جدید",
            style: TextStyle(fontFamily: 'Peyda'),
          ),
          content: Form(
            key: formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: nameController,
                    style: const TextStyle(fontFamily: 'Peyda'),
                    decoration: const InputDecoration(
                      labelText: "نام و نام خانوادگی*",
                      prefixIcon: Icon(Icons.person),
                    ),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? "نام اجباری است"
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
                        ? "شماره باید ۱۱ رقم باشد"
                        : null,
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
                    viewModel: viewModel,
                  );
                  Navigator.pop(ctx);
                }
              },
              child: const Text(
                "ثبت و ادامه",
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
    required HiTabViewModel viewModel,
  }) async {
    try {
      final url = Uri.parse("${AppConstants.baseUrl}/add_new_customer/");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "name": name,
          "phone_number": phone,
          "address": "",
          "code_meli": "",
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        if (data.containsKey('data') && data['data']['ok'] != null) {
          _showSnackBar("مشتری '$name' ثبت شد", Colors.green);
          _sendSaleRequest(data['data']['ok'].toString(), viewModel);
        }
      } else {
        _showSnackBar("خطا در ثبت مشتری", Colors.red);
      }
    } catch (e) {
      _showSnackBar("خطای ارتباط", Colors.red);
    }
  }

  Future<void> _sendSaleRequest(
    String customerId,
    HiTabViewModel viewModel,
  ) async {
    setState(() => _isProcessingSale = true);
    try {
      List<String> productCodes = viewModel.invoiceList
          .map((item) => item['code'].toString())
          .toList();
      final url = Uri.parse("${AppConstants.baseUrl}/sale/");
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"Code": productCodes, "Customer": customerId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        viewModel.clearAllItems();
        _showSnackBar("فروش با موفقیت ثبت شد", Colors.green);
        _focusNode.requestFocus();
      } else {
        _showSnackBar("خطا در ثبت فروش", Colors.redAccent);
      }
    } catch (e) {
      _showSnackBar("خطای ارتباط", Colors.red);
    } finally {
      setState(() => _isProcessingSale = false);
    }
  }

  // ─── ابزارهای کمکی ──────────────────────────────────────────────────
  void _showSnackBar(String message, Color color) {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          message,
          style: const TextStyle(
            fontFamily: 'Peyda',
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 1),
      ),
    );
  }

  String _formatCurrency(dynamic value) {
    if (value == null) return "0";
    String priceStr = value
        .toString()
        .replaceAll(',', '')
        .replaceAll(' ', '')
        .trim();
    if (priceStr.isEmpty || priceStr == "null") return "0";
    try {
      double? p = double.tryParse(priceStr);
      if (p == null) return priceStr;
      return p.toInt().toString().replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      );
    } catch (e) {
      return priceStr;
    }
  }

  double _calculateTotal(List<Map<String, dynamic>> list, String key) {
    double total = 0;
    for (var item in list) {
      String cleanValue = item[key].toString().replaceAll(',', '').trim();
      total += double.tryParse(cleanValue) ?? 0;
    }
    return total;
  }

  // ─── رابط کاربری (UI) ───────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    // 👈 دریافت اطلاعات از ویومدل
    final viewModel = Provider.of<HiTabViewModel>(context);

    // مدیریت اسنک‌بارها از طریق ویومدل
    if (viewModel.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSnackBar(viewModel.errorMessage!, Colors.redAccent);
        viewModel.clearMessages();
      });
    }

    if (viewModel.successMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _showSnackBar(viewModel.successMessage!, Colors.green);
        // اسکرول خودکار به پایین بعد از اضافه شدن آیتم جدید
        if (_scrollController.hasClients) {
          _scrollController.animateTo(
            _scrollController.position.maxScrollExtent,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
        viewModel.clearMessages();
      });
    }

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (bool didPop, dynamic result) {
        if (didPop) return;
        Navigator.pop(
          context,
          viewModel.invoiceList,
        ); // 👈 برگرداندن لیست از ویومدل
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,

          // هدر
          appBar: AppBar(
            backgroundColor: Theme.of(context).colorScheme.surface,
            elevation: 0,
            centerTitle: true,
            title: const Text(
              "HI-TAB",
              style: TextStyle(
                fontFamily: 'Peyda',
                color: AppTheme.primaryGold,
                fontWeight: FontWeight.bold,
              ),
            ),
            leading: IconButton(
              icon: Icon(
                Icons.arrow_back_ios,
                color: Theme.of(context).colorScheme.onSurface,
              ),
              onPressed: () => Navigator.pop(context, viewModel.invoiceList),
            ),
            actions: [
              if (viewModel.invoiceList.isNotEmpty)
                IconButton(
                  tooltip: "حذف همه",
                  icon: const Icon(Icons.delete_sweep, color: Colors.redAccent),
                  onPressed: () => _showClearDialog(viewModel),
                ),
            ],
          ),

          // فوتر
          bottomNavigationBar: _buildBottomBar(viewModel),

          // بدنه
          body: GestureDetector(
            onTap: () => _focusNode.requestFocus(),
            behavior: HitTestBehavior.translucent,
            child: KeyboardListener(
              focusNode: _focusNode,
              autofocus: true,
              onKeyEvent: (KeyEvent event) {
                if (event is KeyDownEvent) {
                  if (event.logicalKey == LogicalKeyboardKey.enter) {
                    if (_scannedEpcBuffer.isNotEmpty) {
                      viewModel.handleScan(
                        _scannedEpcBuffer,
                      ); // 👈 استفاده از ویومدل
                      _scannedEpcBuffer = '';
                    }
                  } else {
                    _scannedEpcBuffer += event.character ?? '';
                  }
                }
              },
              child: Column(
                children: [
                  if (viewModel.isLoading || _isProcessingSale)
                    const LinearProgressIndicator(
                      color: AppTheme.primaryGold,
                      minHeight: 3,
                    ),
                  Expanded(child: _buildInvoiceList(viewModel)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showClearDialog(HiTabViewModel viewModel) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Theme.of(ctx).colorScheme.surface,
          title: Text(
            "هشدار",
            style: TextStyle(
              fontFamily: 'Peyda',
              color: Theme.of(ctx).colorScheme.onSurface,
            ),
          ),
          content: Text(
            "آیا مطمئن هستید که می‌خواهید کل لیست فروش را پاک کنید؟",
            style: TextStyle(
              fontFamily: 'Peyda',
              color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                "خیر",
                style: TextStyle(
                  fontFamily: 'Peyda',
                  color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.redAccent,
              ),
              onPressed: () {
                Navigator.pop(ctx);
                viewModel.clearAllItems();
                _showSnackBar("لیست فروش پاک شد", Colors.orange);
                _focusNode.requestFocus();
              },
              child: const Text(
                "بله، پاک کن",
                style: TextStyle(fontFamily: 'Peyda', color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInvoiceList(HiTabViewModel viewModel) {
    if (viewModel.invoiceList.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.document_scanner_outlined,
              size: 80,
              color: AppTheme.primaryGold.withOpacity(0.3),
            ),
            const SizedBox(height: 20),
            Text(
              "لیست فروش خالی است",
              style: TextStyle(
                fontFamily: 'Peyda',
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "تگ کالا را با ریدر اسکن کنید",
              style: TextStyle(
                fontFamily: 'Peyda',
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                fontSize: 12,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      controller: _scrollController,
      padding: const EdgeInsets.all(16),
      itemCount: viewModel.invoiceList.length,
      itemBuilder: (context, index) {
        final item = viewModel.invoiceList[index];
        return Directionality(
          textDirection: TextDirection.rtl,
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface,
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: Theme.of(
                  context,
                ).colorScheme.onSurface.withOpacity(0.05),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.02),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 25,
                  height: 25,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryGold.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    "${index + 1}",
                    style: const TextStyle(
                      fontFamily: 'Peyda',
                      color: AppTheme.primaryGold,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item['name'],
                        style: TextStyle(
                          fontFamily: 'Peyda',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            "کد: ${item['code']}",
                            style: TextStyle(
                              fontFamily: 'Peyda',
                              fontSize: 11,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            "وزن: ${item['weight']}g",
                            style: TextStyle(
                              fontFamily: 'Peyda',
                              fontSize: 11,
                              color: Theme.of(
                                context,
                              ).colorScheme.onSurface.withOpacity(0.5),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(item['price']),
                        style: const TextStyle(
                          fontFamily: 'Peyda',
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(
                    Icons.delete_outline,
                    color: Colors.redAccent,
                    size: 22,
                  ),
                  onPressed: () => viewModel.removeFromInvoice(index),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  // ── ساخت فوتر ثابت پایین صفحه ──
  Widget _buildBottomBar(HiTabViewModel viewModel) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
        borderRadius: const BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Directionality(
              textDirection: TextDirection.rtl,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "تعداد: ${viewModel.invoiceList.length} عدد",
                        style: TextStyle(
                          fontFamily: 'Peyda',
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "وزن کل: ${_calculateTotal(viewModel.invoiceList, 'weight').toStringAsFixed(2)} گرم",
                        style: TextStyle(
                          fontFamily: 'Peyda',
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        "جمع کل فاکتور:",
                        style: TextStyle(
                          fontFamily: 'Peyda',
                          fontSize: 12,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatCurrency(
                          _calculateTotal(viewModel.invoiceList, 'price'),
                        ),
                        style: const TextStyle(
                          fontFamily: 'Peyda',
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryGold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // دکمه ثبت نهایی
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                // اگر لیست خالیه یا داره پردازش میکنه، دکمه غیرفعال بشه
                onPressed:
                    viewModel.invoiceList.isNotEmpty && !_isProcessingSale
                    ? () => _finalizeSale(viewModel)
                    : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: viewModel.invoiceList.isNotEmpty
                      ? AppTheme.primaryGold
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.1),
                  foregroundColor: viewModel.invoiceList.isNotEmpty
                      ? Colors.black87
                      : Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: _isProcessingSale
                    ? const SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          color: Colors.black87,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        "ثبت نهایی فروش",
                        style: TextStyle(
                          fontFamily: 'Peyda',
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
