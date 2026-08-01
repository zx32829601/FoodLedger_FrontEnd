import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:food_ledger_frontend/core/api/api_exception.dart';
import 'package:food_ledger_frontend/features/profile/data/api_body_profile_repository.dart';
import 'package:food_ledger_frontend/features/profile/domain/models/body_profile.dart';

void main() {
  test('GET 完整保留身體資料與版本', () async {
    late RequestOptions request;
    final dio = _dio((options) {
      request = options;
      return {
        'birthDate': '1990-05-20',
        'biologicalSexCode': 'MALE',
        'heightInCentimeters': 175.5,
        'fitnessGoalCode': 'MAINTAIN',
        'activityLevelCode': 'MODERATE',
        'timeZone': 'Asia/Taipei',
        'version': '419fbd52-0bf9-4e47-9321-98fe759471e8',
      };
    });
    addTearDown(dio.close);

    final profile = await ApiBodyProfileRepository(dio).getProfile();

    expect(request.path, '/api/me/body-profile');
    expect(profile?.birthDate, DateTime(1990, 5, 20));
    expect(profile?.heightInCentimeters, 175.5);
    expect(profile?.version, '419fbd52-0bf9-4e47-9321-98fe759471e8');
  });

  test('BodyProfile.NotFound 轉換為尚未建立', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://localhost'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(
          DioException(
            requestOptions: options,
            response: Response<Object?>(
              requestOptions: options,
              statusCode: 404,
              data: {'code': 'BodyProfile.NotFound', 'message': '尚未建立身體資料。'},
            ),
            type: DioExceptionType.badResponse,
          ),
        ),
      ),
    );
    addTearDown(dio.close);

    expect(await ApiBodyProfileRepository(dio).getProfile(), isNull);
  });

  test('PUT 建立時保留 version null，修改時傳回版本', () async {
    late RequestOptions request;
    final dio = _dio((options) {
      request = options;
      return {
        ...Map<String, Object?>.from(options.data as Map),
        'version': 'new-version',
      };
    });
    addTearDown(dio.close);
    final profile = BodyProfile(
      birthDate: DateTime(1990, 5, 20),
      biologicalSexCode: 'FEMALE',
      heightInCentimeters: 165,
      fitnessGoalCode: 'FAT_LOSS',
      activityLevelCode: 'LIGHT',
      timeZone: 'Asia/Taipei',
      version: 'old-version',
    );

    final saved = await ApiBodyProfileRepository(dio).saveProfile(profile);

    expect(request.path, '/api/me/body-profile');
    expect(request.method, 'PUT');
    expect(request.data['birthDate'], '1990-05-20');
    expect(request.data['version'], 'old-version');
    expect(saved.version, 'new-version');
  });

  test('健身目標與活動程度使用相同語系並保留 Note', () async {
    final requests = <RequestOptions>[];
    final dio = _dio((options) {
      requests.add(options);
      return <Object?>[
        {
          'code': 'MAINTAIN',
          'displayName': '維持體重',
          'langCode': 'zh-TW',
          'note': '維持目前熱量平衡。',
          'sortOrder': 1,
        },
      ];
    });
    addTearDown(dio.close);
    final repository = ApiBodyProfileRepository(dio);

    final goals = await repository.getFitnessGoals(langCode: 'zh-TW');
    final levels = await repository.getActivityLevels(langCode: 'zh-TW');

    expect(requests.map((item) => item.path), [
      '/api/defined-codes/fitness-goals',
      '/api/defined-codes/activity-levels',
    ]);
    expect(
      requests.every((item) => item.queryParameters['langCode'] == 'zh-TW'),
      isTrue,
    );
    expect(goals.single.note, '維持目前熱量平衡。');
    expect(levels.single.displayName, '維持體重');
  });

  test('409 保留 BodyProfile.Conflict 供畫面提示重新讀取', () async {
    final dio = Dio(BaseOptions(baseUrl: 'https://localhost'));
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) => handler.reject(
          DioException(
            requestOptions: options,
            response: Response<Object?>(
              requestOptions: options,
              statusCode: 409,
              data: {
                'code': 'BodyProfile.Conflict',
                'message': '資料已被更新。',
                'traceId': 'trace-1',
              },
            ),
            type: DioExceptionType.badResponse,
          ),
        ),
      ),
    );
    addTearDown(dio.close);

    expect(
      () => ApiBodyProfileRepository(dio).saveProfile(
        BodyProfile(
          birthDate: DateTime(1990, 5, 20),
          biologicalSexCode: 'MALE',
          heightInCentimeters: 175,
          fitnessGoalCode: 'MAINTAIN',
          activityLevelCode: 'MODERATE',
          timeZone: 'Asia/Taipei',
          version: 'old',
        ),
      ),
      throwsA(
        isA<ApiException>()
            .having((error) => error.code, 'code', 'BodyProfile.Conflict')
            .having((error) => error.statusCode, 'statusCode', 409),
      ),
    );
  });
}

Dio _dio(Object? Function(RequestOptions options) response) {
  final dio = Dio(BaseOptions(baseUrl: 'https://localhost'));
  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) => handler.resolve(
        Response<Object?>(
          requestOptions: options,
          statusCode: 200,
          data: response(options),
        ),
      ),
    ),
  );
  return dio;
}
