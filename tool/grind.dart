import 'package:grinder/grinder.dart';

main(args) => grind(args);

@Task()
@Depends(test,buildSamples)
build() {
}

@Task()
@Depends(analyze)
buildSamples() async {
    // Sitegen Sample
    await runAsync("/Users/mikemitterer/.pub-cache/bin/buildSamples",arguments: [ "--sitegen" ]);

    // Update Sample
    await runAsync("/Users/mikemitterer/.pub-cache/bin/buildSamples",arguments: [ "-u" ]);

    // Analyze
    analyze();

    // Build!
    await runAsync("/Users/mikemitterer/.pub-cache/bin/buildSamples",arguments: [ "-bc" ]);
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

    final List<String> samples = [
        "simple/web/main.dart"
    ];

    libs.forEach((final String lib) => Analyzer.analyze(lib));

    // samples.forEach((final String sample ) {
    //    final String sampleFolder = sample.replaceAll("/web/main.dart","");
    //    run("tool/scripts/analyze-sample.sh",arguments: [ "samples/${sampleFolder}", "web/main.dart" ]);
    // });

    // Analyzer.analyze("test");
}
@Task()
clean() => defaultClean();
