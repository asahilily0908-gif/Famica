/// ユーザーカスタムカテゴリモデル
class CustomCategory {
  final String id;
  final String name;
  final String emoji;
  final int defaultMinutes;
  final bool isVisible;
  final int order;
  final DateTime createdAt;

  CustomCategory({
    required this.id,
    required this.name,
    required this.emoji,
    required this.defaultMinutes,
    this.isVisible = true,
    required this.order,
    required this.createdAt,
  });

  /// Firestoreドキュメントから作成
  factory CustomCategory.fromFirestore(Map<String, dynamic> data, String id) {
    return CustomCategory(
      id: id,
      name: data['name'] as String? ?? '',
      emoji: data['emoji'] as String? ?? '📝',
      defaultMinutes: data['defaultMinutes'] as int? ?? 30,
      isVisible: data['isVisible'] as bool? ?? true,
      order: data['order'] as int? ?? 0,
      createdAt: (data['createdAt'] as dynamic)?.toDate() ?? DateTime.now(),
    );
  }

  /// Firestoreドキュメントに変換
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      'emoji': emoji,
      'defaultMinutes': defaultMinutes,
      'isVisible': isVisible,
      'order': order,
      'createdAt': createdAt,
    };
  }

  /// コピーを作成
  CustomCategory copyWith({
    String? id,
    String? name,
    String? emoji,
    int? defaultMinutes,
    bool? isVisible,
    int? order,
    DateTime? createdAt,
  }) {
    return CustomCategory(
      id: id ?? this.id,
      name: name ?? this.name,
      emoji: emoji ?? this.emoji,
      defaultMinutes: defaultMinutes ?? this.defaultMinutes,
      isVisible: isVisible ?? this.isVisible,
      order: order ?? this.order,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  /// デフォルトカテゴリセット
  static List<CustomCategory> getDefaultCategories() {
    return [
      CustomCategory(
        id: 'default_cooking',
        name: '料理',
        emoji: '🍳',
        defaultMinutes: 30,
        order: 1,
        createdAt: DateTime.now(),
      ),
      CustomCategory(
        id: 'default_laundry',
        name: '洗濯',
        emoji: '🧺',
        defaultMinutes: 15,
        order: 2,
        createdAt: DateTime.now(),
      ),
      CustomCategory(
        id: 'default_cleaning',
        name: '掃除',
        emoji: '🧹',
        defaultMinutes: 20,
        order: 3,
        createdAt: DateTime.now(),
      ),
      CustomCategory(
        id: 'default_shopping',
        name: '買い物',
        emoji: '🛒',
        defaultMinutes: 45,
        order: 4,
        createdAt: DateTime.now(),
      ),
      CustomCategory(
        id: 'default_trash',
        name: 'ゴミ出し',
        emoji: '🗑️',
        defaultMinutes: 5,
        order: 5,
        createdAt: DateTime.now(),
      ),
      CustomCategory(
        id: 'default_water',
        name: '水回り',
        emoji: '💧',
        defaultMinutes: 15,
        order: 6,
        createdAt: DateTime.now(),
      ),
    ];
  }
}
