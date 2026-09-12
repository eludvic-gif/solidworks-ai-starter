# AGENTS.md — Regras para agentes de IA neste repositório

Este arquivo segue a convenção `AGENTS.md`. Alguns agentes o carregam automaticamente; outros precisam receber uma instrução explícita de leitura. Confirme o comportamento da sua ferramenta. O `CLAUDE.md` deste kit remete a estas regras.

Se você é uma IA lendo isto pela primeira vez: leia também
[docs/GUIA-COMPLETO.md](docs/GUIA-COMPLETO.md) antes de executar qualquer
script ou macro. Este arquivo é o resumo das regras; o guia completo tem o
"porquê" e o passo a passo.

## Escopo do que existe aqui

Laboratório pessoal, sem PLM, sem dados de produto real. Toda geometria de
exemplo (cone, furo, placa) é sintética. Nenhum nome de projeto real ou
dimensão de produto real deve ser introduzido nestes arquivos.

## Proibições absolutas

1. **Nunca** usar `app.ActiveDoc` como substituto de uma referência de
   documento perdida. Não há garantia de que seja o documento certo.
2. **Nunca** comparar identidade de objetos COM com `ReferenceEquals` do C#/.NET.
   Compare ponteiros `IUnknown` nativos (`Marshal.GetIUnknownForObject`), como
   já implementado em `tools/SwConnection.cs` (`SameComObject`).
3. **Nunca** reativar automaticamente um documento que não foi criado e
   rastreado pela própria execução atual. Verificar por título único registrado
   na criação, não apenas por nome (nomes como "Part1" se repetem). Após ativar, confirmar novamente a identidade COM do documento retornado e ativo.
4. **Nunca** matar o processo do SOLIDWORKS (`Stop-Process`, `taskkill` etc.),
   mesmo em timeout. A intervenção nesse caso é manual, do usuário.
5. **Nunca** chamar `CloseAllDocuments` ou qualquer rotina genérica de
   "limpeza" de documentos. `CloseDoc` descarta alterações não salvas sem
   avisar — só deve ser chamado em um documento específico, criado pela mesma
   execução, com intenção explícita, sem mudanças externas e sem trabalho não salvo a preservar.
6. **Nunca** repetir automaticamente uma operação de geometria que travou ou
   falhou no meio do caminho. O timeout/retry deste kit existe apenas para a
   fase de conexão (probe), nunca para transações de geometria.
7. **Nunca** trocar templates de peça, preferências globais do SOLIDWORKS,
   registro do Windows, PLM, política de segurança de macros ou add-ins.
8. **Nunca** usar `NewDocument` com fallback silencioso para outro template se
   o template pedido falhar.
9. **Nunca** enviar CAD, configurações locais, dados privados ou credenciais à rede. Login do assistente, obtenção de dependências e clone exigem política e autorização apropriadas. Commit/push/publicação somente quando explicitamente autorizados para o destino e material revisados; esta documentação não concede autorização automática.
10. **Nunca** presumir que "agente rodando localmente" significa que nenhum
    dado sai da máquina. Revise a política de dados do provedor de IA em uso;
    trate qualquer dado sensível como fora do escopo — use apenas dados
    sintéticos.

## Operações previstas, quando autorizadas no pedido atual

O arquivo descreve capacidades, não consentimento permanente. Obtenha autorização antes de criar geometria, iniciar CAD, instalar dependências/skills, sobrescrever arquivos ou publicar; não amplie um pedido de diagnóstico para modelagem.

- Ler arquivos de configuração e código deste repositório.
- Rodar `tools\diagnose.ps1` e `tools\check-offline.ps1` livremente — eles só
  leem arquivos, compilam/refletem código e não abrem o SOLIDWORKS.
- Rodar `tools\connect-solidworks.ps1` para uma sonda de conexão descartável,
  respeitando os limites de tentativa/timeout descritos abaixo.
- Importar e compilar as macros de exemplo em `examples/`, criando peças novas
  e não salvas, sem exportar ou fechar automaticamente.
- Rodar os testes Python (`python -m unittest discover -s tests -v`) e os
  utilitários `tools/scan_release.py` e `tools/build_guide.py`.

## Contrato de cada script

| Script | O que faz | O que nunca faz |
|---|---|---|
| `tools\diagnose.ps1 -ConfigPath <arquivo>` | Lê `config.local.json`, valida campos, verifica se os arquivos apontados existem, compila/reflete a montagem de interop apenas para checagem estática | Abrir ou conectar ao SOLIDWORKS |
| `tools\connect-solidworks.ps1 -ConfigPath <arquivo> [-LaunchIfAbsent] [-Attempts 8]` | Sonda C# descartável: timeout de 12 s por tentativa, até 8 tentativas (padrão), intervalo de 3 s entre tentativas; só inicia o SOLIDWORKS se `-LaunchIfAbsent` for passado | Manter sessão aberta, fazer qualquer operação de geometria, matar o processo |
| `tools\check-offline.ps1` | Testa parse/compilação de código, sem qualquer contato com o SOLIDWORKS | Abrir o SOLIDWORKS |
| `python -m unittest discover -s tests -v` | Roda os testes Python (stdlib) | Depender de rede ou do SOLIDWORKS |
| `python tools\scan_release.py` | Varredura estática de release/config | Alterar arquivos do usuário |
| `python tools\build_guide.py` | Gera `docs/GUIA-COMPLETO.docx` a partir do Markdown, usando `python-docx` 1.2.0 | Qualquer coisa além de gerar o Word |

## Decisão de conexão (o que `connect-solidworks.ps1` de fato decide)

- Timeout encerra imediatamente a sonda; não consome outras tentativas. O processo encerrado pelo supervisor é apenas seu próprio cliente PowerShell descartável. Reinício real e tratamento de timeout não foram ensaiados nesta release.
- `check-offline.ps1` sem `-ConfigPath` analisa sintaxe e testa políticas; a compilação C# é explicitamente pulada. Com configuração, roda diagnóstico em processo separado.
- `build_guide.py` recusa Word existente; use `--replace` somente após revisar o arquivo gerado e sua fonte. Preserve documentos editados manualmente em outro nome.
- 0 processos do SOLIDWORKS e `-LaunchIfAbsent` não foi passado: erro pedindo
  para abrir manualmente ou usar a flag.
- 0 processos e já houve uma tentativa de lançamento nesta mesma execução:
  erro de "crash loop prevented" — não relança automaticamente de novo.
- Exatamente 1 processo: prossegue para a sonda (`Probe`).
- Mais de 1 processo do SOLIDWORKS ao mesmo tempo: recusa por ambiguidade —
  não tenta adivinhar qual instância usar.
- Durante a sonda: timeout vira `Timeout`; código de saída 0 vira `Connected`;
  erros específicos de indisponibilidade (ver
  [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md)) podem virar `Retry`
  dentro do limite de tentativas; qualquer outro erro vira `Stop` — sem
  repetição automática indefinida.

## Configuração

`config.local.json` (cópia local de `config.example.json`, deve estar no
`.gitignore`) tem exatamente três campos:

| Campo | Formato exigido |
|---|---|
| `interop_path` | Caminho absoluto para `SolidWorks.Interop.sldworks.dll` instalado localmente |
| `executable_path` | Caminho absoluto para `SLDWORKS.exe` instalado localmente |
| `expected_revision_prefix` | Dígitos seguidos de um ponto literal, nada depois — ex. `"33."` (regex `^\d+\.$`); `"33.5"` é inválido |

Não existe (e não deve existir) chave de caminho de template neste JSON. O
caminho do template `.PRTDOT` é pedido interativamente pela macro via
`InputBox`, com o usuário confirmando um caminho já existente localmente;
cancelar ou deixar vazio aborta a macro sem criar nada.

## Macros de exemplo (`examples/`)

- `ConeValidation.bas` — pontos de entrada `main` (cria uma peça nova a partir
  do template informado) e `TestGeometryOnly` (matemática pura, sem tocar em
  nenhum documento).
- `ConeBore9.bas` — pontos de entrada `RunConeBore9` (cria peça nova) e
  `TestBore9Math` (matemática pura).
- Cada macro é independente e cria um `.SLDPRT` novo por execução — nunca
  salva, exporta ou fecha o documento automaticamente.
- Ao importar um `.bas` num projeto de macro novo (`Tools > Macro > New`),
  exclua o módulo padrão vazio gerado pelo SOLIDWORKS antes de rodar, para
  evitar `Sub main` ambíguo entre dois módulos.
- Confirme que a referência à biblioteca de tipos do SOLIDWORKS instalada
  aparece sem `MISSING` em `Tools > References` no editor de VBA, e compile o
  projeto (`Debug > Compile`) antes de rodar.
- O template usado deve ser um `.PRTDOT` vazio (sem corpos nem esboços
  pré-existentes). A macro usa "o primeiro plano padrão encontrado" para
  construir o esboço base — isso depende de como o template organiza seus
  planos, então meça o eixo resultante na peça gerada; não assuma uma
  orientação global fixa.

Detalhes de matemática (volumes, espessura radial, regra de bloqueio) em
[docs/GUIA-COMPLETO.md](docs/GUIA-COMPLETO.md#11-fundamentos-geométricos-e-matemática)
e em [docs/VALIDACAO.md](docs/VALIDACAO.md).

## Antes de gerar ou alterar qualquer geometria

1. Traduzir o pedido em função, interfaces, datums, eixos, unidades e
   critérios verificáveis — nunca assumir números genéricos quando há medida
   real disponível (do próprio CAD ou do usuário).
2. Registrar dimensões nominais, tolerâncias e folgas por interface; não
   copiar a mesma folga para tudo.
3. Se o usuário editar a peça manualmente, a versão salva por ele manda — não
   regenerar por cima com parâmetros antigos da macro, e preservar contornos
   já aprovados.
4. Separar aprovação visual, validação dimensional e ensaio físico; uma não
   substitui a outra.

## Exportação, kerf e validação

Regras completas em [docs/VALIDACAO.md](docs/VALIDACAO.md). Resumo:

- Nome de arquivo exclusivo (incluindo revisão/quantidade quando fizer
  sentido) para cada exportação de SLDPRT/STEP.
- DXF plano só faz sentido para uma face plana adequada (ex.: uma placa), não
  para a face curva do cone.
- Parâmetros de compensação (kerf) são independentes por caminho: contorno
  externo usa alvo `+k`, contorno interno usa alvo `-k`. Nunca aplicar a
  compensação duas vezes (uma vez no CAD e outra no software de corte).
  `k` é a largura efetiva total de corte no modelo idealizado de trajetória central; medir cupom antes. Folga total entre dimensões só vira folga por lado ao dividir por dois se o encaixe for simétrico/concentrado; tolerância ±t é desvio dimensional, não kerf nem folga.
- "Espessura radial" (usada nos exemplos de furo) é uma distância radial
  medida numa altura específica, não a espessura normal à face inclinada nem
  uma verificação de resistência mecânica.

## Recuperação de erros

Ver [docs/TROUBLESHOOTING.md](docs/TROUBLESHOOTING.md) para a tabela completa
de erros. Regra geral: identifique se o erro é de **indisponibilidade** (ex.
`MK_E_UNAVAILABLE` / `0x800401E3` — sem instância no ROT) ou de **despacho**
(erro de tipo/interface ao chamar um método já conectado) antes de decidir o
que fazer — são causas diferentes com correções diferentes.

## Skills opcionais

Nenhuma skill externa é necessária para usar este kit — as regras deste
arquivo e a matemática em `docs/GUIA-COMPLETO.md`/`docs/VALIDACAO.md` bastam.
Se você quiser avaliar skills de terceiros relacionadas a CAD/automação, veja
[docs/SKILLS.md](docs/SKILLS.md) antes de instalar qualquer coisa — nenhuma
delas foi incorporada a este repositório.

## Desenhos 2D, montagem e encerramento

Leia [docs/DESENHOS-2D.md](docs/DESENHOS-2D.md) antes de implementar um driver
SLDDRW. O módulo descreve operações de API demonstradas, não fornece o driver
privado nem autoriza copiar dados do laboratório para este repositório.

- Meça o modelo/configuração e prove uma vista/cota associativa antes de replicar.
- Confirme nomes localizados, enums e referenciais modelo/folha/esboço; retorno
  não nulo de corte/detalhe não comprova plano ou região corretos.
- Não fabrique tolerâncias, datum, revisão ou aprovação; pendências impedem liberação.
- Reabra nativo, confira cotas e todas as páginas do PDF. Pack and Go não prova
  portabilidade; audite vínculos Interconnect e reabra a cópia sem fontes originais.
- Limpeza exige autorização pertinente, inventário/dependências e seleção exata
  dos temporários próprios; prefira Lixeira e registre hashes. Nunca apague por
  extensão/wildcard ou porque o nome parece antigo. Um lembrete de hook não é
  prova de término nem autorização genérica para exclusão automática.
- Vídeo novo deve usar cópias, captura exclusiva da janela e indicação de
  demonstração recriada; sem modificar gravações existentes ou publicar CAD.

## Base normativa e revisão estruturada 2D

Antes de novas revisões técnicas, leia [docs/NORMAS-2D.md](docs/NORMAS-2D.md) e
[standards/registry.json](standards/registry.json). Use o verificador
`tools/review_drawing.py` somente com metadados/evidências reais autorizados e saída
nova; o exemplo JSON é sintético, com hash/tolerâncias/afirmações inventados para teste.

- Registre edição exata, data, acesso e contrato. Catálogo, prefácio, sumário e
  trecho parcial não equivalem ao texto integral. Não invente cláusulas.
- Não migre desenhos legados por substituição automática de número de norma.
- Campos de material, inspeção, datum e tolerância exigem fundamento; nunca
  preenchê-los artificialmente para passar os testes.
- O verificador não mede CAD nem autentica evidência. `review_required`, exit 0
  e `iso_compliant=null` NÃO são aprovação, conformidade ou liberação de fabricação.
- Preserve somente resumos próprios, links, código e testes no kit público.
  Não incorporar PDFs/prévias, scans, extrações ou tabelas de normas; ser acessível
  publicamente não transfere direitos de redistribuição.
- Para atualizar a base, revalide fontes e testes. Não acessar bibliotecas privadas,
  comprar normas ou publicar sem autorização específica.

## Para outros agentes de IA (não Claude Code)

Este arquivo foi escrito para ser lido manualmente por qualquer agente, humano
ou IA, que trabalhe neste repositório. Se seu agente não carrega `AGENTS.md`
automaticamente, aponte-o explicitamente para este arquivo no início de
qualquer sessão de trabalho aqui.
