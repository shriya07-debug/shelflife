import 'package:cloud_firestore/cloud_firestore.dart';
import '../service/off_service.dart';
import 'product_repo.dart';

/// SHARED cache at Firestore collection 'products', doc id = barcode.
class ProductRepoFirebaseImpl implements ProductRepo {
  final CollectionReference<Map<String, dynamic>> _col =
      FirebaseFirestore.instance.collection('products');

  @override
  Future<ScannedProduct?> getCached(String barcode) async {
    try {
      final m = (await _col.doc(barcode).get()).data();
      if (m == null) return null;
      return ScannedProduct(
        barcode: barcode,
        name: (m['name'] as String?) ?? '',
        category: (m['category'] as String?) ?? 'Other',
        shelfLifeDays: (m['shelfLifeDays'] as num?)?.toInt() ?? 30,
        imageUrl: m['imageUrl'] as String?,
      );
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> cache(ScannedProduct p) async {
    await _col.doc(p.barcode).set({
      'name': p.name,
      'category': p.category,
      'shelfLifeDays': p.shelfLifeDays,
      'imageUrl': p.imageUrl,
    });
  }
}
