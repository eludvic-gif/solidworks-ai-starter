# Checklist de revisão e publicação

Este arquivo é um procedimento, não um relatório automático de testes.

## Antes de modelar em outro computador

- Ler o guia completo e AGENTS.md; usar somente geometria sintética no primeiro teste.
- Confirmar licença, versão, PowerShell 5.1 x64, mesma sessão desktop e arquivos da instalação confiável.
- Validar caminhos locais ignorados pelo Git. Não carregar DLL recebida de terceiros.
- Executar testes Python, análise PowerShell e compilação C# offline.
- Compilar VBA e executar os testes matemáticos no editor; depois autorizar criação de cada nova peça.
- Executar as duas demonstrações separadamente, conferir dimensões, corpo, árvore, seção e volumes.
- Validar arquivo salvo/reaberto e STEP. DXF exige geometria plana adequada, não a lateral curva do cone.
- Registrar evidências locais e limites: nenhuma aprovação mecânica automática.

## Antes de compartilhar uma revisão do kit

1. Conferir `git status --short`, `git diff` e a lista de arquivos novos. Não usar `git add .` em pastas de projetos existentes.
2. Revisar todos os arquivos que entrarão no staging; nenhum CAD, screenshot, log privado, configuração local, DLL, executável ou macro binária.
3. Gerar Word a partir da versão revisada de `GUIA-COMPLETO.md`; revisar texto, links e metadados. A geração recusa sobrescrita por padrão; `--replace` só para o Word gerado pelo kit após revisão.
4. Rodar `python -m unittest discover -s tests -v` e `python tools/scan_release.py` na raiz do kit.
5. Rodar `powershell.exe -NoProfile -File tools/check-offline.ps1`; com interop instalada, acrescentar `-ConfigPath config.local.json`.
6. Adicionar somente arquivos revisados ao Git. Conferir `git diff --cached --stat`, `git diff --cached` e `git ls-files`. Rodar `python tools/scan_release.py --tracked`.
7. Verificar manualmente nomes de empresa/produtos, dimensões confidenciais e URLs internas. O scanner é heurístico: não conhece todos os dados privados e não substitui a revisão humana.
8. Confirmar autorização para publicar, conta, destino e visibilidade. Um repo privado ainda envia dados a um serviço externo.
9. Commitar e enviar somente o material autorizado; conferir hash remoto e visibilidade depois.

## O que cada teste demonstra

- Python: funções matemáticas, sinais, domínio, alguns limites e consistência do pacote/documento.
- PowerShell: sintaxe de todos os scripts e 11 decisões puras da política de conexão.
- Compilação C#: compatibilidade dos tipos com a DLL instalada, sem abrir COM.
- Testes estáticos: presença/ausência de padrões de proteção, não prova formal de segurança.
- Word: comparação ordenada de todo texto principal e tabelas com a transformação do Markdown, SHA da fonte, inspeção de XML/relacionamentos/metadados. Isso não verifica visualmente paginação.
- Não coberto pelos testes offline: execução VBA, chamada COM real, espera/timeout de processos reais, reinício do CAD, reimportação geométrica e resistência física.
