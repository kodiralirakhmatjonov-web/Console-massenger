import 'package:cryptography_flutter/cryptography_flutter.dart';
import 'package:flutter/cupertino.dart';

import 'app.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  FlutterCryptography.enable();
  runApp(const ConsoleApp());
}
