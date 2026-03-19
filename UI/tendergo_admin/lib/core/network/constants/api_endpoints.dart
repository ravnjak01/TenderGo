class ApiEndpoints {
  // --- AUTH MODUL ---
  static const String login = '/api/auth/login';
  static const String register = 'api/auth/register';

  // --- TENDERI (TenderGo) ---
  static const String getTenders = '/tenders';
  static const String createTender = '/tenders/create';
  
  // Primjer putanje sa parametrom 
  static String tenderDetails(int id) => '/tenders/$id';

  // --- KORISNIK ---
  static const String userProfile = '/user/profile';
}