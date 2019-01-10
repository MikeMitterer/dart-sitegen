import 'package:console_log_handler/console_log_handler.dart';

import 'package:m4d_core/m4d_ioc.dart' as ioc;
import "package:m4d_components/m4d_components.dart";

final Logger _logger = new Logger('I am your logger');

main() async {
    configLogging();

    ioc.Container.bindModules([ CoreComponentsModule() ]);

    await componentFactory().upgrade().then((_) {
        _logger.info("Upgraded!");
    });
}
