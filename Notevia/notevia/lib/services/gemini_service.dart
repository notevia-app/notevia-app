import 'package:google_generative_ai/google_generative_ai.dart';

class GeminiService {
  static const String _apiKey = 'AIzaSyCPsbLFC2RKKf5BTo8GlPvKFd0DiKHMUoM';
  late final GenerativeModel _model;
  
  GeminiService() {
    _model = GenerativeModel(
      model: 'gemini-1.5-flash-002',
      apiKey: _apiKey,
    );
  }
  
  Future<String> generateResponse(String prompt, {String? context}) async {
    const maxRetries = 3;
    const retryDelay = Duration(seconds: 2);
    
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      try {
        final fullPrompt = context != null && context.isNotEmpty
            ? 'Mevcut not içeriği: "$context"\n\nKullanıcı isteği: $prompt\n\nLütfen kullanıcının isteğine göre yanıt ver. Eğer not içeriğiyle ilgili bir soru soruyorsa not içeriğini kullan, değilse genel bir sohbet yanıtı ver.'
            : 'Kullanıcı isteği: $prompt\n\nLütfen doğal bir sohbet yanıtı ver.';
        
        final content = [Content.text(fullPrompt)];
        final response = await _model.generateContent(content);
        
        return response.text ?? 'Yanıt alınamadı.';
      } catch (e) {
        final errorMessage = e.toString();
        
        // Server overloaded hatası için retry yap
        if (errorMessage.contains('503') || errorMessage.contains('overloaded')) {
          if (attempt < maxRetries - 1) {
            await Future.delayed(retryDelay * (attempt + 1));
            continue;
          } else {
            return 'AI servisi şu anda yoğun. Lütfen birkaç saniye sonra tekrar deneyin.';
          }
        }
        
        // Diğer hatalar için direkt döndür
        if (errorMessage.contains('API key')) {
          return 'API anahtarı hatası. Lütfen ayarlardan API anahtarınızı kontrol edin.';
        }
        
        return 'AI yanıt verirken bir hata oluştu. Lütfen tekrar deneyin.';
      }
    }
    
    return 'AI yanıt verirken bir hata oluştu. Lütfen tekrar deneyin.';
  }
  
  Future<String> enhanceNote(String noteContent, String instruction) async {
    final prompt = '''
Bu not içeriğini geliştir: "$noteContent"

İstek: $instruction

Lütfen sadece geliştirilmiş not içeriğini döndür, açıklama yapma.''';
    
    return await generateResponse(prompt);
  }
  
  Future<String> summarizeNote(String noteContent) async {
    final prompt = 'Bu notu özetle: "$noteContent"';
    return await generateResponse(prompt);
  }
  
  Future<String> continueWriting(String noteContent) async {
    final prompt = 'Bu not içeriğini devam ettir: "$noteContent"';
    return await generateResponse(prompt);
  }
}