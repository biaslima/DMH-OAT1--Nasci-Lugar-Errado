import 'package:flutter/material.dart';
import '../data/dao/usuario_dao.dart';
import '../data/models/usuario_model.dart';

class UsuarioProvider with ChangeNotifier {
  final _dao = UsuarioDao();

  UsuarioModel? _usuario;
  bool _isLoading = false;
  String? _error;

  // ── Getters
  UsuarioModel? get usuario => _usuario;
  bool get isLoading => _isLoading;
  String? get error => _error;

  // ── Inicialização
  Future<void> carregarUltimoUsuario() async {
    try {
      _usuario = await _dao.getLast();
      notifyListeners();
    } catch (_) {
      // Silencioso — é normal não ter usuário no primeiro acesso
    }
  }

  // ── Salvar
  /// Cria um novo usuário no SQLite e o define como atual.
  /// Retorna o modelo com o id gerado, ou null em caso de erro.
  Future<UsuarioModel?> salvarUsuario({
    required String dataNascimento,
    required String paisOrigemCode,
    required String paisOrigemNome,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final novo = UsuarioModel(
        dataNascimento: dataNascimento,
        paisOrigemCode: paisOrigemCode,
        paisOrigemNome: paisOrigemNome,
      );
      final id = await _dao.insert(novo);
      _usuario = await _dao.getById(id);
      return _usuario;
    } catch (e) {
      _error = 'Erro ao salvar usuário: $e';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}