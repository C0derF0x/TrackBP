
import 'package:flutter/material.dart';

import '../../data/repositories/measurement_repository.dart';
import '../../models/measurement.dart';

class AddMeasurementScreen extends StatefulWidget {
  final Measurement? existingMeasurement;

  const AddMeasurementScreen({
    super.key,
    this.existingMeasurement,
  });

  @override
  State<AddMeasurementScreen> createState() =>
      _AddMeasurementScreenState();
}

class _AddMeasurementScreenState extends State<AddMeasurementScreen> {
  final _formKey = GlobalKey<FormState>();

  final _systolicController = TextEditingController();
  final _diastolicController = TextEditingController();
  final _pulseController = TextEditingController();

  final MeasurementRepository _repository = MeasurementRepository();

  static const String _userId = 'default';

  MeasurementArm _selectedArm = MeasurementArm.left;
  DateTime _measuredAt = DateTime.now();

  bool _isSaving = false;

  bool get _isEditing => widget.existingMeasurement != null;

  @override
  void initState() {
    super.initState();

    final existing = widget.existingMeasurement;

    if (existing != null) {
      _systolicController.text = existing.systolic.toString();
      _diastolicController.text = existing.diastolic.toString();
      _pulseController.text = existing.pulse?.toString() ?? '';

      _selectedArm = existing.arm;
      _measuredAt = existing.measuredAt;
    }
  }

  @override
  void dispose() {
    _systolicController.dispose();
    _diastolicController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  String? _validateNumber(
    String? value, {
    required int min,
    required int max,
    bool optional = false,
  }) {
    if (optional && (value == null || value.trim().isEmpty)) {
      return null;
    }

    if (value == null || value.trim().isEmpty) {
      return 'This field is required';
    }

    final number = int.tryParse(value);

    if (number == null) {
      return 'Enter a valid number';
    }

    if (number < min || number > max) {
      return 'Enter a value between $min and $max';
    }

    return null;
  }

  Future<void> _selectDateTime() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _measuredAt,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );

    if (date == null || !mounted) return;

    final time = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_measuredAt),
    );

    if (time == null || !mounted) return;

    final selectedDateTime = DateTime(
      date.year,
      date.month,
      date.day,
      time.hour,
      time.minute,
    );

    if (selectedDateTime.isAfter(DateTime.now())) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Date and time cannot be in the future.'),
        ),
      );
      return;
    }

    setState(() {
      _measuredAt = selectedDateTime;
    });
  }

  Future<void> _saveMeasurement() async {
    if (_isSaving) return;

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final systolic = int.parse(_systolicController.text);
    final diastolic = int.parse(_diastolicController.text);

    if (systolic <= diastolic) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Systolic pressure must be greater than diastolic pressure.',
          ),
        ),
      );
      return;
    }

    final existing = widget.existingMeasurement;

    final measurement = Measurement(
      id: existing?.id ??
          DateTime.now().microsecondsSinceEpoch.toString(),
      userId: existing?.userId ?? _userId,
      systolic: systolic,
      diastolic: diastolic,
      pulse: _pulseController.text.trim().isEmpty
          ? null
          : int.parse(_pulseController.text),
      arm: _selectedArm,
      measuredAt: _measuredAt,
    );

    setState(() {
      _isSaving = true;
    });

    try {
      if (_isEditing) {
        await _repository.updateMeasurement(measurement);
      } else {
        await _repository.saveMeasurement(measurement);
      }

      if (!mounted) return;

      Navigator.pop(context, measurement);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isSaving = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Could not save reading: $e'),
        ),
      );
    }
  }

  Widget _buildInput({
    required String label,
    required TextEditingController controller,
    required String suffix,
    required int min,
    required int max,
    bool optional = false,
  }) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.titleMedium,
        ),
        const SizedBox(height: 9),
        TextFormField(
          controller: controller,
          keyboardType: TextInputType.number,
          style: theme.textTheme.bodyLarge,
          decoration: InputDecoration(
            hintText: 'Enter value',
            suffixText: suffix,
            filled: true,
            fillColor: colors.surface,
            hintStyle: theme.textTheme.bodyMedium,
            suffixStyle: theme.textTheme.bodyMedium,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 17,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: theme.dividerColor,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: theme.dividerColor,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: colors.primary,
                width: 1.5,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: colors.error,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(
                color: colors.error,
                width: 1.5,
              ),
            ),
          ),
          validator: (value) => _validateNumber(
            value,
            min: min,
            max: max,
            optional: optional,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _isEditing ? 'Edit Measurement' : 'Add Measurement',
        ),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _isEditing ? 'Update your reading' : 'Enter your reading',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontSize: 23,
                  ),
                ),

                const SizedBox(height: 7),

                Text(
                  _isEditing
                      ? 'Make the necessary changes below.'
                      : 'Record your blood pressure measurements below.',
                  style: theme.textTheme.bodyMedium,
                ),

                const SizedBox(height: 28),

                _buildInput(
                  label: 'Systolic pressure',
                  controller: _systolicController,
                  suffix: 'mmHg',
                  min: 1,
                  max: 300,
                ),

                const SizedBox(height: 20),

                _buildInput(
                  label: 'Diastolic pressure',
                  controller: _diastolicController,
                  suffix: 'mmHg',
                  min: 1,
                  max: 200,
                ),

                const SizedBox(height: 20),

                _buildInput(
                  label: 'Pulse rate',
                  controller: _pulseController,
                  suffix: 'BPM',
                  min: 1,
                  max: 250,
                  optional: true,
                ),

                const SizedBox(height: 30),

                Text(
                  'Arm used',
                  style: theme.textTheme.titleMedium,
                ),

                const SizedBox(height: 12),

                SegmentedButton<MeasurementArm>(
                  segments: const [
                    ButtonSegment(
                      value: MeasurementArm.left,
                      label: Text('L — Left'),
                      icon: Icon(Icons.back_hand_outlined),
                    ),
                    ButtonSegment(
                      value: MeasurementArm.right,
                      label: Text('R — Right'),
                      icon: Icon(Icons.back_hand_outlined),
                    ),
                  ],
                  selected: {_selectedArm},
                  onSelectionChanged: (selection) {
                    setState(() {
                      _selectedArm = selection.first;
                    });
                  },
                  style: SegmentedButton.styleFrom(
                    foregroundColor: colors.onSurface,
                    selectedForegroundColor: colors.onPrimary,
                    selectedBackgroundColor: colors.primary,
                  ),
                ),

                const SizedBox(height: 30),

                Text(
                  'Date and time',
                  style: theme.textTheme.titleMedium,
                ),

                const SizedBox(height: 12),

                OutlinedButton.icon(
                  onPressed: _isSaving ? null : _selectDateTime,
                  icon: const Icon(Icons.calendar_today_outlined),
                  label: Text(
                    '${_measuredAt.day}/${_measuredAt.month}/${_measuredAt.year}'
                    '  ·  '
                    '${TimeOfDay.fromDateTime(_measuredAt).format(context)}',
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colors.primary,
                    minimumSize: const Size(double.infinity, 52),
                    side: BorderSide(
                      color: theme.dividerColor,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),

                const SizedBox(height: 35),

                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _saveMeasurement,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: colors.primary,
                      foregroundColor: colors.onPrimary,
                      disabledBackgroundColor: colors.primary.withValues(
                        alpha: 0.6,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                    child: _isSaving
                        ? SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(
                              color: colors.onPrimary,
                              strokeWidth: 2.5,
                            ),
                          )
                        : Text(
                            _isEditing ? 'Save Changes' : 'Save Reading',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
