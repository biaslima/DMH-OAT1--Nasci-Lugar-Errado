import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:screenshot/screenshot.dart';
import 'package:share_plus/share_plus.dart';
import 'package:nasci_lugar_errado/data/models/vida_alternativa_model.dart';
import 'package:nasci_lugar_errado/widgets/bandeira_widget.dart';

/// Captura o widget do comparativo e dispara o share nativo.
/// Chame [ShareCardService.compartilhar] passando o contexto e a vida.
class ShareCardService {
  static Future<void> compartilhar({
    required BuildContext context,
    required VidaAlternativaModel vida,
    required String paisOrigemNome,
    required String paisOrigemCode,
  }) async {
    final controller = ScreenshotController();

    // Renderiza o card fora da árvore principal
    final Uint8List? bytes = await controller.captureFromLongWidget(
      _ShareCardWidget(
        vida: vida,
        paisOrigemNome: paisOrigemNome,
        paisOrigemCode: paisOrigemCode,
      ),
      pixelRatio: 3.0,
    );

    if (bytes == null) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Erro ao gerar imagem.')),
        );
      }
      return;
    }

    await Share.shareXFiles(
      [XFile.fromData(bytes, mimeType: 'image/png', name: 'minha_vida.png')],
      text: '🌍 E se eu tivesse nascido em ${vida.paisNome}? #NasceuLugarErrado',
    );
  }
}

/// Card visual gerado para compartilhamento.
class _ShareCardWidget extends StatelessWidget {
  final VidaAlternativaModel vida;
  final String paisOrigemNome;
  final String paisOrigemCode;

  const _ShareCardWidget({
    required this.vida,
    required this.paisOrigemNome,
    required this.paisOrigemCode,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 380,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF5C35D4), Color(0xFF3B82F6)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Text(
            '🌍 Você Nasceu no Lugar Errado?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 16,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),

          // Comparativo lado a lado
          Row(
            children: [
              Expanded(child: _ColunaPais(
                titulo: 'Sua Vida Real',
                paisNome: paisOrigemNome,
                paisCode: paisOrigemCode,
                bandeiraUrl: null,
                expectativaVida: null,
                capital: null,
              )),
              Column(
                children: [
                  Container(
                    height: 60,
                    width: 1,
                    color: Colors.white.withOpacity(0.3),
                  ),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Text('⚡', style: TextStyle(fontSize: 16)),
                  ),
                  Container(
                    height: 60,
                    width: 1,
                    color: Colors.white.withOpacity(0.3),
                  ),
                ],
              ),
              Expanded(child: _ColunaPais(
                titulo: 'Vida Alternativa',
                paisNome: vida.paisNome,
                paisCode: vida.paisCode,
                bandeiraUrl: vida.bandeiraUrl,
                expectativaVida: vida.expectativaVida,
                capital: vida.capital,
              )),
            ],
          ),

          const SizedBox(height: 20),

          // Rodapé
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Text(
              'Descubra a sua outra vida 🚀',
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ColunaPais extends StatelessWidget {
  final String titulo;
  final String paisNome;
  final String paisCode;
  final String? bandeiraUrl;
  final double? expectativaVida;
  final String? capital;

  const _ColunaPais({
    required this.titulo,
    required this.paisNome,
    required this.paisCode,
    required this.bandeiraUrl,
    required this.expectativaVida,
    required this.capital,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          titulo,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        BandeiraWidget(
          bandeiraUrl: bandeiraUrl,
          paisCode: paisCode,
          width: 56,
          height: 38,
          borderRadius: BorderRadius.circular(8),
        ),
        const SizedBox(height: 8),
        Text(
          paisNome,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 13,
          ),
          textAlign: TextAlign.center,
        ),
        if (capital != null) ...[
          const SizedBox(height: 4),
          Text(
            capital!,
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
        if (expectativaVida != null) ...[
          const SizedBox(height: 6),
          Text(
            '${expectativaVida!.toStringAsFixed(1)} anos',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 15,
            ),
          ),
          const Text(
            'expectativa de vida',
            style: TextStyle(color: Colors.white60, fontSize: 10),
          ),
        ],
      ],
    );
  }
}