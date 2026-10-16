import 'package:flutter_device_info_plus/flutter_device_info_plus.dart';

class DeviceInfoService {
  const DeviceInfoService();

  final FlutterDeviceInfoPlus _deviceInfo = const FlutterDeviceInfoPlus();

  Future<DeviceInformation> getDeviceInfo() => _deviceInfo.getDeviceInfo();
  Future<BatteryInfo?> getBatteryInfo() => _deviceInfo.getBatteryInfo();
  Future<SensorInfo> getSensorInfo() => _deviceInfo.getSensorInfo();
  Future<NetworkInfo> getNetworkInfo() => _deviceInfo.getNetworkInfo();
  String getCurrentPlatform() => _deviceInfo.getCurrentPlatform();

  Future<String> getInfo(String field) async {
    switch (field.toLowerCase().trim()) {
      case 'model':
        final d = await getDeviceInfo();
        return 'Model: ${d.model}';
      case 'manufacturer':
        final d = await getDeviceInfo();
        return 'Manufacturer: ${d.manufacturer}';
      case 'brand':
        final d = await getDeviceInfo();
        return 'Brand: ${d.brand}';
      case 'os':
        final d = await getDeviceInfo();
        return 'Operating System: ${d.operatingSystem}';
      case 'os_version':
        final d = await getDeviceInfo();
        return 'OS Version: ${d.systemVersion}';
      case 'build_number':
        final d = await getDeviceInfo();
        return 'Build Number: ${d.buildNumber}';
      case 'kernel':
        final d = await getDeviceInfo();
        return 'Kernel Version: ${d.kernelVersion}';
      case 'processor':
        final d = await getDeviceInfo();
        final p = d.processorInfo;
        return 'Processor:\nName: ${p.processorName}\nArchitecture: ${p.architecture}\nCores: ${p.coreCount}\nMax Frequency: ${p.maxFrequency}';
      case 'memory':
      case 'ram':
        final d = await getDeviceInfo();
        final m = d.memoryInfo;
        final totalGB = m.totalPhysicalMemory / (1024 * 1024 * 1024);
        final availGB = m.availablePhysicalMemory / (1024 * 1024 * 1024);
        return 'RAM:\nTotal: ${totalGB.toStringAsFixed(1)} GB\nAvailable: ${availGB.toStringAsFixed(1)} GB\nUsage: ${m.memoryUsagePercentage.toStringAsFixed(0)}%';
      case 'storage':
        final d = await getDeviceInfo();
        final volumes = d.storageInfo.volumes;
        if (volumes.isEmpty) return 'Storage information unavailable.';
        return volumes.map((v) {
          final total = v.totalCapacity / (1024 * 1024 * 1024);
          final avail = v.availableCapacity / (1024 * 1024 * 1024);
          return '${v.name}: ${total.toStringAsFixed(1)} GB total, ${avail.toStringAsFixed(1)} GB free';
        }).join('\n');
      case 'display':
        final d = await getDeviceInfo();
        if (d.displays.isEmpty) return 'Display information unavailable.';
        return d.displays.map((disp) =>
          'Display: ${disp.orientation}, density: ${disp.pixelDensity}, refresh: ${disp.refreshRate}').join('\n');
      case 'battery':
        final b = await getBatteryInfo();
        if (b == null) return 'Battery information unavailable.';
        return 'Battery: ${b.batteryLevel}%, charging: ${b.isCharging}';
      case 'sensors':
        final s = await getSensorInfo();
        return 'Sensors: $s';
      case 'network':
        final n = await getNetworkInfo();
        return 'Network: $n';
      case 'all':
        final d = await getDeviceInfo();
        final b = await getBatteryInfo();
        final m = d.memoryInfo;
        final totalGB = m.totalPhysicalMemory / (1024 * 1024 * 1024);
        return '''Device: ${d.model} (${d.manufacturer})
OS: ${d.operatingSystem} ${d.systemVersion}
RAM: ${totalGB.toStringAsFixed(1)} GB
Battery: ${b?.batteryLevel ?? 'N/A'}%
Platform: ${getCurrentPlatform()}''';
      default:
        return 'Unknown field "$field". Supported: model, manufacturer, brand, os, os_version, build_number, kernel, processor, memory, storage, display, battery, sensors, network, all.';
    }
  }
}