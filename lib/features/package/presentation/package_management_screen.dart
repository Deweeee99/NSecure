import 'package:flutter/material.dart';

import '../../../core/localization/app_localizations_x.dart';
import '../../../core/theme/security_tokens.dart';
import '../domain/models/security_package_models.dart';
import '../domain/repositories/security_package_repository.dart';

class PackageManagementScreen extends StatefulWidget {
  const PackageManagementScreen({
    required this.repository,
    required this.onBackHome,
    this.onSessionExpired,
    super.key,
  });

  final SecurityPackageRepository repository;
  final VoidCallback onBackHome;
  final Future<void> Function()? onSessionExpired;

  @override
  State<PackageManagementScreen> createState() => _PackageManagementScreenState();
}

enum _PackageView { dashboard, receive, detail }

class _PackageManagementScreenState extends State<PackageManagementScreen> {
  final _packageSearchController = TextEditingController();
  final _residentSearchController = TextEditingController();
  final _courierController = TextEditingController();
  final _trackingController = TextEditingController();
  final _senderController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _storageController = TextEditingController();
  final _notesController = TextEditingController();
  final _collectionNotesController = TextEditingController();
  final _collectionRecipientNameController = TextEditingController();

  _PackageView _view = _PackageView.dashboard;
  SecurityPackageStatus? _statusFilter;
  List<SecurityPackageRecord> _packages = const <SecurityPackageRecord>[];
  List<SecurityPackageResidentLookup> _residentResults =
      const <SecurityPackageResidentLookup>[];
  SecurityPackageResidentLookup? _selectedResident;
  SecurityPackageRecord? _selectedPackage;
  SecurityPackageCollectionRecipientType _collectionRecipientType =
      SecurityPackageCollectionRecipientType.resident;
  bool _loading = true;
  bool _residentSearching = false;
  bool _submitting = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadPackages();
  }

  @override
  void dispose() {
    _packageSearchController.dispose();
    _residentSearchController.dispose();
    _courierController.dispose();
    _trackingController.dispose();
    _senderController.dispose();
    _descriptionController.dispose();
    _storageController.dispose();
    _notesController.dispose();
    _collectionNotesController.dispose();
    _collectionRecipientNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return switch (_view) {
      _PackageView.dashboard => _buildDashboard(context),
      _PackageView.receive => _buildReceive(context),
      _PackageView.detail => _buildDetail(context),
    };
  }

  Widget _buildDashboard(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: _loadPackages,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            SecuritySpacing.md,
            SecuritySpacing.sm,
            SecuritySpacing.md,
            SecuritySpacing.xl,
          ),
          children: [
            _PackageHeader(
              title: context.l10n.packageReceiving,
              subtitle: context.l10n.packageReceivingSubtitle,
              onBack: widget.onBackHome,
            ),
            const SizedBox(height: SecuritySpacing.md),
            _PackageNotice(message: context.l10n.packageCenterSourceOfTruth),
            const SizedBox(height: SecuritySpacing.md),
            FilledButton.icon(
              key: const Key('openReceivePackageButton'),
              onPressed: _openReceive,
              icon: const Icon(Icons.inventory_2_outlined),
              label: Text(context.l10n.receivePackage),
            ),
            const SizedBox(height: SecuritySpacing.lg),
            TextField(
              key: const Key('packageListSearchField'),
              controller: _packageSearchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _loadPackages(),
              decoration: InputDecoration(
                labelText: context.l10n.searchPackages,
                hintText: context.l10n.searchPackagesHint,
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: IconButton(
                  tooltip: context.l10n.search,
                  onPressed: _loadPackages,
                  icon: const Icon(Icons.arrow_forward_rounded),
                ),
              ),
            ),
            const SizedBox(height: SecuritySpacing.sm),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _StatusFilterChip(
                    label: context.l10n.all,
                    selected: _statusFilter == null,
                    onSelected: () => _setStatusFilter(null),
                  ),
                  const SizedBox(width: SecuritySpacing.xs),
                  _StatusFilterChip(
                    label: context.l10n.packageStatusReadyForPickup,
                    selected:
                        _statusFilter == SecurityPackageStatus.readyForPickup,
                    onSelected: () => _setStatusFilter(
                      SecurityPackageStatus.readyForPickup,
                    ),
                  ),
                  const SizedBox(width: SecuritySpacing.xs),
                  _StatusFilterChip(
                    label: context.l10n.packageStatusCollected,
                    selected: _statusFilter == SecurityPackageStatus.collected,
                    onSelected: () => _setStatusFilter(
                      SecurityPackageStatus.collected,
                    ),
                  ),
                  const SizedBox(width: SecuritySpacing.xs),
                  _StatusFilterChip(
                    label: context.l10n.packageStatusExpired,
                    selected: _statusFilter == SecurityPackageStatus.expired,
                    onSelected: () => _setStatusFilter(
                      SecurityPackageStatus.expired,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: SecuritySpacing.lg),
            Row(
              children: [
                Expanded(
                  child: Text(
                    context.l10n.packageList,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Text(
                  '${_packages.length}',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
            const SizedBox(height: SecuritySpacing.sm),
            if (_loading)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(SecuritySpacing.xl),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (_error != null)
              _PackageErrorCard(message: _error!, onRetry: _loadPackages)
            else if (_packages.isEmpty)
              _PackageEmptyCard(
                icon: Icons.inventory_2_outlined,
                title: context.l10n.noPackages,
                message: context.l10n.noPackagesMessage,
              )
            else
              ..._packages.map(
                (record) => Padding(
                  padding: const EdgeInsets.only(bottom: SecuritySpacing.sm),
                  child: _PackageRecordCard(
                    record: record,
                    onTap: () => _openPackage(record.packageId),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildReceive(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          key: const Key('packageReceiveFormList'),
          padding: const EdgeInsets.fromLTRB(
            SecuritySpacing.md,
            SecuritySpacing.sm,
            SecuritySpacing.md,
            SecuritySpacing.xl,
          ),
          children: [
            _PackageHeader(
              title: context.l10n.receivePackage,
              subtitle: context.l10n.receivePackageSubtitle,
              onBack: _backToDashboard,
            ),
            const SizedBox(height: SecuritySpacing.md),
            _PackageNotice(message: context.l10n.packageServerOwnedNotice),
            const SizedBox(height: SecuritySpacing.md),
            Text(
              context.l10n.searchResidentUnit,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: SecuritySpacing.sm),
            TextField(
              key: const Key('packageResidentSearchField'),
              controller: _residentSearchController,
              textInputAction: TextInputAction.search,
              onSubmitted: (_) => _searchResidents(),
              decoration: InputDecoration(
                hintText: context.l10n.searchResidentUnitHint,
                prefixIcon: const Icon(Icons.person_search_outlined),
              ),
            ),
            const SizedBox(height: SecuritySpacing.xs),
            OutlinedButton.icon(
              key: const Key('packageResidentSearchButton'),
              onPressed: _residentSearching ? null : _searchResidents,
              icon: _residentSearching
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.search_rounded),
              label: Text(context.l10n.searchResident),
            ),
            if (_residentResults.isNotEmpty) ...[
              const SizedBox(height: SecuritySpacing.sm),
              ..._residentResults.map(
                (lookup) => Padding(
                  padding: const EdgeInsets.only(bottom: SecuritySpacing.xs),
                  child: _ResidentLookupCard(
                    key: Key('packageResidentResult-${lookup.resident.id}'),
                    lookup: lookup,
                    selected: _selectedResident?.resident.id ==
                        lookup.resident.id,
                    onTap: () => setState(() => _selectedResident = lookup),
                  ),
                ),
              ),
            ] else if (!_residentSearching &&
                _residentSearchController.text.trim().isNotEmpty) ...[
              const SizedBox(height: SecuritySpacing.sm),
              _PackageEmptyCard(
                icon: Icons.person_off_outlined,
                title: context.l10n.noResidentsFound,
                message: context.l10n.noResidentsFoundMessage,
              ),
            ],
            if (_selectedResident != null) ...[
              const SizedBox(height: SecuritySpacing.md),
              _SelectedResidentCard(lookup: _selectedResident!),
            ],
            const SizedBox(height: SecuritySpacing.lg),
            Text(
              context.l10n.packageDetails,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: SecuritySpacing.sm),
            TextField(
              key: const Key('packageCourierField'),
              controller: _courierController,
              decoration: InputDecoration(labelText: context.l10n.courierName),
            ),
            const SizedBox(height: SecuritySpacing.sm),
            TextField(
              key: const Key('packageTrackingField'),
              controller: _trackingController,
              decoration: InputDecoration(
                labelText: context.l10n.trackingNumberOptional,
              ),
            ),
            const SizedBox(height: SecuritySpacing.sm),
            TextField(
              key: const Key('packageSenderField'),
              controller: _senderController,
              decoration: InputDecoration(
                labelText: context.l10n.senderNameOptional,
              ),
            ),
            const SizedBox(height: SecuritySpacing.sm),
            TextField(
              key: const Key('packageDescriptionField'),
              controller: _descriptionController,
              decoration: InputDecoration(
                labelText: context.l10n.packageDescriptionOptional,
              ),
            ),
            const SizedBox(height: SecuritySpacing.sm),
            TextField(
              key: const Key('packageStorageField'),
              controller: _storageController,
              decoration: InputDecoration(
                labelText: context.l10n.storageLocationOptional,
              ),
            ),
            const SizedBox(height: SecuritySpacing.sm),
            TextField(
              key: const Key('packageNotesField'),
              controller: _notesController,
              minLines: 2,
              maxLines: 4,
              decoration: InputDecoration(labelText: context.l10n.optionalNotes),
            ),
            if (_error != null) ...[
              const SizedBox(height: SecuritySpacing.md),
              _PackageErrorCard(message: _error!),
            ],
          ],
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(
          SecuritySpacing.md,
          SecuritySpacing.xs,
          SecuritySpacing.md,
          SecuritySpacing.md,
        ),
        child: FilledButton.icon(
          key: const Key('packageReceiveButton'),
          onPressed: _submitting ? null : _receivePackage,
          icon: _submitting
              ? const SizedBox.square(
                  dimension: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.inventory_2_outlined),
          label: Text(context.l10n.registerPackage),
        ),
      ),
    );
  }

  Widget _buildDetail(BuildContext context) {
    final record = _selectedPackage;
    if (record == null) {
      return const SizedBox.shrink();
    }
    final canCollect = record.status == SecurityPackageStatus.readyForPickup;
    final canRecordMissingRecipient =
        record.status == SecurityPackageStatus.collected &&
            record.collectedBy == null;
    final canSubmitCollectionRecipient =
        canCollect || canRecordMissingRecipient;

    return Scaffold(
      body: SafeArea(
        bottom: false,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(
            SecuritySpacing.md,
            SecuritySpacing.sm,
            SecuritySpacing.md,
            SecuritySpacing.xl,
          ),
          children: [
            _PackageHeader(
              title: context.l10n.packageDetail,
              subtitle: record.packageNo,
              onBack: _backToDashboard,
            ),
            const SizedBox(height: SecuritySpacing.md),
            _PackageStatusPill(status: record.status),
            const SizedBox(height: SecuritySpacing.md),
            _PackageDetailCard(
              children: [
                _DetailRow(
                  label: context.l10n.resident,
                  value: record.resident.name,
                ),
                _DetailRow(
                  label: context.l10n.unit,
                  value: _unitLabel(record.unit),
                ),
                _DetailRow(
                  label: context.l10n.property,
                  value: record.property.name,
                ),
                _DetailRow(
                  label: context.l10n.courierName,
                  value: record.courierName,
                ),
                if (record.trackingNumber != null)
                  _DetailRow(
                    label: context.l10n.trackingNumber,
                    value: record.trackingNumber!,
                  ),
                if (record.senderName != null)
                  _DetailRow(
                    label: context.l10n.senderName,
                    value: record.senderName!,
                  ),
                if (record.packageDescription != null)
                  _DetailRow(
                    label: context.l10n.packageDescription,
                    value: record.packageDescription!,
                  ),
                if (record.storageLocation != null)
                  _DetailRow(
                    label: context.l10n.storageLocation,
                    value: record.storageLocation!,
                  ),
                _DetailRow(
                  label: context.l10n.receivedAt,
                  value: _formatTimestamp(context, record.receivedAt),
                ),
                if (record.receivedBy != null)
                  _DetailRow(
                    label: context.l10n.receivedBy,
                    value: record.receivedBy!.name,
                  ),
                if (record.expiresAt != null)
                  _DetailRow(
                    label: context.l10n.expiresAt,
                    value: _formatTimestamp(context, record.expiresAt!),
                  ),
                if (record.collectedAt != null)
                  _DetailRow(
                    label: context.l10n.collectedAt,
                    value: _formatTimestamp(context, record.collectedAt!),
                  ),
                if (record.collectedBy != null) ...[
                  _DetailRow(
                    label: context.l10n.pickedUpByType,
                    value: _recipientTypeLabel(
                      context,
                      record.collectedBy!.type,
                    ),
                  ),
                  _DetailRow(
                    label: context.l10n.collectedBy,
                    value: record.collectedBy!.name,
                  ),
                ] else if (record.status == SecurityPackageStatus.collected)
                  _DetailRow(
                    label: context.l10n.collectedBy,
                    value: context.l10n.pickupRecipientNotRecorded,
                  ),
                if (record.processedBy != null)
                  _DetailRow(
                    label: context.l10n.processedBy,
                    value: record.processedBy!.name,
                  ),
                if (record.notes != null)
                  _DetailRow(label: context.l10n.notes, value: record.notes!),
                if (record.collectionNotes != null)
                  _DetailRow(
                    label: context.l10n.collectionNotes,
                    value: record.collectionNotes!,
                  ),
              ],
            ),
            if (_error != null) ...[
              const SizedBox(height: SecuritySpacing.md),
              _PackageErrorCard(
                message: _error!,
                onRetry: () => _openPackage(record.packageId),
              ),
            ],
            if (canSubmitCollectionRecipient) ...[
              const SizedBox(height: SecuritySpacing.md),
              if (canRecordMissingRecipient) ...[
                _PackageNotice(
                  message: context.l10n.pickupRecipientCorrectionHint,
                ),
                const SizedBox(height: SecuritySpacing.sm),
              ],
              Text(
                context.l10n.collectionRecipient,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: SecuritySpacing.sm),
              SegmentedButton<SecurityPackageCollectionRecipientType>(
                key: const Key('packageCollectionRecipientTypeControl'),
                segments: <ButtonSegment<SecurityPackageCollectionRecipientType>>[
                  ButtonSegment<SecurityPackageCollectionRecipientType>(
                    value: SecurityPackageCollectionRecipientType.resident,
                    label: Text(context.l10n.collectionRecipientResident),
                    icon: const Icon(Icons.person_outline_rounded),
                  ),
                  ButtonSegment<SecurityPackageCollectionRecipientType>(
                    value: SecurityPackageCollectionRecipientType.others,
                    label: Text(context.l10n.collectionRecipientOthers),
                    icon: const Icon(Icons.group_outlined),
                  ),
                ],
                selected: <SecurityPackageCollectionRecipientType>{
                  _collectionRecipientType,
                },
                showSelectedIcon: false,
                onSelectionChanged: _submitting
                    ? null
                    : (selection) {
                        final type = selection.single;
                        setState(() {
                          _collectionRecipientType = type;
                          _error = null;
                          if (type ==
                              SecurityPackageCollectionRecipientType.resident) {
                            _collectionRecipientNameController.clear();
                          }
                        });
                      },
              ),
              const SizedBox(height: SecuritySpacing.sm),
              if (_collectionRecipientType ==
                  SecurityPackageCollectionRecipientType.resident)
                _PackageNotice(
                  message:
                      '${context.l10n.collectionRecipientResident}: ${record.resident.name}',
                )
              else
                TextField(
                  key: const Key('packageCollectionRecipientNameField'),
                  controller: _collectionRecipientNameController,
                  textInputAction: TextInputAction.next,
                  decoration: InputDecoration(
                    labelText: context.l10n.collectionRecipientName,
                    hintText: context.l10n.collectionRecipientNameHint,
                  ),
                ),
              const SizedBox(height: SecuritySpacing.sm),
              TextField(
                key: const Key('packageCollectionNotesField'),
                controller: _collectionNotesController,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(
                  labelText: context.l10n.collectionNotesOptional,
                  hintText: context.l10n.collectionNotesHint,
                ),
              ),
            ],
          ],
        ),
      ),
      bottomNavigationBar: canSubmitCollectionRecipient
          ? SafeArea(
              minimum: const EdgeInsets.fromLTRB(
                SecuritySpacing.md,
                SecuritySpacing.xs,
                SecuritySpacing.md,
                SecuritySpacing.md,
              ),
              child: FilledButton.icon(
                key: const Key('packageCollectButton'),
                onPressed: _submitting ? null : () => _collectPackage(record),
                icon: _submitting
                    ? const SizedBox.square(
                        dimension: 16,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline_rounded),
                label: Text(
                  canRecordMissingRecipient
                      ? context.l10n.recordPickupRecipient
                      : context.l10n.markPackageCollected,
                ),
              ),
            )
          : null,
    );
  }

  Future<void> _loadPackages() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final records = await widget.repository.packages(
        status: _statusFilter,
        search: _packageSearchController.text,
      );
      if (!mounted) return;
      setState(() {
        _packages = records;
        _loading = false;
      });
    } on SecurityPackageRepositoryException catch (error) {
      if (await _handleSessionExpired(error)) return;
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _failureMessage(context, error);
      });
    } on Object {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = context.l10n.packageFailureUnknown;
      });
    }
  }

  Future<void> _setStatusFilter(SecurityPackageStatus? status) async {
    if (_statusFilter == status) return;
    setState(() => _statusFilter = status);
    await _loadPackages();
  }

  void _openReceive() {
    _resetReceiveForm();
    setState(() {
      _view = _PackageView.receive;
      _error = null;
    });
  }

  Future<void> _searchResidents() async {
    setState(() {
      _residentSearching = true;
      _error = null;
    });
    try {
      final residents = await widget.repository.searchResidents(
        query: _residentSearchController.text,
      );
      if (!mounted) return;
      setState(() {
        _residentResults = residents;
        _residentSearching = false;
      });
    } on SecurityPackageRepositoryException catch (error) {
      if (await _handleSessionExpired(error)) return;
      if (!mounted) return;
      setState(() {
        _residentSearching = false;
        _error = _failureMessage(context, error);
      });
    }
  }

  Future<void> _receivePackage() async {
    final resident = _selectedResident;
    final courier = _courierController.text.trim();
    if (resident == null) {
      setState(() => _error = context.l10n.packageResidentRequired);
      return;
    }
    if (courier.isEmpty) {
      setState(() => _error = context.l10n.packageCourierRequired);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final record = await widget.repository.receivePackage(
        SecurityPackageReceiveInput(
          residentId: resident.resident.id,
          courierName: courier,
          trackingNumber: _trackingController.text,
          senderName: _senderController.text,
          packageDescription: _descriptionController.text,
          storageLocation: _storageController.text,
          notes: _notesController.text,
        ),
      );
      if (!mounted) return;
      setState(() {
        _selectedPackage = record;
        _resetCollectionForm();
        _view = _PackageView.detail;
        _submitting = false;
      });
      await _refreshPackageListBestEffort();
    } on SecurityPackageRepositoryException catch (error) {
      if (await _handleSessionExpired(error)) return;
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = _failureMessage(context, error);
      });
    }
  }

  Future<void> _openPackage(int packageId) async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final record = await widget.repository.findById(packageId);
      if (!mounted) return;
      if (record == null) {
        setState(() {
          _loading = false;
          _error = context.l10n.packageFailureNotFound;
        });
        return;
      }
      setState(() {
        _selectedPackage = record;
        _resetCollectionForm();
        _collectionNotesController.text = record.collectionNotes ?? '';
        _view = _PackageView.detail;
        _loading = false;
      });
    } on SecurityPackageRepositoryException catch (error) {
      if (await _handleSessionExpired(error)) return;
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = _failureMessage(context, error);
      });
    }
  }

  Future<void> _collectPackage(SecurityPackageRecord record) async {
    final recipientName = _collectionRecipientNameController.text.trim();
    if (_collectionRecipientType ==
            SecurityPackageCollectionRecipientType.others &&
        recipientName.isEmpty) {
      setState(() => _error = context.l10n.collectionRecipientNameRequired);
      return;
    }

    setState(() {
      _submitting = true;
      _error = null;
    });
    try {
      final updated = await widget.repository.collectPackage(
        record.packageId,
        recipientType: _collectionRecipientType,
        collectionRecipientName:
            _collectionRecipientType ==
                    SecurityPackageCollectionRecipientType.others
                ? recipientName
                : null,
        collectionNotes: _collectionNotesController.text,
      );
      if (!mounted) return;
      setState(() {
        _selectedPackage = updated;
        _submitting = false;
      });
      await _refreshPackageListBestEffort();
    } on SecurityPackageRepositoryException catch (error) {
      if (await _handleSessionExpired(error)) return;
      if (!mounted) return;
      setState(() {
        _submitting = false;
        _error = _failureMessage(context, error);
      });
    }
  }

  Future<void> _refreshPackageListBestEffort() async {
    try {
      final records = await widget.repository.packages(
        status: _statusFilter,
        search: _packageSearchController.text,
      );
      if (!mounted) return;
      setState(() => _packages = records);
    } on Object {
      // The mutation already returned canonical backend state. List refresh is
      // best effort and must not hide a successful receive/collect operation.
    }
  }

  void _backToDashboard() {
    setState(() {
      _view = _PackageView.dashboard;
      _selectedPackage = null;
      _resetCollectionForm();
      _error = null;
      _submitting = false;
    });
    _loadPackages();
  }

  void _resetReceiveForm() {
    _residentSearchController.clear();
    _courierController.clear();
    _trackingController.clear();
    _senderController.clear();
    _descriptionController.clear();
    _storageController.clear();
    _notesController.clear();
    _residentResults = const <SecurityPackageResidentLookup>[];
    _selectedResident = null;
  }

  void _resetCollectionForm() {
    _collectionRecipientType =
        SecurityPackageCollectionRecipientType.resident;
    _collectionRecipientNameController.clear();
    _collectionNotesController.clear();
  }

  Future<bool> _handleSessionExpired(
    SecurityPackageRepositoryException error,
  ) async {
    if (error.code != SecurityPackageRepositoryFailureCode.unauthorized) {
      return false;
    }
    final handler = widget.onSessionExpired;
    if (handler != null) await handler();
    return true;
  }
}

class _PackageHeader extends StatelessWidget {
  const _PackageHeader({
    required this.title,
    required this.subtitle,
    required this.onBack,
  });

  final String title;
  final String subtitle;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        IconButton(
          tooltip: context.l10n.back,
          onPressed: onBack,
          icon: const Icon(Icons.arrow_back_rounded),
        ),
        const SizedBox(width: SecuritySpacing.xs),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 2),
              Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            ],
          ),
        ),
      ],
    );
  }
}

class _PackageNotice extends StatelessWidget {
  const _PackageNotice({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SecuritySpacing.sm),
      decoration: BoxDecoration(
        color: SecurityColors.infoSoft,
        borderRadius: BorderRadius.circular(SecurityRadius.md),
        border: Border.all(color: SecurityColors.info.withValues(alpha: 0.22)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.inventory_2_outlined,
            color: SecurityColors.info,
            size: 20,
          ),
          const SizedBox(width: SecuritySpacing.xs),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodySmall),
          ),
        ],
      ),
    );
  }
}

class _StatusFilterChip extends StatelessWidget {
  const _StatusFilterChip({
    required this.label,
    required this.selected,
    required this.onSelected,
  });

  final String label;
  final bool selected;
  final VoidCallback onSelected;

  @override
  Widget build(BuildContext context) {
    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) => onSelected(),
    );
  }
}

class _PackageRecordCard extends StatelessWidget {
  const _PackageRecordCard({required this.record, required this.onTap});

  final SecurityPackageRecord record;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SecurityRadius.lg),
        child: Ink(
          padding: const EdgeInsets.all(SecuritySpacing.md),
          decoration: BoxDecoration(
            color: SecurityColors.surface,
            borderRadius: BorderRadius.circular(SecurityRadius.lg),
            border: Border.all(color: SecurityColors.border),
            boxShadow: SecurityShadows.soft,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      record.packageNo,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                  ),
                  _PackageStatusPill(status: record.status),
                ],
              ),
              const SizedBox(height: SecuritySpacing.xs),
              Text(
                record.resident.name,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 2),
              Text(
                '${_unitLabel(record.unit)} • ${record.courierName}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              if (record.trackingNumber != null) ...[
                const SizedBox(height: 2),
                Text(
                  record.trackingNumber!,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: SecurityColors.textMuted,
                      ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _PackageStatusPill extends StatelessWidget {
  const _PackageStatusPill({required this.status});

  final SecurityPackageStatus status;

  @override
  Widget build(BuildContext context) {
    final (foreground, background) = switch (status) {
      SecurityPackageStatus.readyForPickup =>
        (SecurityColors.info, SecurityColors.infoSoft),
      SecurityPackageStatus.collected =>
        (SecurityColors.success, SecurityColors.successSoft),
      SecurityPackageStatus.expired =>
        (SecurityColors.warning, SecurityColors.warningSoft),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        _statusLabel(context, status),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: foreground,
              fontSize: 9,
              fontWeight: FontWeight.w800,
            ),
      ),
    );
  }
}

class _ResidentLookupCard extends StatelessWidget {
  const _ResidentLookupCard({
    required this.lookup,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final SecurityPackageResidentLookup lookup;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(SecurityRadius.md),
        child: Ink(
          padding: const EdgeInsets.all(SecuritySpacing.sm),
          decoration: BoxDecoration(
            color: selected ? SecurityColors.primarySoft : SecurityColors.surface,
            borderRadius: BorderRadius.circular(SecurityRadius.md),
            border: Border.all(
              color: selected ? SecurityColors.primary : SecurityColors.border,
            ),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 18,
                backgroundColor: SecurityColors.primarySoft,
                child: Icon(Icons.person_outline_rounded, size: 20),
              ),
              const SizedBox(width: SecuritySpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      lookup.resident.name,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    Text(
                      _unitLabel(lookup.unit),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              if (selected)
                const Icon(Icons.check_circle_rounded, color: SecurityColors.primary),
            ],
          ),
        ),
      ),
    );
  }
}

class _SelectedResidentCard extends StatelessWidget {
  const _SelectedResidentCard({required this.lookup});

  final SecurityPackageResidentLookup lookup;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SecuritySpacing.sm),
      decoration: BoxDecoration(
        color: SecurityColors.successSoft,
        borderRadius: BorderRadius.circular(SecurityRadius.md),
        border: Border.all(color: SecurityColors.success.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline_rounded, color: SecurityColors.success),
          const SizedBox(width: SecuritySpacing.xs),
          Expanded(
            child: Text(
              '${context.l10n.selectedResident}: ${lookup.resident.name} • ${_unitLabel(lookup.unit)}',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageDetailCard extends StatelessWidget {
  const _PackageDetailCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SecuritySpacing.md),
      decoration: BoxDecoration(
        color: SecurityColors.surface,
        borderRadius: BorderRadius.circular(SecurityRadius.lg),
        border: Border.all(color: SecurityColors.border),
        boxShadow: SecurityShadows.soft,
      ),
      child: Column(children: children),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 116,
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: SecurityColors.textMuted,
                  ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: SecurityColors.textPrimary,
                    fontWeight: FontWeight.w700,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageEmptyCard extends StatelessWidget {
  const _PackageEmptyCard({
    required this.icon,
    required this.title,
    required this.message,
  });

  final IconData icon;
  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SecuritySpacing.lg),
      decoration: BoxDecoration(
        color: SecurityColors.surface,
        borderRadius: BorderRadius.circular(SecurityRadius.lg),
        border: Border.all(color: SecurityColors.border),
      ),
      child: Column(
        children: [
          Icon(icon, color: SecurityColors.textMuted),
          const SizedBox(height: SecuritySpacing.xs),
          Text(title, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ],
      ),
    );
  }
}

class _PackageErrorCard extends StatelessWidget {
  const _PackageErrorCard({required this.message, this.onRetry});

  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(SecuritySpacing.sm),
      decoration: BoxDecoration(
        color: SecurityColors.dangerSoft,
        borderRadius: BorderRadius.circular(SecurityRadius.md),
        border: Border.all(color: SecurityColors.danger.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded, color: SecurityColors.danger),
          const SizedBox(width: SecuritySpacing.xs),
          Expanded(child: Text(message)),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: Text(context.l10n.retry)),
        ],
      ),
    );
  }
}

String _statusLabel(BuildContext context, SecurityPackageStatus status) {
  return switch (status) {
    SecurityPackageStatus.readyForPickup =>
      context.l10n.packageStatusReadyForPickup,
    SecurityPackageStatus.collected => context.l10n.packageStatusCollected,
    SecurityPackageStatus.expired => context.l10n.packageStatusExpired,
  };
}

String _unitLabel(SecurityPackageUnitRef unit) {
  final tower = unit.tower?.trim();
  return tower == null || tower.isEmpty ? unit.code : '$tower • ${unit.code}';
}

String _formatTimestamp(BuildContext context, DateTime value) {
  final local = value.toLocal();
  final material = MaterialLocalizations.of(context);
  final date = material.formatCompactDate(local);
  final time = material.formatTimeOfDay(
    TimeOfDay.fromDateTime(local),
    alwaysUse24HourFormat: MediaQuery.alwaysUse24HourFormatOf(context),
  );
  return '$date • $time';
}

String _recipientTypeLabel(
  BuildContext context,
  SecurityPackageCollectionRecipientType type,
) =>
    switch (type) {
      SecurityPackageCollectionRecipientType.resident =>
        context.l10n.collectionRecipientResident,
      SecurityPackageCollectionRecipientType.others =>
        context.l10n.collectionRecipientOthers,
    };

String? _firstPackageValidationMessage(
  SecurityPackageRepositoryException error,
) {
  for (final value in error.fieldErrors.values) {
    if (value is String && value.trim().isNotEmpty) {
      return value.trim();
    }
    if (value is List) {
      for (final item in value) {
        if (item is String && item.trim().isNotEmpty) {
          return item.trim();
        }
      }
    }
  }
  final message = error.message?.trim();
  if (message != null &&
      message.isNotEmpty &&
      message != 'The given data was invalid.' &&
      message != 'Data yang diberikan tidak valid.') {
    return message;
  }
  return null;
}

String _failureMessage(
  BuildContext context,
  SecurityPackageRepositoryException error,
) {
  return switch (error.code) {
    SecurityPackageRepositoryFailureCode.centerUnavailable =>
      context.l10n.packageFailureCenterUnavailable,
    SecurityPackageRepositoryFailureCode.residentNotFound =>
      context.l10n.packageFailureResidentNotFound,
    SecurityPackageRepositoryFailureCode.packageNotFound =>
      context.l10n.packageFailureNotFound,
    SecurityPackageRepositoryFailureCode.validation =>
      _firstPackageValidationMessage(error) ??
          context.l10n.packageFailureValidation,
    SecurityPackageRepositoryFailureCode.collectionResidentUnavailable =>
      context.l10n.packageCollectionResidentUnavailable,
    SecurityPackageRepositoryFailureCode.unauthorized =>
      context.l10n.authUnauthenticated,
    SecurityPackageRepositoryFailureCode.forbidden =>
      context.l10n.packageFailureForbidden,
    SecurityPackageRepositoryFailureCode.network => context.l10n.authNetwork,
    SecurityPackageRepositoryFailureCode.unknown =>
      error.message?.trim().isNotEmpty == true
          ? error.message!
          : context.l10n.packageFailureUnknown,
  };
}
