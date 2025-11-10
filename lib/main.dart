import 'package:flutter/material.dart';
import 'app.dart';
import 'shared/services/supabase_client.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Supa.init();
  runApp(const TesiXpressApp());
}
