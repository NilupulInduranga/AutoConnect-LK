import 'package:flutter_screenutil/flutter_screenutil.dart';

extension ResponsiveNum on num {
  /// Responsive width
  double get w => ScreenUtil().setWidth(toDouble());

  /// Responsive height
  double get h => ScreenUtil().setHeight(toDouble());

  /// Responsive font size
  double get sp => ScreenUtil().setSp(toDouble());

  /// Responsive radius
  double get r => ScreenUtil().radius(toDouble());

  /// Vertical spacing
  double get verticalSpace => ScreenUtil().setHeight(toDouble());

  /// Horizontal spacing
  double get horizontalSpace => ScreenUtil().setWidth(toDouble());

  /// Screen width percentage
  double get sw => ScreenUtil().screenWidth * toDouble();

  /// Screen height percentage
  double get sh => ScreenUtil().screenHeight * toDouble();
}
