import 'dart:io';
import 'package:flutter/material.dart';
import '../../core/networking/api_client.dart';
import '../../shared/models/models.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/provinces.dart';
import '../../core/constants/api_constants.dart';
import 'package:image_picker/image_picker.dart';
import 'avatar_crop_screen.dart';

class EditProfileScreen extends StatefulWidget {
  final UserModel user;
  const EditProfileScreen({super.key, required this.user});
  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _form = GlobalKey<FormState>();
  late final _displayName =
      TextEditingController(text: widget.user.displayName);
  late final _username = TextEditingController(text: widget.user.username);
  late String? _province;
  bool _saving = false;
  bool _avatarBusy = false;
  late String? _avatarUrlValue = widget.user.avatarUrl;
  String? _error;

  @override
  void initState() {
    super.initState();
    _province = dominicanProvinces.contains(widget.user.province)
        ? widget.user.province
        : null;
  }

  @override
  void dispose() {
    _displayName.dispose();
    _username.dispose();
    super.dispose();
  }

  String _avatarUrl(String value) {
    final uri = Uri.tryParse(value);
    if (uri != null && uri.hasScheme) return value;
    return '${ApiConstants.hostUrl}/${value.replaceFirst(RegExp(r'^/'), '')}';
  }

  Future<void> _changeAvatar() async {
    if (_avatarBusy) return;

    final source = await showModalBottomSheet<ImageSource>(
      context: context,
      backgroundColor: context.surfaceColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 36,
                height: 4,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: ctx.mutedColor.withValues(alpha: 0.4),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              ListTile(
                leading: Icon(Icons.photo_library_outlined, color: ctx.textPrimaryColor),
                title: Text('Elegir de la galería',
                    style: TextStyle(color: ctx.textPrimaryColor, fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(ctx, ImageSource.gallery),
              ),
              ListTile(
                leading: Icon(Icons.camera_alt_outlined, color: ctx.textPrimaryColor),
                title: Text('Tomar foto con la cámara',
                    style: TextStyle(color: ctx.textPrimaryColor, fontWeight: FontWeight.w600)),
                onTap: () => Navigator.pop(ctx, ImageSource.camera),
              ),
            ],
          ),
        ),
      ),
    );

    if (source == null || !mounted) return;

    final image = await ImagePicker().pickImage(
      source: source,
      maxWidth: 2048,
      maxHeight: 2048,
    );
    if (image == null || !mounted) return;

    final croppedFile = await Navigator.push<File?>(
      context,
      MaterialPageRoute(
        builder: (_) => AvatarCropScreen(imageFile: File(image.path)),
      ),
    );
    if (croppedFile == null || !mounted) return;

    setState(() => _avatarBusy = true);
    try {
      final url = await ApiClient().uploadImage(croppedFile.path);
      if (url == null) throw Exception('No se pudo subir la imagen.');
      await ApiClient().updateProfile(avatarUrl: url);
      if (mounted) setState(() => _avatarUrlValue = url);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Foto de perfil actualizada.')),
        );
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ApiClient.errorMessage(error))),
        );
      }
    } finally {
      if (mounted) setState(() => _avatarBusy = false);
    }
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ApiClient().updateProfile(
          displayName: _displayName.text.trim(),
          username: _username.text.trim().toLowerCase(),
          province: _province!,
          municipality: '');
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _selectProvince(FormFieldState<String> field) async {
    final searchController = TextEditingController();
    var query = '';
    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => StatefulBuilder(
        builder: (context, setSheetState) {
          final provinces = dominicanProvinces
              .where((province) =>
                  province.toLowerCase().contains(query.trim().toLowerCase()))
              .toList();

          return SafeArea(
            child: FractionallySizedBox(
              heightFactor: 0.72,
              child: Container(
                decoration: BoxDecoration(
                  color: context.surfaceColor,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(26)),
                  border: Border.all(color: context.borderColor, width: 1.5),
                ),
                child: Column(
                  children: [
                    const SizedBox(height: 10),
                    Container(
                      width: 38,
                      height: 4,
                      decoration: BoxDecoration(
                        color: context.mutedColor.withValues(alpha: 0.55),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 18, 20, 12),
                      child: Row(
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Elige tu provincia',
                                    style: TextStyle(
                                      color: context.textPrimaryColor,
                                      fontSize: 18,
                                      fontWeight: FontWeight.w700,
                                    )),
                                const SizedBox(height: 3),
                                Text('República Dominicana',
                                    style: TextStyle(
                                        color: context.subtleColor,
                                        fontSize: 12)),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'Cerrar',
                            onPressed: () => Navigator.pop(sheetContext),
                            icon: Icon(Icons.close_rounded,
                                color: context.mutedColor),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: TextField(
                        controller: searchController,
                        onChanged: (value) => setSheetState(() => query = value),
                        decoration: InputDecoration(
                          hintText: 'Buscar provincia',
                          prefixIcon: const Icon(Icons.search_rounded),
                          filled: true,
                          fillColor: context.overlayColor,
                          contentPadding:
                              const EdgeInsets.symmetric(vertical: 12),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: context.borderColor),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: context.borderColor),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Expanded(
                      child: provinces.isEmpty
                          ? Center(
                              child: Text('No se encontraron provincias',
                                  style: TextStyle(
                                      color: context.subtleColor)))
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(14, 2, 14, 16),
                              itemCount: provinces.length,
                              separatorBuilder: (_, __) =>
                                  const SizedBox(height: 4),
                              itemBuilder: (context, index) {
                                final province = provinces[index];
                                final isSelected = province == _province;
                                return Material(
                                  color: isSelected
                                      ? context.loveColor.withValues(alpha: 0.12)
                                      : Colors.transparent,
                                  borderRadius: BorderRadius.circular(14),
                                  child: InkWell(
                                    borderRadius: BorderRadius.circular(14),
                                    onTap: () => Navigator.pop(sheetContext, province),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                          horizontal: 14, vertical: 12),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(province,
                                                style: TextStyle(
                                                  color: context.textPrimaryColor,
                                                  fontWeight: isSelected
                                                      ? FontWeight.w700
                                                      : FontWeight.w500,
                                                )),
                                          ),
                                          if (isSelected)
                                            Icon(Icons.check_circle_rounded,
                                                color: context.loveColor,
                                                size: 20),
                                        ],
                                      ),
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
    searchController.dispose();
    if (selected != null) {
      setState(() => _province = selected);
      field.didChange(selected);
    }
  }

  Widget _buildProvinceField() => FormField<String>(
        initialValue: _province,
        validator: (value) => value == null ? 'Selecciona una provincia' : null,
        builder: (field) => InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _selectProvince(field),
          child: InputDecorator(
            isEmpty: false,
            decoration: InputDecoration(
              labelText: 'Provincia',
              errorText: field.errorText,
              prefixIcon: const Icon(Icons.location_on_outlined),
              suffixIcon: const Icon(Icons.expand_more_rounded),
            ),
            child: Text(
              _province ?? 'Selecciona tu provincia',
              style: TextStyle(
                color: _province == null
                    ? context.subtleColor
                    : context.textPrimaryColor,
              ),
            ),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Editar mi perfil')),
        body: Form(
            key: _form,
            child: ListView(padding: const EdgeInsets.all(24), children: [
              Center(
                child: GestureDetector(
                  onTap: _avatarBusy ? null : _changeAvatar,
                  child: Stack(
                    clipBehavior: Clip.none,
                    children: [
                      CircleAvatar(
                        radius: 36,
                        backgroundColor: context.isDarkMode
                            ? context.overlayColor
                            : const Color(0xFFFFFAF3),
                        backgroundImage: _avatarUrlValue?.isNotEmpty == true
                            ? NetworkImage(_avatarUrl(_avatarUrlValue!))
                            : null,
                        child: _avatarBusy
                            ? CircularProgressIndicator(color: context.loveColor)
                            : _avatarUrlValue?.isNotEmpty == true
                                ? null
                                : Text(
                                    widget.user.username.isNotEmpty
                                        ? widget.user.username[0].toUpperCase()
                                        : 'U',
                                    style: TextStyle(fontSize: 28, color: context.loveColor)),
                      ),
                      Positioned(
                        right: -4,
                        bottom: 0,
                        child: CircleAvatar(
                          radius: 13,
                          backgroundColor: context.loveColor,
                          child: const Icon(Icons.photo_camera_rounded, size: 14, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Text(widget.user.displayName,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text('@${widget.user.username}',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: context.subtleColor)),
              const SizedBox(height: 28),
              TextFormField(
                  controller: _displayName,
                  maxLength: 80,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                      labelText: 'Nombre de perfil',
                      prefixIcon: Icon(Icons.badge_outlined)),
                  validator: (text) {
                    if (text == null || text.trim().length < 2) {
                      return 'Escribe al menos 2 caracteres';
                    }
                    return null;
                  }),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _username,
                  enabled: _canChangeUsername,
                  maxLength: 30,
                  autocorrect: false,
                  enableSuggestions: false,
                  decoration: InputDecoration(
                    labelText: '@usuario',
                    prefixIcon: const Icon(Icons.alternate_email_rounded),
                    helperText: _usernameHelper,
                  ),
                  validator: (text) {
                    if (!_canChangeUsername) return null;
                    final value = text?.trim() ?? '';
                    if (value.length < 3) {
                      return 'Escribe al menos 3 caracteres';
                    }
                    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(value)) {
                      return 'Usa solo letras, números y guion bajo';
                    }
                    return null;
                  }),
              const SizedBox(height: 16),
              _buildProvinceField(),
              if (_error != null)
                Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    child: Text(_error!,
                        style: TextStyle(
                            color: Theme.of(context).colorScheme.error))),
              const SizedBox(height: 20),
              FilledButton(
                  onPressed: _saving ? null : _save,
                  child: Text(_saving ? 'Guardando…' : 'Guardar cambios')),
            ])),
      );
  bool get _canChangeUsername {
    final date = widget.user.usernameCanChangeAt;
    return date == null || !date.isAfter(DateTime.now().toUtc());
  }

  String get _usernameHelper {
    final date = widget.user.usernameCanChangeAt;
    if (_canChangeUsername || date == null) {
      return 'Podrás volver a cambiarlo 15 días después de guardar.';
    }
    final local = date.toLocal();
    return 'Disponible nuevamente el ${local.day.toString().padLeft(2, '0')}/${local.month.toString().padLeft(2, '0')}/${local.year}.';
  }
}
