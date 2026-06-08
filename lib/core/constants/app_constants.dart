class AppConstants {
  // ── Base URL ────────────────────────────────────────────────────
  // اینجا دیگه const نیست، یه مقدار اولیه داره که بعد از لاگین عوض میشه
  static String baseUrl = 'http://127.0.0.1:8000';

  // ── Auth ─────────────────────────────────────────────────────────
  static const String loginUrl = 'http://176.97.218.146:8000/login/';

  // ── HiCounter ───────────────────────────────────────────────────
  // دقت کن! اینجا از کلمه get استفاده کردیم.
  // این باعث میشه هر بار که این متغیر رو صدا میزنی، با baseUrl جدید ساخته بشه
  static String get getProductByRfidUrl => '$baseUrl/get_info_with_RFID/';
}
