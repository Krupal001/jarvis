import 'package:installed_apps/app_info.dart';
import 'package:installed_apps/installed_apps.dart';

class UninstallAppService {
  Future<String> uninstallApp(String packageName) async {
    // Implementation for uninstalling an app
    // This would typically use platform channels to call native code
    List<AppInfo> apps = await InstalledApps.getInstalledApps();
    print('All apps: ${apps.map((app) => app.name).toList()}');
    
    // Find the app with the given package name and uninstall it
    for (var app in apps) {
      if (app.name.toLowerCase() == packageName.toLowerCase()) {
        await InstalledApps.uninstallApp(app.packageName);
        return '${app.name} uninstalled successfully';
      }
      if(app.isSystemApp) {
        return '${app.name} is a system app and it cannot be uninstalled';
      }
    }
    return 'App not found with package name: $packageName';
  }
}