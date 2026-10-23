/// Cuenta de Cloudinary donde se guardan las fotos y videos de evidencia.
///
/// El proyecto usa el plan Spark de Firebase, que no incluye Storage, así
/// que las evidencias se suben a Cloudinary y en Firestore solo se guarda
/// su URL.
///
/// Para configurarlo, en el panel de Cloudinary:
/// 1. Copia el *Cloud name* del Dashboard en [cloudName].
/// 2. En Settings → Upload → Upload presets, crea un preset con
///    *Signing mode: Unsigned* y pon su nombre en [uploadPreset].
abstract final class CloudinaryConfig {
  static const String cloudName = 'a60rrjpn';
  static const String uploadPreset = 'n752cjos';

  /// Carpeta raíz de las evidencias dentro de la cuenta.
  static const String folder = 'fixo';
}
