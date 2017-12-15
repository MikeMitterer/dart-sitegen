import 'dart:async';
import 'package:sitegen/sitegen.dart';

Future main(List<String> arguments) async {
    final Application application = new Application();
    return await application.run( arguments );
}
