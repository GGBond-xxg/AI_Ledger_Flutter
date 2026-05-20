import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../app/app_theme.dart';
import '../core/app_constants.dart';
import '../core/id.dart';
import '../core/app_toast.dart';
import '../core/local_image_compressor.dart';
import '../l10n/translation_service.dart';
import '../models/debt_item.dart';
import '../services/ledger_store.dart';
import '../widgets/common_cards.dart';
import '../widgets/form_fields.dart';

class DebtFormPage extends StatefulWidget {
  const DebtFormPage({super.key, this.existing});
  final DebtItem? existing;

  @override
  State<DebtFormPage> createState() => _DebtFormPageState();
}

class _DebtFormPageState extends State<DebtFormPage> {
  final LedgerStore store = Get.find<LedgerStore>();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _amountController = TextEditingController();
  final _noteController = TextEditingController();

  String _direction = 'payable';
  String _currency = 'CNY';
  String _imageBase64 = '';
  bool _pickingImage = false;
  final RxInt _uiVersion = 0.obs;

  void _refreshUi() => _uiVersion.value++;

  @override
  void initState() {
    super.initState();
    final existing = widget.existing;
    if (existing != null) {
      _nameController.text = existing.name;
      _amountController.text = existing.amount.toString();
      _noteController.text = existing.note;
      _direction = existing.direction;
      _currency = existing.currency;
      _imageBase64 = existing.imageBase64;
    }
  }

  bool get _isEditing => widget.existing != null;

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      _uiVersion.value;
      return Scaffold(
      appBar: AppBar(title: Text(_isEditing ? 'editDebt'.tr : 'addDebt'.tr)),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                FormCard(
                  children: [
                    LedgerDropdownField<String>(
                      label: 'direction'.tr,
                      value: _direction,
                      items: [
                        DropdownMenuItem(value: 'payable', child: Text('iOweOthers'.tr)),
                        DropdownMenuItem(value: 'receivable', child: Text('othersOweMe'.tr)),
                      ],
                      onChanged: (value) { _direction = value ?? _direction; _refreshUi(); },
                    ),
                    LedgerTextField(
                      controller: _nameController,
                      label: 'name'.tr,
                      hint: _direction == 'payable' ? 'debtNamePayableHint'.tr  : 'debtNameReceivableHint'.tr,
                      validator: (value) => value == null || value.trim().isEmpty ? 'enterName'.tr : null,
                    ),
                    LedgerTextField(
                      controller: _amountController,
                      label: 'amount'.tr,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        final number = double.tryParse(value?.trim() ?? '');
                        if (number == null || number <= 0) return 'enterPositiveAmount'.tr;
                        return null;
                      },
                    ),
                    LedgerDropdownField<String>(
                      label: 'currency'.tr,
                      value: _currency,
                      items: kCurrencies.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
                      onChanged: (value) { _currency = value ?? _currency; _refreshUi(); },
                    ),
                    LedgerTextField(controller: _noteController, label: 'noteOptional'.tr, maxLines: 3),
                    _DebtImagePicker(
                      imageBase64: _imageBase64,
                      busy: _pickingImage,
                      onPickFromGallery: () => _pickImage(ImageSource.gallery),
                      onTakePhoto: () => _pickImage(ImageSource.camera),
                      onRemove: () { _imageBase64 = ''; _refreshUi(); },
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                const _LocalImageNotice(),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(onPressed: _submit, child: Text(_isEditing ? 'saveChanges'.tr  : 'save'.tr)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
    });
  }

  Future<void> _pickImage(ImageSource source) async {
    _pickingImage = true;
    _refreshUi();
    try {
      final encoded = await LocalImageCompressor.pickAndCompress(source: source);
      if (!mounted) return;
      if (encoded != null) {
        _imageBase64 = encoded;
        _refreshUi();
      }
    } catch (e) {
      if (!mounted) return;
      showAppToast(trImageLoadFailed(e.toString().replaceFirst('Exception: ', '')), title: 'apiTestFailed'.tr, icon: Icons.error_outline_rounded);
    } finally {
      if (mounted) {
        _pickingImage = false;
        _refreshUi();
      }
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final existing = widget.existing;
    final item = DebtItem(
      id: existing?.id ?? newId(),
      name: _nameController.text.trim(),
      direction: _direction,
      amount: double.parse(_amountController.text.trim()),
      currency: _currency,
      note: _noteController.text.trim(),
      imageBase64: _imageBase64,
      createdAt: existing?.createdAt,
    );

    if (_isEditing) {
      await store.updateDebt(item);
    } else {
      await store.addDebt(item);
    }
    await store.refreshValuation(force: true, source: 'debtSaved');
    if (mounted) Get.back<void>();
  }
}

class _DebtImagePicker extends StatelessWidget {
  const _DebtImagePicker({
    required this.imageBase64,
    required this.busy,
    required this.onPickFromGallery,
    required this.onTakePhoto,
    required this.onRemove,
  });

  final String imageBase64;
  final bool busy;
  final VoidCallback onPickFromGallery;
  final VoidCallback onTakePhoto;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final hasImage = imageBase64.trim().isNotEmpty;

    return Padding(
      padding: const EdgeInsets.only(top: 4, bottom: 4),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppTheme.inputColor(context),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('photoProof'.tr, style: const TextStyle(fontWeight: FontWeight.w800)),
                ),
                if (hasImage)
                  TextButton.icon(
                    onPressed: busy ? null : onRemove,
                    icon: const Icon(Icons.close_rounded, size: 18),
                    label: Text('remove'.tr),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (hasImage)
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.memory(
                  base64Decode(imageBase64),
                  width: double.infinity,
                  height: 150,
                  fit: BoxFit.cover,
                ),
              )
            else
              Text('imageProofDesc'.tr, style: TextStyle(color: AppTheme.textSubtle(context), height: 1.45)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : onPickFromGallery,
                    icon: busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.photo_rounded),
                    label: Text('chooseFromAlbum'.tr),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy ? null : onTakePhoto,
                    icon: const Icon(Icons.photo_camera_rounded),
                    label: Text('takePhoto'.tr),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _LocalImageNotice extends StatelessWidget {
  const _LocalImageNotice();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(18),
      ),
      child: Text(
        'localImageNotice'.tr,
        style: TextStyle(color: AppTheme.textSubtle(context), height: 1.5),
      ),
    );
  }
}
