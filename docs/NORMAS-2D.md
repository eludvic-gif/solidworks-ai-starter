# Normas e revisão técnica de desenhos 2D

Referência pesquisada em **2026-09-12**. Este módulo preserva conhecimento original, referências e um verificador genérico. Não contém normas completas, prévias PDF, páginas digitalizadas, extrações textuais, modelos CAD reais ou evidências privadas. Não é material oficial ISO/BSI nem certificado de conformidade.

## 1. O que foi aprendido e o que foi realmente lido

O [registro](../standards/registry.json) reúne **20 registros**, incluindo históricos, e **8 relações de substituição** confirmadas em prefácios de prévias oficiais. Quinze registros tiveram prévias consultadas; isso não significa quinze textos integrais. As prévias tinham 1–8 páginas, frequentemente apenas capas, prefácios, sumários e introduções.

Na ISO 128-3:2022, a prévia também continha escopo, definições e a cláusula 4.1. O critério de selecionar a vista principal pela capacidade de informar função/fabricação/montagem foi lido. A verificação por software apenas pede a justificativa: não decide se a vista escolhida é tecnicamente a melhor.

**Nenhuma norma foi lida integralmente nesta pesquisa.** Um título no sumário não é cláusula lida. Resumo comercial não autoriza implementar regras detalhadas. Texto de tracked changes mistura trechos removidos/adicionados e não substitui a versão de registro. Um exemplo de figura normativa não equivale a uma especificação completa da peça.

Cada registro distingue edição ISO, adoção nacional, acesso efetivo, status observado e fonte. `Current` significa estado observado no catálogo BSI naquela data, não serviço atualizado automaticamente nem confirmação de adoção ABNT. O ano da adoção britânica não deve ser copiado como ano ISO.

## 2. Mapa de referências

| Tema | Referência identificada | Aplicação e limite |
|---|---|---|
| Representação | ISO 128-1:2020 | Fundamentos; prévia preliminar, regras completas não lidas |
| Linhas | ISO 128-2:2022 | Linhas e anexos por área; larguras/hierarquias não implementadas por cláusula |
| Vistas/cortes/seções | ISO 128-3:2022 | Escolha da vista principal; projeções e anexos exigem leitura adicional |
| Apresentação de cotas | ISO 129-1:2018 + Amd 1:2020 | Não confundir apresentação com escolha/interpretação da tolerância |
| GPS fundamental | ISO 8015:2011 | Princípios e operadores; sumário não comprova regras completas consultadas |
| Tolerâncias geométricas | ISO 1101:2017 | Notação/interpretação de tolerâncias; não implementadas integralmente |
| Datums | ISO 5459:2024 | Datum e sistemas; função/inspeção não são escolhidas automaticamente pela norma |
| Tamanhos lineares | ISO 14405-1:2025 | Revisão técnica com alterações de sintaxe e operadores |
| Especificações gerais | ISO 22081:2021 | Não é uma troca automática de número em notas legadas |
| Textura por perfil | ISO 21920-1:2021 | Indicação; parâmetros/operadores e inspeção precisam das partes aplicáveis |
| Projeção | ISO 5456-2:1996 | Símbolo e disposição requerem conferência da norma integral |
| Folha | ISO 5457:1999 + Amd 1:2010 | Não inferir margens/layout de capas ou PDFs de exemplo |
| Identificação | ISO 7200:2004 | Campos documentais; nosso mínimo de revisão é política interna, não tabela transcrita |
| Escalas/letras/ajustes | ISO 5455, 3098-1, 286-1, 2768-1 | Ver partes/edições e limitações individuais no registro |

Fontes oficiais e páginas de prefácio estão indicadas no JSON. As normas não acompanham este kit: obtenha acesso legal pelo editor ou biblioteca licenciada. Não baixe cópias ilícitas nem contorne autenticação/paywall.

## 3. Substituições que não podem ser ignoradas

- ISO 5459:2011 → **ISO 5459:2024**.
- ISO 1101:2012 e sua corrigenda de 2013 → **ISO 1101:2017**.
- ISO 14405-1:2016 → **ISO 14405-1:2025**.
- ISO 2768-2:1989 → **ISO 22081:2021**; essa relação **não substitui a ISO 2768-1**.
- ISO 1302:2002 → **ISO 21920-1:2021**.
- ISO 128-2:2020 → **ISO 128-2:2022**.
- ISO 128-3:2020 e ISO 128-43:2015 → **ISO 128-3:2022**.

Sucessão documental não significa equivalência técnica. Desenho legado pode continuar vinculado a uma edição contratual: registrar justificativa e revisão, sem migrar silenciosamente. Não substituir uma nota `2768-mK` por `22081` por busca/substituição. A revisão 2025 de tamanhos lineares contém mudanças técnicas; prefácio permite identificar a necessidade de revisão, não reconstruir todas as regras de sintaxe.

## 4. Método de trabalho para a pessoa e a IA

1. **Função e contrato:** interfaces, comportamento do material, fabricação/inspeção e requisitos fornecidos. Não tratar chapa, espuma e peça rígida como equivalentes.
2. **Baseline:** normas com edição exata, origem e exceções contratuais. Não presumir equivalência ISO/ASME/ABNT.
3. **Cobertura:** requisito → característica → vista/cota → aceitação → inspeção. Hash/manifesto declarados não medem a peça.
4. **Vistas:** justificar a principal; escolher projeção e conferir símbolo/disposição, cortes/detalhes e escala. A cláusula 4.1 consultada depende do contexto de projeção; não inferir uma regra universal de nomear toda vista projetada com letra.
5. **Cotas:** valores associativos, sem texto sobreposto escondendo erro; evitar controles redundantes. Cota de referência/TED isolada não fornece aceitação neste perfil interno. Casas decimais não substituem tolerância.
6. **GPS:** datums precisam elemento identificado, função e realização na inspeção. Não adicionar letras/tolerâncias genéricas apenas para parecer técnico. Verificar zonas, modificadores e ordem com as fontes aplicáveis.
7. **Gerais e textura:** especificar abrangência/exclusões, parâmetro/superfície/unidade/base de avaliação; não copiar pressupostos antigos de aceitação ou rugosidade global sem função.
8. **Arquivos:** reabrir nativo, conferir configuração/referências e revisar todas as folhas PDF. Aprovação estética, testes de software e resistência física são coisas distintas.
9. **Conclusão:** falhas bloqueiam; lacunas normativas e julgamento funcional continuam explícitos. Nunca gerar assinatura/aprovação de fabricação por inferência.

## 5. Verificador disponível

[tools/drawing_review.py](../tools/drawing_review.py) implementa o perfil interno `engineering_v2`. O [CLI](../tools/review_drawing.py) lê apenas JSON; não abre CAD, não acessa rede e não escreve no arquivo de entrada. Usa o registro curado do kit e recusa sobrescrever a saída.

Checagens: identidade/revisão/configuração da fonte; material/processo; controle documental; folhas/escalas/projeção; vistas não vazias; referências derivadas; cota/vista/característica; finitude; dangling/override; IDs e controles duplicados; limites de tolerância; datums; cobertura/inspeção; edição histórica/sem evidência; gerais/textura; PDF e reabertura.

São **políticas internas de revisão estruturada**, não implementação integral das normas citadas. Campos booleanos de evidência são afirmações de quem produziu o JSON: o verificador não autentica revisores, não confirma o hash contra um modelo nem mede geometria. Seu perfil é orientado a revisão ISO_GPS; aceitar a string ASME não o torna um verificador ASME. Não usar para liberação de máquina.

### Executar sem instalar CAD

Na raiz do kit, Python 3.12, somente biblioteca padrão:

```powershell
# Crie output apenas se ainda não existir; a pasta é ignorada pelo Git
if (-not (Test-Path output)) { New-Item -ItemType Directory output }
python tools/review_drawing.py examples/drawing-review.synthetic.json output/drawing-review.json
python -m unittest discover -s tests -v
```

O exemplo é **inteiramente sintético**, com hash inventado, tolerância didática e afirmações de revisão feitas somente para testar a estrutura. Não corresponde a um desenho CAD, material aprovado ou processo real. Não reutilize seus valores de tolerância em produção.

Resultado esperado: `review_required`, `release=NOT_AUTHORIZED`, `iso_compliant=null`. Código de saída **0 significa apenas que a revisão estruturada terminou sem bloqueios**, nunca aprovação; **2 significa revisão bloqueada**. O mesmo destino não pode ser reutilizado: escolha outro nome depois de inspecionar resultados.

Campos principais do JSON:

- `source`: model_id, revision, configuration, sha256; identificação declarada.
- `material` e `process_basis`: fonte da especificação, não dedução por aparência.
- `titleblock`: document_id, revision, title, sheet_count, status=review; mínimo interno.
- `sheets`: IDs, scale=[numerador,denominador], projection_symbol, vistas e dimensões.
- `dimensions`: value_si e limites em SI; comprimentos em metros, ângulos em radianos quando aplicável. Não confundir unidade de exibição com unidade da API.
- `requirements`: dimension_ids, functional_reason, inspection_method.
- `datums`, `geometric_controls`, `general_specifications`, `surface_texture`: opcionais quando aplicáveis, com vínculos explícitos e revisão humana.
- `standards`: designation com edição; legacy_contract e justification apenas se existir contrato legítimo.
- `pdf_all_sheets_reviewed`, `native_reopen_verified`: evidência declarada, não prova automática.

**Limites adicionais:** não valida toda sintaxe GPS, larguras de linha, lista normativa de escalas, semântica completa dos operadores ou datum DOF. Não há extrator automático de SLDDRW neste módulo. Importações programáticas usam dicionários no esquema mostrado; para JSON externo, prefira o CLI, que bloqueia entradas inválidas e chaves duplicadas.

## 6. Preservar e atualizar sem perder rastreabilidade

- Versionar código, testes, resumos próprios, URLs, datas, edições e decisões de revisão.
- Guardar fontes licenciadas e evidências reais somente no armazenamento autorizado, fora deste repositório público. `.gitignore` não impede adição forçada: revisar staging.
- Atualizar registro a partir de fonte oficial; registrar se foi catálogo, prefácio, cláusula parcial ou texto integral.
- Não promover `full_text_read=false` a true por existir um PDF ou título no sumário.
- Executar testes negativos, revisão de privacidade, links e integridade documental antes de publicar.
- Usar commits com motivo e escopo; manter edições históricas identificadas em vez de apagar evidências de decisões legadas.
- Outra IA deve ler [AGENTS.md](../AGENTS.md), este guia e o registro. Um repositório preserva conhecimento consultável; não treina permanentemente o modelo.

## 7. Pendências normativas reais

Acesso legal às cláusulas de cotagem/apresentação, linhas/projeções/símbolos/carimbo, fundamentos GPS, datums/operadores e gerais/textura continua necessário para uma revisão completa. Confirmar adoções ABNT separadamente. Conforme o recurso, investigar edições aplicáveis das famílias 14253, 7083, 13715, 15786, 6410, 10579, 2692 e 5458. Não acrescentar normas por lista decorativa: ligar cada uma ao requisito que controla.

O [prompt de continuidade](prompts/06-revisao-normativa.md) orienta futuras sessões. O [histórico do módulo](HISTORICO-NORMAS-2D.md) registra o alcance desta primeira publicação.
