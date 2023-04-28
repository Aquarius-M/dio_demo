import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:dio_demo/utils/dio_utils/apis.dart';
import 'package:dio_demo/utils/dio_utils/result_handle.dart';
import 'package:flutter/foundation.dart';
import 'package:format_dio_logger/format_dio_logger.dart';

import 'intercept.dart';

// 枚举请求类型
enum DioMethod { get, post, put, patch, delete, head }

class DioUtil {
  /// 请求的URL前缀
  static String baseUrl = API.apiBaseUrl;

  /// 连接超时时间
  final Duration _connectTimeout = const Duration(seconds: 6);

  /// 响应超时时间
  final Duration _receiveTimeout = const Duration(seconds: 6);

  /// 发送超时时间
  final Duration _sendTimeout = const Duration(seconds: 6);

  static DioUtil? _instance;
  static Dio _dio = Dio();
  Dio get dio => _dio;

  DioUtil._internal() {
    _instance = this;
    _instance!._init();
  }

  factory DioUtil() => _instance ?? DioUtil._internal();

  static DioUtil? getInstance() {
    _instance ?? DioUtil._internal();
    return _instance;
  }

  /// 取消请求token
  final CancelToken _cancelToken = CancelToken();

  _init() {
    /// 初始化基本选项
    BaseOptions options = BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: _connectTimeout,
      receiveTimeout: _receiveTimeout,
      sendTimeout: _sendTimeout,
    );

    /// 初始化dio
    _dio = Dio(options);

    /// 添加拦截器
    /// 统一添加身份验证请求头
    _dio.interceptors.add(AuthInterceptor());

    /// 刷新Token
    _dio.interceptors.add(TokenInterceptor());

    /// 打印日志
    if (kDebugMode) {
      _dio.interceptors.add(FormatDioLogger());
    }
  }

  /// 请求类
  Future<dynamic> request<T>(
    String url, {
    DioMethod method = DioMethod.get,
    Map<String, dynamic>? params,
    data,
    CancelToken? cancelToken,
    Options? options,
    ProgressCallback? onSendProgress,
    ProgressCallback? onReceiveProgress,
  }) async {
    const methodValues = {
      DioMethod.get: 'get',
      DioMethod.post: 'post',
      DioMethod.put: 'put',
      DioMethod.delete: 'delete',
      DioMethod.patch: 'patch',
      DioMethod.head: 'head'
    };

    options ??= Options(method: methodValues[method]);
    // 没有网络
    var connectivityResult = await (Connectivity().checkConnectivity());
    if (connectivityResult == ConnectivityResult.none) {
      var netError = {
        "code": ExceptionHandle.netError,
        "mseeage": "没有网络了",
      };
      return BaseResponse.fromJson(netError, (json) => null);
    }
    try {
      Response response;
      response = await _dio.request(url,
          data: data,
          queryParameters: params,
          cancelToken: cancelToken ?? _cancelToken,
          options: options,
          onSendProgress: onSendProgress,
          onReceiveProgress: onReceiveProgress);
      return BaseResponse.fromJson(response.data, (json) => null);
    } on DioError catch (e) {
      if (e.type == DioErrorType.unknown) {
        var jsonError = {
          "code": ExceptionHandle.unknownError,
          "mseeage": e.error,
        };
        return BaseResponse.fromJson(jsonError, (json) => null);
      }
      // rethrow;
    }
  }

  /// 取消网络请求
  void cancelRequests({CancelToken? token}) {
    token ?? _cancelToken.cancel("cancelled");
  }
}
