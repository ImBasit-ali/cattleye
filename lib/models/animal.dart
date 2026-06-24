/// Animal Model — represents a cattle in the Supabase `animals` table
class Animal {
  final String id;
  final String animalId;
  final String species;
  final int age;
  final String healthStatus;
  final String? imageUrl;
  final DateTime createdAt;
  final DateTime updatedAt;
  final String userId;
  final String? breed;
  final double? weight;
  final String? notes;
  final String? earTag;

  Animal({
    required this.id,
    required this.animalId,
    required this.species,
    required this.age,
    required this.healthStatus,
    this.imageUrl,
    required this.createdAt,
    required this.updatedAt,
    required this.userId,
    this.breed,
    this.weight,
    this.notes,
    this.earTag,
  });

  factory Animal.fromJson(Map<String, dynamic> json) => Animal(
        id: json['id'] as String,
        animalId: json['animal_id'] as String,
        species: json['species'] as String? ?? 'Cow',
        age: (json['age'] as num?)?.toInt() ?? 0,
        healthStatus: json['health_status'] as String? ?? 'Healthy',
        imageUrl: json['image_url'] as String?,
        createdAt: json['created_at'] != null
            ? DateTime.parse(json['created_at'] as String)
            : DateTime.now(),
        updatedAt: json['updated_at'] != null
            ? DateTime.parse(json['updated_at'] as String)
            : DateTime.now(),
        userId: json['user_id'] as String? ?? '',
        breed: json['breed'] as String?,
        weight: (json['weight'] as num?)?.toDouble(),
        notes: json['notes'] as String?,
        earTag: json['ear_tag'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'animal_id': animalId,
        'ear_tag': earTag,
        'species': species,
        'age': age,
        'health_status': healthStatus,
        'image_url': imageUrl,
        'created_at': createdAt.toIso8601String(),
        'updated_at': updatedAt.toIso8601String(),
        'user_id': userId,
        'breed': breed,
        'weight': weight,
        'notes': notes,
      };

  Animal copyWith({
    String? id,
    String? animalId,
    String? species,
    int? age,
    String? healthStatus,
    String? imageUrl,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? userId,
    String? breed,
    double? weight,
    String? notes,
    String? earTag,
  }) =>
      Animal(
        id: id ?? this.id,
        animalId: animalId ?? this.animalId,
        species: species ?? this.species,
        age: age ?? this.age,
        healthStatus: healthStatus ?? this.healthStatus,
        imageUrl: imageUrl ?? this.imageUrl,
        createdAt: createdAt ?? this.createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        userId: userId ?? this.userId,
        breed: breed ?? this.breed,
        weight: weight ?? this.weight,
        notes: notes ?? this.notes,
        earTag: earTag ?? this.earTag,
      );

  @override
  String toString() =>
      'Animal{id: $id, animalId: $animalId, species: $species}';
}
