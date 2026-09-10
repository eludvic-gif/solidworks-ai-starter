# Solução de problemas

Referência standalone de erros e causas. Nada aqui afirma que uma execução
real no CAD ou uma renderização visual do Word foi testada nesta entrega —
os testes automatizados cobrem apenas parsing/compilação/reflexão e
matemática pura (veja [RELEASE-CHECKLIST.md](RELEASE-CHECKLIST.md), seção
"O que cada teste demonstra"). Registre qualquer teste local real numa cópia
do modelo [SMOKE-TEST.md](SMOKE-TEST.md) guardada fora do controle de
versão compartilhado.

## 1. Erros de conexão (`tools/connect-solidworks.ps1`)

A sonda é descartável: conecta, lê a revisão, desconecta — nunca mantém
sessão nem toca em geometria. O comportamento de timeout/repetição é
específico e não deve ser confundido:

| Situação | O script... |
|---|---|
| Tentativa individual passa de 12 segundos (timeout) | **Para imediatamente**, sem tentar de novo. Só o processo PowerShell filho descartável daquela tentativa é encerrado — o SOLIDWORKS e documentos abertos nunca são tocados |
| Erro contém `MK_E_UNAVAILABLE` ou `0x800401E3` | Repete (até `-Attempts`, 8 por padrão, 3 s entre tentativas) — nenhuma instância registrada no momento, pode aparecer depois |
| Erro contém `0x80010108` (RPC_E_DISCONNECTED) ou `0x800706BA` (servidor RPC indisponível) | Repete, mesma regra acima |
| Qualquer outro erro (inclusive erro de despacho/tipo incompatível) | **Para imediatamente**, sem repetir — não é um problema de disponibilidade, repetir não ajuda |
| Mais de um processo `SLDWORKS` ao mesmo tempo | Recusa por ambiguidade antes mesmo de tentar — nunca adivinha qual instância usar. Feche as instâncias extras manualmente **salvando qualquer trabalho pendente antes** — nunca finalize o processo à força; o script nunca decide isso por você |
| Nenhum processo `SLDWORKS` e sem `-LaunchIfAbsent` | Recusa e informa para abrir manualmente ou passar `-LaunchIfAbsent` explicitamente — só sugerido quando **não há** processo algum, nunca quando já existe um |
| SOLIDWORKS iniciado por `-LaunchIfAbsent` mas saiu antes de registrar | Recusa (evita repetir lançamento em loop) |
| Sonda retorna sucesso mas a contagem/PID de processos mudou entre o fim da sonda e a checagem seguinte | Para com erro de identidade — recusa continuar em vez de arriscar operar no processo errado |

Timeout e código de saída têm precedência; em saída não zero, o texto do erro classifica repetição. As decisões são funções puras testadas offline (`Get-ProbeDecision`/`Get-ConnectionDecision` em
`tools/connection-policy.ps1`, exercitada por `tools/check-offline.ps1`).

**Distinção importante:** um erro de **indisponibilidade** (nenhuma
instância registrada, ex. `MK_E_UNAVAILABLE`) tem causa e correção diferentes
de um erro de **despacho** (a conexão existe, mas uma chamada específica
falha por incompatibilidade de tipo/interface/assinatura de método) — não
tente corrigir um com a receita do outro. Erro de despacho geralmente indica
revisão de interop incompatível ou assinatura de método diferente da
esperada, não ausência de processo.

## 2. Diagnóstico offline (`tools/diagnose.ps1`)

Roda antes de qualquer conexão real; falhas aqui nunca tocam o SOLIDWORKS.

| Sintoma | Causa | Ação |
|---|---|---|
| "Use 64-bit Windows PowerShell 5.1..." | Rodando `pwsh` (PowerShell 7) ou x86 | Use `powershell.exe` (Desktop, 64 bits) |
| "Create config.local.json from config.example.json..." | Arquivo ausente | Copie `config.example.json` para `config.local.json` |
| "Missing absolute local file for interop_path/executable_path" | Caminho relativo ou arquivo inexistente | Use caminho absoluto real, confirmado no Explorer (Propriedades) |
| "Select the installed SolidWorks.Interop.sldworks.dll" / "...SLDWORKS.exe" | Nome de arquivo não bate | Aponte exatamente para esses dois nomes de arquivo, não para outra DLL/atalho |
| "An explicit major revision prefix such as 33. is required" | `expected_revision_prefix` não é dígitos+ponto (ex.: `"33.5"`) | Use só o prefixo principal, ex. `"33."` |
| Falha ao compilar/refletir a montagem de interop | DLL incompatível, corrompida ou de outra arquitetura | Reconfirme o caminho da instalação real via Propriedades do arquivo |

`diagnose.ps1` também reflete os métodos `IFeatureManager.FeatureRevolve2` e
`FeatureExtrusion3` da interop carregada e imprime nomes/tipos/quantidade de
parâmetros — isso é só uma checagem estática de assinatura, não uma chamada
real ao SOLIDWORKS.

## 3. Macros VBA

| Sintoma | Causa | Ação |
|---|---|---|
| `Sub main` ambíguo / erro de nome duplicado | O módulo padrão vazio criado por `Tools > Macro > New` não foi excluído após importar o `.bas` | Exclua o módulo padrão vazio |
| Referência marcada `MISSING` em `Tools > References` | Biblioteca de tipos do SOLIDWORKS não corresponde à instalada | Desmarque a referência quebrada, marque a versão instalada |
| Erro ao compilar antes de rodar | Referência ausente/quebrada, ou edição incompleta | Sempre `Debug > Compile` antes de rodar qualquer sub |
| `InputBox` do template cancelado/vazio | Ação intencional do usuário | Nada a corrigir — a macro aborta sem criar nada, como esperado |
| "Use an absolute local drive path without quotes or wildcards" | Caminho não é absoluto em unidade local (`C:\...`), contém aspas/`*`/`?`, ou é um caminho de rede UNC (`\\servidor\...`) | Informe um caminho absoluto local válido, sem aspas/curingas/UNC |
| "Caminho nao termina em .PRTDOT" / "Arquivo nao encontrado" | Extensão errada ou arquivo inexistente | Confirme o caminho exato de um `.PRTDOT` existente; não há busca automática |
| "Template contains existing geometry/sketches" / "Template contains bodies" | O `.PRTDOT` indicado não está vazio | Use um template limpo, sem corpos/esboços/recursos prévios |
| "SOLIDWORKS API revision '...' does not match the checked prefix '33.'" | A instância aberta tem revisão diferente da constante `EXPECTED_REVISION_PREFIX` **do próprio arquivo `.bas`** | Esse gate é independente do `expected_revision_prefix` de `config.local.json` — mudar o JSON não muda a macro. Reveja/teste explicitamente os dois antes de usar outra revisão |
| "Active document changed. Operation stopped." | Outro documento ganhou foco, ou seleção mudou durante a execução | Não clique/troque de aba/rode outra automação enquanto a macro está executando |
| Furo pedido não é cortado mesmo com parede positiva | Comportamento esperado de `ConeValidation.bas`: `main` **nunca** executa corte, seja qual for o sinal da parede — ela só constrói o cone e classifica o pedido | Use `ConeBore9.bas`/`RunConeBore9` se precisar do corte de fato executado |

**Identidade de documento — VBA `Is` vs. `IUnknown` (.NET):** o operador VBA
`Is` usado em `RequireActive` compara referências de objeto **dentro do
mesmo processo** — é uma guarda local válida, mas não é a mesma garantia que
uma comparação real de identidade COM. O auxiliar `.NET` deste kit
(`tools/SwConnection.cs`, `SameComObject`) compara ponteiros `IUnknown`
nativos via `Marshal.GetIUnknownForObject` dos wrappers no mesmo contexto cliente COM. Não compare valores numéricos de ponteiros obtidos em processos diferentes: eles não são identificadores globais.
Nunca use `ReferenceEquals` do C#/.NET para essa comparação, e nunca use
`ActiveDoc` como substituto de uma referência perdida.

## 4. Testes e geração do guia

| Sintoma | Causa | Ação |
|---|---|---|
| `python -m unittest discover -s tests -v` falha | Ambiente Python errado, ou markdown/tabela malformada (para os testes de `test_release.py`) | Confirme Python 3.12; revise o markdown alterado |
| `python tools/build_guide.py` recusa sobrescrever | `docs/GUIA-COMPLETO.docx` já existe | Use `--replace` conscientemente |
| `build_guide.py` falha ao interpretar uma tabela | Colunas inconsistentes entre linhas de uma tabela em pipe (`\|`) | Corrija a tabela para ter o mesmo número de colunas em todas as linhas |
| `build_guide.py` falha por bloco de código não fechado | Uma cerca de código sem par correspondente | Feche o bloco; cercas indentadas também são reconhecidas |
| `python tools/scan_release.py` reporta um achado | Caminho pessoal, credencial ou padrão suspeito no texto | Revise manualmente — a varredura é heurística, não prova ausência de problema |
| `tools/verify-guide.ps1` falha em alguma etapa | Agrega testes Python + `scan_release.py` + `check-offline.ps1` em sequência | Rode cada um separadamente para isolar qual etapa falhou |

## 5. Fora do escopo automatizado

Os testes offline **não cobrem**: execução real de VBA, chamadas COM reais,
timeout/robustez de processo real, reabertura do CAD, reimportação
geométrica real (STEP/DXF) ou resistência física. Trate qualquer sucesso
relatado por um teste offline como evidência de que o texto/código está bem
formado — não como prova de que a operação real no CAD funciona.
