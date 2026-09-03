class AmenityItem {
  final String id;
  final String category;
  final String name;
  final String? description;
  final double? price;
  final String currency;
  final String? imageUrl;

  const AmenityItem({
    required this.id,
    required this.category,
    required this.name,
    this.description,
    this.price,
    required this.currency,
    this.imageUrl,
  });

  factory AmenityItem.fromJson(Map<String, dynamic> j) => AmenityItem(
    id:          j['id'] as String,
    category:    j['category'] as String,
    name:        j['name'] as String,
    description: j['description'] as String?,
    price:       (j['price'] as num?)?.toDouble(),
    currency:    j['currency'] as String? ?? 'ILS',
    imageUrl:    j['image_url'] as String?,
  );
}
