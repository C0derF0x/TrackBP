
import 'package:flutter/material.dart';

import '../../data/repositories/measurement_repository.dart';
import '../../models/measurement.dart';
import 'add_measurement_screen.dart';

enum _DateFilter {
  all,
  today,
  thisWeek,
  thisMonth,
  custom,
}

class MeasurementHistoryScreen extends StatefulWidget {
  const MeasurementHistoryScreen({super.key});

  @override
  State<MeasurementHistoryScreen> createState() =>
      _MeasurementHistoryScreenState();
}

class _MeasurementHistoryScreenState
    extends State<MeasurementHistoryScreen> {
  final MeasurementRepository _repository = MeasurementRepository();
  final TextEditingController _searchController =
      TextEditingController();

  static const String _userId = 'default';

  List<Measurement> _measurements = [];

  bool _isLoading = true;
  bool _isClearing = false;

  String? _errorMessage;

  _DateFilter _selectedDateFilter = _DateFilter.all;
  DateTimeRange? _customDateRange;
  MeasurementArm? _selectedArm;

  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadMeasurements();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadMeasurements() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final measurements =
          await _repository.getMeasurements(_userId);

      if (!mounted) return;

      setState(() {
        _measurements = measurements;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage = 'Could not load measurements: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _editMeasurement(Measurement measurement) async {
    final result = await Navigator.push<Measurement>(
      context,
      MaterialPageRoute<Measurement>(
        builder: (context) => AddMeasurementScreen(
          existingMeasurement: measurement,
        ),
      ),
    );

    if (!mounted) return;

    if (result != null) {
      await _loadMeasurements();
    }
  }

  Future<void> _deleteMeasurement(Measurement measurement) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Delete reading?'),
          content: Text(
            'Are you sure you want to delete '
            '${measurement.systolic}/${measurement.diastolic} '
            'recorded on ${_formatDate(measurement.measuredAt)}? '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await _repository.deleteMeasurement(measurement.id);

      if (!mounted) return;

      await _loadMeasurements();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Reading deleted successfully.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not delete reading: $e'),
        ),
      );
    }
  }

  Future<void> _handleMeasurementAction(
    String action,
    Measurement measurement,
  ) async {
    switch (action) {
      case 'edit':
        await _editMeasurement(measurement);
        break;

      case 'delete':
        await _deleteMeasurement(measurement);
        break;
    }
  }

  Future<void> _confirmClearAll() async {
    if (_measurements.isEmpty || _isClearing) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Clear all readings?'),
          content: Text(
            'This will permanently delete all '
            '${_measurements.length} saved readings. '
            'This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              style: TextButton.styleFrom(
                foregroundColor: Colors.red,
              ),
              child: const Text('Clear all'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    setState(() {
      _isClearing = true;
    });

    try {
      await _repository.deleteAllMeasurements(_userId);

      if (!mounted) return;

      setState(() {
        _measurements = [];
        _isClearing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('All readings have been cleared.'),
        ),
      );
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isClearing = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not clear readings: $e'),
        ),
      );
    }
  }

  String _formatDate(DateTime date) {
    const months = [
      'Jan', 'Feb', 'Mar', 'Apr',
      'May', 'Jun', 'Jul', 'Aug',
      'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${date.day} ${months[date.month - 1]} ${date.year}';
  }

  String _formatTime(DateTime date) {
    return TimeOfDay.fromDateTime(date).format(context);
  }

  String _getDateHeading(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));

    final readingDate = DateTime(
      date.year,
      date.month,
      date.day,
    );

    if (readingDate == today) {
      return 'Today';
    }

    if (readingDate == yesterday) {
      return 'Yesterday';
    }

    return _formatDate(date);
  }

  String _getDateKey(DateTime date) {
    return '${date.year}-${date.month}-${date.day}';
  }

  bool get _hasActiveFilters {
    return _selectedDateFilter != _DateFilter.all ||
        _selectedArm != null ||
        _searchQuery.trim().isNotEmpty;
  }

  bool _matchesSearch(Measurement measurement) {
    final query = _searchQuery.trim().toLowerCase();

    if (query.isEmpty) return true;

    final date = measurement.measuredAt;

    final dateText = [
      _formatDate(date),
      '${date.day}/${date.month}/${date.year}',
      '${date.day.toString().padLeft(2, '0')}/'
          '${date.month.toString().padLeft(2, '0')}/${date.year}',
      '${date.year}-${date.month.toString().padLeft(2, '0')}-'
          '${date.day.toString().padLeft(2, '0')}',
      _formatTime(date),
    ].join(' ');

    final armText = measurement.arm == MeasurementArm.left
        ? 'left left arm'
        : 'right right arm';

    final searchableText = [
      measurement.systolic.toString(),
      measurement.diastolic.toString(),
      '${measurement.systolic}/${measurement.diastolic}',
      measurement.pulse?.toString() ?? '',
      armText,
      dateText,
    ].join(' ').toLowerCase();

    final searchTerms = query.split(RegExp(r'\s+'));

    return searchTerms.every(
      (term) => searchableText.contains(term),
    );
  }

  List<Measurement> get _filteredMeasurements {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    DateTime? startDate;
    DateTime? endDateExclusive;

    switch (_selectedDateFilter) {
      case _DateFilter.all:
        break;

      case _DateFilter.today:
        startDate = today;
        endDateExclusive = today.add(const Duration(days: 1));
        break;

      case _DateFilter.thisWeek:
        final monday = today.subtract(
          Duration(days: today.weekday - 1),
        );

        startDate = monday;
        endDateExclusive = monday.add(
          const Duration(days: 7),
        );
        break;

      case _DateFilter.thisMonth:
        startDate = DateTime(today.year, today.month);
        endDateExclusive = DateTime(
          today.year,
          today.month + 1,
        );
        break;

      case _DateFilter.custom:
        if (_customDateRange != null) {
          startDate = DateTime(
            _customDateRange!.start.year,
            _customDateRange!.start.month,
            _customDateRange!.start.day,
          );

          final end = _customDateRange!.end;

          endDateExclusive = DateTime(
            end.year,
            end.month,
            end.day,
          ).add(const Duration(days: 1));
        }
        break;
    }

    return _measurements.where((measurement) {
      final date = measurement.measuredAt;

      final matchesDate = startDate == null ||
          (!date.isBefore(startDate) &&
              date.isBefore(endDateExclusive!));

      final matchesArm = _selectedArm == null ||
          measurement.arm == _selectedArm;

      final matchesSearch = _matchesSearch(measurement);

      return matchesDate && matchesArm && matchesSearch;
    }).toList();
  }

  Future<void> _selectCustomDateRange() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    final selectedRange = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: today,
      initialDateRange: _customDateRange ??
          DateTimeRange(
            start: today,
            end: today,
          ),
      helpText: 'Select measurement date range',
      saveText: 'Apply',
    );

    if (selectedRange == null || !mounted) return;

    setState(() {
      _customDateRange = selectedRange;
      _selectedDateFilter = _DateFilter.custom;
    });
  }

  void _setDateFilter(_DateFilter filter) {
    if (filter == _DateFilter.custom) {
      _selectCustomDateRange();
      return;
    }

    setState(() {
      _selectedDateFilter = filter;
      _customDateRange = null;
    });
  }

  void _clearFilters() {
    setState(() {
      _selectedDateFilter = _DateFilter.all;
      _customDateRange = null;
      _selectedArm = null;
      _searchQuery = '';
      _searchController.clear();
    });
  }

  String _customRangeLabel() {
    if (_customDateRange == null) {
      return 'Custom';
    }

    final start = _customDateRange!.start;
    final end = _customDateRange!.end;

    return '${start.day}/${start.month} – '
        '${end.day}/${end.month}';
  }

  Widget _buildSearchBar() {
    final colors = Theme.of(context).colorScheme;

    return TextField(
      controller: _searchController,
      onChanged: (value) {
        setState(() {
          _searchQuery = value;
        });
      },
      textInputAction: TextInputAction.search,
      style: TextStyle(color: colors.onSurface),
      decoration: InputDecoration(
        hintText: 'Search date, BP, pulse or arm...',
        hintStyle: TextStyle(
          fontSize: 13,
          color: colors.onSurfaceVariant,
        ),
        prefixIcon: Icon(
          Icons.search,
          color: colors.primary,
        ),
        suffixIcon: _searchQuery.isNotEmpty
            ? IconButton(
                tooltip: 'Clear search',
                onPressed: () {
                  _searchController.clear();
                  setState(() {
                    _searchQuery = '';
                  });
                },
                icon: const Icon(Icons.close),
              )
            : null,
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 15,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(color: Theme.of(context).dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(15),
          borderSide: BorderSide(
            color: colors.primary,
            width: 1.5,
          ),
        ),
      ),
    );
  }

  Widget _buildDateFilters() {
    final colors = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'DATE RANGE',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildDateChip('All time', _DateFilter.all),
              _buildDateChip('Today', _DateFilter.today),
              _buildDateChip('This week', _DateFilter.thisWeek),
              _buildDateChip('This month', _DateFilter.thisMonth),
              _buildDateChip(
                _customRangeLabel(),
                _DateFilter.custom,
              ),
            ],
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'ARM USED',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: colors.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          children: [
            _buildArmChip('Both arms', null),
            _buildArmChip('Left arm', MeasurementArm.left),
            _buildArmChip('Right arm', MeasurementArm.right),
          ],
        ),
        if (_hasActiveFilters) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: _clearFilters,
              icon: const Icon(
                Icons.filter_alt_off_outlined,
                size: 17,
              ),
              label: const Text('Clear all'),
              style: TextButton.styleFrom(
                foregroundColor: colors.primary,
                visualDensity: VisualDensity.compact,
              ),
            ),
          ),
        ],
        const SizedBox(height: 12),
        Divider(color: Theme.of(context).dividerColor),
        const SizedBox(height: 12),
      ],
    );
  }

  Widget _buildDateChip(
    String label,
    _DateFilter filter,
  ) {
    final colors = Theme.of(context).colorScheme;
    final selected = _selectedDateFilter == filter;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => _setDateFilter(filter),
        selectedColor: colors.primary.withValues(alpha: 0.18),
        backgroundColor: colors.surface,
        side: BorderSide(
          color: selected ? colors.primary : Theme.of(context).dividerColor,
        ),
        labelStyle: TextStyle(
          fontSize: 12,
          fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
          color: selected ? colors.primary : colors.onSurfaceVariant,
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildArmChip(
    String label,
    MeasurementArm? arm,
  ) {
    final colors = Theme.of(context).colorScheme;
    final selected = _selectedArm == arm;

    return ChoiceChip(
      label: Text(label),
      selected: selected,
      onSelected: (_) {
        setState(() {
          _selectedArm = arm;
        });
      },
      selectedColor: colors.primary.withValues(alpha: 0.18),
      backgroundColor: colors.surface,
      side: BorderSide(
        color: selected ? colors.primary : Theme.of(context).dividerColor,
      ),
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
        color: selected ? colors.primary : colors.onSurfaceVariant,
      ),
      showCheckmark: false,
    );
  }

  Map<DateTime, List<Measurement>> _groupMeasurementsByDate(
    List<Measurement> measurements,
  ) {
    final grouped = <DateTime, List<Measurement>>{};

    for (final measurement in measurements) {
      final date = DateTime(
        measurement.measuredAt.year,
        measurement.measuredAt.month,
        measurement.measuredAt.day,
      );

      grouped.putIfAbsent(date, () => []);
      grouped[date]!.add(measurement);
    }

    return grouped;
  }

  Widget _buildEmptyState() {
    final colors = Theme.of(context).colorScheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(22),
              decoration: BoxDecoration(
                color: colors.primary.withValues(alpha: 0.13),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.monitor_heart_outlined,
                color: colors.primary,
                size: 42,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'No readings yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: colors.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your saved blood pressure measurements '
              'will appear here.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResultsState() {
    final colors = Theme.of(context).colorScheme;
    final hasSearch = _searchQuery.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: 20,
        vertical: 45,
      ),
      child: Column(
        children: [
          Icon(
            hasSearch ? Icons.search_off : Icons.filter_list_off,
            size: 38,
            color: colors.onSurfaceVariant,
          ),
          const SizedBox(height: 14),
          Text(
            hasSearch
                ? 'No matching readings'
                : 'No readings in this selection',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w600,
              color: colors.onSurface,
            ),
          ),
          const SizedBox(height: 7),
          Text(
            hasSearch
                ? 'Try another date, BP value, pulse or arm.'
                : 'Try changing your date range or arm filter.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _clearFilters,
            child: const Text('Clear search and filters'),
          ),
        ],
      ),
    );
  }

  Widget _buildMeasurementTile(Measurement measurement) {
    final colors = Theme.of(context).colorScheme;

    final arm = measurement.arm == MeasurementArm.left
        ? 'Left arm'
        : 'Right arm';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colors.primary.withValues(alpha: 0.13),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.favorite_outline,
                  color: colors.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _formatTime(measurement.measuredAt),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.onSurface,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      arm,
                      style: TextStyle(
                        fontSize: 12,
                        color: colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                '${measurement.systolic}/${measurement.diastolic}',
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.bold,
                  color: colors.onSurface,
                ),
              ),
              const SizedBox(width: 2),
              PopupMenuButton<String>(
                tooltip: 'Reading options',
                onSelected: (action) {
                  _handleMeasurementAction(action, measurement);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_outlined, size: 19),
                        SizedBox(width: 10),
                        Text('Edit'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(
                          Icons.delete_outline,
                          size: 19,
                          color: Colors.red,
                        ),
                        SizedBox(width: 10),
                        Text(
                          'Delete',
                          style: TextStyle(color: Colors.red),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          if (measurement.pulse != null) ...[
            const SizedBox(height: 12),
            Divider(
              color: Theme.of(context).dividerColor,
              height: 1,
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Icon(
                  Icons.favorite,
                  color: colors.secondary,
                  size: 16,
                ),
                const SizedBox(width: 7),
                Text(
                  'Pulse: ${measurement.pulse} BPM',
                  style: TextStyle(
                    fontSize: 12,
                    color: colors.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildDateGroup(
    DateTime date,
    List<Measurement> measurements,
  ) {
    final colors = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 14),
      clipBehavior: Clip.antiAlias,
      color: colors.surface,
      child: ExpansionTile(
        key: PageStorageKey<String>(_getDateKey(date)),
        initiallyExpanded: true,
        tilePadding: const EdgeInsets.symmetric(
          horizontal: 17,
          vertical: 4,
        ),
        childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 8),
        backgroundColor: colors.surface,
        collapsedBackgroundColor: colors.surface,
        shape: const Border(),
        collapsedShape: const Border(),
        title: Text(
          _getDateHeading(date),
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: colors.onSurface,
          ),
        ),
        subtitle: Text(
          '${measurements.length} '
          '${measurements.length == 1 ? 'reading' : 'readings'}',
          style: TextStyle(
            fontSize: 12,
            color: colors.onSurfaceVariant,
          ),
        ),
        children: measurements
            .map(_buildMeasurementTile)
            .toList(),
      ),
    );
  }

  Widget _buildHistoryContent() {
    final colors = Theme.of(context).colorScheme;
    final filteredMeasurements = _filteredMeasurements;
    final groupedMeasurements =
        _groupMeasurementsByDate(filteredMeasurements);

    final dateGroups = groupedMeasurements.entries.toList();

    return RefreshIndicator(
      onRefresh: _loadMeasurements,
      color: colors.primary,
      child: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          _buildSearchBar(),
          const SizedBox(height: 22),
          _buildDateFilters(),
          Text(
            _hasActiveFilters
                ? '${filteredMeasurements.length} of '
                    '${_measurements.length} readings'
                : '${_measurements.length} '
                    '${_measurements.length == 1 ? 'reading' : 'readings'} recorded',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: colors.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 16),
          if (filteredMeasurements.isEmpty)
            _buildNoResultsState()
          else
            ...dateGroups.map(
              (entry) => _buildDateGroup(
                entry.key,
                entry.value,
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Measurement History'),
        actions: [
          IconButton(
            onPressed: _isLoading ? null : _loadMeasurements,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          if (_measurements.isNotEmpty && !_isLoading)
            PopupMenuButton<String>(
              tooltip: 'More options',
              onSelected: (action) {
                if (action == 'clear') {
                  _confirmClearAll();
                }
              },
              itemBuilder: (context) => [
                PopupMenuItem(
                  value: 'clear',
                  enabled: !_isClearing,
                  child: const Row(
                    children: [
                      Icon(
                        Icons.delete_sweep_outlined,
                        color: Colors.red,
                        size: 20,
                      ),
                      SizedBox(width: 10),
                      Text(
                        'Clear all readings',
                        style: TextStyle(color: Colors.red),
                      ),
                    ],
                  ),
                ),
              ],
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoading
            ? Center(
                child: CircularProgressIndicator(
                  color: colors.primary,
                ),
              )
            : _errorMessage != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            _errorMessage!,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: colors.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: _loadMeasurements,
                            child: const Text('Try again'),
                          ),
                        ],
                      ),
                    ),
                  )
                : _measurements.isEmpty
                    ? _buildEmptyState()
                    : _buildHistoryContent(),
      ),
    );
  }
}
