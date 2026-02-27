import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:storm_sense/core/astro/birth_chart.dart';

class BirthChartSheet extends StatefulWidget {
  const BirthChartSheet({super.key, this.existingData});

  final BirthData? existingData;

  static Future<BirthData?> show(
    BuildContext context, {
    BirthData? existingData,
  }) {
    return showModalBottomSheet<BirthData>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => BirthChartSheet(existingData: existingData),
    );
  }

  @override
  State<BirthChartSheet> createState() => _BirthChartSheetState();
}

class _BirthChartSheetState extends State<BirthChartSheet> {
  late DateTime _selectedDate;
  TimeOfDay? _selectedTime;
  bool _knowTime = true;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.existingData?.birthDate ?? DateTime(1990, 1, 1);
    if (widget.existingData?.birthTime != null) {
      final parts = widget.existingData!.birthTime!.split(':');
      if (parts.length == 2) {
        _selectedTime = TimeOfDay(
          hour: int.tryParse(parts[0]) ?? 0,
          minute: int.tryParse(parts[1]) ?? 0,
        );
      }
    }
    _knowTime = _selectedTime != null;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    const accent = Color(0xFF818CF8);

    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        24,
        24,
        MediaQuery.of(context).viewInsets.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Birth Chart Setup',
            style: theme.textTheme.titleLarge
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 4),
          Text(
            'Add your birth info for personalized readings.',
            style: theme.textTheme.bodySmall
                ?.copyWith(color: cs.onSurfaceVariant),
          ),
          const SizedBox(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.calendar_today, color: accent),
            title: const Text('Birth Date'),
            subtitle: Text(
              '${_selectedDate.month}/${_selectedDate.day}/${_selectedDate.year}',
            ),
            onTap: () async {
              final picked = await showDatePicker(
                context: context,
                initialDate: _selectedDate,
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
              );
              if (picked != null) setState(() => _selectedDate = picked);
            },
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('I know my birth time'),
            value: _knowTime,
            onChanged: (v) => setState(() {
              _knowTime = v;
              if (!v) _selectedTime = null;
            }),
          ),
          if (_knowTime)
            ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const Icon(Icons.access_time, color: accent),
              title: const Text('Birth Time'),
              subtitle: Text(
                _selectedTime != null
                    ? _selectedTime!.format(context)
                    : 'Tap to select',
              ),
              onTap: () async {
                final picked = await showTimePicker(
                  context: context,
                  initialTime:
                      _selectedTime ?? const TimeOfDay(hour: 12, minute: 0),
                );
                if (picked != null) setState(() => _selectedTime = picked);
              },
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _save,
              style: FilledButton.styleFrom(backgroundColor: accent),
              child: const Text('Save'),
            ),
          ),
          if (widget.existingData != null)
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _clear,
                style: TextButton.styleFrom(foregroundColor: cs.error),
                child: const Text('Clear Birth Data'),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _save() async {
    final timeStr = _selectedTime != null
        ? '${_selectedTime!.hour.toString().padLeft(2, '0')}:'
            '${_selectedTime!.minute.toString().padLeft(2, '0')}'
        : null;

    final data = BirthData(birthDate: _selectedDate, birthTime: timeStr);
    final prefs = await SharedPreferences.getInstance();
    await BirthDataStore.save(prefs, data);

    if (mounted) Navigator.of(context).pop(data);
  }

  Future<void> _clear() async {
    final prefs = await SharedPreferences.getInstance();
    await BirthDataStore.clear(prefs);
    if (mounted) Navigator.of(context).pop();
  }
}
