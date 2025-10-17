import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/packing_provider.dart';
import '../models/bag.dart' as model;

class AddBagDialog extends StatefulWidget {
  const AddBagDialog({super.key});

  @override
  State<AddBagDialog> createState() => _AddBagDialogState();
}

class _AddBagDialogState extends State<AddBagDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  String _selectedType = '';

  final List<String> _types = [
    'carry-on',
    'checked',
    'personal',
  ];

  final Map<String, String> _typeLabels = {
    'carry-on': '기내용',
    'checked': '위탁용',
    'personal': '개인 소지품',
  };

  @override
  void dispose() {
    _nameController.dispose();
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
                '새 가방 추가',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: '가방 이름',
                  hintText: '예: 보조 가방, 크로스백',
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '가방 이름을 입력해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                initialValue: _selectedType.isEmpty ? null : _selectedType,
                decoration: const InputDecoration(
                  labelText: '가방 종류',
                ),
                items: _types.map((type) {
                  return DropdownMenuItem(
                    value: type,
                    child: Text(_typeLabels[type]!),
                  );
                }).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedType = value ?? '';
                  });
                },
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return '가방 종류를 선택해주세요';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _addBag,
                      child: const Text('추가하기'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      child: const Text('취소'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _addBag() {
    if (_formKey.currentState!.validate()) {
      final colors = ['blue', 'green', 'purple', 'orange', 'pink', 'teal'];
      final randomColor = colors[DateTime.now().millisecondsSinceEpoch % colors.length];

      final bag = model.Bag(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text,
        type: _selectedType,
        color: randomColor,
        items: [],
      );

      Provider.of<PackingProvider>(context, listen: false).addBag(bag);
      Navigator.of(context).pop();
    }
  }
}
