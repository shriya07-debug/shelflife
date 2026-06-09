import 'package:flutter/material.dart';
import '../../../constants/app_colors.dart';
import '../../../constants/app_categories.dart';
import '../../../constants/app_units.dart';
import '../../../model/pantry_item.dart';
import '../../../model/enums.dart';
import '../../../viewmodel/pantry_vm.dart';

/// Modal bottom sheet for ADD or EDIT pantry item.
/// Pass [existing] to edit; omit it to add.
Future<void> showPantryItemSheet(BuildContext context,
    {PantryItem? existing}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: AppColors.card(context),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _PantryItemForm(existing: existing),
  );
}

class _PantryItemForm extends StatefulWidget {
  final PantryItem? existing;
  const _PantryItemForm({this.existing});
  @override
  State<_PantryItemForm> createState() => _PantryItemFormState();
}

class _PantryItemFormState extends State<_PantryItemForm> {
  late final TextEditingController _name;
  late final TextEditingController _qtyCtrl;
  late final TextEditingController _notes;
  late final TextEditingController _imagePath;
  late String _category;
  late String _unitCode;
  late DateTime _expiry;
  DateTime? _purchase;
  late StorageLocation _storage;
  late bool _favorite;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _qtyCtrl = TextEditingController(
        text: e != null ? _trimZeros(e.quantity) : '1');
    _notes = TextEditingController(text: e?.notes ?? '');
    _imagePath = TextEditingController(text: e?.imagePath ?? '');
    _category = e?.category ?? 'Other';
    if (!AppCategories.all.contains(_category)) _category = 'Other';
    _unitCode = e?.unitCode ?? 'unit';
    _expiry = e?.expiryDate ?? DateTime.now().add(const Duration(days: 7));
    _purchase = e?.purchaseDate;
    _storage = e?.storage ?? StorageLocation.fridge;
    _favorite = e?.favorite ?? false;
  }

  static String _trimZeros(double v) {
    if (v == v.truncate()) return v.toInt().toString();
    return v.toString();
  }

  @override
  void dispose() {
    _name.dispose();
    _qtyCtrl.dispose();
    _notes.dispose();
    _imagePath.dispose();
    super.dispose();
  }

  Future<void> _pickExpiry() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiry,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
      helpText: 'Select expiry date',
    );
    if (picked != null) setState(() => _expiry = picked);
  }

  Future<void> _pickPurchase() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _purchase ?? DateTime.now(),
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now(),
      helpText: 'Select purchase date',
    );
    if (picked != null) setState(() => _purchase = picked);
  }

  double _qtyAsDouble() {
    return double.tryParse(_qtyCtrl.text.trim()) ?? 1.0;
  }

  void _save() {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an item name.')),
      );
      return;
    }
    final now = DateTime.now();
    final item = PantryItem(
      id: widget.existing?.id ?? 'p_${now.microsecondsSinceEpoch}',
      name: _name.text.trim(),
      category: _category,
      quantity: _qtyAsDouble(),
      unitCode: _unitCode,
      expiryDate: _expiry,
      addedDate: widget.existing?.addedDate ?? now,
      purchaseDate: _purchase,
      imageAsset: widget.existing?.imageAsset,
      imagePath:
          _imagePath.text.trim().isEmpty ? null : _imagePath.text.trim(),
      notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
      storage: _storage,
      favorite: _favorite,
      status: widget.existing?.status ?? ItemStatus.active,
    );

    if (_isEdit) {
      pantryVM.update(item);
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item updated.')),
      );
      return;
    }

    // For NEW items — duplicate check
    final dup = pantryVM.findDuplicate(item.name);
    if (dup != null) {
      _showDuplicateDialog(item, dup);
      return;
    }

    pantryVM.add(item);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Item added.')),
    );
  }

  void _showDuplicateDialog(PantryItem newItem, PantryItem existing) {
    showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Already in pantry'),
        content: Text(
            'You already have "${existing.name}" (${existing.quantityLabel}) in your pantry. What do you want to do?'),
        actionsAlignment: MainAxisAlignment.spaceBetween,
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              pantryVM.bumpQuantity(existing, _qtyAsDouble());
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                  content: Text(
                      'Increased ${existing.name} by ${_qtyAsDouble()} ${existing.unitCode}.')));
            },
            child: const Text('Increase existing'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryDark),
            onPressed: () {
              Navigator.pop(context);
              pantryVM.add(newItem);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Item added (duplicate).')),
              );
            },
            child: const Text('Add anyway'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final viewInsets = MediaQuery.of(context).viewInsets;
    final secondary =
        AppUnits.secondaryDisplay(_qtyAsDouble(), AppUnits.byCode(_unitCode));
    return Padding(
      padding: EdgeInsets.only(bottom: viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 36, height: 4,
                decoration: BoxDecoration(
                  color: AppColors.divider(context),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: Text(_isEdit ? 'Edit Item' : 'Add New Item',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPri(context),
                      )),
                ),
                if (_isEdit)
                  IconButton(
                    icon: Icon(
                      _favorite ? Icons.favorite : Icons.favorite_border,
                      color: _favorite
                          ? AppColors.danger
                          : AppColors.textMut(context),
                    ),
                    onPressed: () =>
                        setState(() => _favorite = !_favorite),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            _label(context, 'Item name'),
            const SizedBox(height: 6),
            TextField(
              controller: _name,
              decoration: const InputDecoration(
                hintText: 'e.g. Fresh Chicken Breast',
                prefixIcon: Icon(Icons.shopping_basket_outlined),
              ),
            ),
            const SizedBox(height: 14),
            // Quantity + Unit + Category
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(context, 'Quantity'),
                      const SizedBox(height: 6),
                      TextField(
                        controller: _qtyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(
                            decimal: true),
                        onChanged: (_) => setState(() {}),
                        decoration: const InputDecoration(
                          hintText: 'e.g. 500',
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _label(context, 'Unit'),
                      const SizedBox(height: 6),
                      DropdownButtonFormField<String>(
                        initialValue: _unitCode,
                        isExpanded: true,
                        decoration: const InputDecoration(isDense: true),
                        items: AppUnits.all
                            .map((u) => DropdownMenuItem(
                                  value: u.code,
                                  child: Text(u.label),
                                ))
                            .toList(),
                        onChanged: (v) => setState(() => _unitCode = v!),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (secondary != null) ...[
              const SizedBox(height: 4),
              Text(secondary,
                  style: TextStyle(
                      fontSize: 12, color: AppColors.textSec(context))),
            ],
            const SizedBox(height: 14),
            _label(context, 'Category'),
            const SizedBox(height: 6),
            DropdownButtonFormField<String>(
              initialValue: _category,
              isExpanded: true,
              decoration: const InputDecoration(isDense: true),
              items: AppCategories.all
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
              onChanged: (v) => setState(() => _category = v!),
            ),
            const SizedBox(height: 14),
            _label(context, 'Expiry Date'),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickExpiry,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.calendar_today, size: 18),
                  isDense: true,
                ),
                child: Text(
                  '${_expiry.year}-${_expiry.month.toString().padLeft(2, '0')}-${_expiry.day.toString().padLeft(2, '0')}',
                  style: TextStyle(color: AppColors.textPri(context)),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _label(context, 'Purchase Date (optional)'),
            const SizedBox(height: 6),
            InkWell(
              onTap: _pickPurchase,
              borderRadius: BorderRadius.circular(12),
              child: InputDecorator(
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.shopping_bag_outlined, size: 18),
                  isDense: true,
                  suffixIcon: _purchase != null
                      ? IconButton(
                          icon: const Icon(Icons.close, size: 18),
                          onPressed: () => setState(() => _purchase = null),
                        )
                      : null,
                ),
                child: Text(
                  _purchase == null
                      ? 'Not set'
                      : '${_purchase!.year}-${_purchase!.month.toString().padLeft(2, '0')}-${_purchase!.day.toString().padLeft(2, '0')}',
                  style: TextStyle(
                    color: _purchase == null
                        ? AppColors.textMut(context)
                        : AppColors.textPri(context),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _label(context, 'Storage Location'),
            const SizedBox(height: 6),
            SegmentedButton<StorageLocation>(
              showSelectedIcon: false,
              segments: const [
                ButtonSegment(
                    value: StorageLocation.fridge,
                    label: Text('Fridge'),
                    icon: Icon(Icons.kitchen, size: 18)),
                ButtonSegment(
                    value: StorageLocation.freezer,
                    label: Text('Freezer'),
                    icon: Icon(Icons.ac_unit, size: 18)),
                ButtonSegment(
                    value: StorageLocation.pantry,
                    label: Text('Pantry'),
                    icon: Icon(Icons.inventory_2, size: 18)),
              ],
              selected: {_storage},
              onSelectionChanged: (s) => setState(() => _storage = s.first),
            ),
            const SizedBox(height: 14),
            _label(context, 'Image path (optional)'),
            const SizedBox(height: 6),
            TextField(
              controller: _imagePath,
              decoration: const InputDecoration(
                hintText: 'assets/items/example.png',
                prefixIcon: Icon(Icons.image_outlined),
                isDense: true,
              ),
            ),
            const SizedBox(height: 14),
            _label(context, 'Notes (optional)'),
            const SizedBox(height: 6),
            TextField(
              controller: _notes,
              maxLines: 2,
              decoration: const InputDecoration(
                hintText: 'e.g. Top shelf, vacuum sealed...',
                isDense: true,
              ),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                if (_isEdit)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        pantryVM.delete(widget.existing!.id);
                        Navigator.pop(context);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Item deleted.')),
                        );
                      },
                      icon: const Icon(Icons.delete_outline,
                          color: AppColors.danger),
                      label: const Text('Delete',
                          style: TextStyle(color: AppColors.danger)),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: AppColors.danger),
                      ),
                    ),
                  ),
                if (_isEdit) const SizedBox(width: 12),
                Expanded(
                  flex: _isEdit ? 1 : 2,
                  child: ElevatedButton(
                    onPressed: _save,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primaryDark,
                    ),
                    child: Text(_isEdit ? 'Save Changes' : 'Add to Pantry'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _label(BuildContext c, String s) => Text(s,
      style: TextStyle(
        fontWeight: FontWeight.w600,
        fontSize: 13,
        color: AppColors.textSec(c),
      ));
}
