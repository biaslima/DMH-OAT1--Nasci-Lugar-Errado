import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class GroqService {
  static final String _apiKey = dotenv.env['GROQ_API_KEY'] ?? '';
  static const String _apiUrl =
      'https://api.groq.com/openai/v1/chat/completions';

  Future<String> gerarResumoComparativo(
    String paisOrigem,
    String paisDestino,
  ) async {
    try {
      print(
        '🤖 [GROQ] Iniciando requisição para comparar $paisOrigem e $paisDestino...',
      );

      final response = await http.post(
        Uri.parse(_apiUrl),
        headers: {
          'Authorization': 'Bearer $_apiKey',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          "model": "llama-3.1-8b-instant",
          "messages": [
            {
              "role": "system",
              "content":
                  "Você é um amigo sincero, descontraído e muito viajado. Responda sempre em português do Brasil, usando um tom bem informal e direto (máximo de 3 ou 4 linhas). Não use palavras difíceis. Dê um veredito claro se a pessoa vai curtir a mudança ou se vai se arrepender.",
            },
            {
              "role": "user",
              "content":
                  "Tô saindo do país: $paisOrigem e indo morar no país: $paisDestino. Compara a vibe dos dois lugares pra mim focando em clima, rolês/hobbies e qualidade de vida. Manda a real: pra qual perfil de pessoa vale a pena essa troca? Eu vou preferir morar lá ou vou sentir saudade de casa?",
            },
          ],
          "temperature": 0.7,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return data['choices'][0]['message']['content'];
      }
      return "Erro na IA (Status ${response.statusCode}). Veja o terminal.";
    } catch (e) {
      return "Ocorreu uma falha de conexão com a IA.";
    }
  }
}
