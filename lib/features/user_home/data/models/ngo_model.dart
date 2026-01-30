import '../../domain/entities/ngo.dart';

class NgoModel extends Ngo {
  const NgoModel({
    required super.id,
    required super.name,
    super.logoUrl,
    super.verified,
  });

  factory NgoModel.fromJson(Map<String, dynamic> json) {
    return NgoModel(
      id: json['id'].toString(),
      name: json['name'] ?? '',
      logoUrl: json['logo_url'],
      verified: json['verified'] ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'logo_url': logoUrl,
        'verified': verified,
      };
}
