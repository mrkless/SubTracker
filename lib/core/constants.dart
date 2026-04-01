class AppConstants {
  // SUPABASE CONFIGURATION
  // Note: Replace these with actual Supabase values in production.
  static const String supabaseUrl = 'https://bkpuegkmxfqtgpenhcpg.supabase.co';
  static const String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImJrcHVlZ2tteGZxdGdwZW5oY3BnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzQ0MzU1OTEsImV4cCI6MjA5MDAxMTU5MX0.YnOV0HZGNDeaFPIjBw7LHGLRhDTjEMirUTgSUz8Di6U';

  // CATEGORIES
  static const List<String> defaultCategories = [
    'Entertainment',
    'Productivity',
    'Music',
    'Gaming',
    'Health&Fitness',
    'Education',
    'Shopping',
    'Utilities',
    'Others',
  ];

  static const List<String> billingCycles = [
    'Monthly',
    'Yearly',
    'Weekly',
  ];
}
