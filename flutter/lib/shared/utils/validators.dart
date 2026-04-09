class Validators {
  Validators._();

  static String? required(String? value, [String field = 'Feld']) {
    if (value == null || value.trim().isEmpty) {
      return '$field darf nicht leer sein';
    }
    return null;
  }

  static String? minLength(String? value, int min, [String field = 'Feld']) {
    if (value == null || value.length < min) {
      return '$field muss mindestens $min Zeichen lang sein';
    }
    return null;
  }

  static String? url(String? value) {
    if (value == null || value.isEmpty) return null;
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme) {
      return 'Bitte eine gültige URL eingeben';
    }
    return null;
  }

  static String? serverUrl(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Server-URL darf nicht leer sein';
    }
    final uri = Uri.tryParse(value);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      return 'Bitte eine gültige URL eingeben (z.B. http://192.168.1.100:8000)';
    }
    return null;
  }
}
