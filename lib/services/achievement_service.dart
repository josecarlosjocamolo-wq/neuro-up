import '../data/local_db.dart';
import '../models/achievement_model.dart';
import '../widgets/neuro_dialog.dart';
import 'auth_service.dart';

class AchievementService {
  static final List<Achievement> _allAchievements = [
    Achievement(
      id: 'fire_discovery',
      title: 'El Primer Paso',
      description: '¡Has descubierto el fuego del conocimiento!',
      imagePath: 'https://images.unsplash.com/photo-1542397284385-601017645516?w=400&q=80',
      moment: 'Descubrimiento del Fuego',
    ),
    Achievement(
      id: 'mj_dance',
      title: 'Rey del Ritmo',
      description: 'Bailando hacia el éxito con el Rey del Pop.',
      imagePath: 'https://images.unsplash.com/photo-1508700115892-45ecd05ae2ad?w=400&q=80',
      moment: 'Thriller con Michael Jackson',
    ),
    Achievement(
      id: 'moon_landing',
      title: 'Salto Gigante',
      description: 'Un pequeño paso para ti, un gran salto para tu productividad.',
      imagePath: 'https://images.unsplash.com/photo-1451187580459-43490279c0fa?w=400&q=80',
      moment: 'Alunizaje 1969',
    ),
    Achievement(
      id: 'da_vinci',
      title: 'Genio Creativo',
      description: 'Ayudando a Leonardo con su próxima obra maestra.',
      imagePath: 'https://images.unsplash.com/photo-1579783902614-a3fb3927b6a5?w=400&q=80',
      moment: 'Taller de Da Vinci',
    ),
  ];

  static Future<List<Achievement>> loadAchievements() async {
    final user = AuthService.current;
    if (user == null) return _allAchievements;

    try {
      final db = await LocalDb.instance.database;
      final response = await db.query(
        'user_achievements',
        columns: ['achievement_id'],
        where: 'user_id = ?',
        whereArgs: [user.id],
      );

      final unlockedIds =
          response.map((r) => r['achievement_id']).toSet();

      return _allAchievements.map((a) {
        return a.copyWith(isUnlocked: unlockedIds.contains(a.id));
      }).toList();
    } catch (e) {
      print('Error loading achievements: $e');
      return _allAchievements;
    }
  }

  static Future<bool> unlockAchievement(String achievementId) async {
    final user = AuthService.current;
    if (user == null) return false;

    try {
      final db = await LocalDb.instance.database;
      final check = await db.query(
        'user_achievements',
        where: 'user_id = ? AND achievement_id = ?',
        whereArgs: [user.id, achievementId],
        limit: 1,
      );
      if (check.isNotEmpty) return false; // Ya desbloqueado

      await db.insert('user_achievements', {
        'user_id': user.id,
        'achievement_id': achievementId,
        'unlocked_at': DateTime.now().toIso8601String(),
      });
      return true;
    } catch (e) {
      print('Error unlocking achievement: $e');
      return false;
    }
  }

  static Achievement getById(String id) {
    return _allAchievements.firstWhere((a) => a.id == id);
  }

  static Future<bool> isUnlocked(String achievementId) async {
    final user = AuthService.current;
    if (user == null) return false;
    final db = await LocalDb.instance.database;
    final rows = await db.query(
      'user_achievements',
      where: 'user_id = ? AND achievement_id = ?',
      whereArgs: [user.id, achievementId],
      limit: 1,
    );
    return rows.isNotEmpty;
  }

  static Future<void> checkAfterTest(dynamic context, dynamic result) async {
    // 1. Primer Test completado -> Fuego
    final isFirstTest = !await isUnlocked('fire_discovery');
    if (isFirstTest) {
      final unlocked = await unlockAchievement('fire_discovery');
      if (unlocked) {
        final a = getById('fire_discovery');
        // ignore: use_build_context_synchronously
        NeuroDialog.showAchievement(
          context: context,
          title: a.title,
          message: a.description,
          assetPath: 'assets/images/achievements/fire.png',
          moment: a.moment,
          onConfirm: () {},
        );
        return; // Solo mostrar uno a la vez
      }
    }

    // 2. Puntuación alta -> MJ
    if (result.score >= 900) {
      final alreadyUnlocked = await isUnlocked('mj_dance');
      if (!alreadyUnlocked) {
        final unlocked = await unlockAchievement('mj_dance');
        if (unlocked) {
          final a = getById('mj_dance');
          // ignore: use_build_context_synchronously
          NeuroDialog.showAchievement(
            context: context,
            title: a.title,
            message: a.description,
            assetPath: 'assets/images/achievements/mj.png',
            moment: a.moment,
            onConfirm: () {},
          );
        }
      }
    }
  }
}
