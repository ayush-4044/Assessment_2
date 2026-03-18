class ServiceProvider {
  final String name;
  final String category;
  final String imageUrl;
  final double rating;

  ServiceProvider({
    required this.name,
    required this.category,
    required this.imageUrl,
    required this.rating,
  });

  factory ServiceProvider.fromJson(Map<String, dynamic> json) {
    return ServiceProvider(
      name: json['name'],
      category: json['category'],
      imageUrl: json['image'],
      rating: double.parse(json['rating'].toString()),
    );
  }
}