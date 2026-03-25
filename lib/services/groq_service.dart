import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroqService {
  static const String _apiUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  static const String _model = 'llama-3.1-8b-instant';

  String get _apiKey => dotenv.env['GROQ_API_KEY'] ?? '';

  Future<String> gerarResumoComparativo(
    String paisOrigem,
    String paisDestino,
  ) async {
    if (_apiKey.isEmpty) {
      return 'Erro de configuração: API Key não encontrada.';
    }

    try {
      final response = await http
          .post(
            Uri.parse(_apiUrl),
            headers: {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
            },
            body: jsonEncode(_buildBody(paisOrigem, paisDestino)),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode != 200) {
        return 'Erro na IA (Status ${response.statusCode}).';
      }

      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return data['choices']?[0]?['message']?['content'] ??
          'Resposta inválida da IA.';
    } catch (_) {
      return 'Falha de conexão com a IA.';
    }
  }

  Map<String, dynamic> _buildBody(String paisOrigem, String paisDestino) {
    return {
      "model": _model,
      "messages": [
        {
          "role": "system",
          "content":
              "Você é um amigo sincero, descontraído e viajado. Responda em português do Brasil, de forma informal e direta (máximo 3-4 linhas). Dê um veredito claro.",
        },
        {
          "role": "user",
          "content":
              "Simulando minha vida: nasci em $paisOrigem, mas poderia ter nascido em $paisDestino. Compare clima, hobbies e qualidade de vida. Valeria mais a pena eu ter nascido lá ou aqui? Quem costuma gostar mais do país alternativo? Responda curto.",
        },
      ],
      "temperature": 0.7,
    };
  }
}
