import 'package:flutter/material.dart';
import '../../models/achievement_model.dart';
import '../../services/achievement_service.dart';
import '../../theme/app_theme.dart';

class StickersPage extends StatefulWidget {
  const StickersPage({super.key});

  @override
  State<StickersPage> createState() => _StickersPageState();
}

class _StickersPageState extends State<StickersPage> {
  List<Achievement> _achievements = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final data = await AchievementService.loadAchievements();
    setState(() {
      _achievements = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: const Text('Mis Momentos Históricos', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Theme.of(context).appBarTheme.backgroundColor ?? Theme.of(context).scaffoldBackgroundColor,
        foregroundColor: Theme.of(context).appBarTheme.foregroundColor ?? Theme.of(context).textTheme.titleLarge?.color,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : GridView.builder(
              padding: const EdgeInsets.all(20),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 0.8,
              ),
              itemCount: _achievements.length,
              itemBuilder: (context, index) {
                final a = _achievements[index];
                return _buildStickerCard(a);
              },
            ),
    );
  }

  Widget _buildStickerCard(Achievement a) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 15,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: a.isUnlocked ? Theme.of(context).cardColor : Theme.of(context).scaffoldBackgroundColor,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
              ),
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                child: Stack(
                  children: [
                    if (a.isUnlocked)
                      Image.network(
                        a.imagePath,
                        fit: BoxFit.cover,
                        width: double.infinity,
                        height: double.infinity,
                        errorBuilder: (context, error, stackTrace) => Container(
                          color: AppColors.primary.withOpacity(0.1),
                          child: const Center(
                            child: Icon(Icons.stars_rounded, size: 50, color: AppColors.primary),
                          ),
                        ),
                      )
                    else
                      const Center(
                        child: Icon(Icons.lock_rounded, color: Colors.grey, size: 40),
                      ),
                    if (!a.isUnlocked)
                      Container(
                        color: Colors.black.withOpacity(0.1),
                      ),
                  ],
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text(
                  a.isUnlocked ? a.moment : "???",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: a.isUnlocked ? Theme.of(context).textTheme.titleLarge?.color : Colors.grey,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  a.isUnlocked ? a.title : "Sigue avanzando",
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: a.isUnlocked ? AppColors.primary : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
