import 'dart:async';
import 'dart:io';
import 'dart:ui';

import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_background_service/flutter_background_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'notification_service.dart';

class BackgroundService {
  static final FlutterBackgroundService _service = FlutterBackgroundService();

  Future<void> initialize() async {
    await _service.configure(
      androidConfiguration: AndroidConfiguration(
        onStart: _onStart,
        autoStart: true,
        isForegroundMode: true,
        notificationChannelId: 'channel_id',
        initialNotificationTitle: 'Notification Service',
        initialNotificationContent: 'Initializing',
        foregroundServiceNotificationId: 888,
        foregroundServiceTypes: [AndroidForegroundType.dataSync],
      ),
      iosConfiguration: IosConfiguration(
        autoStart: true,
        onForeground: _onStart,
        onBackground: _onIosBackground,
      ),
    );
  }

  Future<void> clearData() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();
    preferences.clear();

    debugPrint("deleted");
  }

  @pragma('vm:entry-point')
  static Future<bool> _onIosBackground(ServiceInstance service) async {
    WidgetsFlutterBinding.ensureInitialized();
    DartPluginRegistrant.ensureInitialized();

    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.reload();

    List<String> log = preferences.getStringList('log') ?? <String>[];
    log.add("Running background task - ${DateTime.now().toIso8601String()}");
    await preferences.setStringList('log', log);

    return true;
  }

  @pragma('vm:entry-point')
  static void _onStart(ServiceInstance service) async {
    DartPluginRegistrant.ensureInitialized();

    SharedPreferences preferences = await SharedPreferences.getInstance();
    await preferences.setString("user", "jibin");

    await preferences.reload();
    List<String> log = preferences.getStringList('log') ?? <String>[];
    log.add("Running background task - ${DateTime.now().toIso8601String()}");
    await preferences.setStringList('log', log);

    final NotificationService notificationService = NotificationService();

    if (service is AndroidServiceInstance) {
      service.on('setAsForeground').listen((event) {
        service.setAsForegroundService();
      });

      service.on('setAsBackground').listen((event) {
        service.setAsBackgroundService();
      });
    }

    service.on('stopService').listen((event) {
      service.stopSelf();
    });

    Timer.periodic(const Duration(seconds: 1), (timer) async {
      if (service is AndroidServiceInstance) {
        if (await service.isForegroundService()) {
          notificationService.showNotification(
              888, 'Background service', 'Date: ${DateTime.now()}');

          service.setForegroundNotificationInfo(
            title: "Foreground Service",
            content: "Updated at ${DateTime.now()}",
          );
        }
      }

      debugPrint('Flutter Service: ${DateTime.now()}');

      final deviceInfo = DeviceInfoPlugin();
      String? device;
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        device = androidInfo.model;
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        device = iosInfo.model;
      }

      service.invoke(
        'update',
        {
          "current_date": DateTime.now().toIso8601String(),
          "device": device,
        },
      );
    });

    // Periodic Task:
    Timer.periodic(const Duration(seconds: 2), (timer) async {
      await _logTask("Running background task");
    });
  }

  static Future<void> _logTask(String message) async {
    // Log the task in shared preferences
    SharedPreferences preferences = await SharedPreferences.getInstance();
    List<String> log = preferences.getStringList('log') ?? <String>[];
    log.add("$message - ${DateTime.now().toIso8601String()}");
    await preferences.setStringList('log', log);
  }
}
