import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

import '../../core/formatters.dart';
import '../../core/theme.dart';
import '../../models/event.dart';
import '../../models/event_draft.dart';
import '../../providers/auth_provider.dart';
import '../../providers/event_provider.dart';
import '../../services/event_image_service.dart';
import '../../widgets/custom_button.dart';
import '../../widgets/event_image.dart';
import '../../widgets/form_error_banner.dart';

/// Pemilih gambar yang bisa diganti pada test.
typedef EventImagePicker = Future<XFile?> Function(ImageSource source);

/// Form organizer untuk membuat event baru atau mengubah event yang ada.
///
/// Poster diunggah ke Supabase Storage bucket `event-images` lebih dulu,
/// lalu public URL-nya disimpan ke `events.image_url`.
class OrganizerEventEditorScreen extends StatefulWidget {
  const OrganizerEventEditorScreen({
    super.key,
    this.event,
    this.imageService,
    this.pickImage,
  });

  /// Null berarti mode buat event baru.
  final Event? event;

  /// Diisi pada test supaya tidak menyentuh Storage.
  final EventImageUploader? imageService;

  /// Diisi pada test supaya tidak memanggil plugin image_picker.
  final EventImagePicker? pickImage;

  @override
  State<OrganizerEventEditorScreen> createState() =>
      _OrganizerEventEditorScreenState();
}

class _OrganizerEventEditorScreenState
    extends State<OrganizerEventEditorScreen> {
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _priceController;
  late final TextEditingController _quotaController;

  late DateTime _date;
  late String _category;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;

  late String _imageUrl;
  Uint8List? _pickedBytes;
  String? _pickedExtension;
  String? _pickedContentType;

  String? _titleError;
  String? _descriptionError;
  String? _locationError;
  String? _priceError;
  String? _quotaError;
  String? _timeError;
  String? _formError;
  bool _saving = false;

  bool get _isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(
      text: event?.description ?? '',
    );
    _locationController = TextEditingController(text: event?.location ?? '');
    _priceController = TextEditingController(
      text: event == null ? '' : '${event.price}',
    );
    _quotaController = TextEditingController(
      text: event == null ? '' : '${event.quota}',
    );
    _date = event?.date ?? DateTime.now();
    _category = event?.category ?? _defaultCategory;
    _imageUrl = event?.imageUrl ?? '';

    final range = _parseTimeRange(event?.timeRange ?? '');
    _startTime = range.$1;
    _endTime = range.$2;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _priceController.dispose();
    _quotaController.dispose();
    super.dispose();
  }

  String get _defaultCategory {
    for (final category in EventProvider.categories) {
      if (category != 'Semua') return category;
    }
    return 'Lainnya';
  }

  List<String> get _categories {
    final result = EventProvider.categories
        .where((category) => category != 'Semua')
        .toList();
    if (!result.contains(_category)) result.add(_category);
    return result;
  }

  bool get _cameraAvailable =>
      !kIsWeb &&
      (defaultTargetPlatform == TargetPlatform.android ||
          defaultTargetPlatform == TargetPlatform.iOS);

  bool get _hasImage => _pickedBytes != null || _imageUrl.trim().isNotEmpty;

  Future<void> _choosePhoto() async {
    if (!_cameraAvailable) {
      await _pickImage(ImageSource.gallery);
      return;
    }

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppTheme.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 18),
              ListTile(
                leading: const Icon(Icons.photo_library_rounded),
                title: const Text('Pilih dari Galeri'),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: const Icon(Icons.photo_camera_rounded),
                title: const Text('Ambil dari Kamera'),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source != null) await _pickImage(source);
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final file = widget.pickImage != null
          ? await widget.pickImage!(source)
          : await ImagePicker().pickImage(
              source: source,
              maxWidth: 1600,
              imageQuality: 85,
            );
      if (file == null) return;

      final bytes = await file.readAsBytes();
      if (!mounted) return;

      final image = EventImageService.validateImage(
        bytes: bytes,
        extension: _extensionFor(file),
        contentType: file.mimeType,
      );

      setState(() {
        _pickedBytes = bytes;
        _pickedExtension = image.extension;
        _pickedContentType = image.contentType;
        _formError = null;
      });
    } on EventImageUploadException catch (error) {
      if (mounted) _showMessage(error.message);
    } catch (_) {
      if (mounted) _showMessage('Gagal membuka gambar. Coba lagi.');
    }
  }

  void _removePhoto() {
    setState(() {
      _pickedBytes = null;
      _pickedExtension = null;
      _pickedContentType = null;
      _imageUrl = '';
    });
  }

  String _extensionFor(XFile file) {
    final name = file.name;
    final dot = name.lastIndexOf('.');
    if (dot != -1 && dot < name.length - 1) {
      return name.substring(dot + 1).toLowerCase();
    }
    return '';
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      helpText: 'Pilih tanggal event',
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTime({required bool start}) async {
    final initial = (start ? _startTime : _endTime) ?? TimeOfDay.now();
    final picked = await showTimePicker(
      context: context,
      initialTime: initial,
      helpText: start ? 'Jam mulai' : 'Jam selesai',
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startTime = picked;
      } else {
        _endTime = picked;
      }
      _timeError = null;
    });
  }

  Future<void> _save() async {
    FocusScope.of(context).unfocus();

    final titleError = _validateTitle(_titleController.text);
    final descriptionError = _validateDescription(_descriptionController.text);
    final locationError = _validateLocation(_locationController.text);
    final priceError = _validatePrice(_priceController.text);
    final quotaError = _validateQuota(_quotaController.text);
    final timeError = _validateTime();

    if (titleError != null ||
        descriptionError != null ||
        locationError != null ||
        priceError != null ||
        quotaError != null ||
        timeError != null) {
      setState(() {
        _titleError = titleError;
        _descriptionError = descriptionError;
        _locationError = locationError;
        _priceError = priceError;
        _quotaError = quotaError;
        _timeError = timeError;
        _formError = null;
      });
      return;
    }

    final auth = context.read<AuthProvider>();
    final events = context.read<EventProvider>();
    final imageService = widget.imageService ?? EventImageService();

    setState(() {
      _saving = true;
      _formError = null;
      _titleError = null;
      _descriptionError = null;
      _locationError = null;
      _priceError = null;
      _quotaError = null;
      _timeError = null;
    });

    String? uploadedUrl;
    try {
      var imageUrl = _imageUrl.trim();

      if (_pickedBytes != null) {
        final user = auth.user;
        if (user == null) {
          setState(() => _formError = 'Sesi login tidak ditemukan.');
          return;
        }

        uploadedUrl = await imageService.uploadEventImage(
          userId: user.id,
          eventId: widget.event?.id,
          bytes: _pickedBytes!,
          extension: _pickedExtension,
          contentType: _pickedContentType,
        );
        imageUrl = uploadedUrl;
      }

      final draft = EventDraft(
        title: _titleController.text,
        description: _descriptionController.text,
        date: _date,
        location: _locationController.text,
        price: int.parse(_priceController.text.trim()),
        quota: int.parse(_quotaController.text.trim()),
        category: _category,
        timeRange: _timeRange,
        imageUrl: imageUrl,
        imageUrls: widget.event?.imageUrls ?? const [],
        tags: widget.event?.tags ?? const [],
      );

      await events.saveEvent(eventId: widget.event?.id, draft: draft);

      // Bersihkan poster lama setelah event berhasil disimpan.
      final oldUrl = widget.event?.imageUrl.trim() ?? '';
      if (oldUrl.isNotEmpty && oldUrl != imageUrl) {
        await imageService.deleteImage(oldUrl);
      }

      if (!mounted) return;
      Navigator.pop(context, true);
    } on EventImageUploadException catch (error) {
      if (uploadedUrl != null) await imageService.deleteImage(uploadedUrl);
      if (mounted) setState(() => _formError = error.message);
    } catch (_) {
      if (uploadedUrl != null) await imageService.deleteImage(uploadedUrl);
      if (mounted) {
        setState(() => _formError = 'Gagal menyimpan event. Coba lagi.');
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  String get _timeRange {
    if (_startTime == null || _endTime == null) return '';
    return '${_formatTime(_startTime!)} - ${_formatTime(_endTime!)}';
  }

  String? _validateTitle(String value) {
    final text = value.trim();
    if (text.isEmpty) return 'Nama event wajib diisi.';
    if (text.length < 3) return 'Nama event minimal 3 karakter.';
    if (text.length > 80) return 'Nama event maksimal 80 karakter.';
    return null;
  }

  String? _validateDescription(String value) {
    final text = value.trim();
    if (text.isEmpty) return 'Deskripsi event wajib diisi.';
    if (text.length < 10) return 'Deskripsi minimal 10 karakter.';
    if (text.length > 2000) return 'Deskripsi maksimal 2000 karakter.';
    return null;
  }

  String? _validateLocation(String value) {
    final text = value.trim();
    if (text.isEmpty) return 'Lokasi event wajib diisi.';
    if (text.length < 3) return 'Lokasi minimal 3 karakter.';
    if (text.length > 200) return 'Lokasi maksimal 200 karakter.';
    return null;
  }

  String? _validatePrice(String value) {
    final text = value.trim();
    if (text.isEmpty) return 'Harga tiket wajib diisi.';
    final price = int.tryParse(text);
    if (price == null) return 'Harga tiket harus berupa angka.';
    if (price < 0) return 'Harga tiket tidak boleh negatif.';
    if (price > 1000000000) return 'Harga tiket terlalu besar.';
    return null;
  }

  String? _validateQuota(String value) {
    final text = value.trim();
    if (text.isEmpty) return 'Kuota tiket wajib diisi.';
    final quota = int.tryParse(text);
    if (quota == null) return 'Kuota tiket harus berupa angka.';
    if (quota < 0) return 'Kuota tiket tidak boleh negatif.';
    if (quota > 1000000) return 'Kuota tiket maksimal 1.000.000.';
    return null;
  }

  String? _validateTime() {
    if (_startTime == null && _endTime == null) return null;
    if (_startTime == null || _endTime == null) {
      return 'Lengkapi jam mulai dan jam selesai.';
    }
    final start = _startTime!.hour * 60 + _startTime!.minute;
    final end = _endTime!.hour * 60 + _endTime!.minute;
    if (end <= start) return 'Jam selesai harus setelah jam mulai.';
    return null;
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppTheme.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.canvas,
      appBar: AppBar(
        title: Text(_isEditing ? 'Edit Event' : 'Buat Event Baru'),
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              children: [
                _buildPoster(),
                const SizedBox(height: 24),
                const _FieldLabel('Nama Event'),
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey('event-editor-title'),
                  controller: _titleController,
                  enabled: !_saving,
                  textInputAction: TextInputAction.next,
                  maxLength: 80,
                  onChanged: (_) {
                    if (_titleError != null) {
                      setState(() => _titleError = null);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Contoh: Sound of Tomorrow',
                    prefixIcon: const Icon(Icons.event_outlined, size: 20),
                    errorText: _titleError,
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                const _FieldLabel('Deskripsi'),
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey('event-editor-description'),
                  controller: _descriptionController,
                  enabled: !_saving,
                  minLines: 3,
                  maxLines: 5,
                  maxLength: 2000,
                  onChanged: (_) {
                    if (_descriptionError != null) {
                      setState(() => _descriptionError = null);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Ceritakan acara kamu...',
                    alignLabelWithHint: true,
                    errorText: _descriptionError,
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                const _FieldLabel('Kategori'),
                const SizedBox(height: 8),
                InputDecorator(
                  decoration: const InputDecoration(
                    prefixIcon: Icon(Icons.category_outlined, size: 20),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String>(
                      key: const ValueKey('event-editor-category'),
                      value: _category,
                      isExpanded: true,
                      onChanged: _saving
                          ? null
                          : (value) {
                              if (value != null) {
                                setState(() => _category = value);
                              }
                            },
                      items: _categories
                          .map(
                            (category) => DropdownMenuItem(
                              value: category,
                              child: Text(category),
                            ),
                          )
                          .toList(growable: false),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                const _FieldLabel('Tanggal'),
                const SizedBox(height: 8),
                _buildPickerTile(
                  key: const ValueKey('event-editor-date'),
                  icon: Icons.calendar_today_rounded,
                  text: formatTanggal(_date),
                  onTap: _saving ? null : _pickDate,
                ),
                const SizedBox(height: 16),
                const _FieldLabel('Waktu'),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: _buildPickerTile(
                        key: const ValueKey('event-editor-start-time'),
                        icon: Icons.schedule_rounded,
                        text: _startTime == null
                            ? 'Jam mulai'
                            : _formatTime(_startTime!),
                        muted: _startTime == null,
                        onTap: _saving
                            ? null
                            : () => _pickTime(start: true),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildPickerTile(
                        key: const ValueKey('event-editor-end-time'),
                        icon: Icons.schedule_rounded,
                        text: _endTime == null
                            ? 'Jam selesai'
                            : _formatTime(_endTime!),
                        muted: _endTime == null,
                        onTap: _saving
                            ? null
                            : () => _pickTime(start: false),
                      ),
                    ),
                  ],
                ),
                if (_timeError != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    _timeError!,
                    style: const TextStyle(
                      color: AppTheme.red,
                      fontSize: 12,
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                const _FieldLabel('Lokasi'),
                const SizedBox(height: 8),
                TextField(
                  key: const ValueKey('event-editor-location'),
                  controller: _locationController,
                  enabled: !_saving,
                  maxLength: 200,
                  onChanged: (_) {
                    if (_locationError != null) {
                      setState(() => _locationError = null);
                    }
                  },
                  decoration: InputDecoration(
                    hintText: 'Nama venue, alamat lengkap, kota',
                    prefixIcon: const Icon(Icons.place_outlined, size: 20),
                    errorText: _locationError,
                    counterText: '',
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel('Harga Tiket'),
                          const SizedBox(height: 8),
                          TextField(
                            key: const ValueKey('event-editor-price'),
                            controller: _priceController,
                            enabled: !_saving,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (_) {
                              if (_priceError != null) {
                                setState(() => _priceError = null);
                              }
                            },
                            decoration: InputDecoration(
                              hintText: '0',
                              prefixText: 'Rp ',
                              errorText: _priceError,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const _FieldLabel('Kuota'),
                          const SizedBox(height: 8),
                          TextField(
                            key: const ValueKey('event-editor-quota'),
                            controller: _quotaController,
                            enabled: !_saving,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                            ],
                            onChanged: (_) {
                              if (_quotaError != null) {
                                setState(() => _quotaError = null);
                              }
                            },
                            decoration: InputDecoration(
                              hintText: '0',
                              suffixText: 'tiket',
                              errorText: _quotaError,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  'Isi 0 pada kuota bila tiket tidak dibatasi.',
                  style: TextStyle(fontSize: 12, color: AppTheme.muted),
                ),
                if (_formError != null) ...[
                  const SizedBox(height: 16),
                  FormErrorBanner(message: _formError!),
                ],
                const SizedBox(height: 28),
                CustomButton(
                  key: const ValueKey('event-editor-save'),
                  label: _isEditing ? 'Simpan Perubahan' : 'Buat Event',
                  icon: Icons.check_rounded,
                  loading: _saving,
                  onPressed: _saving ? null : _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPoster() {
    Widget preview;
    if (_pickedBytes != null) {
      preview = Image.memory(
        _pickedBytes!,
        fit: BoxFit.cover,
        width: double.infinity,
        height: double.infinity,
        gaplessPlayback: true,
      );
    } else if (_imageUrl.trim().isNotEmpty) {
      preview = EventImage(
        imageUrl: _imageUrl,
        eventId: widget.event?.id ?? 'event-baru',
        fit: BoxFit.cover,
      );
    } else {
      preview = Container(
        color: AppTheme.fieldBg,
        alignment: Alignment.center,
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.add_photo_alternate_outlined,
              size: 40,
              color: AppTheme.textGrey,
            ),
            SizedBox(height: 8),
            Text(
              'Tambah poster event',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppTheme.textMuted,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Rasio 16:9, JPG/PNG/WebP',
              style: TextStyle(fontSize: 11.5, color: AppTheme.textGrey),
            ),
          ],
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const _FieldLabel('Poster Event'),
        const SizedBox(height: 8),
        Semantics(
          button: true,
          label: _hasImage ? 'Ganti poster event' : 'Pilih poster event',
          child: Material(
            color: Colors.transparent,
            borderRadius: BorderRadius.circular(AppTheme.radiusLg),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              key: const ValueKey('event-editor-poster'),
              onTap: _saving ? null : _choosePhoto,
              child: AspectRatio(
                aspectRatio: 16 / 9,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    preview,
                    if (_hasImage)
                      Positioned(
                        right: 10,
                        bottom: 10,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                          decoration: BoxDecoration(
                            color: AppTheme.ink.withValues(alpha: 0.82),
                            borderRadius: BorderRadius.circular(
                              AppTheme.radiusPill,
                            ),
                          ),
                          child: const Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.photo_camera_rounded,
                                size: 15,
                                color: Colors.white,
                              ),
                              SizedBox(width: 6),
                              Text(
                                'Ganti',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Wrap(
          spacing: 8,
          runSpacing: 4,
          children: [
            OutlinedButton.icon(
              onPressed: _saving ? null : _choosePhoto,
              icon: const Icon(Icons.photo_library_rounded, size: 18),
              label: Text(_hasImage ? 'Ganti Poster' : 'Pilih Poster'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 48),
              ),
            ),
            if (_hasImage)
              TextButton.icon(
                onPressed: _saving ? null : _removePhoto,
                icon: const Icon(Icons.delete_outline_rounded, size: 18),
                label: const Text('Hapus'),
                style: TextButton.styleFrom(
                  minimumSize: const Size(0, 48),
                  foregroundColor: AppTheme.red,
                ),
              ),
          ],
        ),
        const SizedBox(height: 2),
        const Text(
          'JPG/PNG/WebP, maksimal 5 MB.',
          style: TextStyle(fontSize: 12, color: AppTheme.muted),
        ),
      ],
    );
  }

  Widget _buildPickerTile({
    required Key key,
    required IconData icon,
    required String text,
    required VoidCallback? onTap,
    bool muted = false,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(AppTheme.radiusField),
      child: InkWell(
        key: key,
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusField),
        child: Container(
          constraints: const BoxConstraints(minHeight: 52),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusField),
            border: Border.all(color: AppTheme.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 19, color: AppTheme.muted),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: muted ? AppTheme.textGrey : AppTheme.ink,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  static String _formatTime(TimeOfDay time) {
    final hour = time.hour.toString().padLeft(2, '0');
    final minute = time.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  static (TimeOfDay?, TimeOfDay?) _parseTimeRange(String value) {
    final match = RegExp(
      r'^(\d{1,2}):(\d{2})\s*-\s*(\d{1,2}):(\d{2})$',
    ).firstMatch(value.trim());
    if (match == null) return (null, null);

    final startHour = int.tryParse(match.group(1)!);
    final startMinute = int.tryParse(match.group(2)!);
    final endHour = int.tryParse(match.group(3)!);
    final endMinute = int.tryParse(match.group(4)!);
    if (startHour == null ||
        startMinute == null ||
        endHour == null ||
        endMinute == null ||
        startHour > 23 ||
        endHour > 23 ||
        startMinute > 59 ||
        endMinute > 59) {
      return (null, null);
    }

    return (
      TimeOfDay(hour: startHour, minute: startMinute),
      TimeOfDay(hour: endHour, minute: endMinute),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: const TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: AppTheme.ink,
      ),
    );
  }
}
