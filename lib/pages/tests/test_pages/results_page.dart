import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../test_model.dart';
import '../results_repository.dart';

// ─── Test color/icon config ───────────────────────────────────────────────────
const _kTestColors = {
  'attention': Color(0xFF3B82F6),
  'memory':    Color(0xFF10B981),
  'emotion':   Color(0xFF8B5CF6),
  'speed':     Color(0xFFF59E0B),
};
const _kTestIcons = {
  'attention': Icons.center_focus_strong_rounded,
  'memory':    Icons.grid_view_rounded,
  'emotion':   Icons.favorite_rounded,
  'speed':     Icons.flash_on_rounded,
};
const _kTestNames = {
  'attention': 'Test de Atención',
  'memory':    'Test de Memoria',
  'emotion':   'Test Emocional',
  'speed':     'Test de Velocidad',
};

Color _tColor(String id) => _kTestColors[id] ?? const Color(0xFF64748B);
IconData _tIcon(String id) => _kTestIcons[id] ?? Icons.quiz_rounded;
String _tName(String id) => _kTestNames[id] ?? 'Test $id';

// ─── Performance helpers ──────────────────────────────────────────────────────
String _perfText(int s) {
  if (s >= 900) return 'Excelente';
  if (s >= 800) return 'Muy bueno';
  if (s >= 700) return 'Bueno';
  if (s >= 600) return 'Regular';
  return 'Mejorable';
}
Color _perfColor(int s) {
  if (s >= 900) return const Color(0xFF10B981);
  if (s >= 800) return const Color(0xFF34D399);
  if (s >= 700) return const Color(0xFFF59E0B);
  if (s >= 600) return const Color(0xFFFB923C);
  return const Color(0xFFEF4444);
}

// ═════════════════════════════════════════════════════════════════════════════
class ResultsPage extends StatefulWidget {
  const ResultsPage({super.key});
  @override
  State<ResultsPage> createState() => _ResultsPageState();
}

class _ResultsPageState extends State<ResultsPage> {
  List<TestResultData> _results = [];
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _load();
  }

  void _load() {
    try {
      setState(() => _results = ResultsRepository.getResults());
    } catch (e) {
      debugPrint('Error loading results: $e');
      setState(() => _results = []);
    }
  }

  List<TestResultData> get _filtered =>
      _filter == 'all' ? _results : _results.where((r) => r.testId == _filter).toList();

  // ── Delete dialog ──────────────────────────────────────────────────────────
  void _confirmDelete(bool isDark, Color cardBg, Color textMain) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text('Borrar historial',
            style: TextStyle(fontWeight: FontWeight.w800, color: textMain)),
        content: Text('¿Quieres borrar todos los registros? Esta acción no se puede deshacer.',
            style: TextStyle(color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B))),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar', style: TextStyle(color: Color(0xFF64748B)))),
          TextButton(
            onPressed: () async {
              await ResultsRepository.clearResults();
              _load();
              if (mounted) Navigator.pop(context);
            },
            child: const Text('Borrar todo', style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.w700)),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    final isDark     = Theme.of(context).brightness == Brightness.dark;
    final bg         = isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC);
    final cardBg     = isDark ? const Color(0xFF1E293B) : Colors.white;
    final cardBorder = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    final textMain   = isDark ? Colors.white : const Color(0xFF0F172A);
    final textSub    = isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);

    return Scaffold(
      backgroundColor: bg,
      body: Column(children: [

        // ── Header ───────────────────────────────────────────────────────
        _pageHeader(context, isDark, cardBg, textMain, textSub),

        // ── Stats banner (if results exist) ──────────────────────────────
        if (_results.isNotEmpty) ...[
          _statsBanner(isDark, textMain, textSub),
          const SizedBox(height: 4),
          _filterRow(isDark, textSub),
          const SizedBox(height: 4),
        ],

        // ── List / empty ─────────────────────────────────────────────────
        Expanded(
          child: _filtered.isEmpty
              ? _emptyState(isDark, textMain, textSub)
              : ListView.builder(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  itemCount: _filtered.length,
                  itemBuilder: (_, i) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _resultCard(_filtered[i], i, isDark, cardBg, cardBorder, textMain, textSub),
                  ),
                ),
        ),
      ]),
    );
  }

  // ── Page header ────────────────────────────────────────────────────────────
  Widget _pageHeader(BuildContext ctx, bool isDark, Color cardBg, Color textMain, Color textSub) {
    final border = isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0);
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        child: Row(children: [
          GestureDetector(
            onTap: () => Navigator.pop(ctx),
            child: Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(color: cardBg, shape: BoxShape.circle,
                  border: Border.all(color: border)),
              child: Icon(Icons.arrow_back_rounded, size: 20, color: textMain),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Historial', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900,
                  color: textMain, letterSpacing: -0.4)),
              Text('Tus resultados cognitivos', style: TextStyle(fontSize: 12, color: textSub)),
            ]),
          ),
          if (_results.isNotEmpty)
            GestureDetector(
              onTap: () => _confirmDelete(isDark, cardBg, textMain),
              child: Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.2)),
                ),
                child: const Icon(Icons.delete_outline_rounded, size: 20, color: Color(0xFFEF4444)),
              ),
            ),
        ]),
      ),
    );
  }

  // ── Stats banner ───────────────────────────────────────────────────────────
  Widget _statsBanner(bool isDark, Color textMain, Color textSub) {
    final total  = _results.length;
    final avg    = (_results.map((r) => r.score).reduce((a, b) => a + b) / total).round();
    final timeSec = _results.map((r) => r.timeSpent).reduce((a, b) => a + b);
    final timeMin = (timeSec / 60).toStringAsFixed(1);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF4F46E5), Color(0xFF7C3AED)],
          ),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: const Color(0xFF4F46E5).withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
          _statItem(total.toString(), 'Tests', Icons.assignment_rounded),
          _divider(),
          _statItem(avg.toString(), 'Promedio', Icons.star_rounded),
          _divider(),
          _statItem('${timeMin}m', 'Tiempo', Icons.timer_rounded),
        ]),
      ).animate().fadeIn(delay: 100.ms).slideY(begin: 0.08),
    );
  }

  Widget _statItem(String value, String label, IconData icon) {
    return Column(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, color: Colors.white70, size: 18),
      const SizedBox(height: 4),
      Text(value, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w900)),
      Text(label, style: const TextStyle(color: Colors.white70, fontSize: 11, fontWeight: FontWeight.w600)),
    ]);
  }

  Widget _divider() => Container(width: 1, height: 36, color: Colors.white.withValues(alpha: 0.2));

  // ── Filter row ─────────────────────────────────────────────────────────────
  Widget _filterRow(bool isDark, Color textSub) {
    final filters = [
      ('all',       'Todos',    const Color(0xFF4F46E5)),
      ('attention', 'Atención', const Color(0xFF3B82F6)),
      ('memory',    'Memoria',  const Color(0xFF10B981)),
      ('emotion',   'Emocional',const Color(0xFF8B5CF6)),
    ];
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: filters.map((f) {
          final sel = _filter == f.$1;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => setState(() => _filter = f.$1),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: sel ? f.$3.withValues(alpha: 0.15) : Colors.transparent,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: sel ? f.$3 : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
                  ),
                ),
                child: Text(f.$2, style: TextStyle(
                  fontSize: 12, fontWeight: sel ? FontWeight.w800 : FontWeight.w600,
                  color: sel ? f.$3 : textSub,
                )),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Empty state ────────────────────────────────────────────────────────────
  Widget _emptyState(bool isDark, Color textMain, Color textSub) {
    return Center(
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: const Color(0xFF4F46E5).withValues(alpha: 0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.assessment_outlined, size: 48, color: Color(0xFF4F46E5)),
        ),
        const SizedBox(height: 20),
        Text('Sin resultados aún', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textMain)),
        const SizedBox(height: 8),
        Text('Completa algún test para ver\ntu progreso aquí.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: textSub, height: 1.5)),
      ]).animate().fadeIn(duration: 400.ms),
    );
  }

  // ── Result card ────────────────────────────────────────────────────────────
  Widget _resultCard(TestResultData result, int idx, bool isDark, Color cardBg,
      Color cardBorder, Color textMain, Color textSub) {
    final tc   = _tColor(result.testId);
    final pc   = _perfColor(result.score);
    final pTxt = _perfText(result.score);

    return GestureDetector(
      onTap: () => _showDetail(result, isDark, cardBg, tc, textMain, textSub),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: cardBorder),
          boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04), blurRadius: 10, offset: const Offset(0, 3))],
        ),
        child: Row(children: [
          // Icon
          Container(
            width: 48, height: 48,
            decoration: BoxDecoration(
              color: tc.withValues(alpha: isDark ? 0.18 : 0.1),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(_tIcon(result.testId), color: tc, size: 22),
          ),
          const SizedBox(width: 14),
          // Info
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(_tName(result.testId), style: TextStyle(fontSize: 14, fontWeight: FontWeight.w800, color: textMain)),
            const SizedBox(height: 4),
            Row(children: [
              Icon(Icons.timer_outlined, size: 11, color: textSub),
              const SizedBox(width: 3),
              Text('${result.timeSpent}s', style: TextStyle(fontSize: 11, color: textSub, fontWeight: FontWeight.w600)),
              const SizedBox(width: 10),
              Icon(Icons.calendar_today_outlined, size: 11, color: textSub),
              const SizedBox(width: 3),
              Text(_fmtDate(result.date), style: TextStyle(fontSize: 11, color: textSub, fontWeight: FontWeight.w600)),
            ]),
          ])),
          // Score + badge
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('${result.score}', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: tc)),
            const SizedBox(height: 4),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: pc.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: pc.withValues(alpha: 0.25)),
              ),
              child: Text(pTxt, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: pc)),
            ),
          ]),
        ]),
      ).animate().fadeIn(delay: Duration(milliseconds: 100 + idx * 60)).slideX(begin: 0.05),
    );
  }

  // ── Detail dialog ──────────────────────────────────────────────────────────
  void _showDetail(TestResultData result, bool isDark, Color cardBg, Color tc,
      Color textMain, Color textSub) {
    final pc   = _perfColor(result.score);
    final pTxt = _perfText(result.score);

    showDialog(
      context: context,
      builder: (_) => Dialog(
        backgroundColor: cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
            // Header
            Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: tc.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_tIcon(result.testId), color: tc, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(_tName(result.testId),
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textMain))),
            ]),
            const SizedBox(height: 20),

            // Score hero
            Center(
              child: Column(children: [
                Text('${result.score}', style: TextStyle(fontSize: 52, fontWeight: FontWeight.w900, color: tc, height: 1)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                  decoration: BoxDecoration(
                    color: pc.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(pTxt, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: pc)),
                ),
              ]),
            ),
            const SizedBox(height: 20),
            Divider(color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0)),
            const SizedBox(height: 12),

            // Detail rows
            _detailRow(Icons.timer_outlined, 'Tiempo', '${result.timeSpent} segundos', textMain, textSub),
            _detailRow(Icons.calendar_today_outlined, 'Fecha', _fmtDate(result.date), textMain, textSub),
            _detailRow(Icons.access_time_rounded, 'Hora', _fmtTime(result.date), textMain, textSub),

            // Extra details
            if (result.details.isNotEmpty) ...[
              const SizedBox(height: 8),
              ...result.details.entries.where((e) {
                final k = e.key.toLowerCase();
                return k != 'testtype' && k != 'answers';
              }).map((e) {
                String label = e.key;
                if (e.key == 'emotionalType')         label = 'Perfil detectado';
                if (e.key == 'dominantEmotionIndex')  label = 'Emoción principal';
                if (e.key == 'accuracy')              label = 'Precisión';
                return _detailRow(Icons.insights_rounded, label, e.value.toString(), textMain, textSub);
              }),
            ],

            const SizedBox(height: 20),

            // Close button
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [tc, _darken(tc)]),
                  borderRadius: BorderRadius.circular(14),
                ),
                alignment: Alignment.center,
                child: const Text('Cerrar', style: TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w800)),
              ),
            ),
          ]),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value, Color textMain, Color textSub) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(children: [
        Icon(icon, size: 16, color: textSub),
        const SizedBox(width: 10),
        Expanded(child: Text(label, style: TextStyle(fontSize: 13, color: textSub))),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700, color: textMain)),
      ]),
    );
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
  String _fmtTime(DateTime d) => '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';

  Color _darken(Color c) {
    final h = HSLColor.fromColor(c);
    return h.withLightness((h.lightness * 0.72).clamp(0.0, 1.0)).toColor();
  }
}