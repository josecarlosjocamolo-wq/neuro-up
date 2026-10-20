import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'calendario_page.dart';
import '../tests/test_pages/home_tests_page.dart';
import '../perfil/perfil_page.dart';
import '../pomodoro/pomodoro_page.dart';
import '../../services/auth_service.dart';
import '../../services/stats_service.dart';
import '../../services/task_service.dart';
import '../../services/user_service.dart';
import '../../widgets/upi_loading.dart';
import '../../widgets/neuro_empty_state.dart';
import '../../widgets/smooth_page_route.dart';
import '../../theme/app_prefs.dart';
import '../chat/chat_bot_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _selectedIndex = 0;
  List<Map<String, dynamic>> _allTasks = [];
  bool _isLoadingTasks = false;
  String _userName = '';
  int _pomodoros = 0;
  int _streak = 0;

  // ─── Task creation controllers ─────────────────────────────────────────────
  final _taskTitleController = TextEditingController();
  DateTime _taskDueDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _loadUserTasks();
    _loadUserName();
    _loadHomeStats();
  }

  @override
  void dispose() {
    _taskTitleController.dispose();
    super.dispose();
  }

  Future<void> _loadUserName() async {
    try {
      final user = await UserService.getCurrentUser();
      final name = user?.name ?? AuthService.current?.name ?? '';
      if (mounted && name.isNotEmpty) {
        setState(() => _userName = name.split(' ').first);
      }
    } catch (_) {}
  }

  Future<void> _loadHomeStats() async {
    try {
      final stats = await StatsService.getQuickStats();
      final streak = await StatsService.getStreak();
      if (!mounted) return;
      setState(() {
        _pomodoros = stats['pomodoros'] as int? ?? 0;
        _streak = streak;
      });
    } catch (_) {}
  }

  Future<void> _loadUserTasks() async {
    try {
      final cachedTasks = await TaskService.getCachedTasks();
      if (cachedTasks.isNotEmpty && mounted) setState(() { _allTasks = cachedTasks; });
      if (mounted) setState(() => _isLoadingTasks = true);
      final tasks = await TaskService.loadUserTasks();
      if (mounted) setState(() { _allTasks = tasks; });
    } catch (e) {
      debugPrint('Error sync tasks: $e');
    } finally {
      if (mounted) setState(() => _isLoadingTasks = false);
    }
  }

  Future<void> _toggleTaskCompletion(String taskId) async {
    try {
      final task = _allTasks.firstWhere((t) => t['id'] == taskId);
      final newState = !(task['completed'] ?? false);
      setState(() { task['completed'] = newState; });
      await TaskService.toggleTaskCompletion(taskId, newState);
      await _loadUserTasks();
      if (newState) {
        await StatsService.recordTaskCompleted();
        await _loadHomeStats();
      }
    } catch (e) {
      debugPrint('Error updating task: $e');
    }
  }

  Future<void> _addTask(String title, DateTime dueDate) async {
    if (title.trim().isEmpty) return;
    await TaskService.addTask(title.trim(), dueDate);
    await StatsService.recordTaskAdded();
    await _loadUserTasks();
  }

  Future<void> _deleteTask(String taskId) async {
    await TaskService.deleteTask(taskId);
    await _loadUserTasks();
  }

  List<Map<String, dynamic>> get _pendingTasks => _allTasks.where((t) => !t['completed']).toList();

  // ─── Add Task Sheet (Bottom Sheet Premium) ─────────────────────────────────
  void _showAddTaskSheet() {
    _taskTitleController.clear();
    _taskDueDate = DateTime.now();

    HapticFeedback.mediumImpact();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _AddTaskSheet(
        onAdd: (title, date) async {
          await _addTask(title, date);
          if (mounted) Navigator.pop(ctx);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0B1120) : const Color(0xFFF8FAFC),
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          switchInCurve: Curves.easeOut,
          switchOutCurve: Curves.easeIn,
          transitionBuilder: (child, anim) => FadeTransition(
            opacity: anim,
            child: child,
          ),
          child: KeyedSubtree(
            key: ValueKey(_selectedIndex),
            child: _buildCurrentPage(),
          ),
        ),
      ),
      bottomNavigationBar: _buildIOSBottomNav(isDark),
    );
  }

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0: return _buildDashboard();
      case 1: return CalendarioPage(allTasks: _allTasks, onToggleTask: _toggleTaskCompletion);
      case 2: return const EnfoquePage();
      case 3: return const HomeTestsPage();
      case 4: return const PerfilPage();
      default: return _buildDashboard();
    }
  }

  /// Aplica una animación solo si no se pidió reducir el movimiento
  /// (Modo Calma activo o ajuste "reducir movimiento" del sistema).
  Widget _motion(bool reduce, Widget child, Widget Function(Widget) anim) =>
      reduce ? child : anim(child);

  // ─── IOS-STYLE PREMIUM BOTTOM NAV ──────────────────────────────────────────
  Widget _buildIOSBottomNav(bool isDark) {
    const activeColor = Color(0xFF4F46E5);
    final inactiveColor = isDark ? const Color(0xFF64748B) : const Color(0xFF9CA3AF);
    final bgColor = isDark ? const Color(0xFF0F172A) : Colors.white;
    final shadowColor = isDark ? Colors.black54 : const Color(0xFF0F172A).withOpacity(0.08);

    // 4 nav items (no placeholder — FAB is handled by Stack overlay)
    final navItems = [
      {'icon': Icons.grid_view_rounded, 'label': 'Inicio', 'idx': 0},
      {'icon': Icons.calendar_month_rounded, 'label': 'Agenda', 'idx': 1},
      {'icon': Icons.psychology_rounded, 'label': 'Tests', 'idx': 3},
      {'icon': Icons.person_rounded, 'label': 'Perfil', 'idx': 4},
    ];

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        boxShadow: [
          BoxShadow(color: shadowColor, blurRadius: 24, offset: const Offset(0, -4)),
        ],
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.06) : const Color(0xFFF1F5F9),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 70,
          child: Stack(
            clipBehavior: Clip.none,
            children:
            [
              // ── 4 nav items split around center ─────────────────────────
              Positioned.fill(
                child: Row(
                  children: [
                    _buildNavItem(navItems[0]['idx'] as int, navItems[0]['icon'] as IconData, navItems[0]['label'] as String, activeColor, inactiveColor),
                    _buildNavItem(navItems[1]['idx'] as int, navItems[1]['icon'] as IconData, navItems[1]['label'] as String, activeColor, inactiveColor),
                    // Gap in center for FAB
                    const SizedBox(width: 76),
                    _buildNavItem(navItems[2]['idx'] as int, navItems[2]['icon'] as IconData, navItems[2]['label'] as String, activeColor, inactiveColor),
                    _buildNavItem(navItems[3]['idx'] as int, navItems[3]['icon'] as IconData, navItems[3]['label'] as String, activeColor, inactiveColor),
                  ],
                ),
              ),

              // ── Elevated center FAB ──────────────────────────────────────
              Positioned(
                top: -22,
                left: 0,
                right: 0,
                child: Center(
                  child: GestureDetector(
                    onTap: _showAddTaskSheet,
                    child: Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        shape: BoxShape.circle,
                        border: Border.all(color: isDark ? const Color(0xFF0F172A) : Colors.white, width: 3.5),
                        boxShadow: [
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withOpacity(0.5),
                            blurRadius: 20,
                            spreadRadius: 0,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: const Color(0xFF4F46E5).withOpacity(0.25),
                            blurRadius: 6,
                            spreadRadius: 2,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: const Icon(Icons.add_rounded, color: Colors.white, size: 30),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(int idx, IconData icon, String label, Color activeColor, Color inactiveColor) {
    final isSelected = _selectedIndex == idx;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedIndex = idx);
          if (idx == 0) {
            _loadUserTasks();
            _loadHomeStats();
          }
        },
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
              decoration: BoxDecoration(
                color: isSelected ? activeColor.withOpacity(0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: isSelected ? activeColor : inactiveColor,
                size: 23,
              ),
            ),
            const SizedBox(height: 3),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? activeColor : inactiveColor,
                letterSpacing: 0.1,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── PREMIUM DASHBOARD ──────────────────────────────────────────────────────
  Widget _buildDashboard() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final reduceMotion = AppPrefs.reduceMotion(context);

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: isDark
              ? [const Color(0xFF0A0F1E), const Color(0xFF0F172A)]
              : [const Color(0xFFF0F4FF), const Color(0xFFF8FAFF)],
        ),
      ),
      child: Stack(
        children: [
          // Ambient glow top-right
          Positioned(
            top: -80,
            right: -80,
            child: _motion(
              reduceMotion,
              Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withOpacity(isDark ? 0.25 : 0.12),
                      blurRadius: 80,
                      spreadRadius: 40,
                    ),
                  ],
                ),
              ),
              (w) => w
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(1, 1), end: const Offset(1.15, 1.15), duration: 5.seconds),
            ),
          ),
          // Ambient glow bottom-left
          Positioned(
            bottom: 150,
            left: -60,
            child: _motion(
              reduceMotion,
              Container(
                width: 220,
                height: 220,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF06B6D4).withOpacity(isDark ? 0.15 : 0.08),
                      blurRadius: 70,
                      spreadRadius: 30,
                    ),
                  ],
                ),
              ),
              (w) => w
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(begin: const Offset(1, 1), end: const Offset(1.1, 1.1), duration: 4.seconds),
            ),
          ),
          // Scrollable content
          Positioned.fill(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 120),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDashboardHeader(isDark),
                  const SizedBox(height: 24),
                  _buildPremiumFocusCard(isDark).animate().fadeIn(delay: 150.ms).slideY(begin: 0.04),
                  const SizedBox(height: 28),
                  _buildSectionHeader('Prioridades de hoy', isDark, onTap: _showAddTaskSheet).animate().fadeIn(delay: 250.ms),
                  const SizedBox(height: 14),
                  _buildPrioritiesList(isDark).animate().fadeIn(delay: 350.ms),
                  const SizedBox(height: 28),
                  _buildMotivationalStripe(isDark).animate().fadeIn(delay: 450.ms),
                  const SizedBox(height: 28),
                  _buildSectionHeader('Hoy en números', isDark).animate().fadeIn(delay: 500.ms),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: _buildSummaryCard('${_pendingTasks.length}', 'Tareas', Icons.task_alt_rounded, const [Color(0xFF6366F1), Color(0xFF4F46E5)], isDark)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildSummaryCard('$_pomodoros', 'Pomodoros', Icons.timer_rounded, const [Color(0xFF10B981), Color(0xFF059669)], isDark)),
                      const SizedBox(width: 10),
                      Expanded(child: _buildSummaryCard('🔥 $_streak', 'Racha', Icons.local_fire_department_rounded, const [Color(0xFFF59E0B), Color(0xFFEF4444)], isDark)),
                    ],
                  ).animate().fadeIn(delay: 600.ms),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, bool isDark, {VoidCallback? onTap}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
            letterSpacing: -0.4,
          ),
        ),
        if (onTap != null)
          GestureDetector(
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_rounded, color: Color(0xFF6366F1), size: 15),
                  SizedBox(width: 4),
                  Text('Agregar', style: TextStyle(color: Color(0xFF6366F1), fontWeight: FontWeight.w700, fontSize: 12)),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildMotivationalStripe(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1B4B), const Color(0xFF312E81)]
              : [const Color(0xFF6366F1), const Color(0xFF4F46E5)],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Text('✨', style: TextStyle(fontSize: 20)),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              '"El progreso, no la perfección, es lo que importa."',
              style: TextStyle(
                color: Colors.white.withOpacity(0.95),
                fontSize: 13,
                fontWeight: FontWeight.w500,
                fontStyle: FontStyle.italic,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDashboardHeader(bool isDark) {
    final now = DateTime.now();
    final days = ['Lun', 'Mar', 'Mié', 'Jue', 'Vie', 'Sáb', 'Dom'];
    final months = ['Ene', 'Feb', 'Mar', 'Abr', 'May', 'Jun', 'Jul', 'Ago', 'Sep', 'Oct', 'Nov', 'Dic'];
    final greetings = ['Buenos días', 'Buenas tardes', 'Buenas noches'];
    final hour = now.hour;
    final greeting = hour < 12 ? greetings[0] : hour < 18 ? greetings[1] : greetings[2];
    final emoji = hour < 12 ? '☀️' : hour < 18 ? '🌤️' : '🌙';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Avatar circle
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [Color(0xFF6366F1), Color(0xFF8B5CF6)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF6366F1).withOpacity(0.35),
                blurRadius: 14,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Center(
            child: Text(
              _userName.isNotEmpty ? _userName[0].toUpperCase() : 'E',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w900,
                fontSize: 20,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '$greeting $emoji',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
              const SizedBox(height: 2),
              Text(
                _userName.isNotEmpty ? _userName : 'Estudiante',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                  height: 1.1,
                ),
              ),
            ],
          ),
        ),
        // Date chip
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
            ),
            boxShadow: isDark ? [] : [
              BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          child: Column(
            children: [
              Text(
                '${days[now.weekday - 1]}',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6366F1),
                  letterSpacing: 0.5,
                ),
              ),
              Text(
                '${now.day}',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  height: 1.1,
                ),
              ),
              Text(
                months[now.month - 1],
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 10),
        // Chat button
        GestureDetector(
          onTap: () => Navigator.push(context, SmoothPageRoute(page: const ChatBotPage())),
          child: Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF1E293B) : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(
                color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
              ),
              boxShadow: isDark ? [] : [
                BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 10, offset: const Offset(0, 3)),
              ],
            ),
            child: const Icon(Icons.chat_bubble_outline_rounded, color: Color(0xFF6366F1), size: 20),
          ),
        ),
      ],
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.04);
  }

  Widget _buildPremiumFocusCard(bool isDark) {
    final reduceMotion = AppPrefs.reduceMotion(context);
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E1B4B), const Color(0xFF1E293B)]
              : [const Color(0xFF4F46E5), const Color(0xFF6366F1)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF4F46E5).withOpacity(isDark ? 0.3 : 0.35),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(22),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.bolt_rounded, color: Colors.white, size: 13),
                        SizedBox(width: 4),
                        Text('Bloque de estudio',
                          style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.2)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Text(
                    'Tiempo para\nenfocarte',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 26,
                      fontWeight: FontWeight.w900,
                      height: 1.1,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '25 min · sin distracciones',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 22),
                  GestureDetector(
                    onTap: () => setState(() => _selectedIndex = 2),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: const Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.play_arrow_rounded, color: Color(0xFF4F46E5), size: 20),
                          SizedBox(width: 6),
                          Text('Iniciar Pomodoro',
                            style: TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w800, fontSize: 14)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // UPI avatar
            GestureDetector(
              onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const ChatBotPage())),
              child: SizedBox(
                width: 110,
                height: 120,
                child: Stack(
                  alignment: Alignment.center,
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    Positioned(
                      bottom: 0,
                      child: _motion(
                        reduceMotion,
                        SizedBox(
                          width: 105,
                          height: 105,
                          child: Image.asset('assets/gifs/upiaudi.gif', fit: BoxFit.contain),
                        ),
                        (w) => w
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .moveY(begin: -4, end: 4, duration: 2.seconds, curve: Curves.easeInOut),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritiesList(bool isDark) {
    if (_isLoadingTasks) return const Center(child: UpiLoading(message: 'Cargando...'));

    final priorities = _pendingTasks.take(3).toList();

    if (priorities.isEmpty) {
      return NeuroEmptyState(
        title: 'Día Libre',
        description: 'No tienes tareas pendientes. Agrega una para empezar.',
        actionText: 'Agregar tarea',
        onAction: _showAddTaskSheet,
      );
    }

    final accentColors = [
      const Color(0xFF6366F1),
      const Color(0xFF10B981),
      const Color(0xFFF59E0B),
    ];
    final labels = ['Alta', 'Media', 'Baja'];

    return Column(
      children: priorities.asMap().entries.map((entry) {
        final idx = entry.key;
        final task = entry.value;
        final accent = accentColors[idx % accentColors.length];
        final label = labels[idx % labels.length];

        return Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1E293B) : Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isDark ? const Color(0xFF334155) : const Color(0xFFEFF0F7),
            ),
            boxShadow: isDark ? [] : [
              BoxShadow(color: Colors.black.withOpacity(0.04), blurRadius: 10, offset: const Offset(0, 3))
            ],
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => _toggleTaskCompletion(task['id']),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                child: Row(
                  children: [
                    // Left accent bar
                    Container(
                      width: 4,
                      height: 38,
                      decoration: BoxDecoration(
                        color: accent,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            task['title'],
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                decoration: BoxDecoration(
                                  color: accent.withOpacity(0.1),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  label,
                                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: accent),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Checkbox
                    GestureDetector(
                      onTap: () => _toggleTaskCompletion(task['id']),
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: accent, width: 2),
                        ),
                        child: Icon(Icons.check_rounded, size: 16, color: accent.withOpacity(0.3)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ).animate().slideX(begin: 0.04, delay: Duration(milliseconds: 60 * idx));
      }).toList(),
    );
  }

  Widget _buildSummaryCard(String value, String label, IconData icon, List<Color> gradient, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? const Color(0xFF334155) : const Color(0xFFEFF0F7),
        ),
        boxShadow: isDark ? [] : [
          BoxShadow(color: gradient[0].withOpacity(0.1), blurRadius: 14, offset: const Offset(0, 5)),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [gradient[0].withOpacity(0.2), gradient[1].withOpacity(0.1)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: gradient[0], size: 18),
          ),
          const SizedBox(height: 14),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: isDark ? const Color(0xFF94A3B8) : gradient[0].withOpacity(0.8),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── ADD TASK BOTTOM SHEET ──────────────────────────────────────────────────
class _AddTaskSheet extends StatefulWidget {
  final Future<void> Function(String title, DateTime date) onAdd;
  const _AddTaskSheet({required this.onAdd});

  @override
  State<_AddTaskSheet> createState() => _AddTaskSheetState();
}

class _AddTaskSheetState extends State<_AddTaskSheet> {
  final _controller = TextEditingController();
  DateTime _dueDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _dueDate,
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _dueDate = picked);
  }

  Future<void> _save() async {
    if (_controller.text.trim().isEmpty) return;
    setState(() => _isSaving = true);
    await widget.onAdd(_controller.text.trim(), _dueDate);
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    if (d.year == now.year && d.month == now.month && d.day == now.day) return 'Hoy';
    if (d.year == now.year && d.month == now.month && d.day == now.day + 1) return 'Mañana';
    return '${d.day}/${d.month}/${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF0F172A);
    final subtextColor = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
    final borderColor = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);

    return Container(
      margin: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.15), blurRadius: 30, offset: const Offset(0, -10)),
        ],
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Drag handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(color: borderColor, borderRadius: BorderRadius.circular(2)),
            ),
          ),
          const SizedBox(height: 20),
          Text('Nueva tarea', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: textColor)),
          const SizedBox(height: 20),
          // Text field
          TextField(
            controller: _controller,
            autofocus: true,
            style: TextStyle(fontSize: 16, color: textColor, fontWeight: FontWeight.w600),
            decoration: InputDecoration(
              hintText: '¿Qué necesitas hacer?',
              hintStyle: TextStyle(color: subtextColor, fontWeight: FontWeight.w400),
              filled: true,
              fillColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(16), borderSide: BorderSide.none),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: Color(0xFF4F46E5), width: 2),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            ),
          ),
          const SizedBox(height: 16),
          // Date picker row
          GestureDetector(
            onTap: _pickDate,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: borderColor),
              ),
              child: Row(
                children: [
                  Icon(Icons.calendar_today_rounded, color: const Color(0xFF4F46E5), size: 18),
                  const SizedBox(width: 10),
                  Text('Fecha límite:', style: TextStyle(color: subtextColor, fontSize: 14)),
                  const SizedBox(width: 8),
                  Text(_formatDate(_dueDate), style: const TextStyle(color: Color(0xFF4F46E5), fontWeight: FontWeight.w700, fontSize: 14)),
                  const Spacer(),
                  Icon(Icons.chevron_right_rounded, color: subtextColor, size: 20),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
          // Save button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4F46E5),
                foregroundColor: Colors.white,
                elevation: 0,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              ),
              child: _isSaving
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                  : const Text('Guardar tarea', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }
}
