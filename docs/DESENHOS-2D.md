# Desenhos 2D nativos — do modelo ao pacote de revisão

Referência: **2026-09-11**, SOLIDWORKS 2025 SP5. Este módulo documenta operações demonstradas em laboratório local e o procedimento para reproduzi-las com **uma peça sintética**. Não inclui o driver específico daquele laboratório, arquivos CAD, vídeos, templates ou geometria de produtos. Os trechos são contratos para implementar um driver revisado; **não são uma macro completa pronta para executar**.

Leia [AGENTS.md](../AGENTS.md) e o [guia principal](GUIA-COMPLETO.md). Use o [prompt de desenho](prompts/05-desenho-2d.md). O CAD deve ser acessado somente com autorização e por um driver sequencial. Preparar este módulo não executa modelagem.

## 1. O que significa desenho nativo

Um `.SLDDRW` contém vistas referenciadas a um modelo/configuração e cotas ligadas às entidades geométricas. Um SVG, imagem renderizada ou PDF com linhas projetadas não substitui esse documento. O PDF é uma saída para leitura/impressão, não a fonte associativa.

Há quatro resultados distintos:

1. **Prova de API:** uma vista e uma cota real funcionam.
2. **Estudo para revisão:** características representadas, hipóteses/pendências explícitas.
3. **Desenho liberado:** requisitos, material, tolerâncias, inspeção e aprovações efetivamente definidos por responsáveis autorizados.
4. **Pacote portátil:** referências resolvem na cópia entregue, sem depender do diretório de origem.

Sucesso num nível não comprova o seguinte. Use `PARA REVISÃO — NÃO LIBERADO PARA FABRICAÇÃO` enquanto existirem lacunas. Não invente assinatura, responsável, data de aprovação ou revisão oficial.

## 2. Preparar uma execução isolada

1. Escolha uma peça **sintética** já salva e autorizada; a placa de 120 × 80 × 10 mm com quatro furos Ø8 do guia serve como exercício, não requisito industrial.
2. Leia os padrões de desenho autorizados localmente: template `.DRWDOT`, formato `.SLDDRT` ou PDF de referência. Não publique esses padrões se forem privados.
3. Confirme material/processo, escopo do fornecedor, interfaces e superfícies que não podem mudar. Diferencie fornecimento de corpo, acessórios e montagem.
4. Faça inventário do SOLIDWORKS: PID único, revisão, caminho/tipo/configuração de cada documento, visibilidade e alterações pendentes. Dirty flag isolado não comprova que um documento já alterado permaneceu intacto.
5. Gere uma pasta nova em `output/` e nomes de documentos exclusivos, inclusive entre pastas. Há operações CAD que podem retornar um documento já aberto de mesmo nome; sempre verifique o caminho devolvido.
6. Copie fontes necessárias, registre SHA256 antes/depois e abra **somente cópias** para análise. `OpenDoc6` com opções silent/read-only é útil para entrada; confira enums, retorno, erros e avisos.
7. Não use o sucesso do probe como sessão permanente: o driver precisa fazer suas próprias guardas de conexão/identidade. Se falhar parcialmente, preserve estado e diagnostique antes de continuar; não repita o build por tentativa.

Para obter os caminhos de templates, leia as opções de locais de arquivos da instalação. Não altere preferências globais. O JSON de conexão deste kit continua com três campos; template e saída devem ser parâmetros locais separados de um futuro driver.

## 3. Medir antes de cotar

Meça BREP: extremos `Body2.GetExtremePoint`, faces planas, cilindros, centros/raios, arestas e profundidades. A árvore pode conter um corpo importado sem cotas de esboço: ausência de parâmetros não significa ausência de geometria mensurável.

- Comprimentos geométricos: metros → milímetros multiplicando por 1000.
- Área: m² → mm² por 10⁶; volume: m³ → mm³ por 10⁹.
- Ângulos: confira unidade de cada método; não trate radianos como graus.
- `EditRebuild3`, erros de features e `Body2.Check3.Count == 0` são evidências diferentes.
- Caixa aproximada, volume ou screenshot não provam posição, fundo ou quantidade de furos.

Crie uma matriz local:

| Característica sintética | Evidência CAD | Vista/cota | Tolerância | Inspeção |
|---|---|---|---|---|
| Envelope da placa | Extremos BREP e planos externos | Duas dimensões ortogonais | Pendente | Instrumento/capacidade a definir |
| Espessura | Distância entre planos | Lateral ou corte | Pendente | Medir superfícies de apoio |
| Furos | Quatro cilindros: centro, eixo e diâmetro | Planta, centros e Ø | Pendente | Medir cada furo e posição |
| Condição passante | Topologia e ausência de fundo | Corte/nota apropriada | Conforme requisito | Conferir percurso completo |

Não copie tolerâncias de uma revisão antiga só porque o nominal parece igual. Classifique cada tolerância como **transferível com justificativa**, **proposta para aprovação** ou **pendente**. Uma nota “conforme modelo 3D” não cria limites de aceitação nem torna toda dimensão não cotada uma dimensão básica.

## 4. Refletir a API instalada sem abrir CAD

Na raiz do kit, com `config.local.json` preenchido:

```powershell
$config = Get-Content -Raw config.local.json | ConvertFrom-Json
$asm = [Reflection.Assembly]::LoadFrom($config.interop_path)
$type = $asm.GetType('SolidWorks.Interop.sldworks.IDrawingDoc')
$type.GetMethods() |
    Where-Object { $_.Name -match 'CreateDrawViewFromModelView3|CreateSectionViewAt5|CreateDetailViewAt4|SetupSheet6' } |
    ForEach-Object {
        $_.ToString()
        $_.GetParameters() | ForEach-Object { $_.Name + ': ' + $_.ParameterType.Name }
    }
```

Este trecho apenas reflete a DLL instalada. Para enums, carregue `SolidWorks.Interop.swconst.dll` da mesma instalação e examine o tipo correspondente. Não baixe DLLs para corrigir uma assinatura.

### Contratos observados em 2025 SP5

| Interface/método | Uso | Cuidado |
|---|---|---|
| `ISldWorks.NewDocument` | Criar desenho por template | Null/tipo diferente de desenho → parar; nunca fallback ActiveDoc |
| `IModelDoc2.GetModelViewNames` | Descobrir vistas do modelo | Nomes localizados; não presumir que o literal inglês exista |
| `IDrawingDoc.CreateDrawViewFromModelView3` | Inserir vista referenciada | Caminho/configuração explícitos; posição na folha em metros |
| `IDrawingDoc.SetupSheet6` / `NewSheet4` | Folha, escala, projeção, zonas | Conferir dimensões, ordem dos argumentos e enums locais |
| `IView.SelectEntity` | Selecionar entidade na vista | Booleano de retorno; limpar seleção anterior; escrita serial |
| `IModelDoc2.AddHorizontalDimension2` / `AddVerticalDimension2` / `AddDimension2` | Cota associativa | Posição de anotação não é valor da dimensão |
| `IDrawingDoc.CreateSectionViewAt5` | Corte a partir de linha selecionada | Coordenadas do esboço da vista, não coordenadas da folha |
| `IDrawingDoc.CreateDetailViewAt4` | Detalhe a partir de círculo selecionado | Transformação, escala, label e recorte precisam de inspeção |
| `IView.GetVisibleEntities2` | Arestas visíveis, inclusive no corte | Percorrer componentes; arestas de seção podem ser novas entidades |
| `IExportPdfData.SetSheets` | Selecionar folhas para PDF | Conferir retorno, enum e nomes efetivos |

## 5. Provar uma vista e uma cota antes do desenho completo

O pseudocódigo C# abaixo omite deliberadamente attach, ownership, busca de entidades e salvamento. Implemente essas guardas antes de executar. `leftEdge` e `rightEdge` devem vir da medição BREP, não de nomes/índices adivinhados.

```csharp
// app, drawingModel, drawing, modelPath e entidades já validados.
// ownedDrawing deve ser a referência criada/rastreada nesta execução.
RequireActiveIdentity(app, ownedDrawing);
var view = drawing.CreateDrawViewFromModelView3(
    modelPath, verifiedModelViewName, 0.140, 0.150, 0.0);
if (view == null) throw new Exception("View creation failed");
view.ReferencedConfiguration = verifiedConfiguration;
view.UseSheetScale = 0;
view.ScaleDecimal = 0.5; // 1:2

drawingModel.ClearSelection2(true);
if (!view.SelectEntity(leftEdge, false) ||
    !view.SelectEntity(rightEdge, true))
    throw new Exception("Entity selection failed");
var dd = (DisplayDimension)drawingModel.AddHorizontalDimension2(
    0.140, 0.080, 0.0);
if (dd == null) throw new Exception("Dimension creation failed");
var dimension = dd.GetDimension2(0);
var annotation = (Annotation)dd.GetAnnotation();
if (dimension == null || annotation.IsDangling() || dd.GetOverride())
    throw new Exception("Invalid associative dimension");
if (Math.Abs(dimension.SystemValue - 0.120) > 1e-8)
    throw new Exception("Synthetic plate width mismatch");
```

O epsilon acima é apenas critério computacional para o exercício de 120 mm; não é tolerância de fabricação. Inspecione também entidades anexadas, tipo da cota e o texto: cotas radial e diametral não são intercambiáveis. Não use `SetOverride` ou texto integral para esconder valor errado. Prefixos como quantidade não devem substituir a medida.

Salve a prova em nome único, reabra uma cópia e confira o vínculo. Só depois replique cotas. A prova local demonstrou criação de vista e cota nativa sem dangling/override; isso não torna a busca de arestas universal.

## 6. Organizar vistas, cortes e detalhes

### Vistas e projeção

- Confirme primeiro/terceiro diedro pelo padrão e pela disposição das vistas, não pelo país ou idioma.
- Use escalas preferenciais adequadas, indique exceções e confira legibilidade no tamanho físico do papel. Mais folhas são melhores que cotas ilegíveis.
- Use vistas ortográficas alinhadas e isométrica como apoio. Preferir vista projetada quando o alinhamento associativo for necessário; duas vistas nomeadas independentes não criam automaticamente uma relação de projeção.
- Confira `swDisplayMode_e`: no ambiente testado `swWIREFRAME = 0` e `swHIDDEN = 2`. Wireframe mostra arestas de trás como se visíveis e pode confundir furos cegos com passantes. Nunca escolher número sem confirmar o enum.

### Corte

1. Ative o desenho próprio e a vista-pai correta, limpe seleção.
2. Obtenha o esboço da vista e sua transformação. Converta os pontos desejados do modelo → folha (`ModelToViewTransform`) → esboço (`ModelToSketchTransform`), verificando escala e orientação em um piloto.
3. Crie a linha por `SketchManager.CreateLine` no referencial correto, selecione apenas essa linha.
4. Chame `CreateSectionViewAt5(X, Y, Z, label, options, excludedComponents, depth)` com opções conferidas.
5. Valide tipo de vista, posição da linha, sentido das setas e plano realmente seccionado. Retorno não nulo não prova corte correto: uma linha fora do centro pode gerar apenas vista projetada sem revelar a interface.
6. Confira hachuras, fundos, paredes e entidades do corte. Cote as arestas que pertencem à seção, não arestas arbitrárias do modelo.

Não copie uma linha “centrada em zero” de outro exemplo: esse zero pode ser a origem do esboço da vista, não do modelo nem da folha.

### Detalhe

Na vista-pai, converta o centro ao esboço, crie e selecione um círculo e use `CreateDetailViewAt4`. A posição da vista de detalhe é na folha; centro/raio do círculo pertencem ao esboço. Confira o efeito da escala nas duas operações. Verifique região realmente ampliada, chamada na vista-pai, label, escala e cotas. Apenas texto “Detalhe” com uma imagem ampliada não é detalhe associativo.

## 7. Formato, carimbo e anotações

Prefira `.DRWDOT`/`.SLDDRT` autorizados. Quando só existir PDF, reconstrução local do formato requer revisão visual; não chame uma versão simplificada de reprodução exata. Preserve o padrão de projeção, bordas, campos, tipografia e espessura de linhas, mas não herde assinaturas/notas inaplicáveis.

- `EditTemplate` edita formato; `EditSheet` retorna ao desenho. Confirme modo e esboço ativos.
- Para linhas curtas de borda, `SketchManager.AddToDB` pode evitar interferência de snapping/inferência. Preserve o valor anterior e restaure em `finally`; depois valide o esboço.
- Formate por `Annotation.GetTextFormat` / `SetTextFormat`, posicionando por `SetPosition2`. Confirme os retornos e tamanho físico da fonte.
- Não use números mágicos para cores/espessuras nem altere preferências globais para contornar o template.
- Evite cadeias fechadas/redundantes; marque dimensões de referência como tal. Dê referências funcionais coerentes a furos, apoio e profundidades.
- Inspecione todos os textos após mudar escala/posição. Overlap de rótulo e corte não aparece num teste de valor da cota.

## 8. Desenho de montagem

1. Liste componentes, quantidade e ordem; mantenha hipóteses explícitas. Componentes ausentes não podem ser fabricados por inferência.
2. Crie `.SLDASM` próprio com template autorizado; `AddComponent5` requer referências carregadas e caminhos verificados.
3. Posicione com transformações rígidas (rotação válida, determinante +1, sem escala), confira `Transform2` e geometria resultante. Componente fixado em posição não equivale a mates funcionais nem a simulação.
4. Para empilhamento sintético: base rígida de 12 mm, rebaixo de 2 mm e camadas de 6 e 18 mm → altura nominal `12 + 6 + 18 − 2 = 34 mm`. Declare ausência de compressão/adesivo; os valores deste exemplo são fictícios.
5. Inspecione apoio, trajetória de inserção, contatos e interferências. Material compressível exige ensaio; não escale o modelo apenas para eliminar uma interferência.
6. Gere planta/lateral/corte do conjunto, isométrica, lista de componentes e sequência. Balões/BOM precisam corresponder aos componentes, sem texto decorativo substituindo vínculo.
7. Arestas obtidas por componente podem estar em coordenadas locais. A base de uma camada pode não aparecer porque coincide com o topo da outra: confira o contexto de seleção, não force a entidade invisível.
8. Vista explodida nativa usa configuração/etapas de explosão. Se usar outra montagem com camadas afastadas para ilustração, identifique-a como **montagem separada ilustrativa**, não como configuração explodida validada nem folga real.

No laboratório, uma tentativa de passo de explosão retornou erro de seleção; foi usada disposição ilustrativa separada. O fluxo de explosão nativa **não foi validado ponta a ponta** e não é prometido por este kit. A inspeção do corte deve diferenciar hachuras dos componentes adjacentes.

## 9. PDF e reabertura

1. Confirme documento ativo por identidade, fonte/configuração e todas as folhas.
2. Salve `.SLDDRW` em destino inexistente, verificando Booleano, erros, avisos e arquivo.
3. Obtenha `ExportPdfData` por `GetExportFileData(swExportPdfData)`.
4. Defina `ViewPdfAfterSaving = false`. No ambiente testado, selecionar explicitamente `swExportData_ExportSpecifiedSheets` com `drawing.GetSheetNames()` funcionou; `SetSheets` com array nulo falhou. Não ignore esse retorno.
5. Exporte PDF via `ModelDocExtension.SaveAs` com objeto PDF configurado. Confirme todas as páginas, tamanho A3/A4 e escalas.
6. Reabra cópia de nome exclusivo do `.SLDDRW`; confira fontes/configurações, vistas não vazias, cotas, `IsDangling`, `GetOverride`, entidades anexadas e unidades. Reconstrução e verificação da versão salva são etapas separadas.
7. Renderize **todas** as páginas localmente; confira sobreposições, recorte, fonte, símbolos, hachuras e contraste. No laboratório foi usado PDFium com Pillow em ambiente isolado; nenhum renderizador é instalado por este módulo.

Registrar contagens ajuda a detectar perdas, mas número de cotas não prova cobertura técnica. Comparar todas às entradas sem uma leitura independente da geometria também não basta.

## 10. Referências e pacote portátil

`GetPackAndGo` / `SavePackAndGo` podem reunir os arquivos. Inspecione primeiro `GetDocumentNames`: uma peça nativa pode manter vínculo **3D Interconnect** para um STEP externo.

- Recuse dependências inesperadas até esclarecer origem/escopo. Um arquivo existir em Downloads não o torna autorizado para publicação.
- Destino novo; conferir colisão de nomes antes de achatar pastas.
- Sucesso do Pack and Go **não comprova relink**. Audite dependências gravadas, inclusive com busca automática desabilitada.
- `ReplaceReferencedDocument` foi útil em cópias nativas fechadas, mas não resolveu todo vínculo Interconnect. Não romper vínculos ou reimportar automaticamente: pode alterar a identidade/geometria.
- Reabra a entrega com originais indisponíveis em ambiente controlado, sem renomear/apagar fontes do usuário para simular isso. Confira caminho efetivamente resolvido, modelo, configuração e dimensões.
- Se essa prova não ocorrer, reporte **portabilidade não validada**. Incluir o STEP e instruções de localização é mitigação, não prova de independência.

## 11. Limpeza autorizada depois da validação

Autorização de um usuário para o próprio laboratório não é consentimento universal para quem clona este kit. Obtenha escopo atual ou uma preferência recorrente explícita.

1. Inventarie finais, fontes, pacotes e documentos abertos/alterados.
2. Calcule dependências transitivas antes de classificar temporários. Mesmo conteúdo/hash não significa mesmo papel: duas peças iguais podem ser referenciadas em caminhos distintos.
3. Liste candidatos por caminho exato, motivo, equivalente preservado e hash; não apague por wildcard, extensão ou número de revisão.
4. Preserve fontes do usuário, ajustes, versões válidas, PLM, scripts e evidências mínimas. Arquivo incerto fica.
5. Feche só documentos próprios identificados, sem trabalho externo a preservar. Referências podem continuar carregadas invisivelmente; fechar uma aba não é descarregar todo o modelo.
6. Prefira Lixeira, confira retorno/arquivos restantes e hashes dos preservados; registre o que foi removido.
7. Mantenha montagem/desenhos finais visíveis conforme combinado. Um hook de lembrete pode ajudar, mas **não deve apagar CAD automaticamente ao evento Stop**, que não comprova conclusão ou validação.

## 12. Vídeo novo para explicar o processo

Opcional, separado do desenho técnico. Sem gravador previamente disponível, conferir ferramenta/licença e obter autorização de instalação.

- Grave operações reais em **cópias de demonstração**, nunca edite finais para encenar o histórico.
- Identifique como **demonstração recriada**; não alegue mostrar todas as ações passadas ou medir desempenho.
- Capture janela específica por HWND/PID verificados, não a área inteira da tela. `PrintWindow` foi usado localmente, mas pode retornar preto/incompleto em outros contextos; testar. **Sem fallback silencioso para desktop**, que pode capturar mensagens privadas.
- Clipes úteis: vistas/cotas; corte/detalhe; montagem/camadas. Preserve originais novos e gere prévia separada.
- Capture cadência/tempo real corretamente ou declare a aceleração: alimentar vídeo CFR sem compensar frames perdidos pode encurtar a duração. Logs de relógio não são timecodes do MP4.
- `ffprobe` confere streams/resolução/duração; decodificação integral detecta falhas, não conteúdo confidencial. Quadros amostrados não são inspeção manual de todos os frames.
- Ao usar texto no FFmpeg em Windows, indicar um arquivo de fonte local pode evitar dependência de configuração Fontconfig. Nunca instalar fontes/DLLs às cegas.
- Gravação existente do usuário permanece intacta. Não publicar CAD/identificadores sem revisão própria; `.mp4` não pertence à release pública deste kit.

## 13. Critério de conclusão e continuidade

Entregue nativo, PDF, fontes referenciadas autorizadas, matriz de cobertura, manifest de hashes e pendências. Distinga testes offline, evidência histórica da API, execução atual, reabertura e ensaio físico. Nenhum desses níveis substitui aprovação de fabricação.

Antes de ampliar o driver: prove um recurso, capture o estado, confira o arquivo salvo e só então replique. Evite tentativas idênticas, agentes sem ferramenta adequada e vários clientes COM concorrentes. Se a etapa falhar, registre o ponto exato e preserve a última saída válida.

Fontes de API: [SOLIDWORKS API Help](https://help.solidworks.com/) com ano/idioma da instalação; reflexão local dos tipos `IDrawingDoc`, `IView`, `IDisplayDimension`, `IAnnotation`, `IExportPdfData`, `IPackAndGo` e enums correspondentes. A documentação online que só mostra “Loading” não comprova uma assinatura.
