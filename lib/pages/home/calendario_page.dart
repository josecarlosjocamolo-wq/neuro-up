import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../data/local_db.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/neuro_button.dart';
import '../../widgets/neuro_chip.dart';

// ─── Colores por categoría ───────────────────────────────────────────────────
const _kPrimary = Color(0xFF4F46E5);

class _CatStyle {
  final Color bg;
  final Color bgDark;
  final Color accent;
  final Color accentDark;
  final IconData icon;
  final String label;
  const _CatStyle(this.bg, this.bgDark, this.accent, this.accentDark, this.icon, this.label);
}

const Map<String, _CatStyle> _kCats = {
  'study':   _CatStyle(Color(0xFFEDE9FE), Color(0x554C1D95), Color(0xFF7C3AED), Color(0xFFC4B5FD), Icons.menu_book_rounded,       'Estudio'),
  'class':   _CatStyle(Color(0xFFE0E7FF), Color(0x551E3A8A), Color(0xFF3B82F6), Color(0xFF93C5FD), Icons.school_outlined,          'Clase'),
  'meeting': _CatStyle(Color(0xFFFEF3C7), Color(0x5578350F), Color(0xFFF59E0B), Color(0xFFFCD34D), Icons.groups_rounded,           'Reunión'),
  'break':   _CatStyle(Color(0xFFD1FAE5), Color(0x55065F46), Color(0xFF10B981), Color(0xFF6EE7B7), Icons.coffee_rounded,           'Descanso'),
  'personal':_CatStyle(Color(0xFFDCFCE7), Color(0x5514532D), Color(0xFF22C55E), Color(0xFF86EFAC), Icons.self_improvement_rounded, 'Personal'),
  'salud':   _CatStyle(Color(0xFFCCFBF1), Color(0x55134E4A), Color(0xFF14B8A6), Color(0xFF5EEAD4), Icons.favorite_outline_rounded, 'Salud'),
};

_CatStyle _cat(String? type) => _kCats[type?.toLowerCase()] ?? _kCats['study']!;

// ─── Modelo de nodo de timeline ──────────────────────────────────────────────
class _TNode {
  final int minutes;
  final String label;
  final bool isHeader;
  final bool isBase;
  final bool isEmpty;
  final Map<String, dynamic>? event;
  final bool isTask;
  const _TNode(this.minutes, this.label, {
    this.isHeader = false,
    this.isBase   = false,
    this.isEmpty  = false,
    this.event,
    this.isTask   = false,
  });
}

// ─── Página principal ────────────────────────────────────────────────────────
class CalendarioPage extends StatefulWidget {
  final Map<String, List<Map<String, String>>>? taskEvents;
  final List<Map<String, dynamic>> allTasks;
  final Function(String) onToggleTask;

  const CalendarioPage({
    super.key,
    this.taskEvents,
    required this.allTasks,
    required this.onToggleTask,
  });

  @override
  State<CalendarioPage> createState() => _CalendarioPageState();
}

class _CalendarioPageState extends State<CalendarioPage> {
  DateTime _selectedDate  = DateTime.now();
  DateTime _currentMonth  = DateTime.now();
  bool _showMonthlyView   = false;

  final _titleCtrl  = TextEditingController();
  final _typeCtrl   = TextEditingController();
  final _timeCtrl   = TextEditingController();
  TimeOfDay _time   = TimeOfDay.now();

  List<Map<String, dynamic>> _events = [];

  // ── Lifecycle ──
  @override
  void initState() {
    super.initState();
    _typeCtrl.text = 'study';
    _refreshTimeCtrl();
    _loadEvents();
  }

  @override
  void dispose() {
    _titleCtrl.dispose();
    _typeCtrl.dispose();
    _timeCtrl.dispose();
    super.dispose();
  }

  // ── Data ──
  Future<void> _loadEvents() async {
    try {
      final user = AuthService.current;
      if (user == null) return;
      final db = await LocalDb.instance.database;
      final res = await db.query(
        'calendar_events',
        where: 'user_id = ?',
        whereArgs: [user.id],
        orderBy: 'event_date ASC',
      );
      if (!mounted) return;
      setState(() {
        _events = res.map((e) {
          return {
            'id': e['id'],
            'title': e['title'],
            'event_date': DateTime.parse(e['event_date'] as String),
            'start_time': e['start_time'],
            'event_type': e['event_type'] ?? 'study',
          };
        }).toList();
      });
    } catch (e) {
      debugPrint('Error loading events: $e');
    }
  }

  Future<void> _saveEvent() async {
    try {
      final user = AuthService.current;
      if (user == null || _titleCtrl.text.trim().isEmpty) return;
      final db = await LocalDb.instance.database;
      await db.insert('calendar_events', {
        'user_id': user.id,
        'title': _titleCtrl.text.trim(),
        'event_date': _selectedDate.toIso8601String(),
        'start_time': _fmtTime(_time),
        'event_type': _typeCtrl.text.isEmpty ? 'study' : _typeCtrl.text,
        'created_at': DateTime.now().toIso8601String(),
      });
      await _loadEvents();
      _titleCtrl.clear();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint('Error saving event: $e');
    }
  }

  Future<void> _deleteEvent(String id) async {
    try {
      final db = await LocalDb.instance.database;
      await db.delete('calendar_events', where: 'id = ?', whereArgs: [id]);
      await _loadEvents();
    } catch (e) {
      debugPrint('Error deleting event: $e');
    }
  }

  // ── Derived ──
  List<Map<String, dynamic>> get _dayEvents => _events.where((e) {
    final d = e['event_date'] as DateTime;
    return d.year == _selectedDate.year && d.month == _selectedDate.month && d.day == _selectedDate.day;
  }).toList();

  List<Map<String, dynamic>> get _dayTasks => widget.allTasks.where((t) {
    final d = t['dueDate'] as DateTime;
    return d.year == _selectedDate.year && d.month == _selectedDate.month && d.day == _selectedDate.day && !(t['completed'] as bool);
  }).toList();

  // ── Helpers ──
  void _refreshTimeCtrl() => _timeCtrl.text = _fmtTime(_time);

  String _fmtTime(TimeOfDay t) {
    final h = t.hourOfPeriod == 0 ? 12 : t.hourOfPeriod;
    final m = t.minute.toString().padLeft(2, '0');
    return '$h:$m ${t.period == DayPeriod.am ? 'AM' : 'PM'}';
  }

  int _toMin(String s) {
    try {
      final p = s.trim().split(' ');
      final tp = p[0].split(':');
      int h = int.parse(tp[0]), m = int.parse(tp[1]);
      final per = p[1].toUpperCase();
      if (per == 'PM' && h != 12) h += 12;
      if (per == 'AM' && h == 12) h = 0;
      return h * 60 + m;
    } catch (_) { return 0; }
  }

  static const _months = ['Enero','Febrero','Marzo','Abril','Mayo','Junio','Julio','Agosto','Septiembre','Octubre','Noviembre','Diciembre'];
  static const _wdShort = ['L','M','M','J','V','S','D'];
  static const _wdFull  = ['Lunes','Martes','Miércoles','Jueves','Viernes','Sábado','Domingo'];
  String _mname(int m) => _months[m - 1];
  String _wshort(int w) => _wdShort[w - 1];
  String _wfull(int w)  => _wdFull[w - 1];

  // ── Dialogs ──
  Future<void> _pickTime() async {
    final t = await showTimePicker(context: context, initialTime: _time);
    if (t != null && mounted) setState(() { _time = t; _refreshTimeCtrl(); });
  }

  void _openAddDialog() {
    _titleCtrl.clear();
    _typeCtrl.text = 'study';
    _time = TimeOfDay.now();
    _refreshTimeCtrl();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: isDark ? const Color(0xFF1E293B) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          title: Text('Nuevo Evento',
              style: TextStyle(fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A))),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              TextField(
                controller: _titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Título del evento',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: () async { await _pickTime(); setSt(() {}); },
                child: AbsorbPointer(child: TextField(
                  controller: _timeCtrl,
                  decoration: InputDecoration(
                    labelText: 'Hora',
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    suffixIcon: const Icon(Icons.access_time_rounded),
                  ),
                )),
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                value: _typeCtrl.text.isEmpty ? 'study' : _typeCtrl.text,
                decoration: InputDecoration(
                  labelText: 'Tipo',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                ),
                items: const [
                  DropdownMenuItem(value: 'study',    child: Text('📚 Estudio')),
                  DropdownMenuItem(value: 'class',    child: Text('🏫 Clase')),
                  DropdownMenuItem(value: 'meeting',  child: Text('👥 Reunión')),
                  DropdownMenuItem(value: 'break',    child: Text('☕ Descanso')),
                  DropdownMenuItem(value: 'personal', child: Text('🧘 Personal')),
                  DropdownMenuItem(value: 'salud',    child: Text('🏃 Salud')),
                ],
                onChanged: (v) => _typeCtrl.text = v!,
              ),
            ]),
          ),
          actions: [
            NeuroButton(text: 'Cancelar', type: NeuroButtonType.ghost,
                onPressed: () => Navigator.pop(context)),
            const SizedBox(width: 8),
            NeuroButton(text: 'Guardar', type: NeuroButtonType.primary,
                onPressed: () { if (_titleCtrl.text.trim().isNotEmpty) _saveEvent(); }),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  BUILD
  // ═══════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
      floatingActionButton: FloatingActionButton(
        onPressed: _openAddDialog,
        backgroundColor: _kPrimary,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
      ).animate().scale(delay: 400.ms, curve: Curves.easeOutBack),
      body: SafeArea(
        child: Column(children: [
          _header(isDark),
          if (!_showMonthlyView) _weekStrip(isDark),
          Expanded(
            child: _showMonthlyView
                ? _monthlyGrid(isDark)
                : _timelineView(isDark),
          ),
        ]),
      ),
    );
  }

  // ── Header ──────────────────────────────────────────────────────────
  Widget _header(bool isDark) {
    final bg = isDark ? const Color(0xFF1E293B) : Colors.white;
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final fg = isDark ? Colors.white : const Color(0xFF0F172A);

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
      child: Row(children: [
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_mname(_selectedDate.month),
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                    color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
            Text('Agenda',
                style: TextStyle(fontSize: 28, fontWeight: FontWeight.w900,
                    color: fg, height: 1.1, letterSpacing: -0.5)),
          ]),
        ),
        _iconBtn(Icons.search_rounded, fg, bg, border, () {}),
        const SizedBox(width: 10),
        _iconBtn(
          _showMonthlyView ? Icons.view_day_rounded : Icons.calendar_month_rounded,
          fg, bg, border, () => setState(() => _showMonthlyView = !_showMonthlyView),
        ),
      ]),
    );
  }

  Widget _iconBtn(IconData icon, Color fg, Color bg, Color border, VoidCallback onTap) {
    return Container(
      decoration: BoxDecoration(color: bg, shape: BoxShape.circle,
          border: Border.all(color: border, width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 8, offset: const Offset(0, 2))]),
      child: IconButton(onPressed: onTap, icon: Icon(icon, size: 20, color: fg),
          padding: const EdgeInsets.all(10), constraints: const BoxConstraints()),
    );
  }

  // ── Week strip ──────────────────────────────────────────────────────
  Widget _weekStrip(bool isDark) {
    final days = List.generate(7, (i) => _selectedDate.subtract(Duration(days: 3 - i)));
    final textFg = isDark ? Colors.white : const Color(0xFF0F172A);
    final muted  = isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: Column(children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: days.map((day) {
            final sel = day.year == _selectedDate.year &&
                        day.month == _selectedDate.month &&
                        day.day   == _selectedDate.day;
            return GestureDetector(
              onTap: () => setState(() => _selectedDate = day),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                width: 44,
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? _kPrimary : Colors.transparent,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Text(_wshort(day.weekday),
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700,
                          color: sel ? Colors.white.withValues(alpha: 0.85) : muted)),
                  const SizedBox(height: 6),
                  Text('${day.day}',
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800,
                          color: sel ? Colors.white : textFg)),
                ]),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 8),
        Text(
          '${_wfull(_selectedDate.weekday)} ${_selectedDate.day} de ${_mname(_selectedDate.month).toLowerCase()}',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: _kPrimary),
        ),
        const SizedBox(height: 12),
        Divider(height: 1, color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0)),
      ]),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  TIMELINE VIEW
  // ═══════════════════════════════════════════════════════════════════
  Widget _timelineView(bool isDark) {
    final tasks  = _dayTasks;
    final events = _dayEvents;
    final noData = tasks.isEmpty && events.isEmpty;

    // Next event
    Map<String, dynamic>? nextEvent;
    if (events.isNotEmpty) {
      final now   = TimeOfDay.now();
      final nowMin = now.hour * 60 + now.minute;
      nextEvent = events.firstWhere(
        (e) => _toMin(e['start_time'] ?? '0:00 AM') >= nowMin,
        orElse: () => events.first,
      );
    }

    // Build nodes
    List<_TNode> nodes = [];

    // Tasks (all-day)
    for (var t in tasks) {
      nodes.add(_TNode(0, 'Todo el día', event: t, isTask: true));
    }

    // Section headers
    nodes.add(const _TNode(360,  'Mañana', isHeader: true));
    nodes.add(const _TNode(720,  'Tarde',  isHeader: true));
    nodes.add(const _TNode(1140, 'Noche',  isHeader: true));

    // Base hour ticks
    for (final h in ['08:00 AM', '09:00 AM', '10:00 AM', '12:00 PM', '02:00 PM', '04:00 PM', '06:00 PM', '08:00 PM']) {
      nodes.add(_TNode(_toMin(h), h, isBase: true));
    }

    // Real events
    for (var e in events) {
      nodes.add(_TNode(_toMin(e['start_time'] ?? '08:00 AM'), e['start_time'] ?? '', event: e));
    }

    // Empty footer
    if (noData) nodes.add(const _TNode(661, '', isEmpty: true));

    nodes.sort((a, b) => a.minutes.compareTo(b.minutes));

    // Remove base ticks that have an event at the same minute
    final eventMins = nodes.where((n) => n.event != null).map((n) => n.minutes).toSet();
    nodes.removeWhere((n) => n.isBase && eventMins.contains(n.minutes));

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 0, 20, 120),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          const SizedBox(height: 16),

          // ── "Qué sigue" card ──
          _queSigueCard(isDark, nextEvent),
          const SizedBox(height: 24),

          // ── Timeline ──
          IntrinsicHeight(
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // Left col: time labels + vertical line
              SizedBox(
                width: 52,
                child: Column(children: nodes.map((n) {
                  if (n.isHeader) return _timeLabelHeader(n.label, isDark);
                  if (n.isEmpty)  return _timeLabelEmpty();
                  if (n.isBase)   return _timeLabelBase(n.label, isDark);
                  return _timeLabelEvent(n.label, isDark);
                }).toList()),
              ),
              // Vertical line
              Container(
                width: 1.5,
                color: isDark ? const Color(0xFF1E293B) : const Color(0xFFE2E8F0),
              ),
              const SizedBox(width: 12),
              // Right col: events
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                    children: nodes.map((n) {
                  if (n.isHeader)  return _sectionHeader(n.label, isDark);
                  if (n.isEmpty)   return _emptySlot(isDark);
                  if (n.isBase)    return _baseTick();
                  if (n.event != null && n.isTask)  return _taskCard(n.event!, isDark);
                  if (n.event != null && !n.isTask) return _eventCard(n.event!, isDark);
                  return const SizedBox();
                }).toList()),
              ),
            ]),
          ),
        ]),
      ),
    );
  }

  // ── "Qué sigue" ─────────────────────────────────────────────────────
  Widget _queSigueCard(bool isDark, Map<String, dynamic>? next) {
    final cardBg     = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMain   = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSub    = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Container(
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: cardBorder, width: 1),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.06), blurRadius: 16, offset: const Offset(0, 4))],
      ),
      padding: const EdgeInsets.all(18),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        // label row
        Row(children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _kPrimary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.access_time_filled_rounded, color: _kPrimary, size: 14),
          ),
          const SizedBox(width: 8),
          const Text('Qué sigue', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: _kPrimary, letterSpacing: 0.8)),
        ]),
        const SizedBox(height: 14),

        if (next == null) ...[
          Text('Tu agenda está libre por ahora', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: textMain)),
          const SizedBox(height: 4),
          Text('Puedes iniciar un Pomodoro o planear una actividad.', style: TextStyle(fontSize: 13, color: textSub)),
        ] else ...[
          Row(children: [
            // Time block
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(next['start_time'] ?? '', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: textMain)),
              Text(_cat(next['event_type']).label, style: TextStyle(fontSize: 11, color: textSub, fontWeight: FontWeight.w600)),
            ]),
            Container(width: 1, height: 44, color: cardBorder, margin: const EdgeInsets.symmetric(horizontal: 16)),
            // Info
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(next['title'], style: TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: textMain),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 4),
              _chip(_cat(next['event_type']).label, _cat(next['event_type']).accent, isDark),
            ])),
            // Icon
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: _cat(next['event_type']).accent.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(_cat(next['event_type']).icon, color: _cat(next['event_type']).accent, size: 22),
            ),
          ]),
        ],
      ]),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.06, curve: Curves.easeOut);
  }

  // ── Timeline left-col labels ─────────────────────────────────────────
  Widget _timeLabelHeader(String label, bool isDark) {
    return SizedBox(
      height: 44,
      child: Align(
        alignment: Alignment.centerRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 10),
          child: Text(label.toUpperCase(),
              style: TextStyle(fontSize: 9, fontWeight: FontWeight.w800, letterSpacing: 1,
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1))),
        ),
      ),
    );
  }

  Widget _timeLabelBase(String label, bool isDark) {
    final parts = label.split(' ');
    return SizedBox(
      height: 56,
      child: Align(
        alignment: Alignment.topRight,
        child: Padding(
          padding: const EdgeInsets.only(right: 10, top: 6),
          child: RichText(text: TextSpan(
            text: parts[0],
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1), height: 1.1),
            children: [
              TextSpan(text: '\n${parts.length > 1 ? parts[1] : ''}',
                  style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600, color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
            ],
          ), textAlign: TextAlign.right),
        ),
      ),
    );
  }

  Widget _timeLabelEvent(String label, bool isDark) {
    final parts = label.split(' ');
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SizedBox(
        height: 80,
        child: Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 10, top: 10),
            child: RichText(text: TextSpan(
              text: parts[0],
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800,
                  color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF475569), height: 1.1),
              children: [
                TextSpan(text: '\n${parts.length > 1 ? parts[1] : ''}',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600,
                        color: isDark ? const Color(0xFF64748B) : const Color(0xFF94A3B8))),
              ],
            ), textAlign: TextAlign.right),
          ),
        ),
      ),
    );
  }

  Widget _timeLabelEmpty() => const SizedBox(height: 120);

  // ── Timeline right-col content ───────────────────────────────────────
  Widget _sectionHeader(String label, bool isDark) {
    IconData ico;
    Color col;
    if (label == 'Mañana') { ico = Icons.wb_sunny_outlined; col = const Color(0xFFF59E0B); }
    else if (label == 'Tarde') { ico = Icons.wb_cloudy_outlined; col = const Color(0xFF3B82F6); }
    else { ico = Icons.bedtime_outlined; col = const Color(0xFF8B5CF6); }

    return SizedBox(
      height: 44,
      child: Row(children: [
        Icon(ico, color: col, size: 14),
        const SizedBox(width: 6),
        Text(label, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, color: col)),
      ]),
    );
  }

  Widget _baseTick() => const SizedBox(height: 56);

  Widget _emptySlot(bool isDark) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Icon(Icons.calendar_today_outlined, size: 28,
              color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
          const SizedBox(height: 8),
          Text('Sin actividades por ahora',
              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600,
                  color: isDark ? const Color(0xFF475569) : const Color(0xFFCBD5E1))),
          const SizedBox(height: 4),
          Text('Toca + para agregar',
              style: TextStyle(fontSize: 11,
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0))),
        ]),
      ),
    );
  }

  Widget _eventCard(Map<String, dynamic> ev, bool isDark) {
    final cs  = _cat(ev['event_type']);
    final bg  = isDark ? cs.bgDark : cs.bg;
    final acc = isDark ? cs.accentDark : cs.accent;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onLongPress: () => _deleteEvent(ev['id'].toString()),
        child: Container(
          height: 80,
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: bg,
            borderRadius: BorderRadius.circular(16),
            border: Border(left: BorderSide(color: acc, width: 3)),
          ),
          child: Row(children: [
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center, children: [
              Text(ev['title'], style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A)),
                  maxLines: 1, overflow: TextOverflow.ellipsis),
              const SizedBox(height: 6),
              _chip(cs.label, acc, isDark),
            ])),
            const SizedBox(width: 10),
            Icon(cs.icon, color: acc, size: 24),
          ]),
        ),
      ),
    );
  }

  Widget _taskCard(Map<String, dynamic> task, bool isDark) {
    const acc = Color(0xFF10B981);
    final bg  = isDark ? const Color(0xFF065F46).withValues(alpha: 0.4) : const Color(0xFFD1FAE5);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(16),
          border: const Border(left: BorderSide(color: acc, width: 3)),
        ),
        child: Row(children: [
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(task['title'] ?? 'Tarea', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A)),
                maxLines: 1, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 6),
            _chip('Tarea', acc, isDark),
          ])),
          const SizedBox(width: 10),
          GestureDetector(
            onTap: () => widget.onToggleTask(task['id'].toString()),
            child: const Icon(Icons.check_circle_outline_rounded, color: acc, size: 26),
          ),
        ]),
      ),
    );
  }

  Widget _chip(String label, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: isDark ? 0.18 : 0.14),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: color)),
    );
  }

  // ═══════════════════════════════════════════════════════════════════
  //  MONTHLY GRID (untouched logic)
  // ═══════════════════════════════════════════════════════════════════
  Widget _monthlyGrid(bool isDark) {
    final first = DateTime(_currentMonth.year, _currentMonth.month, 1);
    final last  = DateTime(_currentMonth.year, _currentMonth.month + 1, 0);
    final before = first.weekday - 1;

    List<DateTime> days = [];
    for (int i = before - 1; i >= 0; i--) days.add(first.subtract(Duration(days: i + 1)));
    for (int i = 0; i < last.day; i++) days.add(DateTime(_currentMonth.year, _currentMonth.month, i + 1));
    while (days.length < 42) days.add(last.add(Duration(days: days.length - last.day - before + 1)));

    return Container(
      margin: const EdgeInsets.all(20),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
        boxShadow: isDark ? [] : [BoxShadow(color: Colors.black.withValues(alpha: 0.06), blurRadius: 20, offset: const Offset(0, 8))],
      ),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          IconButton(icon: const Icon(Icons.chevron_left_rounded, color: _kPrimary),
              onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month - 1))),
          Text('${_mname(_currentMonth.month)} ${_currentMonth.year}',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17,
                  color: isDark ? Colors.white : const Color(0xFF0F172A))),
          IconButton(icon: const Icon(Icons.chevron_right_rounded, color: _kPrimary),
              onPressed: () => setState(() => _currentMonth = DateTime(_currentMonth.year, _currentMonth.month + 1))),
        ]),
        const SizedBox(height: 16),
        Row(mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(7, (i) => Text(_wdShort[i],
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12, color: _kPrimary)))),
        const SizedBox(height: 16),
        Expanded(child: GridView.builder(
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7, mainAxisSpacing: 8, crossAxisSpacing: 4),
          itemCount: days.length,
          itemBuilder: (_, i) {
            final day = days[i];
            final inMonth  = day.month == _currentMonth.month;
            final sel      = day.day == _selectedDate.day && day.month == _selectedDate.month && day.year == _selectedDate.year;
            return GestureDetector(
              onTap: () { setState(() { _selectedDate = day; _showMonthlyView = false; }); },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                decoration: BoxDecoration(
                  color: sel ? _kPrimary : Colors.transparent,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text('${day.day}', style: TextStyle(
                  fontSize: 14,
                  fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                  color: sel ? Colors.white : (inMonth
                      ? (isDark ? Colors.white : const Color(0xFF0F172A))
                      : (isDark ? const Color(0xFF334155) : const Color(0xFFCBD5E1))),
                )),
              ),
            );
          },
        )),
      ]),
    ).animate().fadeIn(duration: 300.ms);
  }
}
