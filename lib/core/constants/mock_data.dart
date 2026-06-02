class MockData {
  // ── Mock Login Credentials ──────────────────────────────────────
  static const String mockUsername = 'admin';
  static const String mockPassword = '123456';

  // ── Mock User Data (اگه نیاز داشتی) ────────────────────────────
  static const Map<String, dynamic> mockUserData = {
    'status': 'ok',
    'user_info': {
      'username': 'admin',
      'name': 'مدیر سیستم',
      'url': 'http://176.97.218.146:8000',
    },
  };
}
