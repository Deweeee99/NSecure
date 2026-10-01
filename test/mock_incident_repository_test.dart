import 'package:nsecure/features/incident/data/mock/mock_incident_repository.dart';
import 'package:nsecure/features/incident/domain/models/incident_models.dart';
import 'package:nsecure/features/incident/domain/repositories/incident_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('MockIncidentRepository', () {
    test('dashboard and active list are deterministic', () async {
      final repository = MockIncidentRepository();

      final dashboard = await repository.dashboard();
      final incidents = await repository.incidents();

      expect(dashboard.open, 2);
      expect(dashboard.critical, 1);
      expect(incidents.map((incident) => incident.incidentId), containsAll(<int>[91, 92]));
    });

    test('create produces a new Open incident', () async {
      final repository = MockIncidentRepository();

      await repository.createIncident(
        const IncidentCreateInput(
          title: 'Gate obstruction',
          description: 'Delivery boxes obstruct the gate.',
          category: 'Safety',
          severity: IncidentSeverity.high,
          location: 'Loading Bay',
        ),
      );

      final incidents = await repository.incidents(query: 'Gate obstruction');
      expect(incidents, hasLength(1));
      expect(incidents.single.status, IncidentStatus.open);
      expect(incidents.single.canAcknowledge, isTrue);
    });

    test('patrol-linked create forwards the checkpoint side effect hook', () async {
      int? linkedCheckpointVisitId;
      final repository = MockIncidentRepository(
        onPatrolIncidentCreated: (checkpointVisitId) async {
          linkedCheckpointVisitId = checkpointVisitId;
        },
      );

      await repository.createIncident(
        const IncidentCreateInput(
          propertyId: 1,
          patrolCheckpointVisitId: 102,
          title: 'Patrol issue',
          description: 'Issue found during patrol.',
          category: 'Safety',
          severity: IncidentSeverity.medium,
          location: 'Tower A',
        ),
      );

      expect(linkedCheckpointVisitId, 102);
    });

    test('lifecycle uses capability-safe transitions', () async {
      final repository = MockIncidentRepository();

      final acknowledged = await repository.acknowledge(91, notes: 'Seen.');
      expect(acknowledged.status, IncidentStatus.acknowledged);
      expect(acknowledged.canStart, isTrue);
      expect(acknowledged.canResolve, isTrue);

      final started = await repository.start(91, notes: 'Investigating.');
      expect(started.status, IncidentStatus.inProgress);
      expect(started.canResolve, isTrue);

      final resolved = await repository.resolve(91, notes: 'Area secured.');
      expect(resolved.status, IncidentStatus.resolved);
      expect(resolved.resolutionNotes, 'Area secured.');

      final history = await repository.history(status: IncidentStatus.resolved);
      expect(history.map((incident) => incident.incidentId), contains(91));
    });

    test('resolve rejects blank notes', () async {
      final repository = MockIncidentRepository();

      await expectLater(
        repository.resolve(92, notes: '   '),
        throwsA(
          isA<IncidentRepositoryException>().having(
            (error) => error.code,
            'code',
            IncidentRepositoryFailureCode.validation,
          ),
        ),
      );
    });
  });
}
