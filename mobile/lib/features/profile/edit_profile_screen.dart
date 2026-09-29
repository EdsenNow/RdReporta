import 'package:flutter/material.dart';
import '../../core/networking/api_client.dart';
import '../../shared/models/models.dart';
import '../../core/theme/app_theme.dart';

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
  late final _province = TextEditingController(text: widget.user.province);
  late final _municipality =
      TextEditingController(text: widget.user.municipality);
  bool _saving = false;
  String? _error;
  @override
  void dispose() {
    _displayName.dispose();
    _username.dispose();
    _province.dispose();
    _municipality.dispose();
    super.dispose();
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
          username: _username.text.trim(),
          province: _province.text.trim(),
          municipality: _municipality.text.trim());
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) setState(() => _error = ApiClient.errorMessage(e));
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(title: const Text('Editar mi perfil')),
        body: Form(
            key: _form,
            child: ListView(padding: const EdgeInsets.all(24), children: [
              CircleAvatar(
                  radius: 36,
                  backgroundColor: context.isDarkMode
                      ? context.overlayColor
                      : const Color(0xFFFFFAF3),
                  child: Text(
                      widget.user.username.substring(0, 1).toUpperCase(),
                      style: TextStyle(
                          fontSize: 28, color: context.loveColor))),
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
              TextFormField(
                  controller: _province,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: 'Provincia'),
                  validator: _required),
              const SizedBox(height: 16),
              TextFormField(
                  controller: _municipality,
                  maxLength: 100,
                  decoration: const InputDecoration(labelText: 'Municipio'),
                  validator: _required),
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
  String? _required(String? text) =>
      text == null || text.trim().isEmpty ? 'Completa este campo' : null;

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
