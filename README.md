# SOLIDWORKS AI Starter

Kit pessoal de laboratório para explorar automação do SOLIDWORKS pela API COM
(VBA e uma sonda em C#), com apoio de um agente de IA local (Claude Code) rodando
no seu computador. Não há PLM, não há rede corporativa, não há dados de produto
real — tudo aqui é sintético (um cone de teste e uma placa de teste) e serve para
aprender o fluxo com segurança antes de tocar em qualquer peça de verdade.

Versão de referência desta documentação: **2026-09-12**.

**Base de conhecimento preservada:** [normas e revisão técnica 2D](docs/NORMAS-2D.md),
[registro de edições/fontes](standards/registry.json), verificador Python offline,
exemplo sintético e testes. Sem redistribuir normas; não certifica conformidade
nem libera fabricação.

**Novo módulo:** [desenhos 2D nativos e montagem](docs/DESENHOS-2D.md), com
passo a passo de vistas, cotas associativas, cortes, detalhes, PDF, reabertura,
referências, limpeza autorizada e demonstrações em vídeo. É um procedimento
para desenvolver/testar o driver local, não um gerador universal pronto.

## O que este kit é (e o que não é)

- É um conjunto de scripts de diagnóstico/conexão, macros VBA de exemplo e
  documentação para uma pessoa leiga (ou uma IA) conseguir seguir sozinha.
- Não é um produto oficial do fabricante do SOLIDWORKS, não instala nenhum
  add-in, não gerencia licenciamento e não altera
  preferências globais do SOLIDWORKS ou do Windows.
- Não é um gerador automático de peças de produção. Os exemplos (cone, furo,
  placa) são exercícios sintéticos de aprendizado, não desenhos funcionais reais.
- Não garante que "rodar localmente" signifique que nenhum dado saia da sua
  máquina. Revise a política de dados do provedor de IA que você usa e trate
  qualquer informação sensível como fora do escopo deste laboratório — use
  somente dados sintéticos.

## Pré-requisitos

| Item | Detalhe |
|---|---|
| Sistema operacional | Windows 11 |
| SOLIDWORKS | Instalação desktop licenciada. O fluxo original foi demonstrado com 2025 SP5 (revisão 33.5); os scripts validam apenas o **prefixo** de revisão principal (ex.: `33.`), não a build exata |
| Shell | Windows PowerShell 5.1, 64 bits (`powershell.exe`) — não `pwsh` (PowerShell 7), não a versão x86 |
| Sessão | O PowerShell deve rodar no mesmo usuário e na mesma sessão/nível de integridade do SOLIDWORKS aberto |
| Python | 3.12, apenas biblioteca padrão para os testes |
| python-docx | 1.2.0 — usado só por `tools/build_guide.py` para gerar o Word do guia |
| Editor + IA | VS Code com a extensão oficial do Claude Code (Anthropic), instalada pela Marketplace, publisher verificado, login com conta própria ou da sua organização |

Nenhum destes itens é instalado por este repositório — são pré-condições do
seu ambiente. Veja o passo a passo completo em
[docs/GUIA-COMPLETO.md](docs/GUIA-COMPLETO.md).

## Obtendo o repositório

O repositório é **público**, disponível nas duas contas:

- [eludvic-gif/solidworks-ai-starter](https://github.com/eludvic-gif/solidworks-ai-starter) — origem.
- [ericludvic-79/solidworks-ai-starter](https://github.com/ericludvic-79/solidworks-ai-starter) — fork.

Não é necessário convite para leitura. Duas formas de obter os arquivos:

1. Via GitHub CLI:
   ```powershell
   gh auth login
   gh repo clone eludvic-gif/solidworks-ai-starter
   ```
2. Via download do ZIP na interface web do GitHub (botão "Code" > "Download ZIP").
   O ZIP já inclui o guia principal gerado em Word
   (`docs/GUIA-COMPLETO.docx`), então você não precisa rodar nada antes de ler.

Escolha uma pasta dentro do seu próprio workspace de trabalho para extrair ou
clonar o repositório; qualquer local em que você tenha permissão de leitura e
escrita serve — este guia não assume nenhum caminho específico.

## Estrutura do projeto

```
solidworks-ai-starter/
├── README.md                 (este arquivo)
├── AGENTS.md                 regras para qualquer agente de IA (genérico)
├── CLAUDE.md                 instruções específicas para o Claude Code
├── config.example.json       modelo de configuração (versionado)
├── config.local.json         sua cópia local, com caminhos reais (ignorado pelo controle de versão)
├── docs/
│   ├── GUIA-COMPLETO.md       guia principal, autossuficiente
│   ├── GUIA-COMPLETO.docx     versão em Word, gerada por tools/build_guide.py
│   ├── TROUBLESHOOTING.md     recuperação de erros, standalone
│   ├── VALIDACAO.md           metodologia de validação, standalone
│   ├── SKILLS.md              skills externas opcionais (não instaladas)
│   └── prompts/
│       ├── 01-onboarding.md
│       ├── 02-briefing.md
│       ├── 03-validacao-exportacao.md
│       └── 04-recuperacao.md
├── tools/
│   ├── SwConnection.cs        sonda C# somente leitura (probe)
│   ├── connection-policy.ps1  decisões puras (sem tocar em CAD)
│   ├── diagnose.ps1           checagem de arquivos/config/compilação
│   ├── connect-solidworks.ps1 conexão descartável com o SOLIDWORKS
│   ├── check-offline.ps1      parse/compilação sem abrir o SOLIDWORKS
│   ├── scan_release.py        varredura estática de release
│   └── build_guide.py         gera docs/GUIA-COMPLETO.docx via python-docx
├── examples/
│   ├── ConeValidation.bas     macro independente (main, TestGeometryOnly)
│   └── ConeBore9.bas          macro independente (RunConeBore9, TestBore9Math)
└── tests/                     testes Python (unittest)
```

Também estão incluídos `tools/engineering_checks.py`, `tools/verify-guide.ps1`, [checklist de release](docs/RELEASE-CHECKLIST.md) e [registro local de smoke test](docs/SMOKE-TEST.md). Não há gerador automático para a placa: ela é um exercício guiado.

## Primeiros passos (resumo)

1. Copie `config.example.json` para `config.local.json`.
2. Preencha `interop_path` e `executable_path` com os caminhos reais da sua
   instalação (veja como descobri-los em
   [docs/GUIA-COMPLETO.md](docs/GUIA-COMPLETO.md#6-configuração-local)).
3. Rode a checagem que **não** toca no CAD:
   ```powershell
   powershell.exe -File tools\diagnose.ps1 -ConfigPath .\config.local.json
   ```
4. Só depois, se quiser testar a conexão de verdade com um SOLIDWORKS aberto:
   ```powershell
   powershell.exe -File tools\connect-solidworks.ps1 -ConfigPath .\config.local.json
   ```
5. Leia o guia completo antes de importar qualquer macro ou criar geometria:
   [docs/GUIA-COMPLETO.md](docs/GUIA-COMPLETO.md).

## Princípios de segurança (resumo)

- Nenhum script inicia o SOLIDWORKS sozinho, a menos que você passe
  `-LaunchIfAbsent` explicitamente.
- Nenhum script mata o processo do SOLIDWORKS, chama `CloseAllDocuments` ou faz
  "limpeza" genérica de documentos.
- A sonda de conexão tem timeout apenas para a própria tentativa de conexão,
  nunca para operações de geometria.
- As macros de exemplo criam uma peça nova a cada execução; nunca salvam,
  exportam ou fecham automaticamente.
- Exportação/reimportação e validação dimensional são processos manuais
  guiados, não um botão mágico.

Detalhes completos em [AGENTS.md](AGENTS.md) e
[docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md).

## Documentação

| Arquivo | Para quem | Conteúdo |
|---|---|---|
| [AGENTS.md](AGENTS.md) | Qualquer agente de IA | Regras normativas completas |
| [CLAUDE.md](CLAUDE.md) | Claude Code | Instruções carregadas automaticamente nesta pasta |
| [docs/GUIA-COMPLETO.md](docs/GUIA-COMPLETO.md) | Pessoa leiga e IA | Guia principal, autossuficiente |
| [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) | Qualquer um | Erros e recuperação |
| [docs/VALIDACAO.md](docs/VALIDACAO.md) | Qualquer um | Metodologia de validação dimensional |
| [docs/DESENHOS-2D.md](docs/DESENHOS-2D.md) | Pessoa e IA | Desenho nativo, montagem, PDF e validação de referências |
| [docs/prompts/05-desenho-2d.md](docs/prompts/05-desenho-2d.md) | Pessoa e IA | Briefing copiável para desenvolver o desenho |
| [docs/NORMAS-2D.md](docs/NORMAS-2D.md) | Pessoa e IA | Base normativa, crivo interno, CLI e limites de evidência |
| [standards/registry.json](standards/registry.json) | Pessoa e IA | Edições, fontes e substituições; não inclui as normas |
| [docs/prompts/06-revisao-normativa.md](docs/prompts/06-revisao-normativa.md) | Pessoa e IA | Continuidade e atualização do conhecimento |
| [docs/SKILLS.md](docs/SKILLS.md) | Qualquer um | Skills externas opcionais (não instaladas) |
| [docs/prompts/](docs/prompts/) | Qualquer um | Prompts copiáveis para o agente de IA |

## Verificação desta entrega

Os testes offline verificam matemática, algumas guardas estáticas, políticas de conexão e consistência do Word. O C# pode ser compilado contra a interop local sem conectar ao SOLIDWORKS. **As macros adaptadas exigem compilação e teste CAD em cada computador**, assim como exportação/reimportação. O kit não foi testado em todas as versões/idiomas; comparação de prefixo não comprova compatibilidade.

```powershell
python -m unittest discover -s tests -v
python tools/scan_release.py
powershell.exe -NoProfile -File tools/check-offline.ps1 -ConfigPath config.local.json
```

A regeneração do Word requer a dependência opcional de `requirements-docs.txt`; o arquivo pronto já está no repositório. Resultados e limites desta release estão em [docs/TESTES-DA-ENTREGA.md](docs/TESTES-DA-ENTREGA.md).

## Avisos finais

- Este repositório não promete que dados "rodando localmente" nunca saem da
  sua máquina — revise sempre a política do provedor de IA que você usa.
- Ignorar `config.local.json` no controle de versão é uma convenção de
  higiene, não uma garantia de segurança; confira o que está sendo commitado
  antes de qualquer push.
- Nenhuma dimensão ou parâmetro deste repositório corresponde a um produto
  real; são exercícios sintéticos de aprendizado.
