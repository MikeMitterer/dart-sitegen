#!/usr/bin/env dart

// Weiterlesen:
//      https://www.dartlang.org/docs/serverguide.html#shell-scripting
//
// Sample:
//      git --git-dir=/Volumes/Daten/DevLocal/DevJava/MobileAdvertising/MobiAd.REST/.git history
//

import 'package:args/args.dart';
import 'dart:io';

const LINE_NUMBER = 'line-number';

ArgResults argResults;

void main(List<String> arguments) {
    final parser = new ArgParser()
        ..addFlag(LINE_NUMBER, negatable: false, abbr: 'n');

    try {
        argResults = parser.parse(arguments);
        List<String> paths = argResults.rest;

        print("ArgResult for $LINE_NUMBER: ${argResults[LINE_NUMBER]}");

        for(final String path in paths) {
            print("Path: $path");
        }

        Process.run('ls', ['-l']).then((ProcessResult results) {
            print(results.stdout);
        });

    } on FormatException catch (error) {
        print("Usage: ...");
    }
}

