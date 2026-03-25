import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';

class BandeiraWidget extends StatelessWidget {
  final String? bandeiraUrl;
  final String paisCode;
  final double width;
  final double height;
  final BorderRadius? borderRadius;

  const BandeiraWidget({
    super.key,
    required this.bandeiraUrl,
    required this.paisCode,
    this.width = 48,
    this.height = 32,
    this.borderRadius,
  });

  String get _flagEmoji {
    // Converte código ISO para emoji de bandeira
    if (paisCode.length != 2) return '🌍';
    return paisCode.toUpperCase().split('').map((c) {
      return String.fromCharCode(c.codeUnitAt(0) + 0x1F1A5);
    }).join();
  }

  @override
  Widget build(BuildContext context) {
    final br = borderRadius ?? BorderRadius.circular(4);

    if (bandeiraUrl == null || bandeiraUrl!.isEmpty) {
      return _fallbackEmoji();
    }

    return ClipRRect(
      borderRadius: br,
      child: CachedNetworkImage(
        imageUrl: bandeiraUrl!,
        width: width,
        height: height,
        fit: BoxFit.cover,
        placeholder: (context, url) => _loadingPlaceholder(),
        errorWidget: (context, url, error) => _fallbackEmoji(),
      ),
    );
  }

  Widget _loadingPlaceholder() {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: borderRadius ?? BorderRadius.circular(4),
      ),
      child: const Center(
        child: SizedBox(
          width: 14,
          height: 14,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }

  Widget _fallbackEmoji() {
    return Container(
      width: width,
      height: height,
      alignment: Alignment.center,
      child: Text(
        _flagEmoji,
        style: TextStyle(fontSize: height * 0.75),
      ),
    );
  }
}