import 'package:flutter_test/flutter_test.dart';
import 'package:locket_ai/viewmodels/user_viewmodel.dart';

void main() {
  test('resolveDisplayUrl returns original for non-blob URLs', () async {
    final vm = UserViewModel();
    final url = 'https://example.com/image.png';
    final jwt = 'token';
    final resolved = await vm.resolveDisplayUrl(jwt: jwt, url: url);
    expect(resolved, url);
    final resolved2 = await vm.resolveDisplayUrl(jwt: jwt, url: url);
    expect(resolved2, url);
  });
}