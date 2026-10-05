import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

enum LegalDocument { terms, privacy }

class LegalDocumentScreen extends StatelessWidget {
  const LegalDocumentScreen({super.key, required this.document});
  final LegalDocument document;

  static const _operator = String.fromEnvironment('LEGAL_OPERATOR_NAME',
      defaultValue: 'Andy Henriquez Luciano');
  static const _contact = String.fromEnvironment('LEGAL_CONTACT_EMAIL',
      defaultValue: 'edsennow@outlook.com');

  static const _terms = [
    (
      title: '1. Qué ofrece RDReporta',
      body:
          'RDReporta permite compartir incidencias ciudadanas, consultar reportes y conocer su ubicación. Las publicaciones son aportaciones de usuarios y no constituyen información oficial verificada. La app no sustituye los servicios de emergencia ni garantiza una respuesta de las autoridades. Ante una emergencia, contacta directamente a los servicios correspondientes.'
    ),
    (
      title: '2. Tu cuenta y tu sesión',
      body:
          'Puedes consultar contenido como invitado o crear una cuenta para participar. Mantén tus datos de acceso protegidos y utiliza información de perfil que tengas derecho a compartir. La sesión se conserva al cerrar la app; puedes finalizarla desde tu perfil. La recuperación de contraseña o una revocación por seguridad pueden requerir un nuevo acceso.'
    ),
    (
      title: '3. Publicaciones responsables',
      body:
          'Publica información relacionada con incidencias, procurando que el texto, los archivos y la ubicación sean correctos. No publiques spam, amenazas, acoso, contenido ilegal, información deliberadamente engañosa ni datos personales de terceros sin autorización. Evita exponer domicilios particulares, documentos, teléfonos o imágenes de menores que permitan identificarlos.'
    ),
    (
      title: '4. Fotos, videos y derechos',
      body:
          'Conservas los derechos que tengas sobre tu contenido. Al publicarlo, autorizas a RDReporta a almacenarlo, mostrarlo dentro del servicio y revisarlo para moderación. Debes contar con autorización para utilizar el material que compartas. Otros usuarios pueden ver o copiar una publicación pública; eliminarla de RDReporta no elimina las copias realizadas fuera del servicio.'
    ),
    (
      title: '5. Moderación y denuncias',
      body:
          'Puedes denunciar una publicación indicando el motivo y detalles adicionales. El equipo de moderación puede revisar denuncias, ocultar contenido o restringir cuentas ante incumplimientos. Una denuncia no implica que el contenido se elimine automáticamente. No utilices esta función para hostigar a otras personas.'
    ),
    (
      title: '6. Ubicación y proveedores externos',
      body:
          'El GPS es opcional y requiere tu permiso. Revisa las coordenadas y la dirección antes de publicar: la ubicación incluida en un reporte será visible para otras personas. Google Maps y los servicios de acceso de Google o Apple tienen sus propias condiciones. La disponibilidad de estas funciones depende también de esos proveedores.'
    ),
    (
      title: '7. Control de tu información',
      body:
          'Puedes editar tu perfil, eliminar tus reportes desde «Mis reportes» y solicitar la eliminación de tu cuenta desde «Perfil > Eliminar mi cuenta». Cerrar sesión o desinstalar la app no elimina los datos guardados en el servidor. Consulta la política de privacidad para conocer los datos que se utilizan y las limitaciones de su eliminación.'
    ),
    (
      title: '8. Disponibilidad y cambios',
      body:
          'El servicio puede presentar interrupciones o errores. Antes de actuar sobre una publicación, verifica la información por otras fuentes. Los cambios relevantes de estas condiciones deben comunicarse dentro de la app antes de aplicarse; esta pantalla identifica la versión que estás consultando.'
    ),
  ];

  static const _privacy = [
    (
      title: '1. Datos de cuenta',
      body:
          'RDReporta utiliza tu correo, nombre de perfil, nombre de usuario y foto de perfil cuando los proporcionas, junto con los identificadores necesarios para gestionar tu cuenta. Si usas Google o Apple, se utilizan los datos autorizados por ese proveedor. El correo y las credenciales no se muestran en los reportes públicos. Tu nombre, usuario y foto de perfil sí pueden ser visibles.'
    ),
    (
      title: '2. Reportes y actividad',
      body:
          'Se almacenan el título, descripción, categoría, fotos o video, dirección, coordenadas y fecha de los reportes que publicas. También se gestionan reacciones, vistas, relaciones de seguimiento, notificaciones y denuncias de moderación. Esta información permite mostrar publicaciones, ordenar contenido y mantener la seguridad de la comunidad. Las denuncias se gestionan por moderación y no se publican como parte del reporte.'
    ),
    (
      title: '3. Permisos y ubicación',
      body:
          'La ubicación se utiliza para buscar incidencias cercanas o completar la dirección de un reporte. Puedes denegar o retirar el permiso en los ajustes del dispositivo y escribir la ubicación manualmente. La ubicación que publiques forma parte de un reporte público. La cámara y la galería se utilizan para los archivos que eliges adjuntar. Las notificaciones requieren el permiso del dispositivo cuando corresponda.'
    ),
    (
      title: '4. Quién puede recibir los datos',
      body:
          'Otros usuarios pueden consultar el contenido y la ubicación de los reportes públicos, así como el perfil de su autor. Los administradores autorizados pueden acceder a información necesaria para gestionar cuentas y moderar contenido. Google o Apple intervienen si eliges sus métodos de acceso; Google Maps interviene al utilizar mapas y Firebase al utilizar sus funciones de notificación. Estos proveedores procesan información según sus propias políticas. Los servidores que alojan RDReporta almacenan los datos necesarios para prestar el servicio.'
    ),
    (
      title: '5. Sesión y protección',
      body:
          'Los tokens de sesión se guardan en el almacenamiento seguro del dispositivo. El servidor almacena las contraseñas y los tokens de renovación mediante mecanismos que evitan guardarlos como texto recuperable. Cerrar sesión elimina las credenciales locales y solicita revocar la renovación cuando hay conexión. Estas medidas no hacen privada una publicación pública ni garantizan que ningún incidente de seguridad pueda ocurrir.'
    ),
    (
      title: '6. Conservación y eliminación',
      body:
          'Los registros de cuenta y actividad permanecen en el servidor mientras se utiliza la cuenta o hasta su eliminación. Puedes eliminar reportes en «Mis reportes» y la cuenta en «Perfil > Eliminar mi cuenta». La eliminación de cuenta retira los registros asociados en la base de datos. Los archivos subidos pueden permanecer hasta su depuración del almacenamiento; las copias externas no se eliminan desde RDReporta. Los plazos de depuración de archivos y copias de respaldo deben concretarse antes del lanzamiento público.'
    ),
    (
      title: '7. Tus opciones',
      body:
          'Puedes corregir los datos disponibles en tu perfil, cambiar permisos desde el dispositivo, cerrar sesión y eliminar contenido o tu cuenta. Para consultas sobre acceso, corrección o eliminación de información, utiliza el contacto de privacidad indicado al final de este documento. No envíes contraseñas ni documentos sensibles al solicitar ayuda.'
    ),
    (
      title: '8. Cambios de esta política',
      body:
          'Si cambian los datos utilizados, sus finalidades, los proveedores o las condiciones de conservación, esta política debe actualizarse y los cambios relevantes deben comunicarse dentro de la app. Revisa la fecha de esta versión para identificar el documento disponible.'
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final privacy = document == LegalDocument.privacy;
    final title = privacy ? 'Política de privacidad' : 'Términos y condiciones';
    final sections = privacy ? _privacy : _terms;
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
          top: false,
          child: Center(
              child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 760),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
              children: [
                Icon(
                    privacy
                        ? Icons.privacy_tip_outlined
                        : Icons.description_outlined,
                    size: 36,
                    color: Theme.of(context).colorScheme.primary),
                const SizedBox(height: 16),
                Text('RDReporta',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimaryColor)),
                const SizedBox(height: 6),
                Text('Versión de desarrollo · 1 de octubre de 2026',
                    style: TextStyle(fontSize: 12, color: context.mutedColor)),
                const SizedBox(height: 16),
                Text(
                    privacy
                        ? 'Conoce qué información utiliza RDReporta y qué controles tienes sobre ella.'
                        : 'Estas condiciones describen el uso de RDReporta y las responsabilidades al compartir incidencias.',
                    style: TextStyle(height: 1.5, color: context.subtleColor)),
                const SizedBox(height: 24),
                for (final section in sections) ...[
                  Text(section.title,
                      style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w700,
                          color: context.textPrimaryColor)),
                  const SizedBox(height: 8),
                  SelectableText(section.body,
                      style: TextStyle(
                          fontSize: 14,
                          height: 1.6,
                          color: context.subtleColor)),
                  const SizedBox(height: 24),
                ],
                Divider(color: context.borderColor),
                const SizedBox(height: 16),
                Text('Responsable y contacto',
                    style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: context.textPrimaryColor)),
                const SizedBox(height: 8),
                SelectableText(
                    _contact.isEmpty
                        ? '$_operator. El canal de contacto de privacidad está pendiente de confirmación antes del lanzamiento público.'
                        : '$_operator\nContacto: $_contact',
                    style: TextStyle(
                        fontSize: 14, height: 1.6, color: context.subtleColor)),
              ],
            ),
          ))),
    );
  }
}
