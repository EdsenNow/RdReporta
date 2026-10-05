import 'package:flutter/material.dart';
import '../../core/networking/api_client.dart';
import '../../core/theme/app_theme.dart';

class ReportPostSheet extends StatefulWidget {
  const ReportPostSheet({super.key, required this.postId});
  final String postId;

  @override
  State<ReportPostSheet> createState() => _ReportPostSheetState();
}

class _ReportPostSheetState extends State<ReportPostSheet> {
  static const _reasons = [
    (
      id: 'InformacionFalsa',
      title: 'Información falsa',
      detail: 'Datos engañosos o sin fundamento.',
      icon: Icons.fact_check_outlined
    ),
    (
      id: 'PublicacionDuplicada',
      title: 'Reporte duplicado',
      detail: 'La misma incidencia ya fue publicada.',
      icon: Icons.copy_all_outlined
    ),
    (
      id: 'Spam',
      title: 'Publicidad o spam',
      detail: 'Promociones o contenido irrelevante.',
      icon: Icons.campaign_outlined
    ),
    (
      id: 'ContenidoViolento',
      title: 'Contenido violento',
      detail: 'Imágenes o mensajes de violencia explícita.',
      icon: Icons.warning_amber_rounded
    ),
    (
      id: 'DatosPersonales',
      title: 'Datos personales expuestos',
      detail: 'Información privada de otra persona.',
      icon: Icons.privacy_tip_outlined
    ),
    (
      id: 'Acoso',
      title: 'Acoso',
      detail: 'Amenazas, intimidación o ataques personales.',
      icon: Icons.person_off_outlined
    ),
    (
      id: 'UbicacionIncorrecta',
      title: 'Ubicación incorrecta',
      detail: 'La dirección no corresponde a la incidencia.',
      icon: Icons.wrong_location_outlined
    ),
    (
      id: 'Otro',
      title: 'Otro motivo',
      detail: 'Un problema diferente con esta publicación.',
      icon: Icons.more_horiz_rounded
    ),
  ];

  final _description = TextEditingController();
  int? _selected;
  bool _review = false;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_sending || _selected == null) return;
    FocusScope.of(context).unfocus();
    setState(() {
      _sending = true;
      _error = null;
    });
    final text = _description.text.trim();
    final ok = await ApiClient().reportPost(
      postId: widget.postId,
      reason: _reasons[_selected!].id,
      description: text.isEmpty ? null : text,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    if (ok) {
      Navigator.pop(context, true);
    } else {
      setState(() => _error =
          'No se pudo enviar la denuncia. Vuelve a intentarlo; es posible que ya hayas denunciado este reporte.');
    }
  }

  Widget _reasonTile(int index) {
    final reason = _reasons[index];
    final selected = index == _selected;
    final accent = Theme.of(context).colorScheme.primary;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: selected
            ? accent.withValues(alpha: 0.10)
            : context.overlayColor.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          borderRadius: BorderRadius.circular(16),
          onTap: _sending
              ? null
              : () => setState(() {
                    _selected = index;
                    _review = true;
                    _error = null;
                  }),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: selected
                        ? accent.withValues(alpha: 0.15)
                        : context.surfaceColor,
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(reason.icon,
                    size: 22, color: selected ? accent : context.subtleColor),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(reason.title,
                        style: TextStyle(
                            fontWeight: FontWeight.w600,
                            fontSize: 14,
                            color: context.textPrimaryColor)),
                    const SizedBox(height: 3),
                    Text(reason.detail,
                        style: TextStyle(
                            fontSize: 12,
                            height: 1.35,
                            color: context.subtleColor)),
                  ])),
              const SizedBox(width: 8),
              Icon(
                  selected
                      ? Icons.check_circle_rounded
                      : Icons.chevron_right_rounded,
                  color: selected ? accent : context.mutedColor,
                  size: 21),
            ]),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PopScope(
      canPop: !_sending,
      child: AnimatedPadding(
        duration: const Duration(milliseconds: 200),
        padding:
            EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: (MediaQuery.sizeOf(context).height -
                    MediaQuery.paddingOf(context).top -
                    MediaQuery.viewInsetsOf(context).bottom) *
                0.92,
          ),
          child: Material(
            color: context.surfaceColor,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            clipBehavior: Clip.antiAlias,
            child: SafeArea(
                top: false,
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const SizedBox(height: 12),
                  Container(
                      width: 36,
                      height: 4,
                      decoration: BoxDecoration(
                          color: context.mutedColor.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(4))),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                    child: Row(children: [
                      if (_review)
                        IconButton(
                            tooltip: 'Cambiar motivo',
                            onPressed: _sending
                                ? null
                                : () => setState(() {
                                      _review = false;
                                      _error = null;
                                    }),
                            icon: const Icon(Icons.arrow_back_rounded))
                      else
                        Padding(
                            padding: const EdgeInsets.all(12),
                            child: Icon(Icons.flag_outlined,
                                color: theme.colorScheme.primary)),
                      Expanded(
                          child: Text(
                              _review
                                  ? 'Revisar denuncia'
                                  : 'Denunciar reporte',
                              style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.w700,
                                  color: context.textPrimaryColor))),
                      IconButton(
                          tooltip: 'Cerrar',
                          onPressed:
                              _sending ? null : () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded)),
                    ]),
                  ),
                  Flexible(
                      child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Text(
                              _review
                                  ? 'Puedes añadir contexto antes de enviar tu denuncia.'
                                  : '¿Qué problema tiene esta publicación?',
                              style: TextStyle(
                                  color: context.subtleColor,
                                  fontSize: 14,
                                  height: 1.4)),
                          const SizedBox(height: 18),
                          if (!_review)
                            for (var i = 0; i < _reasons.length; i++)
                              _reasonTile(i)
                          else ...[
                            _reasonTile(_selected!),
                            Align(
                                alignment: Alignment.centerLeft,
                                child: TextButton(
                                    onPressed: _sending
                                        ? null
                                        : () => setState(() => _review = false),
                                    child: const Text('Cambiar motivo'))),
                            const SizedBox(height: 12),
                            TextField(
                              controller: _description,
                              enabled: !_sending,
                              minLines: 3,
                              maxLines: 5,
                              maxLength: 500,
                              decoration: InputDecoration(
                                labelText: 'Detalles adicionales (opcional)',
                                alignLabelWithHint: true,
                                hintText:
                                    'Cuéntanos qué debería revisar moderación.',
                                filled: true,
                                fillColor: context.overlayColor
                                    .withValues(alpha: 0.45),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(16)),
                              ),
                            ),
                            const SizedBox(height: 16),
                            Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Icon(Icons.shield_outlined,
                                      size: 18,
                                      color: theme.colorScheme.secondary),
                                  const SizedBox(width: 8),
                                  Expanded(
                                      child: Text(
                                          'El equipo de moderación revisará tu denuncia.',
                                          style: TextStyle(
                                              fontSize: 12,
                                              height: 1.4,
                                              color: context.subtleColor))),
                                ]),
                            if (_error != null) ...[
                              const SizedBox(height: 16),
                              Semantics(
                                  liveRegion: true,
                                  child: Text(_error!,
                                      style: TextStyle(
                                          color: theme.colorScheme.error,
                                          fontSize: 13))),
                            ],
                          ],
                        ]),
                  )),
                  if (_review)
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      child: SizedBox(
                          width: double.infinity,
                          height: 50,
                          child: FilledButton.icon(
                            onPressed: _sending ? null : _submit,
                            icon: _sending
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Icon(Icons.send_rounded, size: 18),
                            label: Text(
                                _sending ? 'Enviando…' : 'Enviar denuncia'),
                            style: FilledButton.styleFrom(
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(16))),
                          )),
                    ),
                ])),
          ),
        ),
      ),
    );
  }
}
