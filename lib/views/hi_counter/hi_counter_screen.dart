import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/rfid_service.dart';
import '../../viewmodels/hi_counter_viewmodel.dart';

class HiCounterScreen extends StatelessWidget {
  const HiCounterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) =>
          HiCounterViewModel(rfidService: context.read<RfidService>()),
      child: const _HiCounterView(),
    );
  }
}

class _HiCounterView extends StatefulWidget {
  const _HiCounterView();

  @override
  State<_HiCounterView> createState() => _HiCounterViewState();
}

class _HiCounterViewState extends State<_HiCounterView> {
  @override
  void initState() {
    super.initState();
    // وقتی وارد صفحه شدیم اسکن رو شروع کن
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HiCounterViewModel>().startScanning();
    });
  }

  @override
  void dispose() {
    // وقتی از صفحه رفتیم اسکن رو متوقف کن
    context.read<HiCounterViewModel>().stopScanning();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<HiCounterViewModel>();

    // نمایش خطا با SnackBar
    if (vm.errorMessage != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              vm.errorMessage!,
              style: const TextStyle(fontFamily: 'Peyda'),
            ),
            backgroundColor: vm.errorMessage!.contains('برگشت')
                ? Colors.orange
                : Colors.redAccent,
            duration: const Duration(seconds: 2),
          ),
        );
        vm.clearError();
      });
    }
    return PopScope(
      canPop: false, // جلوگیری از خروج خودکار
      onPopInvoked: (didPop) async {
        if (didPop) return;

        // اول اسکن رو متوقف می‌کنیم و منتظر می‌مونیم تموم شه
        await context.read<HiCounterViewModel>().stopScanning();

        // بعد از اینکه مطمئن شدیم خاموش شد، از صفحه خارج میشیم
        if (context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: SafeArea(
        child: Scaffold(
          backgroundColor: Theme.of(context).scaffoldBackgroundColor,
          appBar: _buildAppBar(context, vm),
          // 👇 اینجا فرق اصلیه - Column به جای Row
          body: Column(
            children: [
              // --- بخش اطلاعات محصول (بالا) ---
              Expanded(
                flex: 5,
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: vm.isLoading
                      ? const Center(
                          child: CircularProgressIndicator(
                            color: AppTheme.primaryGold,
                          ),
                        )
                      : vm.currentProduct == null
                      ? _buildWaitingState(context)
                      : _buildProductDetails(context, vm),
                ),
              ),

              // --- خط جداکننده ---
              Divider(
                color: AppTheme.primaryGold.withOpacity(0.3),
                thickness: 1,
                indent: 16,
                endIndent: 16,
              ),

              // --- لیست امانی (پایین) ---
              Expanded(flex: 5, child: _buildTrustList(context, vm)),
            ],
          ),
        ),
      ),
    );
  }

  AppBar _buildAppBar(BuildContext context, HiCounterViewModel vm) {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: const Text(
        'HI-COUNTER',
        style: TextStyle(fontFamily: 'Peyda', color: AppTheme.primaryGold),
      ),
      centerTitle: true,
      leading: IconButton(
        icon: Icon(
          Icons.arrow_back_ios,
          color: Theme.of(context).colorScheme.onSurface,
        ),
        onPressed: () async {
          await vm.stopScanning();
          if (context.mounted) {
            Navigator.maybePop(context);
          }
        },
      ),
      actions: [
        IconButton(
          icon: Icon(
            vm.isMuted ? Icons.volume_off : Icons.volume_up,
            color: vm.isMuted
                ? Colors.redAccent
                : Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: vm.toggleMute,
        ),
        IconButton(
          icon: Icon(
            Icons.timer_outlined,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          onPressed: () => _showTimeDialog(context, vm),
        ),
      ],
    );
  }

  // ── حالت انتظار ─────────────────────────────────────────────────
  Widget _buildWaitingState(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface.withOpacity(0.05),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
          width: 2,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Image.asset(
            'assets/images/rfid.png',
            width: 70,
            height: 70,
            color: AppTheme.primaryGold,
          ),
          const SizedBox(height: 16),
          Text(
            'آماده اسکن...',
            style: TextStyle(
              fontFamily: 'Peyda',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'برای اضافه کردن یا حذف، تگ را اسکن کنید',
            style: TextStyle(
              fontFamily: 'Peyda',
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.54),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  // ── اطلاعات محصول ───────────────────────────────────────────────
  Widget _buildProductDetails(BuildContext context, HiCounterViewModel vm) {
    final product = vm.currentProduct!;
    final bool isAvailable = product['is_available'];

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppTheme.primaryGold, width: 2),
      ),
      child: Column(
        children: [
          // هدر
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                onPressed: vm.clearCurrentProduct,
                icon: const Icon(
                  Icons.close,
                  color: Colors.redAccent,
                  size: 24,
                ),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
              Text(
                'اطلاعات محصول',
                style: TextStyle(
                  fontFamily: 'Peyda',
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.primaryGold,
                ),
              ),
              const SizedBox(width: 40),
            ],
          ),

          const SizedBox(height: 8),

          // محتوا - افقی برای صرفه‌جویی در فضا
          Expanded(
            child: Row(
              children: [
                // تصویر
                Container(
                  width: 90,
                  height: double.infinity,
                  decoration: BoxDecoration(
                    color: Theme.of(
                      context,
                    ).colorScheme.surface.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.2),
                    ),
                    image: product['image'] != ''
                        ? DecorationImage(
                            image: NetworkImage(product['image']),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: product['image'] == ''
                      ? Icon(
                          Icons.image_not_supported,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.24),
                        )
                      : null,
                ),

                const SizedBox(width: 12),

                // اطلاعات
                Expanded(
                  child: SingleChildScrollView(
                    child: Column(
                      children: [
                        _buildRow(context, 'نام کالا', product['name']),
                        _buildRow(context, 'کد', product['code']),
                        _buildRow(context, 'وزن', '${product['weight']} گرم'),
                        _buildRow(
                          context,
                          'قیمت',
                          product['price'] == '0'
                              ? 'محاسبه نشده'
                              : '${product['price']} ریال',
                          isBold: true,
                        ),
                        // وضعیت
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              isAvailable ? 'موجود' : 'ناموجود',
                              style: TextStyle(
                                fontFamily: 'Peyda',
                                color: isAvailable
                                    ? Colors.greenAccent
                                    : Colors.redAccent,
                                fontSize: 13,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            const SizedBox(width: 4),
                            Text(
                              'وضعیت:',
                              style: TextStyle(
                                fontFamily: 'Peyda',
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurface.withOpacity(0.54),
                                fontSize: 12,
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

          const SizedBox(height: 8),

          // دکمه تایید
          SizedBox(
            width: double.infinity,
            height: 40,
            child: ElevatedButton(
              onPressed: isAvailable ? vm.addToTrust : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: isAvailable
                    ? AppTheme.primaryGold
                    : Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
              ),
              child: Text(
                isAvailable ? 'تایید امانی' : 'کالا ناموجود است',
                style: TextStyle(
                  fontFamily: 'Peyda',
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                  color: isAvailable ? Colors.black87 : Colors.white54,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── لیست امانی ──────────────────────────────────────────────────
  Widget _buildTrustList(BuildContext context, HiCounterViewModel vm) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
        ),
      ),
      child: Column(
        children: [
          // هدر لیست
          Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'تعداد: ${vm.trustList.length}',
                  style: TextStyle(
                    fontFamily: 'Peyda',
                    color: Theme.of(
                      context,
                    ).colorScheme.onSurface.withOpacity(0.54),
                    fontSize: 13,
                  ),
                ),
                Text(
                  'لیست امانی',
                  style: TextStyle(
                    fontFamily: 'Peyda',
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
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

          // لیست آیتم‌ها
          Expanded(
            child: vm.trustList.isEmpty
                ? Center(
                    child: Text(
                      'لیست خالی',
                      style: TextStyle(
                        fontFamily: 'Peyda',
                        color: Theme.of(
                          context,
                        ).colorScheme.onSurface.withOpacity(0.24),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(8),
                    itemCount: vm.trustList.length,
                    itemBuilder: (context, index) {
                      final reversedIndex = vm.trustList.length - 1 - index;
                      final item = vm.trustList[reversedIndex];
                      final duration = DateTime.now().difference(
                        item['start_time'],
                      );
                      final timeStr =
                          '${duration.inMinutes}:${(duration.inSeconds % 60).toString().padLeft(2, '0')}';
                      final isOverdue =
                          vm.alertTimeInMinutes != null &&
                          duration.inMinutes >= vm.alertTimeInMinutes!;

                      return _buildTrustItem(
                        context: context,
                        item: item,
                        timeStr: timeStr,
                        isOverdue: isOverdue,
                        onDelete: () => vm.removeFromTrust(reversedIndex),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildTrustItem({
    required BuildContext context,
    required Map<String, dynamic> item,
    required String timeStr,
    required bool isOverdue,
    required VoidCallback onDelete,
  }) {
    return GestureDetector(
      onLongPress: () => _showDeleteDialog(context, onDelete),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: isOverdue
              ? Colors.red.withOpacity(0.2)
              : Theme.of(context).colorScheme.surface.withOpacity(0.05),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isOverdue
                ? Colors.redAccent.withOpacity(0.8)
                : Theme.of(context).colorScheme.onSurface.withOpacity(0.1),
            width: isOverdue ? 2 : 1,
          ),
        ),
        child: Row(
          textDirection: TextDirection.rtl,
          children: [
            // تصویر کوچک
            Container(
              width: 45,
              height: 45,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                image: item['image'] != ''
                    ? DecorationImage(
                        image: NetworkImage(item['image']),
                        fit: BoxFit.cover,
                      )
                    : null,
              ),
              child: item['image'] == ''
                  ? Icon(
                      Icons.image,
                      color: Theme.of(
                        context,
                      ).colorScheme.onSurface.withOpacity(0.24),
                      size: 20,
                    )
                  : null,
            ),

            const SizedBox(width: 8),

            // اطلاعات
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    item['name'] ?? 'بدون نام',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontFamily: 'Peyda',
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'کد: ${item['code'] ?? '-'}',
                        style: TextStyle(
                          fontFamily: 'Peyda',
                          fontSize: 11,
                          color: Theme.of(
                            context,
                          ).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        '${item['price']} ریال',
                        style: const TextStyle(
                          fontFamily: 'Peyda',
                          fontSize: 11,
                          color: AppTheme.primaryGold,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // تایمر
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppTheme.primaryGold.withOpacity(0.2),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                timeStr,
                style: const TextStyle(
                  fontFamily: 'Peyda',
                  color: AppTheme.primaryGold,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRow(
    BuildContext context,
    String label,
    String value, {
    bool isBold = false,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        textDirection: TextDirection.rtl,
        children: [
          Text(
            label,
            style: TextStyle(
              fontFamily: 'Peyda',
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontFamily: 'Peyda',
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              color: isBold
                  ? AppTheme.primaryGold
                  : Theme.of(context).colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteDialog(BuildContext context, VoidCallback onDelete) {
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Theme.of(ctx).colorScheme.surface,
          title: Row(
            children: [
              const Icon(
                Icons.warning_amber_rounded,
                color: AppTheme.primaryGold,
              ),
              const SizedBox(width: 10),
              Text(
                'حذف آیتم',
                style: TextStyle(
                  fontFamily: 'Peyda',
                  color: Theme.of(ctx).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          content: Text(
            'آیا از حذف این کالا از لیست امانی مطمئن هستید؟',
            style: TextStyle(
              fontFamily: 'Peyda',
              color: Theme.of(ctx).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(
                'خیر',
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
                onDelete();
              },
              child: const Text(
                'بله، حذف شود',
                style: TextStyle(color: Colors.white, fontFamily: 'Peyda'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showTimeDialog(BuildContext context, HiCounterViewModel vm) {
    final controller = TextEditingController(
      text: vm.alertTimeInMinutes?.toString() ?? '',
    );
    showDialog(
      context: context,
      builder: (ctx) => Directionality(
        textDirection: TextDirection.rtl,
        child: AlertDialog(
          backgroundColor: Theme.of(ctx).colorScheme.surface,
          title: Text(
            'تنظیم زمان هشدار',
            style: TextStyle(
              fontFamily: 'Peyda',
              color: Theme.of(ctx).colorScheme.onSurface,
            ),
          ),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'زمان به دقیقه',
              labelStyle: TextStyle(fontFamily: 'Peyda'),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('لغو', style: TextStyle(fontFamily: 'Peyda')),
            ),
            ElevatedButton(
              onPressed: () {
                vm.setAlertTime(int.tryParse(controller.text));
                Navigator.pop(ctx);
              },
              child: const Text('ذخیره', style: TextStyle(fontFamily: 'Peyda')),
            ),
          ],
        ),
      ),
    );
  }
}
