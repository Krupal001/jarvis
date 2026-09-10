import 'dart:convert';

import 'package:flutter_gemma_agent/flutter_gemma_agent.dart';
import 'package:flutter_gemma_demo/core/services/device_info_service.dart';

class DeviceInfoSkillExecutor extends SkillExecutor {
  final DeviceInfoService deviceInfoService;

  DeviceInfoSkillExecutor({
    required this.deviceInfoService,
  });

  @override
  String get name => 'device-info-executor';

  @override
  int get priority => 0;

  @override
  bool canExecute(String skillType) {
    return skillType == 'text';
  }

  @override
  bool canExecuteSkill(Skill skill) {
    return skill.name == 'device-info' &&
        skill.type == SkillType.textOnly;
  }

  @override
  Future<SkillResult> execute(
    Skill skill,
    String dataJson, {
    String? secret,
  }) async {
    try {
      final input = _parseInput(dataJson);

      final category = _getCategory(input);

      final result = await _getRequestedInformation(category);

      return TextResult(
        result,
      );
    } catch (e) {
      return TextResult(
        'Unable to get device information: $e',
      );
    }
  }

  Map<String, dynamic> _parseInput(String dataJson) {
    if (dataJson.trim().isEmpty) {
      return {};
    }

    final decoded = jsonDecode(dataJson);

    if (decoded is Map<String, dynamic>) {
      return decoded;
    }

    return {
      'request': dataJson,
    };
  }

  String _getCategory(Map<String, dynamic> input) {
    final category = input['category'] ?? input['request'];

    if (category == null) {
      return 'all';
    }

    return category.toString().toLowerCase();
  }

  Future<String> _getRequestedInformation(String category) async {
    if (_isAllRequest(category)) {
      return _getAllInformation();
    }

    if (_isRamRequest(category)) {
      return _getRamInformation();
    }

    if (_isStorageRequest(category)) {
      return _getStorageInformation();
    }

    if (_isBatteryRequest(category)) {
      return _getBatteryInformation();
    }

    if (_isProcessorRequest(category)) {
      return _getProcessorInformation();
    }

    if (_isDisplayRequest(category)) {
      return _getDisplayInformation();
    }

    if (_isNetworkRequest(category)) {
      return _getNetworkInformation();
    }

    if (_isSensorRequest(category)) {
      return _getSensorInformation();
    }

    if (_isSecurityRequest(category)) {
      return _getSecurityInformation();
    }

    if (_isDeviceRequest(category)) {
      return _getBasicDeviceInformation();
    }

    return _getAllInformation();
  }

  Future<String> _getAllInformation() async {
    final platform = deviceInfoService.getCurrentPlatform();
    final device = await deviceInfoService.getDeviceInfo();
    final battery = await deviceInfoService.getBatteryInfo();
    final sensors = await deviceInfoService.getSensorInfo();
    final network = await deviceInfoService.getNetworkInfo();

    final buffer = StringBuffer();

    buffer.writeln('Platform: $platform');

    buffer.writeln('\nDevice Information:');
    buffer.writeln('Device ID: ${device.deviceId}');
    buffer.writeln('Name: ${device.deviceName}');
    buffer.writeln('Manufacturer: ${device.manufacturer}');
    buffer.writeln('Model: ${device.model}');
    buffer.writeln('Brand: ${device.brand}');

    buffer.writeln('\nSystem Information:');
    buffer.writeln('OS: ${device.operatingSystem}');
    buffer.writeln('Version: ${device.systemVersion}');
    buffer.writeln('Build: ${device.buildNumber}');
    buffer.writeln('Kernel: ${device.kernelVersion}');

    buffer.writeln('\nProcessor:');
    buffer.writeln(
      'Architecture: ${device.processorInfo.architecture}',
    );
    buffer.writeln(
      'Cores: ${device.processorInfo.coreCount}',
    );
    buffer.writeln(
      'Max Frequency: ${device.processorInfo.maxFrequency} MHz',
    );
    buffer.writeln(
      'Name: ${device.processorInfo.processorName}',
    );
    buffer.writeln(
      'Features: ${device.processorInfo.features.join(', ')}',
    );

    buffer.writeln('\nMemory:');
    buffer.writeln(
      'Total RAM: ${device.memoryInfo.totalPhysicalMemoryMB.toStringAsFixed(0)} MB',
    );
    buffer.writeln(
      'Available RAM: ${device.memoryInfo.availablePhysicalMemoryMB.toStringAsFixed(0)} MB',
    );
    buffer.writeln(
      'Memory Usage: ${device.memoryInfo.memoryUsagePercentage.toStringAsFixed(1)}%',
    );

    buffer.writeln('\nStorage:');

    for (final volume in device.storageInfo.volumes) {
      final totalGB =
          volume.totalCapacity / (1024 * 1024 * 1024);
      final availableGB =
          volume.availableCapacity / (1024 * 1024 * 1024);

      buffer.writeln(
        '${volume.name ?? volume.mountPath}: '
        '${totalGB.toStringAsFixed(1)} GB total, '
        '${availableGB.toStringAsFixed(1)} GB available',
      );
    }

    buffer.writeln('\nDisplay:');

    for (var i = 0; i < device.displays.length; i++) {
      final display = device.displays[i];

      buffer.writeln(
        'Display ${i + 1}: '
        '${display.resolutionString}, '
        '${display.refreshRate} Hz, '
        '${display.pixelDensity}x, '
        'HDR: ${display.isHdr ? 'Yes' : 'No'}',
      );
    }

    buffer.writeln('\nBattery:');

    if (battery != null) {
      buffer.writeln('Level: ${battery.batteryLevel}%');
      buffer.writeln('Status: ${battery.chargingStatus}');
      buffer.writeln('Health: ${battery.batteryHealth}');
      buffer.writeln('Capacity: ${battery.batteryCapacity} mAh');
      buffer.writeln(
        'Voltage: ${battery.batteryVoltage.toStringAsFixed(2)} V',
      );
      buffer.writeln(
        'Temperature: ${battery.batteryTemperature.toStringAsFixed(1)}°C',
      );
      buffer.writeln('Charging: ${battery.isCharging ? 'Yes' : 'No'}');
      buffer.writeln(
        'Low Battery: ${battery.isLowBattery ? 'Yes' : 'No'}',
      );
    }

    buffer.writeln('\nSensors:');
    buffer.writeln('Total: ${sensors.sensorCount}');
    buffer.writeln(
      'Available: ${sensors.availableSensors.join(', ')}',
    );

    buffer.writeln('\nNetwork:');
    buffer.writeln('Type: ${network.connectionType}');
    buffer.writeln('Speed: ${network.networkSpeed}');
    buffer.writeln(
      'Connected: ${network.isConnected ? 'Yes' : 'No'}',
    );
    buffer.writeln('IP: ${network.ipAddress}');
    buffer.writeln(
      'VPN: ${network.isVpn ? 'Active' : 'Inactive'}',
    );

    buffer.writeln('\nSecurity:');
    buffer.writeln(
      'Device Secure: '
      '${device.securityInfo.isDeviceSecure ? 'Yes' : 'No'}',
    );
    buffer.writeln(
      'Fingerprint: '
      '${device.securityInfo.hasFingerprint ? 'Available' : 'Not Available'}',
    );
    buffer.writeln(
      'Face Unlock: '
      '${device.securityInfo.hasFaceUnlock ? 'Available' : 'Not Available'}',
    );
    buffer.writeln(
      'Screen Lock: '
      '${device.securityInfo.screenLockEnabled ? 'Enabled' : 'Disabled'}',
    );
    buffer.writeln(
      'Encryption: ${device.securityInfo.encryptionStatus}',
    );
    buffer.writeln(
      'Security Score: ${device.securityInfo.securityScore}/100',
    );
    buffer.writeln(
      'Security Level: ${device.securityInfo.securityLevel}',
    );

    return buffer.toString();
  }

  Future<String> _getBasicDeviceInformation() async {
    final device = await deviceInfoService.getDeviceInfo();

    return '''
Device: ${device.deviceName}
Manufacturer: ${device.manufacturer}
Model: ${device.model}
Brand: ${device.brand}
OS: ${device.operatingSystem}
Version: ${device.systemVersion}
Build: ${device.buildNumber}
Kernel: ${device.kernelVersion}
''';
  }

  Future<String> _getProcessorInformation() async {
    final device = await deviceInfoService.getDeviceInfo();
    final processor = device.processorInfo;

    return '''
Processor: ${processor.processorName}
Architecture: ${processor.architecture}
Cores: ${processor.coreCount}
Max Frequency: ${processor.maxFrequency} MHz
Features: ${processor.features.join(', ')}
''';
  }

  Future<String> _getRamInformation() async {
    final device = await deviceInfoService.getDeviceInfo();
    final memory = device.memoryInfo;

    return '''
Total RAM: ${memory.totalPhysicalMemoryMB.toStringAsFixed(0)} MB
Available RAM: ${memory.availablePhysicalMemoryMB.toStringAsFixed(0)} MB
Memory Usage: ${memory.memoryUsagePercentage.toStringAsFixed(1)}%
''';
  }

  Future<String> _getStorageInformation() async {
    final device = await deviceInfoService.getDeviceInfo();

    if (device.storageInfo.volumes.isEmpty) {
      return 'No storage volumes found.';
    }

    final buffer = StringBuffer();

    for (final volume in device.storageInfo.volumes) {
      final totalGB =
          volume.totalCapacity / (1024 * 1024 * 1024);
      final availableGB =
          volume.availableCapacity / (1024 * 1024 * 1024);

      buffer.writeln(
        '${volume.name ?? volume.mountPath}: '
        '${totalGB.toStringAsFixed(1)} GB total, '
        '${availableGB.toStringAsFixed(1)} GB available',
      );
    }

    return buffer.toString();
  }

  Future<String> _getBatteryInformation() async {
    final battery = await deviceInfoService.getBatteryInfo();

    if (battery == null) {
      return 'Battery information is not available.';
    }

    return '''
Battery Level: ${battery.batteryLevel}%
Status: ${battery.chargingStatus}
Health: ${battery.batteryHealth}
Capacity: ${battery.batteryCapacity} mAh
Voltage: ${battery.batteryVoltage.toStringAsFixed(2)} V
Temperature: ${battery.batteryTemperature.toStringAsFixed(1)}°C
Charging: ${battery.isCharging ? 'Yes' : 'No'}
Low Battery: ${battery.isLowBattery ? 'Yes' : 'No'}
''';
  }

  Future<String> _getDisplayInformation() async {
    final device = await deviceInfoService.getDeviceInfo();

    if (device.displays.isEmpty) {
      return 'No display information available.';
    }

    final buffer = StringBuffer();

    for (var i = 0; i < device.displays.length; i++) {
      final display = device.displays[i];

      buffer.writeln('Display ${i + 1}:');
      buffer.writeln('Resolution: ${display.resolutionString}');
      buffer.writeln('Density: ${display.pixelDensity}x');
      buffer.writeln('Refresh Rate: ${display.refreshRate} Hz');
      buffer.writeln('Orientation: ${display.orientation}');
      buffer.writeln('HDR: ${display.isHdr ? 'Yes' : 'No'}');
    }

    return buffer.toString();
  }

  Future<String> _getNetworkInformation() async {
    final network = await deviceInfoService.getNetworkInfo();

    return '''
Connection Type: ${network.connectionType}
Network Speed: ${network.networkSpeed}
Connected: ${network.isConnected ? 'Yes' : 'No'}
IP Address: ${network.ipAddress}
VPN: ${network.isVpn ? 'Active' : 'Inactive'}
WiFi: ${network.connectionType == 'wifi' ? 'Yes' : 'No'}
Mobile: ${network.connectionType == 'mobile' ? 'Yes' : 'No'}
Ethernet: ${network.isEthernetConnected ? 'Yes' : 'No'}
''';
  }

  Future<String> _getSensorInformation() async {
    final sensors = await deviceInfoService.getSensorInfo();

    return '''
Total Sensors: ${sensors.sensorCount}
Accelerometer: ${sensors.hasAccelerometer ? 'Available' : 'Not Available'}
Gyroscope: ${sensors.hasGyroscope ? 'Available' : 'Not Available'}
Magnetometer: ${sensors.hasMagnetometer ? 'Available' : 'Not Available'}
Proximity: ${sensors.hasProximity ? 'Available' : 'Not Available'}
Light Sensor: ${sensors.hasLightSensor ? 'Available' : 'Not Available'}
Barometer: ${sensors.hasBarometer ? 'Available' : 'Not Available'}
Step Counter: ${sensors.hasStepCounter ? 'Available' : 'Not Available'}
Heart Rate: ${sensors.hasHeartRate ? 'Available' : 'Not Available'}
Available Sensors: ${sensors.availableSensors.join(', ')}
''';
  }

  Future<String> _getSecurityInformation() async {
    final device = await deviceInfoService.getDeviceInfo();
    final security = device.securityInfo;

    return '''
Device Secure: ${security.isDeviceSecure ? 'Yes' : 'No'}
Fingerprint: ${security.hasFingerprint ? 'Available' : 'Not Available'}
Face Unlock: ${security.hasFaceUnlock ? 'Available' : 'Not Available'}
Screen Lock: ${security.screenLockEnabled ? 'Enabled' : 'Disabled'}
Encryption: ${security.encryptionStatus}
Security Score: ${security.securityScore}/100
Security Level: ${security.securityLevel}
''';
  }

  bool _isAllRequest(String value) {
    return value.contains('all') ||
        value.contains('spec') ||
        value.contains('detail');
  }

  bool _isRamRequest(String value) {
    return value.contains('ram') ||
        value.contains('memory');
  }

  bool _isStorageRequest(String value) {
    return value.contains('storage') ||
        value.contains('space') ||
        value.contains('disk');
  }

  bool _isBatteryRequest(String value) {
    return value.contains('battery') ||
        value.contains('charging');
  }

  bool _isProcessorRequest(String value) {
    return value.contains('processor') ||
        value.contains('cpu') ||
        value.contains('chip');
  }

  bool _isDisplayRequest(String value) {
    return value.contains('display') ||
        value.contains('screen') ||
        value.contains('resolution');
  }

  bool _isNetworkRequest(String value) {
    return value.contains('network') ||
        value.contains('wifi') ||
        value.contains('internet') ||
        value.contains('ip');
  }

  bool _isSensorRequest(String value) {
    return value.contains('sensor') ||
        value.contains('accelerometer') ||
        value.contains('gyroscope');
  }

  bool _isSecurityRequest(String value) {
    return value.contains('security') ||
        value.contains('fingerprint') ||
        value.contains('face unlock') ||
        value.contains('encryption');
  }

  bool _isDeviceRequest(String value) {
    return value.contains('device') ||
        value.contains('phone') ||
        value.contains('model') ||
        value.contains('manufacturer');
  }
}