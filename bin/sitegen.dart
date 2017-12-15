import 'dart:async';
import 'dart:io';
import 'package:sitegen/sitegen.dart';

Future main(List<String> arguments) async {
    final Application application = new Application();
    exitCode = await application.run( arguments );
}
