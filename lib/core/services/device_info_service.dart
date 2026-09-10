import 'package:flutter_device_info_plus/flutter_device_info_plus.dart';

class DeviceInfoService {
  const DeviceInfoService();

  final FlutterDeviceInfoPlus _deviceInfo = const FlutterDeviceInfoPlus();

  Future<DeviceInformation> getDeviceInfo() {
    return _deviceInfo.getDeviceInfo();
  }

  Future<BatteryInfo?> getBatteryInfo() {
    return _deviceInfo.getBatteryInfo();
  }

  Future<SensorInfo> getSensorInfo() {
    return _deviceInfo.getSensorInfo();
  }

  Future<NetworkInfo> getNetworkInfo() {
    return _deviceInfo.getNetworkInfo();
  }

  String getCurrentPlatform() {
    return _deviceInfo.getCurrentPlatform();
  }
}