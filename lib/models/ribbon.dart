class Ribbon {
  final String id;
  final String nameEn;
  final String nameDe;
  final String descEn;
  final String descDe;
  final String titleDe;
  final String locationDe;
  final String imageUrl;
  final int isMark;
  final int minGen;
  final List<String> availableGames;

  Ribbon({
    required this.id,
    required this.nameEn,
    required this.nameDe,
    required this.descEn,
    required this.descDe,
    required this.titleDe,
    required this.locationDe,
    required this.imageUrl,
    required this.isMark,
    required this.minGen,
    required this.availableGames,
  });

  factory Ribbon.fromMap(Map<String, dynamic> map) {
    final availableStr = map['available_games']?.toString() ?? '';

    return Ribbon(
      id: map['id']?.toString() ?? '',
      nameEn: map['name_en']?.toString() ?? '',
      nameDe: map['name_de']?.toString() ?? '',
      descEn: map['desc_en']?.toString() ?? '',
      descDe: map['desc_de']?.toString() ?? '',
      titleDe: map['title_de']?.toString() ?? '',
      locationDe: map['location_de']?.toString() ?? '',
      imageUrl: map['image_url']?.toString() ?? '',
      isMark: (map['is_mark'] as num?)?.toInt() ?? 0,
      minGen: (map['min_gen'] as num?)?.toInt() ?? 3,
      availableGames: availableStr.isNotEmpty ? availableStr.split(',') : [],
    );
  }

  String getName(String lang) => lang == 'de' ? nameDe : nameEn;
  String getDesc(String lang) => lang == 'de' ? descDe : descEn;
}
