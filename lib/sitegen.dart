library sitegen;

import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:intl/intl.dart';
import 'package:args/args.dart';
import 'package:where/where.dart';

import 'package:logging/logging.dart';
import 'package:console_log_handler/print_log_handler.dart';

import 'package:validate/validate.dart';

import "package:path/path.dart" as path;
import "package:markdown/markdown.dart" as md;
import "package:mustache/mustache.dart" as mustache;
import "package:yaml/yaml.dart" as yaml;

import 'package:http_server/http_server.dart';
import 'package:system_info/system_info.dart';
import 'package:packages/packages.dart';

part "src/Application.dart";
part "src/CommandManager.dart";
part "src/Options.dart";
part "src/Config.dart";
part "src/Init.dart";

part "src/Generator.dart";

bool _runsOnOSX() => (SysInfo.operatingSystemName == "Mac OS X");

// final _commands = new List<CommandWrapper>();

Future main(List<String> arguments) async {
    final Application application = new Application();

    application.run( arguments );
}




