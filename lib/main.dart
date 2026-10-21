// 入口：阿拉伯语 RTL 为默认界面（目标市场），可在首页一键切换英语。
// 应用本身不含任何内容——全部由数据包 pack_v1.json 驱动。
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'app_state.dart';
import 'screens/home_shell.dart';
import 'theme.dart';

void main() => runApp(const ChineseTravelApp());

class ChineseTravelApp extends StatefulWidget {
  const ChineseTravelApp({super.key});

  @override
  State<ChineseTravelApp> createState() => _ChineseTravelAppState();
}

class _ChineseTravelAppState extends State<ChineseTravelApp> {
  final _state = AppState();

  @override
  void initState() {
    super.initState();
    _state.init();
  }

  @override
  Widget build(BuildContext context) {
    return AppStateScope(
      state: _state,
      child: ListenableBuilder(
        listenable: _state,
        builder: (context, _) {
          if (_state.loading) {
            return const MaterialApp(
              home: Scaffold(
                body: Center(child: CircularProgressIndicator()),
              ),
            );
          }
          return MaterialApp(
            title: 'Chinese Travel',
            debugShowCheckedModeBanner: false,
            locale: Locale(_state.lang),
            supportedLocales: const [Locale('ar'), Locale('en')],
            localizationsDelegates: const [
              GlobalMaterialLocalizations.delegate,
              GlobalWidgetsLocalizations.delegate,
              GlobalCupertinoLocalizations.delegate,
            ],
            theme: ThemeData(
              useMaterial3: true,
              scaffoldBackgroundColor: AppColors.cream,
              colorScheme: ColorScheme.fromSeed(
                seedColor: AppColors.cinnabar,
                primary: AppColors.cinnabar,
              ),
              fontFamily: _state.lang == 'ar' ? AppText.ar : AppText.latin,
            ),
            home: const HomeShell(),
          );
        },
      ),
    );
  }
}
