import 'package:flutter/material.dart';

class StyleConfig {
  // 主色调配置
  static const MaterialColor primarySwatch = Colors.blue;

  // 品牌色系
  static const Color brandPrimary = Color(0xFF2196F3); // 主色调
  static const Color brandSecondary = Color(0xFF42A5F5); // 次要色调
  static const Color brandAccent = Color(0xFF4CAF50); // 强调色
  static const Color brandHighlight = Color(0xFFFFA726); // 高亮色

  // 功能色系
  static const Color successColor = Color(0xFF4CAF50); // 成功
  static const Color warningColor = Color(0xFFFFA726); // 警告
  static const Color errorColor = Color(0xFFF44336); // 错误
  static const Color infoColor = Color(0xFF2196F3); // 信息

  // 字幕颜色配置
  static const Color subtitleEnglish = Color(0xFF64B5F6); // 英文字幕
  static const Color subtitleChinese = Color(0xFF81C784); // 中文字幕
  static const Color subtitleHighQuality = Color(0xFFFFB74D); // 高质量字幕
  
  // 播放器控件颜色
  static const Color playerControlPrimary = Color(0xFF2196F3); // 主要控件
  static const Color playerControlSecondary = Color(0xFF90CAF9); // 次要控件
  static const Color playerBackground = Color(0xFF1A1A1A); // 播放器背景
  static const Color playerOverlay = Color(0x99000000); // 播放器遮罩
  
  // 字幕样式配置 - 浅色主题
  static const TextStyle subtitleLightEnglishStyle = TextStyle(
    fontSize: 16,
    height: 1.5,
    color: subtitleEnglish,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    shadows: [
      Shadow(
        color: Colors.black12,
        offset: Offset(0, 1),
        blurRadius: 1,
      ),
    ],
  );

  static const TextStyle subtitleLightChineseStyle = TextStyle(
    fontSize: 18,
    height: 1.5,
    color: subtitleChinese,
    fontWeight: FontWeight.w500,
    letterSpacing: 1,
    shadows: [
      Shadow(
        color: Colors.black12,
        offset: Offset(0, 1),
        blurRadius: 1,
      ),
    ],
  );

  static const TextStyle subtitleLightHighQualityStyle = TextStyle(
    fontSize: 18,
    height: 1.5,
    color: subtitleHighQuality,
    fontWeight: FontWeight.w600,
    letterSpacing: 1,
    shadows: [
      Shadow(
        color: Colors.black12,
        offset: Offset(0, 1),
        blurRadius: 1,
      ),
    ],
  );

  // 字幕样式配置 - 深色主题
  static const TextStyle subtitleDarkEnglishStyle = TextStyle(
    fontSize: 16,
    height: 1.5,
    color: subtitleEnglish,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    shadows: [
      Shadow(
        color: Colors.black54,
        offset: Offset(1, 1),
        blurRadius: 2,
      ),
    ],
  );

  static const TextStyle subtitleDarkChineseStyle = TextStyle(
    fontSize: 18,
    height: 1.5,
    color: subtitleChinese,
    fontWeight: FontWeight.w500,
    letterSpacing: 1,
    shadows: [
      Shadow(
        color: Colors.black54,
        offset: Offset(1, 1),
        blurRadius: 2,
      ),
    ],
  );

  static const TextStyle subtitleDarkHighQualityStyle = TextStyle(
    fontSize: 18,
    height: 1.5,
    color: subtitleHighQuality,
    fontWeight: FontWeight.w600,
    letterSpacing: 1,
    shadows: [
      Shadow(
        color: Colors.black54,
        offset: Offset(1, 1),
        blurRadius: 2,
      ),
    ],
  );

  // 中性色系 - 浅色主题
  static const Color lightBackground = Color(0xFFF8F9FA);
  static const Color lightSurfaceColor = Colors.white;
  static const Color lightDividerColor = Color(0xFFE0E0E0);
  static const Color lightTextPrimary = Color(0xFF2C3E50);
  static const Color lightTextSecondary = Color(0xFF718096);
  static const Color lightTextHint = Color(0xFFA0AEC0);

  // 中性色系 - 深色主题
  static const Color darkBackground = Color(0xFF1A202C);
  static const Color darkSurfaceColor = Color(0xFF2D3748);
  static const Color darkDividerColor = Color(0xFF4A5568);
  static const Color darkTextPrimary = Color(0xFFE2E8F0);
  static const Color darkTextSecondary = Color(0xFFA0AEC0);
  static const Color darkTextHint = Color(0xFF718096);

  // 渐变色配置
  static const List<LinearGradient> gradients = [
    LinearGradient(
      colors: [Color(0xFF2196F3), Color(0xFF1976D2)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFF4CAF50), Color(0xFF388E3C)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
    LinearGradient(
      colors: [Color(0xFFFFA726), Color(0xFFF57C00)],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    ),
  ];

  // 状态色配置
  static const Map<String, Color> statusColors = {
    'pending': Color(0xFFFFA726), // 等待中
    'processing': Color(0xFF2196F3), // 处理中
    'completed': Color(0xFF4CAF50), // 已完成
    'failed': Color(0xFFF44336), // 失败
  };

  // 阴影配置
  static List<BoxShadow> get lightShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.08),
          offset: const Offset(0, 1),
          blurRadius: 2,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          offset: const Offset(0, 2),
          blurRadius: 8,
        ),
      ];

  static List<BoxShadow> get darkShadow => [
        BoxShadow(
          color: Colors.black.withOpacity(0.2),
          offset: const Offset(0, 2),
          blurRadius: 4,
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.14),
          offset: const Offset(0, 4),
          blurRadius: 12,
        ),
      ];

  // 间距配置
  static const double spacingXS = 4.0;
  static const double spacingS = 8.0;
  static const double spacingM = 16.0;
  static const double spacingL = 24.0;
  static const double spacingXL = 32.0;

  // 响应式布局断点
  static const double mobileBreakpoint = 600;
  static const double tabletBreakpoint = 900;
  static const double desktopBreakpoint = 1200;

  // 圆角配置
  static const double radiusS = 4.0;
  static const double radiusM = 8.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 24.0;

  // 字体大小
  static const double fontSizeXS = 12.0;
  static const double fontSizeS = 14.0;
  static const double fontSizeM = 16.0;
  static const double fontSizeL = 20.0;
  static const double fontSizeXL = 24.0;
  static const double fontSizeXXL = 32.0;

  // 动画时长
  static const Duration animDurationFast = Duration(milliseconds: 200);
  static const Duration animDurationNormal = Duration(milliseconds: 300);
  static const Duration animDurationSlow = Duration(milliseconds: 400);

  // 获取响应式布局宽度
  static double getResponsiveWidth(
    BuildContext context, {
    double mobile = 0.95,
    double tablet = 0.85,
    double desktop = 0.75,
  }) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= desktopBreakpoint) {
      return MediaQuery.of(context).size.width * desktop;
    } else if (screenWidth >= tabletBreakpoint) {
      return MediaQuery.of(context).size.width * tablet;
    }
    return MediaQuery.of(context).size.width * mobile;
  }

  // 获取响应式内边距
  static EdgeInsets getResponsivePadding(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth >= desktopBreakpoint) {
      return const EdgeInsets.symmetric(
        horizontal: spacingXL * 2,
        vertical: spacingXL,
      );
    } else if (screenWidth >= tabletBreakpoint) {
      return const EdgeInsets.symmetric(
        horizontal: spacingXL,
        vertical: spacingL,
      );
    }
    return const EdgeInsets.symmetric(
      horizontal: spacingM,
      vertical: spacingM,
    );
  }

  // Material 3 浅色主题配置
  static ThemeData getLightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandPrimary,
        primary: brandPrimary,
        secondary: brandSecondary,
        tertiary: brandHighlight,
        background: lightBackground,
        surface: lightSurfaceColor,
        error: errorColor,
        onBackground: lightTextPrimary,
        onSurface: lightTextPrimary,
        onError: Colors.white,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: lightBackground,
      cardTheme: CardTheme(
        elevation: 2,
        shadowColor: Colors.black.withOpacity(0.1),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: spacingM,
          vertical: spacingS,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: spacingL,
            vertical: spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          elevation: 2,
          shadowColor: brandPrimary.withOpacity(0.3),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: spacingM,
            vertical: spacingS,
          ),
          foregroundColor: brandPrimary,
        ),
      ),
      iconTheme: IconThemeData(
        size: 24,
        color: lightTextPrimary,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: fontSizeXXL,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          color: lightTextPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: fontSizeXL,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          color: lightTextPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: fontSizeL,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
          color: lightTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: fontSizeM,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          color: lightTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: fontSizeM,
          letterSpacing: 0.5,
          height: 1.5,
          color: lightTextSecondary,
        ),
        bodyMedium: TextStyle(
          fontSize: fontSizeS,
          letterSpacing: 0.25,
          height: 1.5,
          color: lightTextSecondary,
        ),
      ),
      dividerTheme: DividerThemeData(
        space: spacingM,
        thickness: 1,
        color: lightDividerColor,
      ),
    );
  }

  // Material 3 深色主题配置
  static ThemeData getDarkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: brandPrimary,
        primary: brandPrimary,
        secondary: brandSecondary,
        tertiary: brandHighlight,
        background: darkBackground,
        surface: darkSurfaceColor,
        error: errorColor,
        onBackground: darkTextPrimary,
        onSurface: darkTextPrimary,
        onError: Colors.white,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: darkBackground,
      cardTheme: CardTheme(
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(radiusL),
        ),
        margin: const EdgeInsets.symmetric(
          horizontal: spacingM,
          vertical: spacingS,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: spacingL,
            vertical: spacingM,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(radiusM),
          ),
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.3),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          padding: const EdgeInsets.symmetric(
            horizontal: spacingM,
            vertical: spacingS,
          ),
          foregroundColor: brandSecondary,
        ),
      ),
      iconTheme: IconThemeData(
        size: 24,
        color: darkTextPrimary,
      ),
      textTheme: TextTheme(
        displayLarge: TextStyle(
          fontSize: fontSizeXXL,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          color: darkTextPrimary,
        ),
        displayMedium: TextStyle(
          fontSize: fontSizeXL,
          fontWeight: FontWeight.bold,
          letterSpacing: -0.5,
          color: darkTextPrimary,
        ),
        titleLarge: TextStyle(
          fontSize: fontSizeL,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.15,
          color: darkTextPrimary,
        ),
        titleMedium: TextStyle(
          fontSize: fontSizeM,
          fontWeight: FontWeight.w500,
          letterSpacing: 0.15,
          color: darkTextPrimary,
        ),
        bodyLarge: TextStyle(
          fontSize: fontSizeM,
          letterSpacing: 0.5,
          height: 1.5,
          color: darkTextSecondary,
        ),
        bodyMedium: TextStyle(
          fontSize: fontSizeS,
          letterSpacing: 0.25,
          height: 1.5,
          color: darkTextSecondary,
        ),
      ),
      dividerTheme: DividerThemeData(
        space: spacingM,
        thickness: 1,
        color: darkDividerColor,
      ),
    );
  }

  // 播放器主题配置
  static ThemeData getPlayerLightTheme() {
    return ThemeData.light().copyWith(
      scaffoldBackgroundColor: lightBackground,
      textTheme: const TextTheme(
        bodyLarge: subtitleLightEnglishStyle,
        bodyMedium: subtitleLightChineseStyle,
        labelLarge: subtitleLightHighQualityStyle,
      ),
      iconTheme: IconThemeData(
        color: lightTextPrimary,
        size: 28,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: brandPrimary,
        inactiveTrackColor: brandPrimary.withOpacity(0.3),
        thumbColor: brandPrimary,
        overlayColor: brandPrimary.withOpacity(0.2),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandPrimary,
          foregroundColor: Colors.white,
          elevation: 2,
          shadowColor: brandPrimary.withOpacity(0.3),
        ),
      ),
    );
  }

  static ThemeData getPlayerDarkTheme() {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: darkBackground,
      textTheme: TextTheme(
        bodyLarge: subtitleDarkEnglishStyle.copyWith(
          color: subtitleEnglish.withOpacity(0.9),
        ),
        bodyMedium: subtitleDarkChineseStyle.copyWith(
          color: subtitleChinese.withOpacity(0.9),
        ),
        labelLarge: subtitleDarkHighQualityStyle.copyWith(
          color: subtitleHighQuality.withOpacity(0.9),
        ),
      ),
      iconTheme: IconThemeData(
        color: darkTextPrimary,
        size: 28,
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: brandPrimary.withOpacity(0.9),
        inactiveTrackColor: brandPrimary.withOpacity(0.3),
        thumbColor: brandPrimary.withOpacity(0.9),
        overlayColor: brandPrimary.withOpacity(0.2),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: brandPrimary.withOpacity(0.8),
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: Colors.black.withOpacity(0.3),
        ),
      ),
    );
  }
}
