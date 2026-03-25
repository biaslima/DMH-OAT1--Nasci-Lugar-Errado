import 'package:flutter/material.dart';
import 'package:nasci_lugar_errado/data/models/vida_alternativa_model.dart';
import 'package:nasci_lugar_errado/widgets/bandeira_widget.dart';

class VidaCard extends StatelessWidget {
  final VidaAlternativaModel vida;
  final VoidCallback? onTap;
  final VoidCallback? onFavoritaTap;

  const VidaCard({
    super.key,
    required this.vida,
    this.onTap,
    this.onFavoritaTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      elevation: 2,
      shadowColor: colorScheme.shadow.withOpacity(0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              // Bandeira
              BandeiraWidget(
                bandeiraUrl: vida.bandeiraUrl,
                paisCode: vida.paisCode,
                width: 56,
                height: 38,
                borderRadius: BorderRadius.circular(8),
              ),
              const SizedBox(width: 14),

              // Dados principais
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vida.paisNome,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        if (vida.capital != null) ...[
                          Icon(Icons.location_city_rounded,
                              size: 13,
                              color: colorScheme.onSurface.withOpacity(0.5)),
                          const SizedBox(width: 3),
                          Text(
                            vida.capital!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.onSurface.withOpacity(0.6),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        if (vida.expectativaVida != null) ...[
                          Icon(Icons.favorite_rounded,
                              size: 13,
                              color: colorScheme.primary.withOpacity(0.7)),
                          const SizedBox(width: 3),
                          Text(
                            '${vida.expectativaVida!.toStringAsFixed(1)} anos',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: colorScheme.primary,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (vida.salvoEm != null) ...[
                      const SizedBox(height: 3),
                      Text(
                        _formatarData(vida.salvoEm!),
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurface.withOpacity(0.4),
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // Botão favorito
              IconButton(
                onPressed: onFavoritaTap,
                icon: Icon(
                  vida.favorita == 1
                      ? Icons.star_rounded
                      : Icons.star_border_rounded,
                  color: vida.favorita == 1
                      ? Colors.amber.shade600
                      : colorScheme.onSurface.withOpacity(0.3),
                  size: 26,
                ),
                tooltip: vida.favorita == 1 ? 'Desfavoritar' : 'Favoritar',
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatarData(String isoDate) {
    try {
      final dt = DateTime.parse(isoDate);
      return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
    } catch (_) {
      return isoDate;
    }
  }
}