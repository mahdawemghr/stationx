import 'package:flutter_test/flutter_test.dart';
import 'package:stationx/domain/domain.dart';

void main() {
  group('Username.normalize', () {
    test('trims and lowercases', () {
      expect(Username.normalize('  Iron_SAM \n'), 'iron_sam');
    });
    test('does not touch inner characters', () {
      expect(Username.normalize('A B'), 'a b');
    });
  });

  group('Username.validate', () {
    final good = [
      'abc',
      'sam',
      'Iron_Sam',
      'a.b-c_1',
      'user123',
      'x1y',
      ' padded ',
      'a' * 24,
      '007',
      'a-b',
      'a.b',
    ];
    for (final g in good) {
      test('accepts "$g"', () => expect(Username.validate(g), isNull));
    }

    final bad = <String, String>{
      '': 'Choose a username',
      '   ': 'Choose a username',
      'ab': 'at least 3',
      'a' * 25: 'at most 24',
      'sam smith': 'no spaces',
      'sam@mail.com': 'Use only letters',
      'émile': 'Use only letters', // unicode letters are not allowed
      'سلام123': 'Use only letters',
      'sam😀': 'Use only letters',
      'İstanbul': 'Use only letters',
      '_sam': 'Start and end',
      'sam_': 'Start and end',
      '.sam': 'Start and end',
      'sam-': 'Start and end',
      '-sam': 'Start and end',
      'sa..m': 'two dots',
      'admin': 'reserved',
      'ADMIN': 'reserved',
      ' Root ': 'reserved',
      'support': 'reserved',
      'stationx': 'reserved',
      'null': 'reserved',
    };
    bad.forEach((input, fragment) {
      test('rejects "$input"', () {
        final m = Username.validate(input);
        expect(m, isNotNull);
        expect(m, contains(fragment));
      });
    });

    test('length edges: 3 and 24 pass, 2 and 25 fail', () {
      expect(Username.validate('a' * 3), isNull);
      expect(Username.validate('a' * 24), isNull);
      expect(Username.validate('a' * 2), isNotNull);
      expect(Username.validate('a' * 25), isNotNull);
    });

    test('a single dot or dash inside is fine, a double dash too', () {
      expect(Username.validate('a.b'), isNull);
      expect(Username.validate('a--b'), isNull);
    });
  });

  group('identifier mapping', () {
    test('toIdentifier is normalised and uses the private domain', () {
      expect(Username.toIdentifier('  Iron_Sam '), 'iron_sam@stationx.local');
    });
    test('round-trips', () {
      for (final u in ['sam', 'a.b-c_1', 'x' * 24]) {
        expect(Username.fromIdentifier(Username.toIdentifier(u)), u);
      }
    });
    test(
      'fromIdentifier is case-insensitive and rejects foreign addresses',
      () {
        expect(Username.fromIdentifier('SAM@StationX.Local'), 'sam');
        expect(Username.fromIdentifier('sam@gmail.com'), isNull);
        expect(Username.fromIdentifier('@stationx.local'), isNull);
        expect(Username.fromIdentifier(''), isNull);
      },
    );
    test('the password never appears in an identifier', () {
      expect(Username.toIdentifier('sam'), isNot(contains('Secret1')));
    });
  });

  group('PasswordPolicy', () {
    test('rules', () {
      expect(PasswordPolicy.rules(''), [false, false, false]);
      expect(PasswordPolicy.rules('abcdefgh'), [true, false, false]);
      expect(PasswordPolicy.rules('Abcdefg1'), [true, true, true]);
      expect(PasswordPolicy.isStrong('Abcdef1'), isFalse); // 7 chars
      expect(PasswordPolicy.isStrong('abcdefg1'), isFalse); // no capital
      expect(PasswordPolicy.isStrong('Abcdefgh'), isFalse); // no digit
      expect(PasswordPolicy.isStrong('Abcdefg1'), isTrue);
    });
  });
}
