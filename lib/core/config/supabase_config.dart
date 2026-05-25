/// Configuración de credenciales Supabase para PROGANA Fantasy
///
/// IMPORTANTE: Las claves ANON_KEY son PÚBLICAS por diseño.
/// La seguridad real está en las RLS policies de la base de datos.
library;

class SupabaseConfig {
  /// URL del proyecto Supabase de PROGANA
  static const String url = 'https://zqqylkabzlqhtfhmbxse.supabase.co';

  /// ANON KEY (clave anónima pública)
  static const String anonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpxcXlsa2FiemxxaHRmaG1ieHNlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzg3MTE0MTUsImV4cCI6MjA5NDI4NzQxNX0.DQn24Zm3Sz6nQ1RVJVZ5KT9W7MTx-dpKOZND0xYBBEQ';
}