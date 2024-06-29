import 'dart:developer';

class Util {
  static List<(String resolution, String endpoint)> searchResolutions(
      String data) {
    final regex = RegExp(
      r'#EXT-X-STREAM-INF:(?:.*,RESOLUTION=(\d+x\d+))?,?(.*)\r?\n(.*)',
      caseSensitive: false,
      multiLine: true,
    );
    final matches = regex.allMatches(data);
    return matches.map((e) {
      log(
        'group 0',
        error: e.group(0),
        level: 10000,
      );
      log(
        'group 1', //resolution
        error: e.group(1),
        level: 10000,
      );
      log(
        'group 2',
        error: e.group(2),
        level: 10000,
      );
      log(
        'group 3', //endpoint
        error: e.group(3),
        level: 10000,
      );
      return (e.group(1) ?? '', e.group(3) ?? '');
    }).toList();
  }
}
