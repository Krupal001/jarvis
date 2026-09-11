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

      final field = input['field']?.toString().toLowerCase().trim();

      if (field == null || field.isEmpty) {
        return const TextResult(
          'Unable to determine the requested device information.',
        );
      }

      final result = await _getRequestedInformation(field);

      return TextResult(result);
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

    try {
      final decoded = jsonDecode(dataJson);

      if (decoded is Map<String, dynamic>) {
        return decoded;
      }

      return {
        'field': dataJson,
      };
    } catch (_) {
      return {
        'field': dataJson,
      };
    }
  }

  Future<String> _getRequestedInformation(String field) async {
    switch (field) {
      case 'model':
        return _getModel();

      case 'manufacturer':
        return _getManufacturer();

      case 'brand':
        return _getBrand();

      case 'os':
        return _getOperatingSystem();

      case 'os_version':
        return _getOsVersion();

      case 'build_number':
        return _getBuildNumber();

      case 'kernel':
        return _getKernel();

      case 'processor':
        return _getProcessor();

      case 'memory':
      case 'ram':
        return _getMemory();

      case 'storage':
        return _getStorage();

      case 'display':
        return _getDisplay();

      case 'battery':
        return _getBattery();

      case 'sensors':
        return _getSensors();

      case 'network':
        return _getNetwork();

      case 'all':
        return _getAllInformation();

      default:
        return 'Unsupported device information request: $field';
    }
  }

  // ---------------------------------------------------------------------------
  // Device
  // ---------------------------------------------------------------------------

  Future<String> _getModel() async {
    final device = await deviceInfoService.getDeviceInfo();

    return 'Model: ${device.model}';
  }

  Future<String> _getManufacturer() async {
    final device = await deviceInfoService.getDeviceInfo();

    return 'Manufacturer: ${device.manufacturer}';
  }

  Future<String> _getBrand() async {
    final device = await deviceInfoService.getDeviceInfo();

    return 'Brand: ${device.brand}';
  }

  // ---------------------------------------------------------------------------
  // Operating System
  // ---------------------------------------------------------------------------

  Future<String> _getOperatingSystem() async {
    final device = await deviceInfoService.getDeviceInfo();

    return 'Operating System: ${device.operatingSystem}';
  }

  Future<String> _getOsVersion() async {
    final device = await deviceInfoService.getDeviceInfo();

    return 'OS Version: ${device.systemVersion}';
  }

  Future<String> _getBuildNumber() async {
    final device = await deviceInfoService.getDeviceInfo();

    return 'Build Number: ${device.buildNumber}';
  }

  Future<String> _getKernel() async {
    final device = await deviceInfoService.getDeviceInfo();

    return 'Kernel Version: ${device.kernelVersion}';
  }

  // ---------------------------------------------------------------------------
  // Processor
  // ---------------------------------------------------------------------------

  Future<String> _getProcessor() async {
    final device = await deviceInfoService.getDeviceInfo();
    final processor = device.processorInfo;

    return '''
Processor:
Name: ${processor.processorName}
Architecture: ${processor.architecture}
Core Count: ${processor.coreCount}
Max Frequency: ${processor.maxFrequency}
Features: ${processor.features.join(', ')}
''';
  }

  // ---------------------------------------------------------------------------
  // Memory
  // ---------------------------------------------------------------------------

  Future<String> _getMemory() async {
    final device = await deviceInfoService.getDeviceInfo();
    final memory = device.memoryInfo;

    final totalGB = memory.totalPhysicalMemory / (1024 * 1024 * 1024);
    final availableGB = memory.availablePhysicalMemory / (1024 * 1024 * 1024);

    return '''
Memory (RAM):
Total: ${totalGB.toStringAsFixed(1)} GB
Available: ${availableGB.toStringAsFixed(1)} GB
Usage: ${memory.memoryUsagePercentage.toStringAsFixed(0)}%
''';
  }

  // ---------------------------------------------------------------------------
  // Storage
  // ---------------------------------------------------------------------------

  Future<String> _getStorage() async {
    final device = await deviceInfoService.getDeviceInfo();
    final storage = device.storageInfo;

    if (storage.volumes.isEmpty) {
      return 'Storage information is unavailable.';
    }

    final volumes = storage.volumes.map((volume) {
      final totalGB = volume.totalCapacity / (1024 * 1024 * 1024);
      final availableGB = volume.availableCapacity / (1024 * 1024 * 1024);
      final usedGB = volume.usedCapacity / (1024 * 1024 * 1024);
      return '''
Volume: ${volume.name}
Mount Path: ${volume.mountPath}
Total Capacity: ${totalGB.toStringAsFixed(1)} GB
Available Capacity: ${availableGB.toStringAsFixed(1)} GB
Used Capacity: ${usedGB.toStringAsFixed(1)} GB
Removable: ${volume.isRemovable}
''';
    }).join('\n');

    return 'Storage (ROM):\n$volumes';
  }

  // ---------------------------------------------------------------------------
  // Display
  // ---------------------------------------------------------------------------

  Future<String> _getDisplay() async {
    final device = await deviceInfoService.getDeviceInfo();

    if (device.displays.isEmpty) {
      return 'Display information is unavailable.';
    }

    final displays = device.displays.map((display) {
      return '''
Resolution: ${display.orientation}
Pixel Density: ${display.pixelDensity}
Refresh Rate: ${display.refreshRate}
Primary: ${display.isPrimary}
''';
    }).join('\n');

    return 'Display:\n$displays';
  }

  // ---------------------------------------------------------------------------
  // Battery
  // ---------------------------------------------------------------------------

  Future<String> _getBattery() async {
    final battery = await deviceInfoService.getBatteryInfo();

    if (battery == null) {
      return 'Battery information is unavailable.';
    }

    return '''
Battery:
Percentage: ${battery.batteryLevel}%
Charging: ${battery.isCharging}
Status: ${battery.batteryCapacity}
''';
  }

  // ---------------------------------------------------------------------------
  // Sensors
  // ---------------------------------------------------------------------------

  Future<String> _getSensors() async {
    final sensors = await deviceInfoService.getSensorInfo();

    return 'Sensors:\n$sensors';
  }

  // ---------------------------------------------------------------------------
  // Network
  // ---------------------------------------------------------------------------

  Future<String> _getNetwork() async {
    final network = await deviceInfoService.getNetworkInfo();

    return 'Network:\n$network';
  }

  // ---------------------------------------------------------------------------
  // All Information
  // ---------------------------------------------------------------------------

  Future<String> _getAllInformation() async {
    final platform = deviceInfoService.getCurrentPlatform();

    final device = await deviceInfoService.getDeviceInfo();
    final battery = await deviceInfoService.getBatteryInfo();
    final sensors = await deviceInfoService.getSensorInfo();
    final network = await deviceInfoService.getNetworkInfo();

    final processor = device.processorInfo;
    final memory = device.memoryInfo;
    final storage = device.storageInfo;

    final displayInfo = device.displays.map((display) {
      return '''
Resolution: ${display.orientation} x ${display.isHighDensity}
Pixel Density: ${display.pixelDensity}
Refresh Rate: ${display.refreshRate}
Primary: ${display.isPrimary}
''';
    }).join('\n');

    final storageInfo = storage.volumes.map((volume) {
      final totalGB = volume.totalCapacity / (1024 * 1024 * 1024);
      final availableGB = volume.availableCapacity / (1024 * 1024 * 1024);
      return '''
Volume: ${volume.name}
Mount Path: ${volume.mountPath}
Total Capacity: ${totalGB.toStringAsFixed(1)} GB
Available Capacity: ${availableGB.toStringAsFixed(1)} GB
Removable: ${volume.isRemovable}
''';
    }).join('\n');

    return '''
Platform:
$platform

Device:
ID: ${device.deviceId}
Name: ${device.deviceName}
Manufacturer: ${device.manufacturer}
Model: ${device.model}
Brand: ${device.brand}

Operating System:
Name: ${device.operatingSystem}
Version: ${device.systemVersion}
Build Number: ${device.buildNumber}
Kernel: ${device.kernelVersion}

Processor:
Name: ${processor.processorName}
Architecture: ${processor.architecture}
Core Count: ${processor.coreCount}
Max Frequency: ${processor.maxFrequency}
Features: ${processor.features.join(', ')}

Memory (RAM):
Total: ${(memory.totalPhysicalMemory / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB
Available: ${(memory.availablePhysicalMemory / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB

Storage:
$storageInfo

Display:
$displayInfo

Battery:
${battery == null ? 'Unavailable' : '''
Percentage: ${battery.batteryLevel}%
Charging: ${battery.isCharging}
Status: ${battery.batteryCapacity}
'''}

Sensors:
$sensors

Network:
$network
}
''';
  }
}