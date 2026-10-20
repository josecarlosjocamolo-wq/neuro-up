class Achievement {
  final String id;
  final String title;
  final String description;
  final String imagePath;
  final String moment; // ej: "Descubrimiento del Fuego"
  final bool isUnlocked;

  Achievement({
    required this.id,
    required this.title,
    required this.description,
    required this.imagePath,
    required this.moment,
    this.isUnlocked = false,
  });

  Achievement copyWith({bool? isUnlocked}) {
    return Achievement(
      id: id,
      title: title,
      description: description,
      imagePath: imagePath,
      moment: moment,
      isUnlocked: isUnlocked ?? this.isUnlocked,
    );
  }
}
