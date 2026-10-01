import 'package:nsecure/core/network/security_api_client.dart';
import 'package:nsecure/features/package/data/api/api_security_package_repository.dart';
import 'package:nsecure/features/package/domain/models/security_package_models.dart';
import 'package:nsecure/features/package/domain/repositories/security_package_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ApiSecurityPackageRepository', () {
    test('resident lookup uses APH.38 search endpoint and filters', () async {
      final client = _FakePackageClient();
      client.getResponses['/packages/residents/search'] = _success(
        <Map<String, dynamic>>[_residentLookupPayload()],
      );
      final repository = ApiSecurityPackageRepository(client);

      final residents = await repository.searchResidents(
        query: ' A-101 ',
        propertyId: 1,
        limit: 25,
      );

      expect(client.lastGetPath, '/packages/residents/search');
      expect(client.lastGetQuery, <String, String?>{
        'q': 'A-101',
        'property_id': '1',
        'limit': '25',
      });
      expect(residents.single.resident.id, 101);
      expect(residents.single.unit.code, 'A-101');
    });

    test('resident lookup decodes current full-handoff top-level shape', () async {
      final client = _FakePackageClient();
      client.getResponses['/packages/residents/search'] = _success(
        <Map<String, dynamic>>[
          <String, dynamic>{
            'id': 101,
            'name': 'Budi Santoso',
            'email': 'budi@example.com',
            'mobile_no': '0812...',
            'property': <String, dynamic>{
              'id': 1,
              'code': 'APT-01',
              'name': 'Aparthub Residence',
            },
            'unit': <String, dynamic>{
              'id': 44,
              'code': 'A-101',
              'tower': 'Tower A',
              'floor': '1',
            },
          },
        ],
      );
      final repository = ApiSecurityPackageRepository(client);

      final residents = await repository.searchResidents(query: 'Budi');

      expect(residents.single.resident.id, 101);
      expect(residents.single.property.id, 1);
      expect(residents.single.unit.code, 'A-101');
      expect(residents.single.unit.floor, 1);
    });

    test('receive sends only client-owned APH.38 fields', () async {
      final client = _FakePackageClient();
      client.postResponses['/packages'] = _success(_packagePayload());
      final repository = ApiSecurityPackageRepository(client);

      final record = await repository.receivePackage(
        const SecurityPackageReceiveInput(
          residentId: 101,
          courierName: ' JNE ',
          trackingNumber: ' JNE-123456 ',
          senderName: ' Seller ',
          packageDescription: ' Medium box ',
          storageLocation: ' Lobby Rack A ',
          notes: ' Handle with care ',
        ),
      );

      expect(client.lastPostPath, '/packages');
      expect(client.lastPostBody, <String, dynamic>{
        'resident_id': 101,
        'courier_name': 'JNE',
        'tracking_number': 'JNE-123456',
        'sender_name': 'Seller',
        'package_description': 'Medium box',
        'storage_location': 'Lobby Rack A',
        'notes': 'Handle with care',
      });
      expect(client.lastPostBody, isNot(containsPair('status', anything)));
      expect(client.lastPostBody, isNot(containsPair('property_id', anything)));
      expect(client.lastPostBody, isNot(containsPair('unit_id', anything)));
      expect(client.lastPostBody, isNot(containsPair('received_at', anything)));
      expect(record.status, SecurityPackageStatus.readyForPickup);
    });

    test('V2 detail parses pickup recipient and processor separately', () async {
      final client = _FakePackageClient();
      client.getResponses['/packages/55'] = _success(
        _packagePayload(status: 'Collected'),
      );
      final repository = ApiSecurityPackageRepository(client);

      final record = await repository.findById(55);

      expect(record, isNotNull);
      expect(record!.collectedBy?.type,
          SecurityPackageCollectionRecipientType.resident);
      expect(record.collectedBy?.name, 'Budi Santoso');
      expect(record.collectedBy?.residentId, 101);
      expect(record.processedBy?.name, 'Security Officer');
      expect(record.receivedBy?.name, 'Security Officer');
    });

    test('legacy collected_by actor is treated as processed_by, not recipient',
        () async {
      final client = _FakePackageClient();
      final payload = _packagePayload(status: 'Collected');
      payload['collected_by'] = <String, dynamic>{
        'id': 9,
        'name': 'Legacy Security Officer',
      };
      payload['processed_by'] = null;
      client.getResponses['/packages/55'] = _success(payload);
      final repository = ApiSecurityPackageRepository(client);

      final record = await repository.findById(55);

      expect(record, isNotNull);
      expect(record!.status, SecurityPackageStatus.collected);
      expect(record.collectedBy, isNull);
      expect(record.processedBy?.id, 9);
      expect(record.processedBy?.name, 'Legacy Security Officer');
    });

    test('collect resident sends canonical recipient type without resident name',
        () async {
      final client = _FakePackageClient();
      client.postResponses['/packages/55/collect'] = _success(
        _packagePayload(status: 'Collected'),
      );
      final repository = ApiSecurityPackageRepository(client);

      final record = await repository.collectPackage(
        55,
        recipientType: SecurityPackageCollectionRecipientType.resident,
        collectionNotes: ' Picked up at lobby. ',
      );

      expect(client.lastPostPath, '/packages/55/collect');
      expect(client.lastPostBody, <String, dynamic>{
        'collection_recipient_type': 'resident',
        'collection_notes': 'Picked up at lobby.',
      });
      expect(record.status, SecurityPackageStatus.collected);
      expect(record.collectedBy?.type,
          SecurityPackageCollectionRecipientType.resident);
      expect(record.collectedBy?.name, 'Budi Santoso');
      expect(record.processedBy?.name, 'Security Officer');
    });

    test('collect others sends canonical type and required free-text name',
        () async {
      final client = _FakePackageClient();
      client.postResponses['/packages/55/collect'] = _success(
        _packagePayload(
          status: 'Collected',
          recipientType: 'others',
          recipientName: 'Mbak Rina - ART',
        ),
      );
      final repository = ApiSecurityPackageRepository(client);

      final record = await repository.collectPackage(
        55,
        recipientType: SecurityPackageCollectionRecipientType.others,
        collectionRecipientName: ' Mbak Rina - ART ',
        collectionNotes: ' Picked up at lobby. ',
      );

      expect(client.lastPostBody, <String, dynamic>{
        'collection_recipient_type': 'others',
        'collection_recipient_name': 'Mbak Rina - ART',
        'collection_notes': 'Picked up at lobby.',
      });
      expect(record.collectedBy?.type,
          SecurityPackageCollectionRecipientType.others);
      expect(record.collectedBy?.name, 'Mbak Rina - ART');
      expect(record.collectedBy?.residentId, isNull);
      expect(record.processedBy?.name, 'Security Officer');
    });

    test('resident unavailable maps the V2 stable package error', () async {
      final client = _FakePackageClient();
      client.postErrors['/packages/55/collect'] = const SecurityApiException(
        statusCode: 422,
        code: 'PACKAGE_COLLECTION_RESIDENT_UNAVAILABLE',
        message: 'The package resident is no longer available for collection.',
      );
      final repository = ApiSecurityPackageRepository(client);

      await expectLater(
        repository.collectPackage(
          55,
          recipientType: SecurityPackageCollectionRecipientType.resident,
        ),
        throwsA(
          isA<SecurityPackageRepositoryException>().having(
            (error) => error.code,
            'code',
            SecurityPackageRepositoryFailureCode.collectionResidentUnavailable,
          ),
        ),
      );
    });

    test('collect others rejects missing recipient name before POST', () async {
      final client = _FakePackageClient();
      final repository = ApiSecurityPackageRepository(client);

      await expectLater(
        repository.collectPackage(
          55,
          recipientType: SecurityPackageCollectionRecipientType.others,
          collectionRecipientName: '   ',
        ),
        throwsA(
          isA<SecurityPackageRepositoryException>()
              .having(
                (error) => error.code,
                'code',
                SecurityPackageRepositoryFailureCode.validation,
              )
              .having(
                (error) => error.fieldErrors,
                'fieldErrors',
                contains('collection_recipient_name'),
              ),
        ),
      );
      expect(client.lastPostPath, isNull);
    });

    test('package center unavailable maps by stable code, not message', () async {
      final client = _FakePackageClient();
      client.getErrors['/packages'] = const SecurityApiException(
        statusCode: 403,
        code: 'PACKAGE_CENTER_UNAVAILABLE',
        message: 'Package Center tidak aktif.',
      );
      final repository = ApiSecurityPackageRepository(client);

      await expectLater(
        repository.packages(),
        throwsA(
          isA<SecurityPackageRepositoryException>().having(
            (error) => error.code,
            'code',
            SecurityPackageRepositoryFailureCode.centerUnavailable,
          ),
        ),
      );
    });

    test(
      'package decoder uses documented nested resident unit when top-level copy is not an object',
      () async {
        final client = _FakePackageClient();
        final payload = _packagePayload();
        final resident = payload['resident']! as Map<String, dynamic>;
        resident['property'] = Map<String, dynamic>.from(
          payload['property']! as Map<String, dynamic>,
        );
        resident['unit'] = <String, dynamic>{
          'id': 44,
          'code': 'A-101',
          'tower': 'Tower A',
          'floor': '1',
        };
        payload['unit'] = 'A-101';
        client.getResponses['/packages/55'] = _success(payload);
        final repository = ApiSecurityPackageRepository(client);

        final record = await repository.findById(55);

        expect(record, isNotNull);
        expect(record!.unit.code, 'A-101');
        expect(record.unit.floor, 1);
      },
    );

    test('unknown package wire status fails closed', () async {
      final client = _FakePackageClient();
      client.getResponses['/packages/55'] = _success(
        _packagePayload(status: 'Stored'),
      );
      final repository = ApiSecurityPackageRepository(client);

      await expectLater(
        repository.findById(55),
        throwsA(
          isA<SecurityPackageRepositoryException>().having(
            (error) => error.code,
            'code',
            SecurityPackageRepositoryFailureCode.unknown,
          ),
        ),
      );
    });
  });
}

Map<String, dynamic> _success(dynamic data) => <String, dynamic>{
      'status': 'success',
      'message': 'OK',
      'data': data,
    };

Map<String, dynamic> _residentLookupPayload() => <String, dynamic>{
      'resident': <String, dynamic>{
        'id': 101,
        'name': 'Budi Santoso',
        'email': 'budi@example.com',
        'mobile_no': '0812...',
      },
      'property': <String, dynamic>{
        'id': 1,
        'code': 'APT-01',
        'name': 'Aparthub Residence',
      },
      'unit': <String, dynamic>{
        'id': 44,
        'code': 'A-101',
        'tower': 'Tower A',
        'floor': 1,
      },
    };

Map<String, dynamic> _packagePayload({
  String status = 'Ready for Pickup',
  String recipientType = 'resident',
  String? recipientName,
}) {
  return <String, dynamic>{
    'package_id': 55,
    'package_no': 'PKG-260814-AB12CD34',
    'status': status,
    'courier_name': 'JNE',
    'tracking_number': 'JNE-123456',
    'sender_name': 'Marketplace Seller',
    'package_description': 'Medium box',
    'storage_location': 'Lobby Rack A',
    'notes': 'Handle with care',
    'collection_notes': status == 'Collected' ? 'Collected by resident.' : null,
    'property': <String, dynamic>{
      'id': 1,
      'code': 'APT-01',
      'name': 'Aparthub Residence',
    },
    'resident': <String, dynamic>{
      'id': 101,
      'name': 'Budi Santoso',
      'email': 'budi@example.com',
      'mobile_no': '0812...',
      'property': <String, dynamic>{
        'id': 1,
        'code': 'APT-01',
        'name': 'Aparthub Residence',
      },
      'unit': <String, dynamic>{
        'id': 44,
        'code': 'A-101',
        'tower': 'Tower A',
        'floor': '1',
      },
    },
    'unit': <String, dynamic>{
      'id': 44,
      'code': 'A-101',
      'tower': 'Tower A',
      'floor': 1,
    },
    'received_by': <String, dynamic>{'id': 9, 'name': 'Security Officer'},
    'collected_by': status == 'Collected'
        ? <String, dynamic>{
            'type': recipientType,
            'name': recipientName ??
                (recipientType == 'resident' ? 'Budi Santoso' : 'Other Person'),
            'resident_id': recipientType == 'resident' ? 101 : null,
          }
        : null,
    'processed_by': status == 'Collected'
        ? <String, dynamic>{'id': 9, 'name': 'Security Officer'}
        : null,
    'received_at': '2026-08-14T13:30:00+07:00',
    'notified_at': null,
    'collected_at': status == 'Collected' ? '2026-08-14T14:00:00+07:00' : null,
    'expires_at': null,
  };
}

class _FakePackageClient implements SecurityApiClient {
  @override
  String? bearerToken = 'token';

  final getResponses = <String, Map<String, dynamic>>{};
  final postResponses = <String, Map<String, dynamic>>{};
  final getErrors = <String, SecurityApiException>{};
  final postErrors = <String, SecurityApiException>{};
  String? lastGetPath;
  Map<String, String?>? lastGetQuery;
  String? lastPostPath;
  Map<String, dynamic>? lastPostBody;

  @override
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String?> query = const <String, String?>{},
    bool authenticated = true,
  }) async {
    lastGetPath = path;
    lastGetQuery = query;
    final error = getErrors[path];
    if (error != null) throw error;
    final response = getResponses[path];
    if (response == null) throw StateError('No fake GET response for $path');
    return response;
  }

  @override
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic> body = const <String, dynamic>{},
    bool authenticated = true,
  }) async {
    lastPostPath = path;
    lastPostBody = body;
    final error = postErrors[path];
    if (error != null) throw error;
    final response = postResponses[path];
    if (response == null) throw StateError('No fake POST response for $path');
    return response;
  }
}
