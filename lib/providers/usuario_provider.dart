import 'package:flutter/material.dart';
import '../data/dao/usuario_dao.dart';
import '../data/models/usuario_model.dart';

class UsuarioProvider with ChangeNotifier {
  final UsuarioDao _dao = UsuarioDao();

  UsuarioModel? _usuario;
  bool _isLoading = false;
  String? _error;

  UsuarioModel? get usuario => _usuario;
  bool get isLoading => _isLoading;
  String? get error => _error;

  Future<void> carregarUltimoUsuario() async {
    _setLoading(true);

    try {
      _usuario = await _dao.getLast();
      _error = null;
    } catch (e) {
      _error = 'Erro ao carregar usuário: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<UsuarioModel?> salvarUsuario({
    required String dataNascimento,
    required String paisOrigemCode,
    required String paisOrigemNome,
  }) async {
    _setLoading(true);

    try {
      final novoUsuario = UsuarioModel(
        dataNascimento: dataNascimento,
        paisOrigemCode: paisOrigemCode,
        paisOrigemNome: paisOrigemNome,
      );

      final id = await _dao.insert(novoUsuario);
      _usuario = await _dao.getById(id);

      _error = null;
      return _usuario;
    } catch (e) {
      _error = 'Erro ao salvar usuário: $e';
      return null;
    } finally {
      _setLoading(false);
    }
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
