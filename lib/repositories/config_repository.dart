import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/config_model.dart';

class ConfigRepository {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Stream<AppConfigModel> watchConfig() {
    return _firestore
        .collection('config')
        .doc('main')
        .snapshots()
        .map((doc) => AppConfigModel.fromMap(doc.data() ?? {}));
  }

  Future<void> updateConfig(AppConfigModel config) async {
    await _firestore.collection('config').doc('main').set(config.toMap());
  }
}
