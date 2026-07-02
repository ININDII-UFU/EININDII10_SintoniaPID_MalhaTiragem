export 'app_config_store_base.dart';

import 'app_config_store_base.dart';
import 'app_config_store_stub.dart'
    if (dart.library.html) 'app_config_store_web.dart'
    if (dart.library.io) 'app_config_store_io.dart';

AppConfigStore createAppConfigStore() => createPlatformConfigStore();
