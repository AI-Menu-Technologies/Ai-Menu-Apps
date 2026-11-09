class MenuItem {
  final String id;
  final String name;
  final String description;
  final int price;
  final String category;
  final String? imageUrl;
  final bool isAvailable;

  const MenuItem({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.category,
    this.imageUrl,
    this.isAvailable = true,
  });
}