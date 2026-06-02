class AppConstants {
  // ── Base URL ────────────────────────────────────────────────────
  // فقط اینجا رو عوض کن، همه جا آپدیت میشه
  static const String baseUrl = 'http://176.97.218.146:8000';

  // ── Auth ─────────────────────────────────────────────────────────
  static const String loginUrl = '$baseUrl/login/';

  // ── HiCounter ───────────────────────────────────────────────────
  static const String getProductByRfidUrl = '$baseUrl/get_info_with_RFID/';

  // بعداً هر URL جدیدی اینجا اضافه میکنی 👇
  // static const String anotherUrl = '$baseUrl/...';
}
