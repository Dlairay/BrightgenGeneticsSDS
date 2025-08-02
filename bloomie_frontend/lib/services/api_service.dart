import 'package:dio/dio.dart';
import 'package:http_parser/http_parser.dart';
import '../core/utils/logger.dart';
import 'storage_service.dart';
import 'mock_api_service.dart';

class ApiService {
  static late Dio _dio;
  // Using the actual API base URL from frontend.html
  static const String baseUrl = 'https://child-profiling-api-271271835247.us-central1.run.app';
  static const String apiKey = 'secure-api-key-2025';
  static const bool useMockData = false; // Using real API from frontend.html
  
  static void init() {
    _dio = Dio(BaseOptions(
      baseUrl: baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        'X-API-Key': apiKey, // Added API key from frontend.html
      },
    ));
    
    // Add interceptors
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        // Add auth token to headers
        final token = await StorageService.getSecureData(StorageService.keyAuthToken);
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
          AppLogger.info('Auth token present (length: ${token.length})');
        } else {
          AppLogger.warning('No auth token found in storage');
        }
        
        // Ensure API key is always present
        options.headers['X-API-Key'] = apiKey;
        
        AppLogger.info('API Request: ${options.method} ${options.path}');
        AppLogger.info('Headers: ${options.headers}');
        handler.next(options);
      },
      onResponse: (response, handler) {
        AppLogger.info('API Response: ${response.statusCode} ${response.requestOptions.path}');
        handler.next(response);
      },
      onError: (error, handler) {
        AppLogger.error('API Error: ${error.message}', error: error);
        handler.next(error);
      },
    ));
  }
  
  // Authentication endpoints (matching frontend.html pattern)
  static Future<Map<String, dynamic>> login(Map<String, dynamic> loginData) async {
    if (useMockData) {
      AppLogger.info('Using mock data for login');
      return await MockApiService.login(loginData);
    }
    
    try {
      final response = await _dio.post('/auth/login', data: loginData);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  static Future<Map<String, dynamic>> register(Map<String, dynamic> userData) async {
    if (useMockData) {
      AppLogger.info('Using mock data for registration');
      return await MockApiService.register(userData);
    }
    
    try {
      final response = await _dio.post('/auth/register', data: userData);
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  static Future<Map<String, dynamic>> getCurrentUser() async {
    if (useMockData) {
      AppLogger.info('Using mock data for current user');
      return await MockApiService.getCurrentUser();
    }
    
    try {
      final response = await _dio.get('/auth/me');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  static Future<List<dynamic>> getChildren() async {
    if (useMockData) {
      AppLogger.info('Using mock data for children');
      return await MockApiService.getChildren();
    }
    
    try {
      final response = await _dio.get('/children');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Chat endpoints
  static Future<Map<String, dynamic>> sendChatMessage(String message) async {
    try {
      final response = await _dio.post('/chat/message', data: {
        'message': message,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  static Future<List<dynamic>> getChatHistory() async {
    try {
      final response = await _dio.get('/chat/history');
      return response.data['messages'];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Dr. Bloom chat endpoints (matching frontend.html)
  static Future<Map<String, dynamic>> startDrBloomSession(String childId, {String? initialConcern}) async {
    try {
      AppLogger.info('Starting Dr. Bloom session for child: $childId');
      final requestData = {
        'initial_concern': initialConcern ?? "I'd like to consult with Dr. Bloom about my child.",
        'image': null,
        'image_type': null,
      };
      AppLogger.info('Request data: $requestData');
      
      final response = await _dio.post('/children/$childId/dr-bloom/start', data: requestData);
      
      AppLogger.info('Dr. Bloom session response: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  static Future<Map<String, dynamic>> sendDrBloomMessage(String sessionId, String message) async {
    try {
      AppLogger.info('Sending message to session $sessionId: $message');
      final requestData = {
        'message': message,
        'agent_type': 'dr_bloom',
        'image': null,
        'image_type': null,
      };
      
      final response = await _dio.post('/chatbot/conversations/$sessionId/messages', data: requestData);
      
      AppLogger.info('Dr. Bloom message response: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  static Future<Map<String, dynamic>> completeDrBloomSession(String childId, String sessionId) async {
    try {
      final response = await _dio.post('/children/$childId/dr-bloom/complete', data: {
        'session_id': sessionId,
        'child_id': childId,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Questionnaire endpoints (matching frontend.html pattern)
  static Future<Map<String, dynamic>> getQuestionnaireQuestions(String childId) async {
    if (useMockData) {
      AppLogger.info('Using mock data for questionnaire questions');
      return await MockApiService.getQuestionnaireQuestions(childId);
    }
    
    try {
      final response = await _dio.get('/children/$childId/check-in/questions');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  static Future<Map<String, dynamic>> submitQuestionnaire(String childId, List<dynamic> answers) async {
    if (useMockData) {
      AppLogger.info('Using mock data for questionnaire submission');
      return await MockApiService.submitQuestionnaire(childId, answers);
    }
    
    try {
      final response = await _dio.post('/children/$childId/check-in/submit', data: {
        'answers': answers,
      });
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  static Future<List<dynamic>> getRecommendationsHistory(String childId) async {
    if (useMockData) {
      AppLogger.info('Using mock data for recommendations history');
      return await MockApiService.getRecommendationsHistory(childId);
    }
    
    try {
      AppLogger.info('Fetching recommendations history for child: $childId');
      final response = await _dio.get('/children/$childId/recommendations-history');
      AppLogger.info('Recommendations history response: ${response.data}');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Traits endpoint (matching frontend.html)
  static Future<List<dynamic>> getChildTraits(String childId) async {
    try {
      AppLogger.info('Fetching traits for child: $childId');
      final response = await _dio.get('/children/$childId/traits');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  static Future<Map<String, dynamic>> getQuestionnaireProgress() async {
    try {
      final response = await _dio.get('/questionnaire/progress');
      return response.data;
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // File upload - Genetic Report (matching frontend.html exactly)
  static Future<Map<String, dynamic>> uploadGeneticReport(String filePath, String childName) async {
    try {
      AppLogger.info('Creating FormData with file: $filePath, child_name: $childName');
      
      // Try setting filename explicitly to help server detect PDF type
      final fileName = filePath.split('/').last;
      AppLogger.info('File name: $fileName');
      
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(
          filePath,
          filename: fileName,
          contentType: MediaType('application', 'pdf'), // Force PDF content type
        ),
        'child_name': childName,
      });
      
      AppLogger.info('FormData created (no content-type specified), sending to /children/upload-genetic-report');
      
      final response = await _dio.post('/children/upload-genetic-report', data: formData);
      
      AppLogger.info('Upload response: ${response.statusCode}');
      return response.data;
    } on DioException catch (e) {
      // Print detailed error information
      AppLogger.error('=== UPLOAD ERROR DETAILS ===');
      AppLogger.error('Status Code: ${e.response?.statusCode}');
      AppLogger.error('Response Data: ${e.response?.data}');
      AppLogger.error('Response Headers: ${e.response?.headers}');
      AppLogger.error('Request URL: ${e.requestOptions.uri}');
      AppLogger.error('Request Headers: ${e.requestOptions.headers}');
      AppLogger.error('Request Method: ${e.requestOptions.method}');
      AppLogger.error('Error Type: ${e.type}');
      AppLogger.error('Error Message: ${e.message}');
      AppLogger.error('=== END ERROR DETAILS ===');
      throw _handleError(e);
    } catch (e) {
      AppLogger.error('Non-Dio error during upload: $e');
      throw 'Upload failed: $e';
    }
  }
  
  // General file upload 
  static Future<String> uploadFile(String filePath) async {
    try {
      final formData = FormData.fromMap({
        'file': await MultipartFile.fromFile(filePath),
      });
      
      final response = await _dio.post('/files/upload', data: formData);
      return response.data['url'];
    } on DioException catch (e) {
      throw _handleError(e);
    }
  }
  
  // Error handling
  static String _handleError(DioException error) {
    AppLogger.error('API Error Details:');
    AppLogger.error('Type: ${error.type}');
    AppLogger.error('Status Code: ${error.response?.statusCode}');
    AppLogger.error('Response Data: ${error.response?.data}');
    AppLogger.error('Request Path: ${error.requestOptions.path}');
    
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return 'Connection timeout. Please check your internet connection.';
      case DioExceptionType.badResponse:
        final statusCode = error.response?.statusCode;
        final responseData = error.response?.data;
        
        // Try to extract the actual server error message
        String message = 'Unknown error';
        if (responseData is Map<String, dynamic>) {
          // Check for 'detail' field (common in FastAPI)
          if (responseData.containsKey('detail')) {
            message = responseData['detail'].toString();
          }
          // Check for 'message' field
          else if (responseData.containsKey('message')) {
            message = responseData['message'].toString();
          }
          // Check for 'error' field
          else if (responseData.containsKey('error')) {
            message = responseData['error'].toString();
          }
        } else if (responseData is String) {
          message = responseData;
        }
        
        // Include status code in error for clarity
        if (statusCode != null) {
          message = '[$statusCode] $message';
        }
        
        // Return the actual server message instead of generic ones
        return message;
      case DioExceptionType.cancel:
        return 'Request cancelled.';
      default:
        return 'Network error. Please check your connection.';
    }
  }
}