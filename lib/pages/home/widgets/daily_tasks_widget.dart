import 'package:flutter/material.dart';
import '../../../theme/app_theme.dart';
import '../../../widgets/neuro_dialog.dart';
import '../../../widgets/skeleton_loader.dart';
import '../../../widgets/upi_loading.dart';
import 'dart:math' as math;

class DailyTasksWidget extends StatefulWidget {
  final VoidCallback playConfetti;
  final List<Map<String, dynamic>> allTasks;
  final List<Map<String, dynamic>> pendingTasks;
  final List<Map<String, dynamic>> completedTasks;
  final bool isLoading;
  final Function(String, DateTime) onAddTask;
  final Function(String) onDeleteTask;
  final Function(String) onToggleTask;

  const DailyTasksWidget({
    super.key,
    required this.playConfetti,
    required this.allTasks,
    required this.pendingTasks,
    required this.completedTasks,
    required this.isLoading,
    required this.onAddTask,
    required this.onDeleteTask,
    required this.onToggleTask,
  });

  @override
  State<DailyTasksWidget> createState() => _DailyTasksWidgetState();
}

class _DailyTasksWidgetState extends State<DailyTasksWidget> {
  final TextEditingController _taskController = TextEditingController();
  DateTime _selectedDueDate = DateTime.now();

  void _deleteTask(String taskId) {
    NeuroDialog.show(
      context: context,
      title: '¿Eliminar actividad?',
      message: 'Esta acción no se puede deshacer. ¿Estás seguro?',
      confirmText: 'Sí, eliminar',
      isDestructive: true,
      onConfirm: () => widget.onDeleteTask(taskId),
    );
  }

  String _formatDueDate(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final taskDate = DateTime(date.year, date.month, date.day);

    if (taskDate == today) {
      return 'Hoy';
    } else if (taskDate == today.add(const Duration(days: 1))) {
      return 'Mañana';
    } else if (taskDate == today.subtract(const Duration(days: 1))) {
      return 'Ayer';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  // Generador determinista de etiquetas visuales para simular el diseño
  Map<String, dynamic> _getTaskTagInfo(String title) {
    final length = title.length;
    if (length % 4 == 0) return {'name': 'Estudio', 'color': AppColors.primary};
    if (length % 3 == 0) return {'name': 'Trabajo', 'color': AppColors.cyan};
    if (length % 2 == 0) return {'name': 'Salud', 'color': AppColors.success};
    return {'name': 'Personal', 'color': AppColors.warning};
  }

  @override
  Widget build(BuildContext context) {
    final pendingTasks = widget.pendingTasks;
    final completedTasks = widget.completedTasks;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Header ──────────────────────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tareas de hoy',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.textDarkPrimary : AppColors.textPrimary,
                ),
              ),
              TextButton(
                onPressed: () {},
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                ),
                child: Text(
                  'Ver todas',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Lista ───────────────────────────────────────────────────
          if (widget.isLoading)
            Column(
              children: [
                const UpiLoading(message: 'Cargando...'),
                const SizedBox(height: 24),
                ...List.generate(3, (index) => const Padding(
                  padding: EdgeInsets.only(bottom: 8.0),
                  child: TaskSkeleton(),
                )),
              ],
            )
          else if (widget.allTasks.isEmpty)
            _buildEmptyState(isDark)
          else ...[
            ...pendingTasks.map((t) => _buildTaskItem(t, false, isDark)),
            ...completedTasks.map((t) => _buildTaskItem(t, true, isDark)),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 40),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.surface,
        borderRadius: BorderRadius.circular(20),
        border: isDark ? Border.all(color: const Color(0xFF334155)) : null,
      ),
      child: Column(
        children: [
          Icon(Icons.task_alt_rounded, size: 48, color: isDark ? AppColors.textDarkSecondary : AppColors.textMuted),
          const SizedBox(height: 16),
          Text(
            '¡No tienes tareas pendientes!',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.textDarkSecondary : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTaskItem(Map<String, dynamic> task, bool isCompleted, bool isDark) {
    final tagInfo = _getTaskTagInfo(task['title']);
    final tagColor = tagInfo['color'] as Color;
    final tagName = tagInfo['name'] as String;

    final bgColor = isCompleted
        ? (isDark ? AppColors.primary.withOpacity(0.15) : AppColors.primary.withOpacity(0.08))
        : (isDark ? AppColors.darkSurface : AppColors.surface);

    final borderColor = isCompleted
        ? Colors.transparent
        : (isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0));

    final textColor = isCompleted
        ? (isDark ? Colors.white : AppColors.primary)
        : (isDark ? AppColors.textDarkPrimary : AppColors.textPrimary);

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Dismissible(
        key: Key(task['id'].toString()),
        direction: DismissDirection.endToStart,
        background: Container(
          decoration: BoxDecoration(
            color: AppColors.error,
            borderRadius: BorderRadius.circular(16),
          ),
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          child: const Icon(Icons.delete_outline_rounded, color: Colors.white, size: 24),
        ),
        onDismissed: (_) => _deleteTask(task['id']),
        child: GestureDetector(
          onTap: () => widget.onToggleTask(task['id']),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Row(
              children: [
                // ── Checkbox circular ─────────────────────────
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted ? AppColors.primary : Colors.transparent,
                    border: Border.all(
                      color: isCompleted ? AppColors.primary : (isDark ? const Color(0xFF64748B) : const Color(0xFFCBD5E1)),
                      width: 2,
                    ),
                  ),
                  child: isCompleted
                      ? const Icon(Icons.check_rounded, size: 16, color: Colors.white)
                      : null,
                ),
                const SizedBox(width: 14),

                // ── Título ─────────────────────────────────────
                Expanded(
                  child: Text(
                    task['title'],
                    style: TextStyle(
                      color: textColor,
                      fontSize: 15,
                      fontWeight: isCompleted ? FontWeight.w700 : FontWeight.w600,
                      decoration: isCompleted ? TextDecoration.lineThrough : null,
                      decorationColor: textColor.withOpacity(0.5),
                    ),
                  ),
                ),

                // ── Etiqueta y Hora (lado derecho) ─────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      tagName,
                      style: TextStyle(
                        color: tagColor,
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _formatDueDate(task['dueDate']),
                      style: TextStyle(
                        color: isDark ? AppColors.textDarkSecondary : AppColors.textMuted,
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
