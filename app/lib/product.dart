class Product {
  final String name;
  final DateTime expirationDate;
  final String emoji;

  Product(this.name, this.expirationDate, this.emoji);

  Product.fromJson(Map<String, dynamic> json) :
    name = json["product"] as String,
    emoji = json["emoji"] as String,
    expirationDate = DateTime.fromMillisecondsSinceEpoch(
      (json['expiry_timestamp'] as int) * 1000);
}