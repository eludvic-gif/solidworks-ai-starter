# Verificações da entrega

## Atualização documental — 2026-09-11

- Adicionado módulo de desenhos 2D nativos, montagem, cotas/cortes/detalhes, PDF/reabertura, referências, limpeza autorizada e vídeo demonstrativo. Incluídos prompt copiável e seção autossuficiente no guia/Word.
- Corrigido acesso público e documentadas as duas contas. Fork requer sincronização explícita, não automática.
- **48 testes Python PASS:** 43 anteriores e 5 contratos documentais. Os novos testes checam presença/coerência dos passos e limites; não executam CAD nem provam precisão de uma peça.
- Scanner de release: **39 arquivos PASS**, junto da revisão manual do conteúdo novo. Nenhuma peça, medida proprietária, captura, vídeo, configuração local ou driver específico do laboratório foi incluído.
- Sintaxe PowerShell + 11 decisões puras de conexão: **PASS**. Compilação C# foi explicitamente **SKIPPED** nesta execução sem ConfigPath; não houve mudança no cliente de conexão.
- Word regenerado com python-docx 1.2.0; texto em ordem, hash da fonte e ausência de embeddings/relacionamentos externos conferidos pela suíte. Paginação visual em editor de escritório não foi inspecionada.
- Evidência histórica separada: as operações de vista, cota associativa, corte, detalhe, montagem posicionada e exportação PDF foram demonstradas no laboratório local em SOLIDWORKS 2025 SP5. O exercício sintético publicado NÃO foi executado ponta a ponta nesta atualização. Não foi publicado um novo gerador CAD.
- Limitações preservadas: tolerâncias/liberação de fabricação não inferidas; explosão nativa e portabilidade de referências Interconnect não declaradas como resolvidas; vídeo recriado não representa o tempo real completo de execução.

## Registro inicial — 2026-09-10

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
