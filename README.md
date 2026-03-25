# 🌍 Nasci no Lugar Errado?

> *E se você tivesse nascido em outro país? Descubra como seria sua vida alternativa.*

---

## 👥 Integrantes

| Nome | GitHub |
|------|--------|
| Anna Beatriz Lima | — |
| Fatima Pinho | — |
| Ian Salomão | — |
| Rebeca Helen Amorim | — |
| Valeria Soares | — |

---

## 📋 Descrição do Problema

Muitas pessoas se perguntam como seria sua vida se tivessem nascido em outro país — com outro idioma, outra cultura, outra expectativa de vida. Não existe nenhuma ferramenta simples e interativa que responda essa curiosidade de forma visual e personalizada.

**Nasci no Lugar Errado?** resolve isso: o usuário informa sua data de nascimento e seu país de origem, e o app sorteia um país alternativo, gerando um comparativo completo entre as duas realidades — incluindo dados como população, capital, idioma, moeda, expectativa de vida e até o clima do dia em que nasceu.

---

## 🎯 Público-alvo

- Pessoas curiosas sobre culturas e países diferentes
- Jovens e adultos que usam redes sociais e gostam de conteúdo interativo e de autoconhecimento
- Usuários que consomem testes e quizzes do estilo "qual seria sua vida se..."

---

## 🛠️ Tecnologias Utilizadas

| Tecnologia | Uso |
|------------|-----|
| **Flutter** | Framework principal para o app mobile (Android/iOS) |
| **Dart** | Linguagem de programação |
| **Provider** | Gerenciamento de estado |
| **GoRouter** | Navegação entre telas |
| **SQLite** | Persistência local do histórico de vidas |
| **REST Countries API** | Dados dos países (bandeira, idioma, moeda, capital, população) |
| **OpenWeather API** | Clima histórico no dia de nascimento |
| **cached_network_image** | Cache de imagens de bandeiras |
| **intl** | Formatação de datas |

---

## 🚀 Instruções para Execução

### Pré-requisitos

- [Flutter SDK](https://flutter.dev/docs/get-started/install) instalado (versão **3.x** ou superior)
- [Dart SDK](https://dart.dev/get-dart) (já incluso no Flutter)
- Android Studio ou VS Code com extensão Flutter
- Dispositivo físico ou emulador configurado

### Passo a passo

**1. Clone o repositório**
```bash
git clone https://github.com/seu-usuario/nasci-no-lugar-errado.git
cd nasci-no-lugar-errado
```

**2. Instale as dependências**
```bash
flutter pub get
```

**3. Configure as variáveis de ambiente**

Crie um arquivo `.env` na raiz do projeto com suas chaves de API:
```env
OPENWEATHER_API_KEY=sua_chave_aqui
```

**4. Execute o app**
```bash
flutter run
```

Para rodar em um dispositivo específico:
```bash
flutter devices          # lista dispositivos disponíveis
flutter run -d <id>      # roda no dispositivo escolhido
```

**5. Gerar build de produção (opcional)**
```bash
# Android
flutter build apk --release

# iOS
flutter build ios --release
```

---

## 📱 Telas do App

```
Entrada       →   Sorteio       →   Comparativo   →   Histórico
(data + país)     (animação)        (duas vidas)       (vidas salvas)
```

---

## 📁 Estrutura do Projeto

```
lib/
├── data/
│   └── models/          # UsuarioModel, VidaAlternativaModel
├── providers/           # VidaProvider, UsuarioProvider
├── screens/             # entrada, sorteio, comparativo, historico
├── services/            # CountriesService, WeatherService
└── widgets/             # VidaCard, AppErrorWidget
```

---

## 📄 Licença

Este projeto foi desenvolvido para fins acadêmicos.

---

<p align="center">Feito com 💜 por Anna Beatriz, Fatima, Ian, Rebeca e Valeria</p>
