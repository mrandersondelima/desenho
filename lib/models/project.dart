import 'dart:convert';

class Project {
  final String id;
  final String name;
  final DateTime createdAt;
  final DateTime lastModified;

  // Configurações da imagem sobreposta
  final String? overlayImagePath;
  final double imageOpacity;
  final double imagePositionX;
  final double imagePositionY;
  final double imageScale;
  final double imageRotation;
  final bool showOverlayImage;

  const Project({
    required this.id,
    required this.name,
    required this.createdAt,
    required this.lastModified,
    this.overlayImagePath,
    this.imageOpacity = 0.5,
    this.imagePositionX = 0.0,
    this.imagePositionY = 0.0,
    this.imageScale = 1.0,
    this.imageRotation = 0.0,
    this.showOverlayImage = true,
  });

  // Construtor para criar um novo projeto
  factory Project.create(String name) {
    final now = DateTime.now();
    return Project(
      id: generateId(),
      name: name,
      createdAt: now,
      lastModified: now,
    );
  }

  // Gera um ID único baseado no timestamp
  static String generateId() {
    return 'project_${DateTime.now().millisecondsSinceEpoch}';
  }

  // Copia o projeto com novos valores
  Project copyWith({
    String? id,
    String? name,
    DateTime? createdAt,
    DateTime? lastModified,
    String? overlayImagePath,
    double? imageOpacity,
    double? imagePositionX,
    double? imagePositionY,
    double? imageScale,
    double? imageRotation,
    bool? showOverlayImage,
  }) {
    return Project(
      id: id ?? this.id,
      name: name ?? this.name,
      createdAt: createdAt ?? this.createdAt,
      lastModified: lastModified ?? DateTime.now(),
      overlayImagePath: overlayImagePath ?? this.overlayImagePath,
      imageOpacity: imageOpacity ?? this.imageOpacity,
      imagePositionX: imagePositionX ?? this.imagePositionX,
      imagePositionY: imagePositionY ?? this.imagePositionY,
      imageScale: imageScale ?? this.imageScale,
      imageRotation: imageRotation ?? this.imageRotation,
      showOverlayImage: showOverlayImage ?? this.showOverlayImage,
    );
  }

  // Converte para Map para serialização
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'lastModified': lastModified.millisecondsSinceEpoch,
      'overlayImagePath': overlayImagePath,
      'imageOpacity': imageOpacity,
      'imagePositionX': imagePositionX,
      'imagePositionY': imagePositionY,
      'imageScale': imageScale,
      'imageRotation': imageRotation,
      'showOverlayImage': showOverlayImage,
    };
  }

  // Cria Project a partir de Map
  factory Project.fromMap(Map<String, dynamic> map) {
    return Project(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      createdAt: DateTime.fromMillisecondsSinceEpoch(map['createdAt'] ?? 0),
      lastModified: DateTime.fromMillisecondsSinceEpoch(
        map['lastModified'] ?? 0,
      ),
      overlayImagePath: map['overlayImagePath'],
      imageOpacity: (map['imageOpacity'] ?? 0.5).toDouble(),
      imagePositionX: (map['imagePositionX'] ?? 0.0).toDouble(),
      imagePositionY: (map['imagePositionY'] ?? 0.0).toDouble(),
      imageScale: (map['imageScale'] ?? 1.0).toDouble(),
      imageRotation: (map['imageRotation'] ?? 0.0).toDouble(),
      showOverlayImage: map['showOverlayImage'] ?? true,
    );
  }

  // Converte para JSON string
  String toJson() => json.encode(toMap());

  // Cria Project a partir de JSON string
  factory Project.fromJson(String source) =>
      Project.fromMap(json.decode(source));

  @override
  String toString() {
    return 'Project(id: $id, name: $name, createdAt: $createdAt, lastModified: $lastModified, overlayImagePath: $overlayImagePath, imageOpacity: $imageOpacity, imagePositionX: $imagePositionX, imagePositionY: $imagePositionY, imageScale: $imageScale, imageRotation: $imageRotation, showOverlayImage: $showOverlayImage)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is Project &&
        other.id == id &&
        other.name == name &&
        other.createdAt == createdAt &&
        other.lastModified == lastModified &&
        other.overlayImagePath == overlayImagePath &&
        other.imageOpacity == imageOpacity &&
        other.imagePositionX == imagePositionX &&
        other.imagePositionY == imagePositionY &&
        other.imageScale == imageScale &&
        other.imageRotation == imageRotation &&
        other.showOverlayImage == showOverlayImage;
  }

  @override
  int get hashCode {
    return id.hashCode ^
        name.hashCode ^
        createdAt.hashCode ^
        lastModified.hashCode ^
        overlayImagePath.hashCode ^
        imageOpacity.hashCode ^
        imagePositionX.hashCode ^
        imagePositionY.hashCode ^
        imageScale.hashCode ^
        imageRotation.hashCode ^
        showOverlayImage.hashCode;
  }

  // Getters de conveniência
  bool get hasOverlayImage =>
      overlayImagePath != null && overlayImagePath!.isNotEmpty;

  String get formattedCreatedAt {
    return '${createdAt.day.toString().padLeft(2, '0')}/${createdAt.month.toString().padLeft(2, '0')}/${createdAt.year}';
  }

  String get formattedLastModified {
    return '${lastModified.day.toString().padLeft(2, '0')}/${lastModified.month.toString().padLeft(2, '0')}/${lastModified.year}';
  }
}
