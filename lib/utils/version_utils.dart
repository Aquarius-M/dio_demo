///  jh_version_utils.dart
///
///  Created by iotjin on 2023/04/02.
///  description:

import 'package:dio/dio.dart';
import 'package:url_launcher/url_launcher.dart';
import 'device_utils.dart';
import 'log_utils/app_log_utils.dart';

class VersionUtils {
  /// 跳转AppStore
  static Future<void> jumpAppStore({String? url}) async {
    // 这是微信的地址，到时候换成自己的应用的地址
    final tempURL =
        url ?? 'itms-apps://itunes.apple.com/cn/app/id414478124?mt=8';
    final Uri uri = Uri.parse(tempURL);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      AppLog.i("跳转失败！");
    }
  }

  /// 安卓检查更新
  /// 返回是否有新版本、安卓apk下载地址和版本号
  static Future androidCheckUpdate() async {
    var api =
        'https://api.github.com/repos/iotjin/jh_flutter_demo/releases/latest';
    var dio = Dio();
    var response = await dio.get(api);
    Map data = response.data;
    if (data.isNotEmpty) {
      String url = data['assets'][0]['browser_download_url'];
      String tagName = data['tag_name'];
      String version = tagName.substring(1);
      String appVersion = await DeviceUtils.version();
      bool hasNewVersion = VersionUtils.hasNewVersion(appVersion, version);
      return {'hasNewVersion': hasNewVersion, 'url': url, 'tagName': tagName};
    }
    return {'hasNewVersion': false};
  }

  /// 版本比较，是否有新版本
  /// appVersion：项目当前版本
  /// version：要比较的版本(比如最新版本)
  static bool hasNewVersion(String appVersion, String version) {
    // print(appVersion.compareTo(version)); // 字符串 比较大小, 0:相同、1:大于、-1:小于
    return appVersion.compareTo(version) < 0 ? true : false;
  }
}
