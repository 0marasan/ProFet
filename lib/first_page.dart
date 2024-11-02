import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:pro_fett/progressbar.dart';
import 'package:sensors_plus/sensors_plus.dart';
import 'package:battery_plus/battery_plus.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

class ProbabilityMeter extends StatefulWidget {
  const ProbabilityMeter({Key? key}) : super(key: key);

  @override
  _ProbabilityMeterState createState() => _ProbabilityMeterState();
}

class _ProbabilityMeterState extends State<ProbabilityMeter> {
  final Random _random = Random();
  final Battery _battery = Battery();

  bool isLoading = true;
  List<double> probabilities = List.filled(9, 0.0);
  bool hasCalculated = false;

  Map<String, double> sensorValues = {
    'battery': 0.0,
    'signal': 0.0,
    'brightness': 0.0,
    'accelerometer_x': 0.0,
    'accelerometer_y': 0.0,
    'accelerometer_z': 0.0,
    'gyroscope_x': 0.0,
    'gyroscope_y': 0.0,
    'gyroscope_z': 0.0,
    'magnetometer_x': 0.0,
    'magnetometer_y': 0.0,
    'magnetometer_z': 0.0,
  };

  final List<Map<String, double>> outputWeights = [
    {'battery': 0.25, 'signal': 0.15, 'brightness': 0.10, 'accelerometer': 0.20, 'gyroscope': 0.15, 'magnetometer': 0.15},
    {'battery': 0.15, 'signal': 0.25, 'brightness': 0.15, 'accelerometer': 0.15, 'gyroscope': 0.20, 'magnetometer': 0.10},
    {'battery': 0.10, 'signal': 0.20, 'brightness': 0.25, 'accelerometer': 0.15, 'gyroscope': 0.15, 'magnetometer': 0.15},
    {'battery': 0.20, 'signal': 0.10, 'brightness': 0.15, 'accelerometer': 0.25, 'gyroscope': 0.15, 'magnetometer': 0.15},
    {'battery': 0.15, 'signal': 0.15, 'brightness': 0.15, 'accelerometer': 0.15, 'gyroscope': 0.25, 'magnetometer': 0.15},
    {'battery': 0.15, 'signal': 0.15, 'brightness': 0.15, 'accelerometer': 0.15, 'gyroscope': 0.15, 'magnetometer': 0.25},
    {'battery': 0.20, 'signal': 0.20, 'brightness': 0.20, 'accelerometer': 0.15, 'gyroscope': 0.15, 'magnetometer': 0.10},
    {'battery': 0.10, 'signal': 0.15, 'brightness': 0.15, 'accelerometer': 0.20, 'gyroscope': 0.20, 'magnetometer': 0.20},
    {'battery': 0.15, 'signal': 0.15, 'brightness': 0.20, 'accelerometer': 0.20, 'gyroscope': 0.15, 'magnetometer': 0.15},
  ];

  late StreamSubscription<AccelerometerEvent> _accelerometerSubscription;
  late StreamSubscription<GyroscopeEvent> _gyroscopeSubscription;
  late StreamSubscription<MagnetometerEvent> _magnetometerSubscription;
  late StreamSubscription<ConnectivityResult> _connectivitySubscription;

  @override
  void initState() {
    super.initState();
    _initSensors();
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
        _calculateAllProbabilities();
      }
    });
  }

  void _initSensors() {
    _accelerometerSubscription = accelerometerEvents.listen((AccelerometerEvent event) {
      if (mounted && !hasCalculated) {
        setState(() {
          sensorValues['accelerometer_x'] = event.x;
          sensorValues['accelerometer_y'] = event.y;
          sensorValues['accelerometer_z'] = event.z;
        });
      }
    });

    _gyroscopeSubscription = gyroscopeEvents.listen((GyroscopeEvent event) {
      if (mounted && !hasCalculated) {
        setState(() {
          sensorValues['gyroscope_x'] = event.x;
          sensorValues['gyroscope_y'] = event.y;
          sensorValues['gyroscope_z'] = event.z;
        });
      }
    });

    _magnetometerSubscription = magnetometerEvents.listen((MagnetometerEvent event) {
      if (mounted && !hasCalculated) {
        setState(() {
          sensorValues['magnetometer_x'] = event.x;
          sensorValues['magnetometer_y'] = event.y;
          sensorValues['magnetometer_z'] = event.z;
        });
      }
    });

    _connectivitySubscription = Connectivity()
        .onConnectivityChanged
        .listen((ConnectivityResult result) {
      if (!hasCalculated) {
        _updateSignalStrength(result);
      }
    });

    _updateDeviceInfo();
  }

  Future<void> _updateDeviceInfo() async {
    try {
      int batteryLevel = await _battery.batteryLevel;
      sensorValues['battery'] = batteryLevel.toDouble();
    } catch (_) {
      sensorValues['battery'] = 50.0;
    }

    try {
      double brightness = await ScreenBrightness().current;
      sensorValues['brightness'] = brightness * 100;
    } catch (_) {
      sensorValues['brightness'] = 50.0;
    }

    final connectivityResult = await Connectivity().checkConnectivity();
    _updateSignalStrength(connectivityResult);
  }

  void _updateSignalStrength(ConnectivityResult result) {
    double strengthValue = 0.0;
    switch (result) {
      case ConnectivityResult.mobile:
      case ConnectivityResult.wifi:
        strengthValue = 20.0 * (_random.nextInt(5) + 1);
        break;
      case ConnectivityResult.ethernet:
        strengthValue = 100.0;
        break;
      case ConnectivityResult.none:
        strengthValue = 0.0;
        break;
      default:
        strengthValue = 50.0;
    }

    if (mounted) {
      setState(() {
        sensorValues['signal'] = strengthValue;
      });
    }
  }

  void _calculateAllProbabilities() {
    if (!mounted || hasCalculated) return;

    double normalizedAccel = (sensorValues['accelerometer_x']!.abs() +
        sensorValues['accelerometer_y']!.abs() +
        sensorValues['accelerometer_z']!.abs()) / 30.0;

    double normalizedGyro = (sensorValues['gyroscope_x']!.abs() +
        sensorValues['gyroscope_y']!.abs() +
        sensorValues['gyroscope_z']!.abs()) / 30.0;

    double normalizedMag = (sensorValues['magnetometer_x']!.abs() +
        sensorValues['magnetometer_y']!.abs() +
        sensorValues['magnetometer_z']!.abs()) / 100.0;

    for (int i = 0; i < 6; i++) {
      var weights = outputWeights[i];
      double weightedSum =
          (sensorValues['battery']! * weights['battery']!) +
              (sensorValues['signal']! * weights['signal']!) +
              (sensorValues['brightness']! * weights['brightness']!) +
              (normalizedAccel * weights['accelerometer']!) +
              (normalizedGyro * weights['gyroscope']!) +
              (normalizedMag * weights['magnetometer']!);
      probabilities[i] = 30 + (weightedSum / 100.0) * 100;
    }

    setState(() {
      hasCalculated = true;
    });
  }

  @override
  void dispose() {
    _accelerometerSubscription.cancel();
    _gyroscopeSubscription.cancel();
    _magnetometerSubscription.cancel();
    _connectivitySubscription.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final outputLabels = [
      'Will my current relationship last?',
      'Will I ever have a re-incarnation?',
      'How happy will I be in my life?',
      'Will I buy a house in the next 10 years?',
      'How happy will I be with my partner?',
      'How successfully will I be in my life?',
    ];

    return Scaffold(
      appBar: AppBar(
        title: const Text("Aura Future"),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : Column(
              children: List.generate(outputLabels.length, (index) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          outputLabels[index],
                          style: const TextStyle(fontSize: 16.0),
                        ),
                      ),
                      CustomLinearProgressBar(
                        percentage: probabilities[index],
                        label: '${(probabilities[index]).toStringAsFixed(1)}%',
                        width: 200,
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ),
      ),
    );
  }
}