import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/packing_provider.dart';
import '../models/packing_item.dart' as model;

class AddItemDialog extends StatefulWidget {
  final String bagId;

  const AddItemDialog({super.key, required this.bagId});

  @override
  State<AddItemDialog> createState() => _AddItemDialogState();
}

class _AddItemDialogState extends State<AddItemDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();

  String _selectedCategory = '';
  String _selectedLocation = '메인칸'; // 기본값

  final List<String> _categories = [
    '의류','신발','세면용품','화장품','전자기기','서류','의료용품','액세서리','음식','기타','도서','운동용품','선물',
  ];

  // 위치 목록 추가
  final List<String> _locations = [
    '메인칸','앞주머니','노트북칸','지퍼백','세컨파우치','슈즈칸','세면파우치','기타',
  ];

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 400),
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text('새 아이템 추가', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 24),

              // 아이템 이름
              TextFormField(
                controller: _nameController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: '아이템 이름',
                  hintText: '예: 여권, 충전기, 옷가지',
                ),
                validator: (v) => (v == null || v.isEmpty) ? '아이템 이름을 입력해주세요' : null,
              ),
              const SizedBox(height: 16),

              //카테고리
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory.isEmpty ? null : _selectedCategory,
                decoration: const InputDecoration(labelText: '카테고리'),
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (v) => setState(() => _selectedCategory = v ?? ''),
                validator: (v) => (v == null || v.isEmpty) ? '카테고리를 선택해주세요' : null,
              ),
              const SizedBox(height: 16),

              //가방 위치
              DropdownButtonFormField<String>(
                initialValue: _selectedLocation,
                decoration: const InputDecoration(labelText: '가방 위치'),
                items: _locations.map((l) => DropdownMenuItem(value: l, child: Text(l))).toList(),
                onChanged: (v) => setState(() => _selectedLocation = v ?? '메인칸'),
                validator: (v) => (v == null || v.isEmpty) ? '가방 위치를 선택해주세요' : null,
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _addItem,
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

  void _addItem() {
    if (_formKey.currentState!.validate()) {
      final item = model.PackingItem(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        name: _nameController.text.trim(),
        category: _selectedCategory,
        packed: false,
        bagId: widget.bagId,
        location: _selectedLocation,
      );

      Provider.of<PackingProvider>(context, listen: false).addItem(item);
      Navigator.of(context).pop();
    }
  }
}
