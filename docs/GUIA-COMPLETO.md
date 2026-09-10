# Guia Completo — SOLIDWORKS AI Starter

Referência: **10 de setembro de 2026**. Laboratório replicável para pessoas e agentes de IA, com exemplos sintéticos, sem arquivos de produtos reais. O Word `GUIA-COMPLETO.docx` é gerado desta mesma fonte. Scripts e fontes VBA estão no repo privado https://github.com/eludvic-gif/solidworks-ai-starter.

## 1. Objetivo e limites

Preparar um computador Windows, orientar uma IA, verificar a API do SOLIDWORKS, testar conexão somente leitura, executar macros em peças novas, conferir dimensões e aprender a salvar, exportar e reimportar resultados. Um exercício opcional de placa permite praticar DXF.

O agente escreve/executa ferramentas autorizadas; o SOLIDWORKS continua sendo o motor CAD. Um chat sem ferramentas locais não controla seu desktop. Uma skill fornece instruções e referências, não treina o modelo nem certifica engenharia. Voz, PLM, serviços corporativos, análise estrutural e geração universal de produtos estão fora do escopo.

**Regras:** não editar documentos existentes; não confundir aparência com medidas; não enviar informações privadas ao agente ou ao GitHub. Agente executando no computador não significa modelo ou dados necessariamente locais: confira a política do provedor e da organização.

## 2. Pré-requisitos e instalação

| Componente | Referência e uso |
|---|---|
| Windows | Windows 11, sessão desktop interativa |
| SOLIDWORKS | Instalação licenciada; fluxo original demonstrado em 2025 SP5, revisão API 33.5 |
| PowerShell | Windows PowerShell 5.1 x64 (`powershell.exe`), não PowerShell 7 (`pwsh`) nem x86 |
| Python | Python 3.12; somente biblioteca padrão para os testes |
| Word | DOCX pronto incluído; use um leitor compatível |
| python-docx | Dependência opcional 1.2.0, apenas para regenerar Word |
| Git/GitHub CLI | Opcionais para clone; download ZIP é alternativa |
| Editor/IA | VS Code + Claude Code oficial são um caminho; outros agentes podem seguir AGENTS.md |

1. Instale/ative SOLIDWORKS pelos canais autorizados do fabricante/organização. Confirme que cria peça nova manualmente. Licença não acompanha o kit; o CAD pode acessar normalmente o licenciamento da sua instalação.
2. Confira a versão em `Ajuda > Sobre o SOLIDWORKS` e o editor VBA em `Ferramentas > Macro > Nova`. Se faltar, siga o instalador/administrador oficial; não baixe DLLs aleatórias.
3. Instale Python 3.12 x64 por https://www.python.org/downloads/windows/ ou catálogo aprovado. Habilite acesso pelo terminal se permitido, abra um terminal novo e rode `python --version`. Se o comando abrir a loja ou não existir, confira instalador/PATH; `py -3.12` pode selecionar pelo launcher. Use o mesmo interpretador nos comandos seguintes.
4. Windows PowerShell 5.1 acompanha Windows. Abra a versão não x86. Use mesma conta, sessão desktop e nível de elevação do CAD. Não execute como administrador por tentativa de corrigir COM.
5. Para clone, instale Git por https://git-scm.com/downloads/win e GitHub CLI por https://cli.github.com/ conforme a política local. Confira `git --version` e `gh --version`. Para ZIP, nenhum deles é necessário.

No PowerShell:

```powershell
$PSVersionTable.PSVersion
[Environment]::Is64BitProcess
python --version
```

Esperado: 5.1, `True`, Python 3.12.x. Outra versão/service pack CAD exige verificação: passar na comparação do prefixo `33.` **não comprova compatibilidade**.

## 3. Obtendo o repositório

O repo é privado: outra pessoa precisa receber acesso do proprietário. O link sozinho não concede permissão. Entre com sua própria conta GitHub.

```powershell
gh auth login
gh repo clone eludvic-gif/solidworks-ai-starter
```

Alternativa: no navegador autenticado, abra o repo, `Code > Download ZIP`, extraia numa pasta local. Não execute de dentro do ZIP. A raiz contém `README.md`, `config.example.json`, `examples`, `tools` e `docs`.

**Todos os comandos seguintes são executados na raiz do kit.** No VS Code, `Arquivo > Abrir Pasta`, escolha a raiz; `Terminal > Novo Terminal`. O Word está em `docs/GUIA-COMPLETO.docx`. Para executar os exemplos, você precisa dos arquivos do repo além deste documento.

## 4. Preparando a IA

1. Instale VS Code por https://code.visualstudio.com/ ou catálogo aprovado.
2. Na aba Extensões, procure **Claude Code**, confira publisher Anthropic e siga instalação/login oficiais. Não use pacotes de terceiros com nome semelhante. Use sua conta/plano autorizado, nunca credenciais alheias ou chaves num arquivo do repo.
3. Abra o agente nesta pasta. O `CLAUDE.md` remete a `AGENTS.md`. Outros agentes podem carregar AGENTS automaticamente ou precisar de instrução explícita; confirme na ferramenta.
4. Autorize leitura/diagnóstico nesta pasta. Não desligue globalmente confirmações/proteções. Escrita CAD, instalação, exclusão e publicação exigem autorização pertinente.
5. Chat simples pode gerar instruções para execução manual. Agente em nuvem não alcança automaticamente o COM do desktop. Não exponha COM pela internet para contornar isso.

Prompt inicial:

```text
Leia AGENTS.md e docs/GUIA-COMPLETO.md. Trabalhe só nesta pasta e com os
exemplos sintéticos. Primeiro verifique pré-requisitos, configuração e testes
offline. Não inicie CAD, gere geometria, instale dependências ou publique
sem autorização. Não leia outros projetos ou credenciais. Informe o que
passou, o que falhou e qual é o próximo teste necessário.
```

## 5. Pastas e dados locais

- `examples/`: dois módulos VBA; não são projetos SWP prontos.
- `tools/`: diagnóstico/conexão, matemática e gerador de Word.
- `tests/`: testes offline; `docs/`: guias, prompts e checklists.
- `config.local.json`: configuração do computador, ignorada pelo Git.
- `local/`: crie para macros `.swp` e registros locais; `output/`: novas revisões CAD. Ambas são ignoradas.

Não trabalhe em pastas de produção. Revisão nova usa nomes/pasta exclusivos, sem sobrescrita. `.gitignore` não protege conteúdo já versionado ou adicionado à força: revise o staging.

## 6. Configuração local

Crie somente se não existir:

```powershell
if (Test-Path config.local.json) { throw 'Configuracao ja existe; revise antes de alterar.' }
Copy-Item config.example.json config.local.json
```

Edite os três campos:

| Campo | Valor |
|---|---|
| `interop_path` | Caminho absoluto da `SolidWorks.Interop.sldworks.dll` instalada |
| `executable_path` | Caminho absoluto do `SLDWORKS.exe` instalado |
| `expected_revision_prefix` | Revisão principal e ponto, como `33.`; não `33.5` |

Localize `SLDWORKS.exe` pelo atalho do menu Iniciar, propriedades/local do arquivo. Na instalação, procure `api\redist\SolidWorks.Interop.sldworks.dll`. Use arquivos da mesma instalação confiável. Copie somente caminhos, não DLL/executável para o repo. Em JSON, barras invertidas são duplicadas: `\\`. O exemplo traz um caminho comum, não descobre automaticamente o seu.

São aceitos caminhos absolutos de unidade local C, D etc., não UNC de rede. Os scripts verificam nome/existência, não autenticidade criptográfica da instalação. Mantenha configuração local fora do compartilhamento.

**Template VBA é separado:** JSON não configura macros. Cada BAS pede `.PRTDOT` numa caixa de entrada e possui constante própria `EXPECTED_REVISION_PREFIX = "33."`. Alterar JSON não altera VBA. Outra versão exige revisão das assinaturas e smoke test, não apenas remover a guarda.

## 7. Testes offline primeiro

```powershell
python -m unittest discover -s tests -v
python tools/scan_release.py
powershell.exe -NoProfile -File tools/check-offline.ps1 -ConfigPath config.local.json
```

Python deve terminar em `OK`: testa matemática, guardas estáticas, links e igualdade do texto Word/Markdown. Não compila VBA nem valida geometria.

`check-offline.ps1` analisa scripts e executa 11 decisões puras de conexão. Com `-ConfigPath`, também compila o cliente C# pelo diagnóstico; sem argumento informa compilação **SKIPPED**. Não abre ou conecta ao CAD.

Diagnóstico individual:

```powershell
powershell.exe -NoProfile -File tools/diagnose.ps1 -ConfigPath config.local.json
```

Carrega interop instalada, compila C# e mostra assinaturas por reflexão. Referência2025: `FeatureRevolve2` tem20 argumentos; `FeatureExtrusion3`,23. Interop/ajuda local prevalecem sobre exemplos da internet. Não adivinhe posições de argumentos.

Se a política bloquear scripts, **não use Bypass nem altere políticas globais**. Consulte `Get-ExecutionPolicy -List` e siga liberação/assinatura autorizada. Revise arquivos baixados antes de eventual desbloqueio permitido. VBA interno depende da política local de macros.

## 8. Unidades e identidade

API geométrica usa metros: `mm × 0,001 = m`. Volume m³ vira mm³ por `10^9`; área m² vira mm² por `10^6`. Ângulos normalmente em radianos: confira cada assinatura. Nomeie unidades e distinga raio/diâmetro.

Parâmetros declarados não provam geometria. Meça corpo, faces e distâncias. Imagem, malha e bounding box aproximado não comprovam apoio útil ou posição interna. BREP é a representação geométrica das faces/arestas; `GetExtremePoint` fornece extremos em drivers futuros.

C# tipado evita alguns erros de despacho dinâmico PowerShell. Em .NET, compare identidade COM por IUnknown, não só `ReferenceEquals` dos wrappers. Títulos podem se repetir. Nunca use `ActiveDoc` como fallback quando `NewDocument` falhar. Só reative documento próprio rastreado, título único e identidade novamente conferida depois de ativar.

## 9. Conexão externa sem geometria

Abra SOLIDWORKS normalmente na mesma sessão. Este probe não exige fechar documentos: não cria, salva ou fecha nada.

```powershell
powershell.exe -NoProfile -File tools/connect-solidworks.ps1 -ConfigPath config.local.json
```

Esperado: `CONNECTED revision=... pid=...`. A sonda lê revisão/PID, confere instância única e termina. **Não mantém conexão permanente** nem habilita modelagem por si só. Drivers futuros precisam conectar e validar referências novamente.

Se não houver processo, abertura autorizada:

```powershell
powershell.exe -NoProfile -File tools/connect-solidworks.ps1 -ConfigPath config.local.json -LaunchIfAbsent
```

- Sem flag/processo: recusa. Mais de uma instância: recusa ambiguidade.
- Até8 tentativas padrão, intervalo3s; `-Attempts` aceita1–20. Só erros específicos de indisponibilidade/desconexão são repetidos.
- Após12s bloqueado, **interrompe imediatamente**: encerra só seu cliente PowerShell descartável, nunca SOLIDWORKS. Timeout não é repetido oito vezes.
- CAD lançado que encerra não inicia ciclo de relançamento.
- Não repete geometria interrompida. Reinício/timeout reais não foram ensaiados nesta entrega.

Se COM externo falhar mas CAD funcionar, macros internas usam `Application.SldWorks` e não dependem do probe. Nenhuma ponte COM, MCP ou add-in é exigida para o exemplo.

## 10. Macros VBA de exemplo

### Encontrar template vazio

Consulte `Ferramentas > Opções > Opções do sistema > Locais de arquivos > Templates de documento` (nomes variam). Apenas leia a pasta, sem alterar preferências. Pelo Explorer identifique o `.PRTDOT` de peça vazio; confirme manualmente que cria só planos/origem, sem corpos/esboços existentes. Não use template de produto real.

A caixa exige caminho completo em unidade local, sem aspas/curingas/UNC. Vazio/cancelar termina antes da criação. Não há escolha automática. Primeiro plano de referência encontrado define orientação: altura/profundidade seguem o Y local do esboço, não um eixo global garantido.

### Importar BAS em SWP e executar

1. `Ferramentas > Macro > Nova` (`Tools > Macro > New`), salve `.swp` novo em `local/`. Nunca reutilize projeto de macro existente.
2. No editor VBA, remova somente o módulo padrão vazio recém-gerado. `Arquivo > Importar arquivo` (`File > Import File`), escolha `examples/ConeValidation.bas`.
3. `Ferramentas > Referências`: confira biblioteca SOLIDWORKS instalada, nenhuma `MISSING`. `Depurar > Compilar`: corrija erros antes de executar.
4. Cursor dentro de `TestGeometryOnly`, F5 no editor: quatro testes aritméticos sem documentos. Sucesso é condição para continuar, não aprovação CAD.
5. Autorize criação, cursor em `main`, F5, informe template e confirme intenção. Cria **só o cone**; informa parede zero para furo Ø5×15mm, sem executar corte.
6. Se aparecer cota, confirme raio5mm/altura30mm. Aguarde mensagem final. Não mude abas/seleção nem execute outra automação durante a sequência.
7. Para segundo teste, crie outro `.swp` novo, importe `ConeBore9.bas`. Compile, execute `TestBore9Math`, depois `RunConeBore9` sob autorização. Cone raio5/altura30; furo raio2,5/profundidade9mm.
8. A segunda macro cria outra peça, revolução sólida e corte por revolução. Não modifica cone anterior. Nenhuma salva/exporta/fecha/apaga ou acessa PLM.

**Não renomeie BAS para SWP:** módulo-fonte não é projeto executável. Fora do editor, `Ferramentas > Macro > Executar` seleciona projeto/ponto de entrada apropriado.

Fontes originais foram demonstrados no ambiente de referência. **Adaptações do kit não foram compiladas/executadas no CAD nesta entrega**; exigem smoke test por computador. Mensagens, nomes e testes são específicos: não basta mudar constantes e assumir generalização.

### Conferir árvore e geometria

Expanda árvore: primeiro cone tem perfil dimensionado/revolução; segundo tem dois perfis, revolução sólida/corte. Depois da macro, entre nos esboços, confira cotas e estado totalmente definido; saia sem alterações.

`Avaliar > Medir` (`Evaluate > Measure`): baseØ10, altura30. No segundo, selecione face cilíndrica: Ø5. Use `Vista de seção` pelo eixo: entrada na base, fundo plano, profundidade9, coaxialidade e sem abertura lateral. `Avaliar > Propriedades de massa`, sem seleção restritiva: volume em mm³, um sólido, nenhum recurso com erro.

Macros medem cotas, corpos, reconstrução, volume; segunda também raio cilíndrico. **Não** auditam completamente posições/fundos BREP, Check3, exportações ou resistência. Complete inspeção independente e registre usando `docs/SMOKE-TEST.md` em cópia local.

## 11. Fundamentos geométricos e matemática

Cone reto circular H30mm, baseØ10 (R5); furo coaxialØ5 (r2,5), entrada pela base, profundidade z e fundo plano.

```text
R(z) = R × (1 − z/H)
w(z) = R(z) − r = 2,5 − z/6 [mm]
Vc = πR²H/3 = 250π ≈ 785,398163397448 mm³
```

- z15: w0, caso degenerado bloqueado, não aceitável.
- z16: w<0, intercepta lateral.
- z9: w1mm. Para parede radial nominal≥1mm neste exemplo, z≤9.
- Removido em z9: `πr²z = 56,25π ≈ 176,714586764426 mm³`.
- Final: `193,75π ≈ 608,683576633022 mm³`.

Parede **radial** não é espessura normal mínima nem resistência. Material, tolerâncias, cargas e concentrações de tensão não são avaliados. Casas decimais apoiam comparação, não precisão fabril.

`tools/engineering_checks.py` contém funções puras: folga/tolerância, kerf, alvo externo compressível, parede cone, grade e escareado. Na raiz:

```powershell
python -c "from tools.engineering_checks import radial_wall_cone; print(radial_wall_cone(30,10,5,9))"
```

Esperado1.0mm. Testes finitos não provam todos os casos: declare hipóteses e confira o CAD construído.

## 12. Salvar, exportar e reimportar

Procedimento **manual/guiado**, não implementado nas macros. Use apenas peça sintética correta; confirme caminho/revisão além do título.

### Nativo e STEP

1. Crie pasta exclusiva como `output/rev-001`, se inexistente. `Arquivo > Salvar como`, tipo Peça SOLIDWORKS, nome `cone_furo9_rev001.SLDPRT`. Se existir, pare, não sobrescreva.
2. Reabra cópia de verificação do nativo, criada pelo Explorer com nome diferente. Reconstrua e repita medidas/volume. Arquivo salvo precisa passar, não só documento em memória.
3. Retorne à fonte conferida. `Arquivo > Salvar como > STEP`, nome exclusivo `cone_furo9_rev001.step`. Em opções confirme sólido/coordenadas previstos; registre formato/AP usado. Não altere preferências globais indiscriminadamente.
4. Abra STEP ou cópia de nome exclusivo. Árvore importada sem histórico paramétrico é normal. Confirme um sólido, sem falhas, envelope/volume, Ø5/eixo/fundo/profundidade. Meça unidades; fator1000 indica escala errada.
5. Se divergir, rejeite aprovação, preserve original. Reconfirme fonte/ativação e exporte nova revisão exclusiva. Sucesso da função/nome do arquivo não garantem conteúdo correto.

### DXF da face plana da placa da seção13

Não transforme lateral curva do cone em contorno plano de corte.

1. Na placa validada, selecione face plana superior com quatro furos. Use exportar DXF/DWG no menu da face ou `Arquivo > Salvar como > DXF`, opção faces/loops/arestas conforme versão.
2. No assistente confira face, orientação, um contorno externo/quatro internos, escala1:1 e mm. Sem textos/cotas/duplicatas. Salve `placa_rev001_face.dxf`, recusando substituir arquivo existente.
3. `Arquivo > Abrir`, DXF. Assistente: **nova peça/esboço2D**, template vazio e mm, não desenho de folha.
4. Meça120×80, centros eØ8. Cinco contornos fechados: externo+quatro internos. Círculos podem vir como arcos/segmentos; contagem bruta de entidades não prova equivalência.
5. Saia do esboço, extrusão10mm com quatro vazios internos. Compare volume, sólidos, dimensões e posições à placa nativa.
6. Contorno aberto/duplicado, escala errada ou falha de extrusão: rejeite entrega e revise exportação. Auditoria textual pode passar enquanto CAD rejeita; use ambas quando automatizar.
7. Feche só cópias identificadas sem trabalho a preservar. `CloseDoc` API pode descartar sem aviso; não use fechar-tudo.

Menus variam por versão/idioma: consulte ajuda local se necessário. Etapa indisponível é **NÃO VALIDADO**, nunca PASS.

## 13. Exercício sintético opcional — placa

Não há gerador automático incluído. Faça manualmente ou com IA autorizada:

1. Nova peça/template vazio. Plano padrão, esboço de retângulo centralizado na origem, cotas120×80mm e relações totalmente definidas. Saia e extrude10mm.
2. Na face plana, quatro círculosØ8 nos centros (−40,−20), (−40,+20), (+40,−20), (+40,+20)mm relativos ao centro. Dimensione posições/diâmetros e confira definição completa.
3. Corte passante, reconstrução. Confira um sólido, quatro furos, posições/bordas e ausência de erro. Use DXF da seção12.

```text
Volume = 120×80×10 − 4×π×4²×10
       = 96000 − 640π ≈ 93989,38070170253 mm³
```

Não há recomendação de material/potência/velocidade/resistência. Compatibilidade do material com laser, exaustão e procedimento aprovado da máquina são pré-requisitos separados; não corte material desconhecido.

## 14. Validação em camadas

| Camada | Evidência | Não comprova |
|---|---|---|
| Requisitos | Função, interfaces, datums, dimensões/fontes/hipóteses | Execução CAD |
| Cálculo | Fórmula/unidades/casos limite/teste independente | Forma/posição/topologia |
| CAD | Recursos, BREP, cotas, corpos, seção, reconstrução | Arquivo exportado |
| Intercâmbio | Reabrir STEP/DXF e comparar características | Material real |
| Visual | Vistas/seções/orientação | Exatidão/resistência |
| Físico | Cupom/protótipo/medidas/ensaio | Outros materiais/processos |

Na API, `EditRebuild3` e erros dos recursos são separados da integridade do corpo. `Body.Check` legado:1 válido/0 inválido. `Check2`: contagem de falhas. `Check3`: objeto de falhas, esperado `Count == 0`. Confirme assinaturas locais. Macros deste kit não implementam Check3; complete com `Avaliar > Verificar` da instalação ou driver revisado.

Volume/envelope iguais não comprovam posição interna. Confira furos por centro/eixo/diâmetro/profundidade/fundo, material que deve permanecer; encaixes por apoio real/trajetória de inserção/folgas. Transformações rígidas preservam orientação/determinante+1; confira todos os pares necessários numa grade.

Manifesto que repete entradas não mede CAD. Critérios e tolerâncias precisam ser explícitos e evidência vir do sólido construído/arquivo reaberto.

## 15. Folgas, compressibilidade e kerf

Folga total positiva=espaço; negativa=interferência. Receptor A±tA e inserto B±tB:

```text
Nominal total = A − B
Mínima total  = (A − tA) − (B + tB)
Máxima total  = (A + tA) − (B − tB)
```

Divida por dois para folga por lado apenas num encaixe simétrico/concentricidade justificada. Tolerância±t é desvio admissível, não folga nem kerf.

Espuma/vedação/material compressível não recebe automaticamente folga de peça rígida. Separe externo final, interferência escolhida por teste e tamanho/formato dos alojamentos. Se só borda externa precisa mudar, não escale tudo: preserve recortes aprovados.

Corte idealizado pela linha central: `k`=largura efetiva total, aproximadamente k/2 em cada borda oposta. Externo final≈caminho−k; abertura interna≈caminho+k. Para o alvo:

```text
Caminho externo = alvo externo + k
Caminho interno = alvo interno − k
```

Não compense valor arbitrário. Queima/conicidade/compressão podem invalidar modelo; medir cupom no mesmo material/espessura/processo. Não duplicar compensação já feita por CAM/controlador. Registre k como medido ou hipótese; não extrapole entre processos.

Edição manual salva pelo usuário passa a ser fonte. Copie-a em nova revisão, meça contornos e preserve o que não foi autorizado mudar; parâmetros antigos não podem sobrescrever ajuste. Prove preservação comparando contornos, descontando somente transformações solicitadas.

## 16. Recuperação sem perder trabalho

| Sintoma | Interpretação/ação |
|---|---|
| MK_E_UNAVAILABLE /800401E3 | COM não acessível, não prova travamento. Se ausente abrir/opt-in; se processo presente conferir inicialização/sessão/elevação, tentar VBA interno, nunca abrir segunda instância às cegas |
| TYPE_E_ELEMENTNOTFOUND | Pode ser despacho dinâmico PowerShell mesmo com COM válido: usar C# tipado |
| 80010108 /800706BA | Desconexão/servidor indisponível: retry limitado só do probe |
| Timeout | Cliente interrompido, CAD preservado; verificar UI/modal com usuário |
| Prefixo divergente | Conferir versão/interop/assinaturas antes de ajustar JSON e constante VBA |
| Template inválido | Conferir caminho local sem aspas e extensão/existência, sem ActiveDoc fallback |
| VBA MISSING/compilação | Corrigir referências da instalação antes de executar |
| Múltiplas instâncias | Usuário identifica/salva/preserva trabalho antes de fechar extra; nunca kill |
| Macro parcial | Deixar peça aberta, registrar etapa/erro; não rerodar cegamente |
| DXF não abre/extruda | Rejeitar corte, revisar unidades/contornos/duplicatas/exportação nativa |

Ao retomar, inventarie documentos/caminhos/save flags, separando usuário e execução. Save flag sozinho não prova imutabilidade de documento já sujo. Ative só referência própria inequívoca, identidade novamente conferida. Fechar/apagar temporários requer escopo autorizado; nada de limpeza genérica.

```text
A execução parou. Não repita modelagem. Identifique última etapa comprovada,
documento parcial e estado atual. Preserve trabalho não salvo, não encerre
SOLIDWORKS e não use ActiveDoc como fallback. Só diagnóstico autorizado.
Proponha próximo passo com saída nova; sucesso anterior não autoriza apagar.
```

## 17. Briefing para uma nova peça e continuidade

Antes da geometria, preencha e peça à IA para converter cada requisito em teste:

```text
Função:
Interfaces e fonte de cada medida:
Unidades, datums, eixos e direção de inserção:
Envelope/regiões proibidas:
Material/processo e limites conhecidos:
Nominais/tolerâncias/folgas/interferência por interface:
Superfícies/recortes que NÃO podem mudar:
Quantidade/padrão/preferências estéticas:
Critério numérico de aceite e método de medir:
Saídas solicitadas e pasta nova:
O que está autorizado agora:
O que depende de teste físico/nova autorização:
```

Cálculo→operação-piloto→validação→replicação. Reutilize wrappers testados; escrita CAD sequencial, testes offline independentes podem paralelizar. Não omita silenciosamente recurso funcional para fazer o build passar.

Ao terminar, registre fonte/revisão, hipóteses, alterações, valores medidos, arquivos finais/hashes e limites. Registros reais ficam localmente, não neste repo de exemplos. Próxima IA lê contexto autorizado e verifica arquivos atuais, não confia cegamente em memória antiga. Use prompts em `docs/prompts/`.

## 18. Skills opcionais e licenças

Nenhuma skill externa é necessária. Para avaliar referências: fixar commit, ler licença/código, incorporar só trechos permitidos com avisos. Não executar instaladores automaticamente.

- `wzyn20051216/solidworks-automation-skill`, revisão `5287d2e3d100dedb10e94910523f294a46176c54`: MIT examinada. Wrappers podem encerrar app, alterar templates globais e usar ActiveDoc fallback; não instalar integralmente por confiança no nome.
- `K-Dense-AI/scientific-agent-skills`, revisão `9cf7d9aea7d84754db4c167ab04b299d33c444bc`, lab-hardware-cad: MIT naquela revisão. Modelos Python executam código arbitrário sem sandbox; geradores podem sobrescrever saídas. Não incorporado.
- `flowful-ai/cad-skill`, revisão `fe4215970d39f388ff1afc411fac49a9c5f79756`: PolyForm Noncommercial naquela revisão. Não incorporar em uso empresarial sem direitos apropriados; isso não define licença do motor CadQuery.
- `github/awesome-copilot`, freecad-scripts: referência opcional; FreeCAD não instalado/validado pelo kit.

Revisão não significa endosso, atualidade permanente ou ganho de desempenho medido. Skills não substituem cálculo ou API instalada. Detalhes em `docs/SKILLS.md`.

## 19. Regenerar e verificar o Word

Word pronto já incluído. Para regenerar depois de editar Markdown, instale dependência opcional em ambiente virtual, se autorizado:

```powershell
python -m venv .venv
.\.venv\Scripts\python.exe -m pip install -r requirements-docs.txt
.\.venv\Scripts\python.exe tools/build_guide.py
```

Gerador recusa Word existente. Se for o documento gerado pelo kit e substituição autorizada, revise antes e use `--replace`. Edições manuais de Word devem ser preservadas em outro nome e incorporadas ao Markdown antes de regenerar.

```powershell
.\.venv\Scripts\python.exe tools/build_guide.py --replace
python -m unittest discover -s tests -v
python tools/scan_release.py
```

SHA256 da fonte está nos metadados. Testes comparam todo texto principal/células em ordem, inspecionam XML/relacionamentos. Links viram texto com destino offline; sem macros, OLE ou relacionamentos externos ativos. Isso não verifica aparência/paginação. Inspeção visual em editor de escritório não foi realizada nesta preparação.

## 20. Checklist por computador

- [ ] Pré-requisitos/sessão/caminhos verificados; configuração privada não versionada.
- [ ] Testes offline e compilação C# comprovados, não apenas SKIPPED.
- [ ] Probe conecta com revisão/PID esperado, ou caminho VBA interno escolhido deliberadamente sem dependência do probe.
- [ ] SWP novo, referências corretas, VBA compilado e matemática executada.
- [ ] Cone simples criado; furo de parede zero não executado.
- [ ] Cone/furo9: cotas, corpo, volume, seção, diâmetro/eixo/fundo verificados.
- [ ] Nativo/STEP salvos/reabertos/comparados, se solicitados.
- [ ] DXF da placa em mm, cinco contornos e extrusão comparada, se exercitado.
- [ ] Trabalho do usuário preservado, fechamento só de temporários autorizados.
- [ ] Teste físico separado, nenhuma certificação inferida.

Não testado é **NÃO TESTADO**, nunca PASS. Copie `docs/SMOKE-TEST.md` para `local/` e registre sua instalação.

## 21. O que foi verificado nesta entrega

Fluxo original demonstrado em SOLIDWORKS2025SP5. Nesta preparação: testes Python, guardas estáticas, política de conexão, sintaxe PowerShell, compilação C# com interop local e estrutura/conteúdo Word. Não se abriu, conectou, modelou ou fechou SOLIDWORKS para gerar este kit.

Não testado: execução VBA adaptada, relançamento/timeout real, todas versões/idiomas, placa proposta, nova exportação/reimportação, renderização visual Word e resistência física. Detalhamento em `docs/TESTES-DA-ENTREGA.md`. Limitações fazem parte da entrega.

## 22. Compartilhamento e privacidade

Revise conteúdo/comentários/nomes/caminhos/imagens/metadados antes de compartilhar. Não copie laboratório inteiro, CAD, screenshots, logs, credenciais, dados empresariais ou dimensões proprietárias. Scanner detecta alguns padrões/tipos, não todo segredo possível.

Publicação futura autorizada: conferir `git status --short`, `git diff`, adicionar só revisados, conferir `git diff --cached`/`git ls-files`, rodar `python tools/scan_release.py --tracked`. Repo privado também envia dados a serviço externo. Confirmar conta/destino/visibilidade/escopo e conferir commit remoto depois.

## 23. Referências e próximos passos

- SOLIDWORKS API Help: https://help.solidworks.com/ — selecionar ano/idioma e API Help.
- Python Windows: https://www.python.org/downloads/windows/
- VS Code: https://code.visualstudio.com/
- Claude Code: https://code.claude.com/docs/
- Git: https://git-scm.com/downloads/win
- GitHub CLI: https://cli.github.com/manual/
- python-docx: https://python-docx.readthedocs.io/

Consulte [troubleshooting](TROUBLESHOOTING.md), [validação](VALIDACAO.md), [skills](SKILLS.md), [prompts](prompts/), [checklist de release](RELEASE-CHECKLIST.md) e [smoke test](SMOKE-TEST.md). Para outra IA, forneça este guia, arquivos do kit e instrução para ler AGENTS.md antes de agir.
