import 'package:flutter_test/flutter_test.dart';
import 'package:tendergo/shared/models/requests/category_update_request.dart';

void main() {
  group('CategoryUpdateRequest', () {
    test('builds a partial payload with only changed fields', () {
      final request = CategoryUpdateRequest.fromChangedFields(
        originalName: 'Old Name',
        originalDescription: 'Old description',
        newName: 'New Name',
        newDescription: 'Old description',
      );

      expect(request.toJson(), {
        'name': 'New Name',
      });
    });

    test('includes description when only description changed', () {
      final request = CategoryUpdateRequest.fromChangedFields(
        originalName: 'Old Name',
        originalDescription: 'Old description',
        newName: 'Old Name',
        newDescription: 'New description',
      );

      expect(request.toJson(), {
        'description': 'New description',
      });
    });

    test('omits unchanged fields after trimming input', () {
      final request = CategoryUpdateRequest.fromChangedFields(
        originalName: 'Old Name',
        originalDescription: 'Old description',
        newName: ' Old Name ',
        newDescription: ' Old description ',
      );

      expect(request.toJson(), isEmpty);
    });
  });
}
