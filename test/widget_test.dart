import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:kayflix/core/auth/jwt_payload.dart';
import 'package:kayflix/features/movies/domain/movie.dart';

void main() {
  group('Movie.fromJson', () {
    test('parses the backend payload and splits genres', () {
      final movie = Movie.fromJson({
        'id': 3,
        'title': 'Crimson Static',
        'year': 2024,
        'rating': '16+',
        'duration': '2h 4m',
        'genres': 'Thriller, Suspenseful',
      });

      expect(movie.id, 3);
      expect(movie.title, 'Crimson Static');
      expect(movie.year, 2024);
      expect(movie.genreList, ['Thriller', 'Suspenseful']);
      expect(movie.matchPercent, inInclusiveRange(80, 98));
    });

    test('tolerates missing fields', () {
      final movie = Movie.fromJson({'id': 1});

      expect(movie.title, 'Tanpa Judul');
      expect(movie.yearLabel, '-');
      expect(movie.genreList, isEmpty);
    });
  });

  group('JwtPayload.tryParse', () {
    String tokenWith(Map<String, dynamic> payload) {
      final header = base64Url.encode(utf8.encode('{"alg":"HS256"}')).toString();
      final body = base64Url.encode(utf8.encode(jsonEncode(payload))).toString();
      return '$header.$body.signature';
    }

    test('reads id, email, role and expiry', () {
      final exp = DateTime.now()
          .add(const Duration(hours: 1))
          .millisecondsSinceEpoch ~/ 1000;
      final payload = JwtPayload.tryParse(
        tokenWith({'id': 9, 'email': 'a@b.c', 'role': 'admin', 'exp': exp}),
      );

      expect(payload, isNotNull);
      expect(payload!.id, 9);
      expect(payload.email, 'a@b.c');
      expect(payload.role, 'admin');
      expect(payload.isExpired, isFalse);
    });

    test('marks past tokens as expired', () {
      final exp = DateTime.now()
          .subtract(const Duration(minutes: 1))
          .millisecondsSinceEpoch ~/ 1000;
      final payload = JwtPayload.tryParse(tokenWith({'id': 1, 'exp': exp}));

      expect(payload?.isExpired, isTrue);
    });

    test('returns null for malformed tokens', () {
      expect(JwtPayload.tryParse('not-a-token'), isNull);
    });
  });
}
