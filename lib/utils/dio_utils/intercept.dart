import 'package:dio/dio.dart';
import 'package:dio_demo/utils/dio_utils/dio_utils.dart';
import 'package:logger/logger.dart';
import 'apis.dart';
import 'result_handle.dart';

var logger = Logger();
// default token
const String defaultToken = '';
const String kRefreshTokenUrl = API.refreshToken;

String getToken() {
  return "1";
}

void setToken(accessToken) {}

String getRefreshToken() {
  return "1";
}

void setRefreshToken(refreshToken) {}

/// 统一添加身份验证请求头
class AuthInterceptor extends Interceptor {
  @override
  void onRequest(RequestOptions options, RequestInterceptorHandler handler) {
    if (options.path != API.login) {
      final String accessToken = getToken();
      if (accessToken.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $accessToken';
      }
    }
    super.onRequest(options, handler);
  }
}

/// 刷新Token
class TokenInterceptor extends QueuedInterceptor {
  Dio? _tokenDio;

  Future<Map<String, dynamic>?> refreshTokenRequest() async {
    var params = {'accessToken': getToken(), 'refreshToken': getRefreshToken()};
    try {
      _tokenDio ??= Dio();
      _tokenDio!.options = DioUtil().dio.options;
      _tokenDio!.options.headers['Authorization'] = 'Bearer ${getToken()}';
      final Response<dynamic> response =
          await _tokenDio!.post<dynamic>(kRefreshTokenUrl, data: params);
      var res = response.data as dynamic;
      if (res['code'] == ExceptionHandle.success) {
        return response.data;
      }
    } catch (e) {
      logger.d('---------- 刷新Token失败！----------');
    }
    return null;
  }

  @override
  Future<void> onResponse(
      Response<dynamic> response, ResponseInterceptorHandler handler) async {
    // 401代表token过期
    if (response.statusCode == ExceptionHandle.unauthorized) {
      logger.d('---------- 自动刷新Token ----------');

      var res = await refreshTokenRequest(); // 获取新的accessToken
      if (res != null) {
        var accessToken = res['accessToken'];
        logger.e('---------- NewToken: $accessToken ----------');

        // 保存token
        setToken(accessToken);
        setRefreshToken(res['refreshToken']);

        // 重新请求失败接口
        final RequestOptions request = response.requestOptions;
        request.headers['Authorization'] = 'Bearer $accessToken';

        final Options options = Options(
          headers: request.headers,
          method: request.method,
        );

        try {
          logger.e('---------- 重新请求接口 ----------');

          /// 避免重复执行拦截器，使用tokenDio
          final Response<dynamic> response = await _tokenDio!.request<dynamic>(
            request.path,
            data: request.data,
            queryParameters: request.queryParameters,
            cancelToken: request.cancelToken,
            options: options,
            onReceiveProgress: request.onReceiveProgress,
          );
          return handler.next(response);
        } on DioError catch (e) {
          return handler.reject(e);
        }
      }
    }
    super.onResponse(response, handler);
  }
}
