import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/find_locale.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wakelock_plus/wakelock_plus.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "WakeLock Clock",
      localizationsDelegates: [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: [Locale('en'), Locale('zh')],
      debugShowCheckedModeBanner: false,
      home: MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  final prefs = SharedPreferences.getInstance();

  var fontSize = 48.0;
  var timeFormat = "a hh:mm:ss";

  var time = "";

  void _updateTime() {
    final nowTime = DateTime.now();
    final nowTimeString = DateFormat(timeFormat).format(nowTime);
    setState(() {
      time = nowTimeString;
    });
  }

  @override
  void initState() {
    super.initState();

    // 横屏并全屏
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);

    // 加载设置
    prefs.then((prefs) {
      setState(() {
        fontSize = prefs.getDouble("fontSize") ?? 48.0;
        timeFormat = prefs.getString("timeFormat") ?? "a hh:mm:ss";
      });
    });

    WakelockPlus.enable();
    findSystemLocale().then((locale) {
      initializeDateFormatting(locale).then((_) {
        Timer.periodic(Duration(milliseconds: 1000), (_) {
          _updateTime();
        });
      });
    });
  }

  @override
  void deactivate() {
    super.deactivate();
    WakelockPlus.disable();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GestureDetector(
        onLongPress: () {
          showDialog(
            context: context,
            builder: (context) {
              return StatefulBuilder(
                builder: (context, setState) {
                  final timeFormatController = TextEditingController(
                    text: timeFormat,
                  );
                  final fontSizeController = TextEditingController(
                    text: fontSize.round().toString(),
                  );
                  return AlertDialog(
                    title: Text("设置"),
                    content: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Row(
                          children: [
                            Text("时间格式"),
                            SizedBox(width: 20),
                            Expanded(
                              child: TextField(
                                controller: timeFormatController,
                                onEditingComplete: () {
                                  final timeFormatFromTextField =
                                      timeFormatController.text;
                                  prefs.then((prefs) {
                                    prefs.setString(
                                      "timeFormat",
                                      timeFormatFromTextField,
                                    );
                                  });
                                  setState(() {
                                    timeFormat = timeFormatFromTextField;
                                  });
                                },
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(),
                                ),
                              ),
                            ),
                          ],
                        ),
                        Row(
                          children: [
                            Text("字体大小"),
                            Expanded(
                              flex: 3,
                              child: Slider(
                                value: fontSize,
                                min: 20,
                                max: 200,
                                divisions: 90,
                                label: fontSize.round().toString(),
                                onChanged: (double value) {
                                  prefs.then((prefs) {
                                    prefs.setDouble("fontSize", value);
                                  });
                                  setState(() {
                                    fontSize = value;
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: TextField(
                                controller: fontSizeController,
                                keyboardType: TextInputType.number,
                                onEditingComplete: () {
                                  final inputSize = double.tryParse(
                                    fontSizeController.text,
                                  );
                                  if (inputSize != null) {
                                    setState(() {
                                      fontSize = inputSize;
                                    });
                                  }
                                },
                                decoration: InputDecoration(suffixText: "em"),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    actions: [
                      TextButton(
                        onPressed: () => showAboutDialog(
                          context: context,
                          applicationIcon: FlutterLogo(),
                          applicationVersion: "0.1.0",
                          applicationLegalese: "MIT",
                        ),
                        child: Text("关于"),
                      ),
                    ],
                  );
                },
              );
            },
          );
        },
        child: Center(
          child: Text(time, style: TextStyle(fontSize: fontSize)),
        ),
      ),
    );
  }
}
