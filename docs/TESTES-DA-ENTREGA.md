# Verificações da entrega — 2026-09-10

## Executado nesta preparação

- 33 testes Python de matemática: PASS. Folgas e extremos de tolerância, NaN/infinito, sinais de compensação idealizada, interferência, parede radial, capacidade em grade e profundidade de escareado.
- 3 testes estáticos VBA: PASS. Presença de guardas, ausência de operações de salvar/fechar/exportar, corte bloqueado antes de NewDocument e assinatura de revolução com 20 argumentos. Não compilam nem executam VBA.
- Análise sintática dos scripts PowerShell e 11 decisões puras de conexão: PASS. Ausência de instância, lançamento opt-in, múltiplos processos, prevenção de relançamento repetido, estados de erro/sucesso/timeout.
- Cliente C# compilado com a interop local `33.5.0.53`: PASS. Reflexão confirmou `FeatureRevolve2` com 20 parâmetros e `FeatureExtrusion3` com 23. Nenhum método de conexão COM foi chamado.

A suíte completa foi executada: **43 testes Python PASS** (33 matemática, 3 guardas VBA estáticas e 7 verificações de release). As verificações de release incluem links/âncoras, scanner de tipos/padrões sensíveis, texto/metadados/relacionamentos do DOCX e correspondência ordenada Word/Markdown. O scanner passou nos 36 arquivos do pacote. Houve uma execução intermediária com falha de links enquanto documentos complementares ainda estavam em criação; após concluí-los e revisar âncoras, a suíte completa passou. Rode os comandos abaixo para obter o resultado da cópia recebida:

```powershell
python -m unittest discover -s tests -v
powershell.exe -NoProfile -File tools/check-offline.ps1 -ConfigPath config.local.json
python tools/scan_release.py
```

## Não executado nesta preparação

- SOLIDWORKS não foi aberto, conectado, modificado nem encerrado para preparar o kit.
- As macros adaptadas não foram compiladas ou executadas no editor VBA. Os fontes originais foram demonstrados historicamente em SOLIDWORKS 2025 SP5, mas isso não valida automaticamente a adaptação ou outro computador.
- Não houve teste de timeout em processo real, encerramento/reinício proposital do CAD ou recuperação de trabalho não salvo. Testes da política são funções puras, não ensaios de falha integrados.
- Não houve nova exportação/reimportação CAD nesta entrega. A placa é um exercício sintético proposto, sem gerador ou arquivo CAD entregue.
- Não houve inspeção visual da paginação do Word em um renderizador de escritório. O teste de conteúdo/XML é separado da aparência final.
- Não há teste físico, análise estrutural, certificação de fabricação ou ganho de desempenho de IA medido.

## Como registrar sua instalação

Use [SMOKE-TEST.md](SMOKE-TEST.md) em uma cópia local. Um teste não realizado deve permanecer **NÃO TESTADO**. Conteúdo e métodos de API devem ser verificados novamente na versão instalada; prefixo de versão igual não é prova de compatibilidade completa.
