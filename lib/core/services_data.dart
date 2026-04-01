import 'package:flutter/material.dart';

class ServiceData {
  final String name;
  final String category;
  final Color color;
  final IconData icon;

  const ServiceData({
    required this.name,
    required this.category,
    required this.color,
    required this.icon,
  });
}

const List<ServiceData> popularServices = [
  ServiceData(
    name: 'Netflix',
    category: 'Entertainment',
    color: Color(0xFFE50914),
    icon: Icons.movie_filter_rounded,
  ),
  ServiceData(
    name: 'Spotify',
    category: 'Music',
    color: Color(0xFF1DB954),
    icon: Icons.music_note_rounded,
  ),
  ServiceData(
    name: 'Disney+',
    category: 'Entertainment',
    color: Color(0xFF113CCF),
    icon: Icons.smart_display_rounded,
  ),
  ServiceData(
    name: 'YouTube Premium',
    category: 'Entertainment',
    color: Color(0xFFFF0000),
    icon: Icons.play_circle_filled_rounded,
  ),
  ServiceData(
    name: 'YouTube Music',
    category: 'Music',
    color: Color(0xFFFF0000),
    icon: Icons.music_video_rounded,
  ),
  ServiceData(
    name: 'Hulu',
    category: 'Entertainment',
    color: Color(0xFF1CE783),
    icon: Icons.movie_outlined,
  ),
  ServiceData(
    name: 'HBO Max',
    category: 'Entertainment',
    color: Color(0xFF5321B0),
    icon: Icons.movie_outlined,
  ),
  ServiceData(
    name: 'Amazon Prime',
    category: 'Entertainment',
    color: Color(0xFF00A8E1),
    icon: Icons.shopping_bag_rounded,
  ),
  ServiceData(
    name: 'Xbox Game Pass',
    category: 'Gaming',
    color: Color(0xFF107C10),
    icon: Icons.sports_esports_rounded,
  ),
  ServiceData(
    name: 'PlayStation Plus',
    category: 'Gaming',
    color: Color(0xFF003087),
    icon: Icons.sports_esports_rounded,
  ),
  ServiceData(
    name: 'iCloud+',
    category: 'Utilities',
    color: Color(0xFF007AFF),
    icon: Icons.cloud_done_rounded,
  ),
  ServiceData(
    name: 'Google One',
    category: 'Utilities',
    color: Color(0xFF4285F4),
    icon: Icons.storage_rounded,
  ),
  ServiceData(
    name: 'ChatGPT Plus',
    category: 'Productivity',
    color: Color(0xFF10A37F),
    icon: Icons.psychology_rounded,
  ),
  ServiceData(
    name: 'Github Copilot',
    category: 'Productivity',
    color: Color(0xFFE6EDF3),
    icon: Icons.code_rounded,
  ),
  ServiceData(
    name: 'Figma Pro',
    category: 'Productivity',
    color: Color(0xFFF24E1E),
    icon: Icons.design_services_outlined,
  ),
  ServiceData(
    name: 'Canva Pro',
    category: 'Productivity',
    color: Color(0xFF00C4CC),
    icon: Icons.palette_outlined,
  ),
  ServiceData(
    name: 'Adobe Creative Cloud',
    category: 'Productivity',
    color: Color(0xFFFA0F00),
    icon: Icons.brush_rounded,
  ),
  ServiceData(
    name: 'Duolingo Plus',
    category: 'Education',
    color: Color(0xFF58CC02),
    icon: Icons.language_rounded,
  ),
  ServiceData(
    name: 'Coursera Plus',
    category: 'Education',
    color: Color(0xFF0056D2),
    icon: Icons.school_rounded,
  ),
  ServiceData(
    name: 'Peloton',
    category: 'Health&Fitness',
    color: Color(0xFFDF1C24),
    icon: Icons.fitness_center_rounded,
  ),
  ServiceData(
    name: 'Calm',
    category: 'Health&Fitness',
    color: Color(0xFF4285F4),
    icon: Icons.spa_rounded,
  ),
  ServiceData(
    name: 'Costco',
    category: 'Shopping',
    color: Color(0xFFE31837),
    icon: Icons.shopping_cart_rounded,
  ),
  ServiceData(
    name: 'Microsoft 365',
    category: 'Productivity',
    color: Color(0xFFD83B01),
    icon: Icons.work_outline_rounded,
  ),
  ServiceData(
    name: 'Discord Nitro',
    category: 'Gaming',
    color: Color(0xFF5865F2),
    icon: Icons.chat_bubble_rounded,
  ),
  ServiceData(
    name: 'Uber One',
    category: 'Utilities',
    color: Color(0xFF000000),
    icon: Icons.directions_car_rounded,
  ),
  ServiceData(
    name: 'DashPass',
    category: 'Shopping',
    color: Color(0xFFFF3008),
    icon: Icons.fastfood_rounded,
  ),
  ServiceData(
    name: 'LinkedIn Premium',
    category: 'Productivity',
    color: Color(0xFF0A66C2),
    icon: Icons.business_center_rounded,
  ),
  ServiceData(
    name: 'Notion Plus',
    category: 'Productivity',
    color: Color(0xFF000000),
    icon: Icons.note_alt_rounded,
  ),
  ServiceData(
    name: 'Paramount+',
    category: 'Entertainment',
    color: Color(0xFF0064FF),
    icon: Icons.movie_rounded,
  ),
  ServiceData(
    name: 'Peacock',
    category: 'Entertainment',
    color: Color(0xFF000000),
    icon: Icons.live_tv_rounded,
  ),
  ServiceData(
    name: 'Skillshare',
    category: 'Education',
    color: Color(0xFF00FF84),
    icon: Icons.lightbulb_rounded,
  ),
  ServiceData(
    name: 'Slack Pro',
    category: 'Productivity',
    color: Color(0xFF4A154B),
    icon: Icons.record_voice_over_rounded,
  ),
];
