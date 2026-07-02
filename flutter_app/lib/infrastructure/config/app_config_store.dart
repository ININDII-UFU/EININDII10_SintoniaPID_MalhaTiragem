export 'app_config_store_base.dart';

import 'app_config_store_base.dart';
import 'app_config_store_stub.dart'
    if (dart.library.html) 'app_config_store_web.dart';

AppConfigStore createAppConfigStore() => createPlatformConfigStore();
