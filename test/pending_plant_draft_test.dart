import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/pending_plant_draft.dart';
import 'package:hive/hive.dart';
import 'package:image_picker/image_picker.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test(
    'recupera foto y formulario tras reinicio, solo para su dueño',
    () async {
      final directory = await Directory.systemTemp.createTemp('camera-draft-');
      Hive.init(directory.path);
      try {
        await PendingPlantDraft.initialize();
        await PendingPlantDraft.save({
          'ownerId': 7,
          'plantId': 12,
          'name': 'Monstera',
          'kept': ['https://example.com/photo.jpg'],
          'photos': [],
        });
        await Hive.close();
        await PendingPlantDraft.initialize();
        await PendingPlantDraft.recoverFiles([
          XFile.fromData(Uint8List.fromList([1, 2, 3]), name: 'camera.jpg'),
        ]);
        expect(PendingPlantDraft.value!['name'], 'Monstera');
        expect(PendingPlantDraft.value!['photos'][0]['bytes'], [1, 2, 3]);
        expect(PendingPlantDraft.routeForUser(7), '/editar-planta/12');
        expect(PendingPlantDraft.routeForUser(8), '/');
        await PendingPlantDraft.clear();
        expect(PendingPlantDraft.value, isNull);
      } finally {
        await Hive.close();
        await directory.delete(recursive: true);
      }
    },
  );
}
