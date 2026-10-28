# 💰 Financeiro — Gestão Financeira Pessoal Local-First

Um aplicativo moderno, elegante e de alto desempenho para gestão financeira pessoal, desenvolvido em **Flutter** com arquitetura modular, segurança biométrica e design inspirado no **Apple Human Interface Guidelines (HIG)** e na paleta Slate do [Biostats](file:///C:/Projetos/biostats).

O **Financeiro** opera no paradigma **Local-First & Privacy-First**: 100% dos seus dados financeiros (contas, extratos, faturas, regras recorrentes e notas) permanecem no seu dispositivo, armazenados em banco SQLite local criptografado pelo sistema operacional.

---

## ✨ Funcionalidades Principais

### 1. Visão Geral & Gestão de Contas (Fase 1)
- **Multi-contas**: Conta Corrente, Carteira / Dinheiro, Cartão de Crédito, Poupança e Investimentos.
- **Card de Saldo Consolidado**: Resumo em tempo real de saldo disponível, receitas e despesas do mês.
- **Modal de Lançamento Rápido**: Criação ágil de despesas, receitas e transferências entre contas com feedback tátil (*Haptic Feedback*).
- **Parcelamento Inteligente**: Divisão automática de compras parceladas (1x até 24x) com vinculação de grupo.
- **Segurança Biométrica**: Bloqueio de tela com PIN numérico de 4 dígitos e autenticação biométrica (Face ID / Touch ID / Biometria Android).

### 2. Gestão Avançada de Cartões de Crédito & Recorrência (Fase 2)
- **Ciclo de Fatura Dinâmico**: Cálculo automático de data de fechamento, data de vencimento e indicação do **Melhor Dia de Compra**.
- **Status de Fatura**: Separação clara entre fatura **Aberta**, **Fechada** e **Paga**.
- **Fluxo "Pagar Fatura"**: Liquidação total ou parcial debitando diretamente de uma conta corrente escolhida.
- **Visual Apple Wallet**: Cards estilizados com limite disponível, limite total e extrato filtrado do ciclo.
- **Motor de Recorrência & Contas Fixas**: Cadastro de assinaturas e despesas fixas (Aluguel, Internet, Streaming) com processamento mensal automático.
- **Detalhamento de Transações**: Edição de data, categoria, conta, anotações e exclusão em lote de parcelas vinculadas.

### 3. Inteligência Analítica & Comparativos (Fase 3)
- **Comparador Mensal (Mês a Mês)**: Comparação direta entre dois períodos (ex: Outubro vs. Setembro) com cálculo de deltas absolutos e percentuais.
- **Evolução do Fluxo de Caixa**: Gráficos interativos construídos com `fl_chart` (barras duplas de receitas vs. despesas e curva de patrimônio líquido em 6 ou 12 meses).
- **Taxa de Poupança & Indicadores**: Card de inteligência financeira com percentual da renda poupado e alertas de teto orçamentário.

### 4. Importação de Extratos & Exportação Contábil (Fase 4)
- **Leitor Universal OFX**: Compatível com extratos bancários brasileiros (Nubank, Itaú, Bradesco, Inter, Santander, BB, Caixa, etc.).
- **Parser de Planilhas CSV**: Detecção inteligente de delimitador (`,` ou `;`) e formatos monetários nacionais.
- **Conciliação Bancária & Detecção de Duplicatas**: Identificação de transações já lançadas para evitar duplicidade antes da confirmação.
- **Exportação CSV / Excel**: Planilha padronizada com cabeçalho UTF-8 BOM ideal para contabilidade e Imposto de Renda.
- **Relatório PDF Enriquecido**: Documento formal com métricas consolidadas, KPIs de poupança, distribuição de despesas por categoria e detalhamento por forma de pagamento.

### 5. Notificações Locais & Widgets de Tela Inicial (Fase 5)
- **Lembretes Diários**: Notificação suave às 20h para registro das movimentações financeiras do dia.
- **Alertas de Vencimento**: Lembretes pontuais no dia de vencimento de faturas de cartão e contas fixas.
- **Widget Compacto de Tela Inicial**: Componente nativo (Android `AppWidgetProvider` e iOS `WidgetKit`) exibindo saldo consolidado, despesa mensal acumulada e botão de atalho rápido para novo lançamento.

### 6. Acessibilidade & Semântica (Fase 6)
- **Leitores de Tela (VoiceOver / TalkBack)**: Rotulagem semântica em todos os cards de métricas, modais e botões flutuantes.
- **Microinterações Táteis**: Vibrações táteis refinadas em seleções, confirmações de pagamento e exclusões.
- **Suíte de Testes Automatizados**: Cobertura de testes unitários e de widgets para cálculo contábil, conciliação e renderização.

---

## 🏗️ Arquitetura do Projeto

O código segue padrões rigorosos de modularidade e separação de responsabilidades:

```
lib/
├── models/                  # Entidades de domínio (TransactionItem, Account, Category, etc.)
│   ├── import_candidate.dart
│   └── models.dart
├── screens/                 # Telas do aplicativo
│   ├── analytics_screen.dart
│   ├── app_lock_screen.dart
│   ├── credit_cards_screen.dart
│   ├── import_reconciliation_screen.dart
│   ├── main_shell/          # As 4 abas principais da barra de navegação
│   │   ├── dashboard_tab.dart
│   │   ├── planning_tab.dart
│   │   ├── settings_tab.dart
│   │   └── transactions_tab.dart
│   ├── main_shell.dart
│   ├── monthly_comparator_screen.dart
│   ├── onboarding_screen.dart
│   ├── recurring_transactions_screen.dart
│   └── transaction_detail_screen.dart
├── services/                # Camada de serviços e infraestrutura local
│   ├── app_state.dart       # Estado global (ChangeNotifier reativo)
│   ├── backup_service.dart  # Exportação e restauração de backups JSON
│   ├── database_service.dart# Banco SQLite local e migrations
│   ├── notification_service.dart # Notificações locais e agendamentos
│   ├── security_service.dart# PIN numérico e biometria com local_auth
│   └── widget_service.dart  # Sincronização com o widget de tela inicial
├── theme/                   # Design Tokens (Slate + Emerald & Rose)
│   └── app_theme.dart
├── utils/                   # Utilitários e Parsers de alta precisão
│   ├── csv_bank_parser.dart
│   ├── currency_formatter.dart
│   ├── export_csv_generator.dart
│   ├── ofx_parser.dart
│   └── report_pdf_generator.dart
└── widgets/                 # Componentes visuais reutilizáveis
    ├── app_lock_gate.dart
    ├── cash_flow_evolution_chart.dart
    ├── financial_health_insight_card.dart
    ├── quick_transaction_modal.dart
    └── summary_card.dart
```

---

## 🎨 Paleta de Cores e Design System

Inspirado na precisão suíça e na interface Apple HIG:

| Token | Hex | Aplicação |
|---|---|---|
| **Emerald Principal** | `#10B981` | Receitas, saldos positivos, botões de ação primária |
| **Emerald Dark** | `#059669` | Gradientes e destaques de cabeçalhos |
| **Rose Accent** | `#F43F5E` | Despesas, avisos de teto orçamentário e exclusões |
| **Indigo Accent** | `#6366F1` | Transferências entre contas e comparativos analíticos |
| **Slate Dark Surface** | `#1E293B` | Superfície de cards no modo escuro |
| **Slate Dark Background** | `#0F172A` | Fundo principal da aplicação no modo escuro |

---

## 🚀 Como Executar o Projeto

### Pré-requisitos
- **Flutter SDK**: 3.24.0 ou superior
- **Dart SDK**: 3.5.0 ou superior
- Emulador Android (API 26+) ou dispositivo iOS físico/simulador

### Passos de Instalação

1. Clone ou acerte a pasta do repositório:
```bash
cd c:\Projetos\financeiro
```

2. Baixe as dependências:
```bash
flutter pub get
```

3. Execute a análise de código para garantir conformidade estática:
```bash
dart analyze lib
```

4. Execute a suíte de testes:
```bash
flutter test
```

5. Inicie o aplicativo em modo de depuração:
```bash
flutter run
```

---

## 🧪 Testes Automatizados

A suíte em `test/widget_test.dart` cobre:
- Formatação de valores monetários no padrão Real Brasileiro (`CurrencyFormatter`).
- Lógica de parcelamento e vínculos de grupo de transações.
- Cálculo de limite total, utilizado e disponível para cartões de crédito.
- Ciclo de faturas e identificação do melhor dia de compra.
- Serialização e restauração de regras recorrentes.
- Cálculo da taxa de poupança com tratamento de divisão por zero.
- Parsers bancários universais OFX e CSV com detecção de delimitadores.
- Geração de CSV contábil compatível com Excel (BOM UTF-8).
- Isolamento e segurança dos serviços nativos (`NotificationService` e `WidgetService`) em ambiente de testes.
- Acessibilidade semântica de widgets visuais com `matchesSemantics`.

---

## 📄 Licença & Privacidade

Este projeto é desenvolvido para uso pessoal e profissional com foco intransigente em privacidade:
- **Sem telemetria**
- **Sem envio de dados para servidores de terceiros**
- **Código 100% auditável**
