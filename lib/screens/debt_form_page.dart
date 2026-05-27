import 'dart:convert';
import 'dart:typed_data';

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
  List<String> _imageBase64List = <String>[];
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
      _imageBase64List = List<String>.from(existing.imageBase64List.take(3));
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
                        images: _imageBase64List,
                        busy: _pickingImage,
                        onPickFromGallery: () => _pickImage(ImageSource.gallery),
                        onTakePhoto: () => _pickImage(ImageSource.camera),
                        onRemove: (index) { _imageBase64List.removeAt(index); _refreshUi(); },
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
    if (_imageBase64List.length >= 3) {
      showAppToast('maxThreeImages'.tr, title: 'photoProof'.tr, icon: Icons.info_outline_rounded);
      return;
    }

    _pickingImage = true;
    _refreshUi();
    try {
      final encoded = await LocalImageCompressor.pickAndCompress(source: source);
      if (!mounted) return;
      if (encoded != null && encoded.trim().isNotEmpty) {
        _imageBase64List = [..._imageBase64List, encoded].take(3).toList(growable: true);
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
      imageBase64List: _imageBase64List,
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
    required this.images,
    required this.busy,
    required this.onPickFromGallery,
    required this.onTakePhoto,
    required this.onRemove,
  });

  final List<String> images;
  final bool busy;
  final VoidCallback onPickFromGallery;
  final VoidCallback onTakePhoto;
  final ValueChanged<int> onRemove;

  @override
  Widget build(BuildContext context) {
    final hasImages = images.isNotEmpty;
    final canAdd = images.length < 3;

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
                Text(
                  '${images.length}/3',
                  style: TextStyle(fontSize: 12, color: AppTheme.textSubtle(context), fontWeight: FontWeight.w800),
                ),
              ],
            ),
            const SizedBox(height: 8),
            if (hasImages)
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: List.generate(images.length, (index) => _DebtImagePreview(
                      imageBase64: images[index],
                      onRemove: busy ? null : () => onRemove(index),
                    )),
              )
            else
              Text('imageProofDesc'.tr, style: TextStyle(color: AppTheme.textSubtle(context), height: 1.45)),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy || !canAdd ? null : onPickFromGallery,
                    icon: busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.photo_rounded),
                    label: Text('chooseFromAlbum'.tr),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: busy || !canAdd ? null : onTakePhoto,
                    icon: const Icon(Icons.photo_camera_rounded),
                    label: Text('takePhoto'.tr),
                  ),
                ),
              ],
            ),
            if (!canAdd) ...[
              const SizedBox(height: 8),
              Text('maxThreeImages'.tr, style: TextStyle(color: AppTheme.textSubtle(context), fontSize: 12)),
            ],
          ],
        ),
      ),
    );
  }
}

class _DebtImagePreview extends StatefulWidget {
  const _DebtImagePreview({required this.imageBase64, required this.onRemove});

  final String imageBase64;
  final VoidCallback? onRemove;

  @override
  State<_DebtImagePreview> createState() => _DebtImagePreviewState();
}

class _DebtImagePreviewState extends State<_DebtImagePreview> {
  Uint8List? _bytes;

  @override
  void initState() {
    super.initState();
    _decode();
  }

  @override
  void didUpdateWidget(covariant _DebtImagePreview oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.imageBase64 != widget.imageBase64) {
      _decode();
    }
  }

  void _decode() {
    try {
      _bytes = base64Decode(widget.imageBase64);
    } catch (_) {
      _bytes = null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final bytes = _bytes;
    final image = bytes == null
        ? Container(
            width: 96,
            height: 72,
            alignment: Alignment.center,
            color: AppTheme.textSubtle(context).withValues(alpha: 0.08),
            child: Icon(Icons.broken_image_rounded, color: AppTheme.textSubtle(context)),
          )
        : Image.memory(
            bytes,
            width: 96,
            height: 72,
            fit: BoxFit.cover,
            gaplessPlayback: true,
            filterQuality: FilterQuality.low,
          );

    return Stack(
      clipBehavior: Clip.none,
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => _showDebtImagePreview(context, widget.imageBase64),
          child: ClipRRect(borderRadius: BorderRadius.circular(14), child: image),
        ),
        Positioned(
          top: -8,
          right: -8,
          child: InkWell(
            onTap: widget.onRemove,
            borderRadius: BorderRadius.circular(99),
            child: Container(
              width: 26,
              height: 26,
              decoration: BoxDecoration(
                color: AppTheme.cardColor(context),
                shape: BoxShape.circle,
                boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.12), blurRadius: 8, offset: const Offset(0, 3))],
              ),
              child: Icon(Icons.close_rounded, size: 16, color: AppTheme.textMain(context)),
            ),
          ),
        ),
      ],
    );
  }
}


void _showDebtImagePreview(BuildContext context, String imageBase64) {
  try {
    final bytes = base64Decode(imageBase64);
    Get.dialog<void>(
      Dialog(
        insetPadding: const EdgeInsets.all(16),
        backgroundColor: Colors.transparent,
        child: Stack(
          children: [
            InteractiveViewer(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(22),
                child: Image.memory(bytes, fit: BoxFit.contain, gaplessPlayback: true),
              ),
            ),
            Positioned(
              top: 10,
              right: 10,
              child: IconButton.filled(
                onPressed: () => Get.back<void>(),
                icon: const Icon(Icons.close_rounded),
              ),
            ),
          ],
        ),
      ),
    );
  } catch (_) {
    // Ignore broken local image data.
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
