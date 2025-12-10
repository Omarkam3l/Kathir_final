import '../../domain/entities/offer.dart';

class OfferModel extends Offer {
  const OfferModel({required super.id, required super.discount});

  factory OfferModel.fromJson(Map<String, dynamic> json) {
    return OfferModel(
      id: json['id'].toString(),
      discount: (json['discount'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'discount': discount,
      };
}

