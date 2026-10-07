import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/stationx_app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: Color(0xFF1A1C1E),
    systemNavigationBarIconBrightness: Brightness.light,
  ));
  runApp(const StationXApp());
}
