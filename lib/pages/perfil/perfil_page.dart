import 'dart:io';
import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../bienvenida/bienvenida_page.dart';
import 'editar_perfil_page.dart';
import '../../models/user_model.dart' as models;
import '../../services/auth_service.dart';
import '../../services/stats_service.dart';
import '../../services/user_service.dart';
import '../../theme/theme_notifier.dart';
import '../../theme/calm_mode_notifier.dart';
import '../../widgets/neuro_dialog.dart';
import '../achievements/stickers_page.dart';
import '../../widgets/smooth_page_route.dart';

class PerfilPage extends StatefulWidget {
  const PerfilPage({super.key});

  @override
  State<PerfilPage> createState() => _PerfilPageState();
}

class _PerfilPageState extends State<PerfilPage> {
  models.User? _user;
  bool _loading = true;

  int _totalFocusTime = 0;
  int _completedTasks = 0;
  int _testsCompleted = 0;
  int _pomodoros = 0;
  int _streak = 0;
  
  int _totalXP = 0;
  int _level = 1;
  int _currentLevelXP = 0;
  int _nextLevelXP = 100;
  String _rankName = "Mente Novata 🌱";
  List<double> _weeklyStats = [];

  @override
  void initState() {
    super.initState();
    _loadUserFromDatabase();
    _loadRealStats();
  }

  //-------------------------
  // CARGAR PERFIL LOCAL
  //-------------------------
  Future<void> _loadUserFromDatabase() async {
    setState(() => _loading = true);
    try {
      final user = await UserService.getCurrentUser();
      if (!mounted) return;
      setState(() {
        _user = user;
        _loading = false;
      });
      await _loadRealStats();
    } catch (e) {
      debugPrint("Error cargando perfil: $e");
      if (mounted) setState(() => _loading = false);
    }
  }

  //-------------------------
  // CARGAR ESTADÍSTICAS
  //-------------------------
  Future<void> _loadRealStats() async {
    try {
      final stats = await StatsService.getQuickStats();
      final focusTime = stats['focusTime'] as int? ?? 0;
      final tasksCompleted = stats['tasksCompleted'] as int? ?? 0;
      final testsCompleted = stats['testsCompleted'] as int? ?? 0;
      final pomodoros = stats['pomodoros'] as int? ?? 0;

      final xpData = await StatsService.getXPAndLevel();
      final weeklyData = await StatsService.getWeeklyActivityStats();
      final streak = await StatsService.getStreak();

      if (!mounted) return;
      setState(() {
        _totalFocusTime = focusTime;
        _completedTasks = tasksCompleted;
        _testsCompleted = testsCompleted;
        _pomodoros = pomodoros;
        _streak = streak;

        _totalXP = xpData['totalXP'];
        _level = xpData['level'];
        _currentLevelXP = xpData['currentLevelXP'];
        _nextLevelXP = xpData['nextLevelXP'];
        _rankName = xpData['rankName'];

        _weeklyStats = weeklyData;
      });
    } catch (e) {
      debugPrint('Error cargando estadísticas: $e');
    }
  }

  //-------------------------
  // BUILD UI
  //-------------------------
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (_loading || _user == null) {
      return Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF1E1B4B)]
                : [const Color(0xFFF8FAFC), const Color(0xFFEEF2FF)],
          ),
        ),
        child: const Center(child: CircularProgressIndicator(color: Color(0xFF4F46E5))),
      );
    }

    final frasesMotivacionales = [
      "Tu crecimiento define tu camino 🌱",
      "Eres el arquitecto de tu mente 🏗️",
      "Cada logro cuenta en tu historia 📖",
      "Tu potencial es ilimitado 💎",
      "La disciplina te lleva al éxito 🎯",
      "Pequeños hábitos, grandes resultados 🌟",
      "Tu mente es tu santuario mental 🧘‍♂️",
      "El progreso es tu mejor recompensa 🏆",
    ];

    final frase =
        frasesMotivacionales[DateTime.now().day % frasesMotivacionales.length];

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF0F172A), const Color(0xFF1E1B4B)]
              : [const Color(0xFFF8FAFC), const Color(0xFFEEF2FF)],
        ),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildPremiumHeader(isDark, frase),
            const SizedBox(height: 24),
            _buildProfileCard(isDark),
            const SizedBox(height: 20),
            _buildLevelCard(isDark),
            const SizedBox(height: 20),
            _buildStatsRow(isDark),
            const SizedBox(height: 20),
            _buildFocusSummaryCard(isDark),
            const SizedBox(height: 20),
            _buildSettingsCard(isDark),
            const SizedBox(height: 20),
            if (_weeklyStats.isNotEmpty) ...[
              _buildActivityChart(isDark),
              const SizedBox(height: 20),
            ],
            _buildLogoutButton(isDark),
          ],
        ),
      ),
    );
  }

  //-------------------------
  // PREMIUM HEADER
  //-------------------------
  Widget _buildPremiumHeader(bool isDark, String frase) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Mi Perfil',
          style: TextStyle(
            fontSize: 26,
            fontWeight: FontWeight.w900,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          frase,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 500.ms).slideY(begin: -0.1);
  }

  //-------------------------
  // PROFILE CARD
  //-------------------------
  Widget _buildProfileCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
        boxShadow: isDark ? [] : [
          BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.06), blurRadius: 24, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: [
              // Avatar
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [Color(0xFF4F46E5), Color(0xFF8B5CF6)]),
                ),
                child: CircleAvatar(
                  radius: 36,
                  backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
                  child: _buildProfileImage(isDark),
                ),
              ),
              const SizedBox(width: 16),
              // Name & Email
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _user!.name ?? 'Usuario',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _user!.email,
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (_user!.career != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF4F46E5).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _user!.career!,
                          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Color(0xFF4F46E5)),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Edit Profile Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  SmoothPageRoute(page: EditarPerfilPage(
                    user: _user!,
                    onUserUpdated: (updated) {
                      setState(() => _user = updated);
                    },
                  )),
                );
              },
              icon: const Icon(Icons.edit_rounded, size: 18),
              label: const Text('Editar perfil', style: TextStyle(fontWeight: FontWeight.w700)),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1);
  }

  Widget _buildProfileImage(bool isDark) {
    final imagePath = _user!.profileImage;
    if (imagePath != null && imagePath.isNotEmpty) {
      if (imagePath.startsWith('http')) {
        return ClipOval(
          child: Image.network(
            imagePath,
            width: 68,
            height: 68,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildDefaultAvatar(isDark),
          ),
        );
      }
      final file = File(imagePath);
      if (file.existsSync()) {
        return ClipOval(
          child: Image.file(
            file,
            width: 68,
            height: 68,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => _buildDefaultAvatar(isDark),
          ),
        );
      }
    }
    return _buildDefaultAvatar(isDark);
  }

  Widget _buildDefaultAvatar(bool isDark) {
    return Icon(Icons.person_rounded, size: 36, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B));
  }

  //-------------------------
  // LEVEL CARD
  //-------------------------
  Widget _buildLevelCard(bool isDark) {
    final progress = _currentLevelXP / _nextLevelXP;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF312E81)]
              : [Colors.white, const Color(0xFFFEF3C7)],
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: isDark ? [] : [
          BoxShadow(color: const Color(0xFFF59E0B).withOpacity(0.08), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _rankName,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Nivel $_level',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withOpacity(0.15),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star_rounded, color: Color(0xFFF59E0B), size: 18),
                    const SizedBox(width: 4),
                    Text(
                      '$_totalXP XP',
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        color: Color(0xFFF59E0B),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9),
              valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFF59E0B)),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$_currentLevelXP XP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
              Text('$_nextLevelXP XP', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 300.ms).slideX(begin: 0.05);
  }

  //-------------------------
  // STATS ROW
  //-------------------------
  Widget _buildStatsRow(bool isDark) {
    return Row(
      children: [
        Expanded(child: _buildStatCard(Icons.local_fire_department_rounded, '$_streak d', 'Racha', const Color(0xFFF59E0B), isDark)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(Icons.task_alt_rounded, '$_completedTasks', 'Tareas', const Color(0xFF10B981), isDark)),
        const SizedBox(width: 12),
        Expanded(child: _buildStatCard(Icons.timer_rounded, '$_pomodoros', 'Pomos', const Color(0xFF8B5CF6), isDark)),
      ],
    ).animate().fadeIn(delay: 400.ms);
  }

  String _formatFocusTime(int totalSeconds) {
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    return hours > 0 ? '${hours}h ${minutes}m' : '${minutes}m';
  }

  Widget _buildStatCard(IconData icon, String value, String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
        boxShadow: isDark ? [] : [
          BoxShadow(color: color.withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(isDark ? 0.15 : 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(height: 12),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  //-------------------------
  // FOCUS SUMMARY CARD
  //-------------------------
  Widget _buildFocusSummaryCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
        boxShadow: isDark ? [] : [
          BoxShadow(color: const Color(0xFF4F46E5).withOpacity(0.06), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      child: Row(
        children: [
          _buildFocusMetric(
            Icons.hourglass_bottom_rounded,
            'Enfoque total',
            _formatFocusTime(_totalFocusTime),
            const Color(0xFF3B82F6),
            isDark,
          ),
          Container(
            width: 1,
            height: 44,
            color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
          ),
          _buildFocusMetric(
            Icons.psychology_rounded,
            'Tests',
            '$_testsCompleted',
            const Color(0xFF8B5CF6),
            isDark,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 450.ms);
  }

  Widget _buildFocusMetric(IconData icon, String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  //-------------------------
  // SETTINGS CARD
  //-------------------------
  Widget _buildSettingsCard(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8, bottom: 8),
          child: Text(
            'Preferencias',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
              letterSpacing: 0.5,
            ),
          ),
        ),
        Container(
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          ),
          child: Column(
            children: [
              // Dark Mode
              ValueListenableBuilder<ThemeMode>(
                valueListenable: themeModeNotifier,
                builder: (context, currentMode, child) {
                  return _buildIOSSettingRow(
                    icon: Icons.dark_mode_rounded,
                    label: 'Modo Oscuro',
                    color: const Color(0xFF000000), // iOS style black
                    isDark: isDark,
                    isFirst: true,
                    isLast: false,
                    trailing: Switch.adaptive(
                      value: currentMode == ThemeMode.dark,
                      onChanged: (bool value) {
                        themeModeNotifier.value = value ? ThemeMode.dark : ThemeMode.light;
                      },
                      activeColor: const Color(0xFF34C759), // iOS Green
                    ),
                  );
                },
              ),
              // Calm Mode
              ValueListenableBuilder<bool>(
                valueListenable: calmModeNotifier,
                builder: (context, isCalmMode, child) {
                  return _buildIOSSettingRow(
                    icon: Icons.spa_rounded,
                    label: 'Modo Calma',
                    color: const Color(0xFF5856D6), // iOS Purple
                    isDark: isDark,
                    isFirst: false,
                    isLast: false,
                    trailing: Switch.adaptive(
                      value: isCalmMode,
                      onChanged: (bool value) {
                        calmModeNotifier.value = value;
                      },
                      activeColor: const Color(0xFF34C759),
                    ),
                  );
                },
              ),
              // Achievements
              GestureDetector(
                onTap: () {
                  Navigator.push(context, SmoothPageRoute(page: const StickersPage()));
                },
                child: _buildIOSSettingRow(
                  icon: Icons.emoji_events_rounded,
                  label: 'Logros y Stickers',
                  color: const Color(0xFFFF9500), // iOS Orange
                  isDark: isDark,
                  isFirst: false,
                  isLast: true,
                  trailing: Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 16,
                    color: isDark ? const Color(0xFF475569) : const Color(0xFFC7C7CC),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1);
  }

  Widget _buildIOSSettingRow({
    required IconData icon,
    required String label,
    required Color color,
    required bool isDark,
    required bool isFirst,
    required bool isLast,
    required Widget trailing,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(
                  label,
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ),
              trailing,
            ],
          ),
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 60),
            child: Divider(
              height: 1,
              thickness: 1,
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE5E5EA),
            ),
          ),
      ],
    );
  }

  //-------------------------
  // ACTIVITY CHART
  //-------------------------
  Widget _buildActivityChart(bool isDark) {
    final textColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFF1F5F9)),
        boxShadow: isDark ? [] : [
          BoxShadow(color: const Color(0xFF64748B).withOpacity(0.05), blurRadius: 20, offset: const Offset(0, 8)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Actividad semanal',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 180,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: _weeklyStats.reduce((a, b) => a > b ? a : b) + 10,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  show: true,
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        const days = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];
                        final todayIndex = DateTime.now().weekday - 1;
                        final index = (todayIndex - 6 + value.toInt()) % 7;
                        final normalizedIndex = index < 0 ? index + 7 : index;
                        return Padding(
                          padding: const EdgeInsets.only(top: 8.0),
                          child: Text(
                            days[normalizedIndex],
                            style: TextStyle(color: textColor, fontSize: 12, fontWeight: FontWeight.w700),
                          ),
                        );
                      },
                    ),
                  ),
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                ),
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  horizontalInterval: 20,
                  getDrawingHorizontalLine: (value) {
                    return FlLine(
                      color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                      strokeWidth: 1,
                    );
                  },
                ),
                borderData: FlBorderData(show: false),
                barGroups: List.generate(7, (index) {
                  return BarChartGroupData(
                    x: index,
                    barRods: [
                      BarChartRodData(
                        toY: _weeklyStats[index],
                        gradient: const LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [Color(0xFF4F46E5), Color(0xFF8B5CF6)],
                        ),
                        width: 20,
                        borderRadius: BorderRadius.circular(6),
                        backDrawRodData: BackgroundBarChartRodData(
                          show: true,
                          toY: _weeklyStats.reduce((a, b) => a > b ? a : b) + 10,
                          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        ),
                      ),
                    ],
                  );
                }),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 600.ms).scale(begin: const Offset(0.95, 0.95));
  }

  //-------------------------
  // LOGOUT BUTTON
  //-------------------------
  Widget _buildLogoutButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: TextButton.icon(
        onPressed: _confirmarCerrarSesion,
        icon: const Icon(Icons.logout_rounded, size: 20),
        label: const Text(
          'Cerrar sesión',
          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700),
        ),
        style: TextButton.styleFrom(
          foregroundColor: const Color(0xFFF43F5E),
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(color: isDark ? const Color(0xFF7F1D1D) : const Color(0xFFFECDD3), width: 1.5),
          ),
          backgroundColor: isDark ? const Color(0xFF7F1D1D).withOpacity(0.15) : const Color(0xFFFFF1F2),
        ),
      ),
    ).animate().fadeIn(delay: 700.ms);
  }

  void _confirmarCerrarSesion() {
    NeuroDialog.show(
      context: context,
      title: '¿Cerrar sesión?',
      message: '¿Estás seguro de que quieres salir de Neuro Up? ¡Te extrañaremos!',
      confirmText: 'Cerrar Sesión',
      cancelText: 'Me quedo',
      isDestructive: true,
      assetPath: 'assets/gifs/upiconfig.gif',
      onConfirm: _cerrarSesion,
    );
  }

  Future<void> _cerrarSesion() async {
    await AuthService.signOut();

    if (!mounted) return;
    Navigator.pushAndRemoveUntil(
      context,
      SmoothReplaceRoute(page: const BienvenidaPage()),
      (route) => false,
    );
  }
}
