import 'package:flutter/material.dart';
import 'package:app/product.dart';

class ProductsList extends StatelessWidget {
  final List<Product> products;

  const ProductsList({Key? key, required this.products}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: products.length,
      itemBuilder: (context, index) {
        final product = products[index];
        final daysUntilExpiration = product.expirationDate.difference(DateTime.now()).inDays;
        return ListTile(
          leading: Text(
            product.emoji,
            style: const TextStyle(fontSize: 24),
          ),
          title: Text(product.name),
          subtitle: Text('Expires on: ${product.expirationDate.toLocal()}'),
          tileColor: daysUntilExpiration < 3 ? Colors.red : null,
        );
      },
    );
  }
}
