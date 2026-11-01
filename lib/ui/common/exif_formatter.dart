// exif_formatter.dart
import 'dart:math';

class ExifFormatter {
  static String formatValue(String fullKey, String rawValue) {
    if (rawValue.isEmpty || rawValue == 'null') return '---';

    // 1. Exposure Time (Direct seconds rational)
    if (fullKey == 'EXIF ExposureTime') {
      return _formatExposureTime(rawValue);
    }

    // 2. Shutter Speed Value (APEX TV units -> converted to seconds)
    if (fullKey == 'EXIF ShutterSpeedValue') {
      return _formatApexShutterSpeed(rawValue);
    }

    // 3. F-Number (Direct ratio)
    if (fullKey == 'EXIF FNumber') {
      return _formatRational(rawValue, prefix: 'f/');
    }

    // 3.5 Flash (Mapped to short descriptions)
    if (fullKey == 'EXIF Flash') {
      return _formatFlash(rawValue);
    }

    // 4. Aperture Value & Max Aperture Value (APEX AV units -> converted to f-number)
    if (fullKey == 'EXIF ApertureValue' || fullKey == 'EXIF MaxApertureValue') {
      return _formatApexAperture(rawValue);
    }

    if (fullKey == 'EXIF MeteringMode') {
      return _formatMeteringMode(rawValue);
    }

    // 5. Focal Length
    if (fullKey == 'GPS FocalLength' ||
        fullKey == 'EXIF FocalLength' ||
        fullKey == 'EXIF FocalLengthIn35mmFilm') {
      return _formatRational(rawValue, suffix: ' mm');
    }

    // 6. GPS Latitude & Longitude (Array parsing into DMS format)
    if (fullKey == 'GPS GPSLatitude' || fullKey == 'GPS GPSLongitude') {
      return _formatGpsCoordinate(rawValue);
    }

    // 7. GPS Altitude (Meters calculation)
    if (fullKey == 'GPS GPSAltitude') {
      return _formatRational(rawValue, suffix: ' m');
    }

    // 8. GPS Altitude Reference (0 = Above Sea Level, 1 = Below Sea Level)
    if (fullKey == 'GPS GPSAltitudeRef') {
      return _formatGpsAltitudeRef(rawValue);
    }

    // 9. GPS Timestamp (Array parsing into HH:MM:SS)
    if (fullKey == 'GPS GPSTimeStamp') {
      return _formatGpsTimeStamp(rawValue);
    }

    // 10. Clean up bracketed byte arrays / MakerNotes (excluding short GPS arrays)
    if (rawValue.startsWith('[') && rawValue.endsWith(']')) {
      if (rawValue.length > 50) {
        return '[Binary Data / Array]';
      }
    }

    return rawValue;
  }

  static String _formatExposureTime(String raw) {
    try {
      final double val = _parseRational(raw);
      if (val <= 0) return raw;

      if (val >= 1) {
        return '${val.toStringAsFixed(1)} s';
      } else {
        final reciprocal = (1 / val).round();
        if ((val - (1 / reciprocal)).abs() < 0.01) {
          return '1/$reciprocal s';
        }
        return '${val.toStringAsFixed(4)} s';
      }
    } catch (_) {
      return '$raw s';
    }
  }

  static String _formatApexShutterSpeed(String raw) {
    try {
      final double tv = _parseRational(raw);
      final double seconds = pow(2, -tv).toDouble();
      return _formatExposureTime(seconds.toString());
    } catch (_) {
      return raw;
    }
  }

  static String _formatApexAperture(String raw) {
    try {
      final double av = _parseRational(raw);
      final double fNumber = pow(2, av / 2).toDouble();
      return 'f/${fNumber.toStringAsFixed(1)}';
    } catch (_) {
      return 'f/$raw';
    }
  }

  static String _formatGpsCoordinate(String raw) {
    try {
      String cleaned = raw.trim();
      if (cleaned.startsWith('[') && cleaned.endsWith(']')) {
        cleaned = cleaned.substring(1, cleaned.length - 1);
      }
      final parts = cleaned.split(',');
      if (parts.length >= 3) {
        final deg = _parseRational(parts[0].trim());
        final min = _parseRational(parts[1].trim());
        final sec = _parseRational(parts[2].trim());
        return "${deg.toInt()}° ${min.toInt()}' ${sec.toStringAsFixed(2)}\"";
      }
    } catch (_) {}
    return raw;
  }

  static String _formatGpsAltitudeRef(String raw) {
    try {
      final double val = _parseRational(raw);
      if (val == 0.0) return 'Above Sea Level';
      if (val == 1.0) return 'Below Sea Level';
    } catch (_) {}
    return raw;
  }

  static String _formatGpsTimeStamp(String raw) {
    try {
      String cleaned = raw.trim();
      if (cleaned.startsWith('[') && cleaned.endsWith(']')) {
        cleaned = cleaned.substring(1, cleaned.length - 1);
      }
      final parts = cleaned.split(',');
      if (parts.length >= 3) {
        final hours = _parseRational(parts[0].trim()).toInt();
        final minutes = _parseRational(parts[1].trim()).toInt();
        final seconds = _parseRational(parts[2].trim()).toInt();

        final hStr = hours.toString().padLeft(2, '0');
        final mStr = minutes.toString().padLeft(2, '0');
        final sStr = seconds.toString().padLeft(2, '0');

        return '$hStr:$mStr:$sStr';
      }
    } catch (_) {}
    return raw;
  }

  static String _formatRational(String raw,
      {String prefix = '', String suffix = ''}) {
    try {
      final double val = _parseRational(raw);
      return '$prefix${val.toStringAsFixed(2)}$suffix';
    } catch (_) {
      return '$prefix$raw$suffix';
    }
  }

  static double _parseRational(String raw) {
    if (raw.contains('/')) {
      final parts = raw.split('/');
      final num = double.parse(parts[0].trim());
      final den = double.parse(parts[1].trim());
      if (den == 0) return 0.0;
      return num / den;
    } else {
      return double.parse(raw);
    }
  }

  static String _formatFlash(String raw) {
    const flashMap = {
      'Flash did not fire': 'No',
      'Flash fired': 'Yes',
      'Flash did not fire, compulsory flash mode': 'No, Compulsory',
      'Flash did not fire, compulsory flash suppression': 'No, Suppressed',
      'Flash did not fire, auto mode': 'No, Auto',
      'Flash fired, compulsory flash mode': 'Yes, Compulsory',
      'Flash fired, auto mode': 'Yes, Auto',
      'Flash fired, auto mode, red-eye reduction': 'Yes, Auto, Red-Eye',
      'Flash fired, red-eye reduction mode': 'Yes, Red-Eye',
      'Flash did not fire, red-eye reduction mode': 'No, Red-Eye',
      'Flash fired, return light not detected': 'Yes (No Return)',
      'Flash fired, return light detected': 'Yes (Return)',
    };

    // Return the mapped short version, or fall back to the raw string if it's unfamiliar
    return flashMap[raw.trim()] ?? raw;
  }

  static String _formatMeteringMode(String raw) {
    const meteringMap = {
      'CenterWeightedAverage': 'Center-Weighted Average',
      'Average': 'Average',
      'Spot': 'Spot',
      'MultiSpot': 'Multi-Spot',
      'Pattern': 'Matrix / Pattern',
      'Matrix': 'Matrix / Pattern',
      'Partial': 'Partial',
      'Unknown': 'Unknown',
      'Other': 'Other',
    };

    return meteringMap[raw.trim()] ?? raw;
  }
}
