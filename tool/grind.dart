import 'package:grinder/grinder.dart';

main(final List<String> args) => grind(args);

@Task()
@Depends(test,buildSamples)
build() {
}

@Task()
clean() => defaultClean();

@Task()
@Depends(analyze)
buildSamples() async {
    // Sitegen Sample
    await runAsync("buildSamples",arguments: [ "--sitegen" ]);

    // Update Sample
    await runAsync("buildSamples",arguments: [ "-u" ]);

    // Analyze
    analyze();

    // Build!
    await runAsync("buildSamples",arguments: [ "-bc" ]);
}

@Task()
@Depends(analyze)
test() {
    // new TestRunner().testAsync(files: "test/unit");
    // new TestRunner().testAsync(files: "test/integration");

    // Alle test mit @TestOn("content-shell") im header
    // new TestRunner().test(files: "test/unit",platformSelector: "content-shell");
    // new TestRunner().test(files: "test/integration",platformSelector: "content-shell");
}

@Task()
analyze() {
    final List<String> libs = [
        "lib/sitegen.dart",
        "bin/sitegen.dart"
    ];

    libs.forEach((final String lib) => Analyzer.analyze(lib));
    // Analyzer.analyze("test");
}

@Task('Deploy built app.')
deploy() {
    run(sdkBin('pub'),arguments: [ "global", "activate", "--source", "path", "."]);
}


