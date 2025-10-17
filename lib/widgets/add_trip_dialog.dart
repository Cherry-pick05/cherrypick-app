import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/trip_provider.dart';
import '../models/trip.dart' as model;

class AddTripDialog extends StatefulWidget {
  const AddTripDialog({super.key});

  @override
  State<AddTripDialog> createState() => _AddTripDialogState();
}

class _AddTripDialogState extends State<AddTripDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _destinationController = TextEditingController();
  final _startDateController = TextEditingController();
  String _selectedDuration = '';

  final List<String> _durations = [
    '1박 2일',
    '2박 3일',
    '3박 4일',
    '4박 5일',
    '5박 6일',
    '6박 7일',
    '7박 이상',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    _destinationController.dispose();
    _startDateController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                '새 여행 추가',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '여행 이름',
                  hintText: '예: 오사카 여행',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '여행 이름을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _destinationController,
                decoration: const InputDecoration(
                  labelText: '목적지',
                  hintText: '예: 일본 오사카',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '목적지를 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _startDateController,
                decoration: const InputDecoration(
                  labelText: '출발 날짜',
                  suffixIcon: Icon(Icons.calendar_today),
                ),
                readOnly: true,
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: DateTime.now(),
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    _startDateController.text = 
                        '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
                  }
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '출발 날짜를 선택해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedDuration.isEmpty ? null : _selectedDuration,
                decoration: const InputDecoration(
                  labelText: '여행 기간',
                ),
                items: _durations.map((duration) {
                  return DropdownMenuItem(
                    value: duration,
                    child: Text(duration),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedDuration = value ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '여행 기간을 선택해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _addTrip,
                  child: const Text('추가'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addTrip() {
    if (_formKey.currentState!.validate()) {
      final trip = model.Trip(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        destination: _destinationController.text,
        startDate: _startDateController.text,
        duration: _selectedDuration,
      );

      Provider.of<TripProvider>(context, listen: false).addTrip(trip);
      Navigator.of(context).pop();
    }
  }
}
