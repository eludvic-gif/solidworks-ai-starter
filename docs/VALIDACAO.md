# Validação

Metodologia de validação geométrica e de compensação de corte. Complementa
[GUIA-COMPLETO.md](GUIA-COMPLETO.md); nada aqui afirma que uma execução real
no CAD foi testada nesta entrega.

## 1. Princípio geral

"Aprovação visual" de uma peça no CAD, uma captura de tela, ou um único
número de volume **nunca** provam, sozinhos, que a geometria está correta.
Combine sempre múltiplas medidas independentes antes de aceitar um
resultado.

## 2. `Check3` não é o mesmo que reconstrução bem-sucedida

- `EditRebuild3()` retornar sucesso só confirma que a **árvore de recursos**
  recalculou sem erro reportado pelo recurso (`GetErrorCode2`). Isso não
  garante que o corpo resultante é geometricamente válido.
- `Check3.Count == 0` verifica a **integridade do corpo** (auto-interseções e
  outras falhas de sólido) — é uma checagem diferente, adicional. A checagem
  legada `Check` tem semântica diferente das duas; não misture as três.
- As macros de exemplo deste kit (`examples/ConeValidation.bas`,
  `examples/ConeBore9.bas`) chamam `EditRebuild3` e conferem o código de erro
  do recurso, mas **não** chamam `Check3` nem fazem uma checagem completa de
  extremos do BREP. Trate isso como um passo manual adicional, feito pelas
  ferramentas do SOLIDWORKS (ou por um driver revisado à parte), não como
  algo já coberto pelo exemplo.

## 3. O que medir (nunca confie só em volume)

- Extremos do BREP (por exemplo GetExtremePoint em driver revisado) e faces reais de apoio. Bounding box aproximado não comprova área útil ou cotas exatas.
- Diâmetros e eixos de furos/cilindros (use a ferramenta Medir sobre a face
  cilíndrica, não estime pelo desenho).
- Profundidade e presença de fundo dos furos cegos.
- Contagem de loops/contornos, ausência de duplicatas.
- Unidades sempre em milímetros — confirme antes de comparar números.
- Volume e dimensões nominais são um sinal a mais, não a prova final.

## 4. Exportação e reimportação — o que comparar

Passo a passo de execução está em
[GUIA-COMPLETO.md, seção 12](GUIA-COMPLETO.md#12-salvar-exportar-e-reimportar).
Ao reabrir cada exportação como um documento novo (nunca sobrescrevendo o
original), compare:

- **SLDPRT:** volume, dimensões principais, contagem de corpos.
- **STEP:** os mesmos itens acima, feitos no arquivo reaberto, mais recursos
  críticos (furos, faces de referência) presentes e nas posições esperadas.
- **DXF (só de face plana):** contorno externo + furos formam a contagem de
  loops esperada (por exemplo, o exercício da placa da seção 13 do guia
  produz 5 loops: 1 contorno externo + 4 furos), sem arcos/segmentos
  duplicados e sem texto de anotação residual no arquivo.

Depois de validar, feche apenas os documentos que você mesmo abriu para
comparação, sem alterações não intencionais — nunca uma rotina genérica de
"fechar tudo".

## 5. Regra de precedência: edição manual do usuário

Se você (ou o agente de IA, com sua aprovação) editar e salvar uma peça
manualmente, essa versão salva passa a ser a fonte de verdade. Nunca
regenere por cima dela com os parâmetros antigos de uma macro, e preserve
contornos já aprovados. "Salvar e reabrir" é sempre o próximo passo manual
depois de uma edição — não é implementado como macro neste kit.

## 6. Compensação de corte (kerf) — sem confundir total com por lado

Modelo de idealização por linha de centro (centerline), implementado em
`tools/engineering_checks.py::laser_contour_size`:

- `k` é a largura **efetiva total** do kerf — o material perdido pelo corte
  em si, medido através das duas bordas na linha de centro do feixe/lâmina —
  não a perda numa única borda isolada.
- **Contorno externo:** alvo `+ k` (compensa para fora).
- **Contorno interno (furos):** alvo `− k` (compensa para dentro).
- **Nunca compense duas vezes:** se o software de corte/controlador já aplica
  compensação de kerf, não aplique de novo no CAD, e vice-versa
  (`laser_contour_size` recusa entradas que tentam as duas coisas).
- Válido só como idealização: não cobre corte cônico (taper), queima não
  uniforme nem compressão de material — nesses casos, meça `k` com um corpo
  de prova (coupon) calibrado antes de confiar no valor.
- Cada interface (contorno externo, cada furo) pode ter sua própria folga —
  não copie o mesmo valor de kerf/folga para todas por conveniência.

**Tolerância não é folga nem interferência.** Uma tolerância `± t` descreve o
desvio permitido em torno de um valor nominal; folga (positiva) e
interferência (negativa) são o resultado de combinar duas peças. Ao
dimensionar um encaixe, a folga/interferência **total** (por exemplo,
diametral, calculada por `tools/engineering_checks.py::fit_budget`) é
diferente da folga/interferência **por lado** (radial) — para um encaixe
cilíndrico simples, a folga por lado é aproximadamente metade da folga
diametral total. Não use uma pela outra sem converter explicitamente, e não
reaproveite dimensões/folgas de projetos reais neste laboratório sintético.

O kit inclui uma função nominal de alvo externo para material compressível, mas não simula compressão ou retenção. Separe externo, alojamentos e kerf; escolha folga/interferência por teste físico. Não transfira valores dos exemplos para material real nem escale globalmente para corrigir somente a borda.

## 7. Marcos do escopo (não pule etapas)

1. **Cálculo** — matemática e regras de validação, sem tocar em CAD.
2. **CAD** — geometria criada e revisada visualmente no SOLIDWORKS.
3. **Exportação** — STEP/DXF gerados com nome exclusivo, reabertos e
   comparados.
4. **Físico** — ensaio ou fabricação real, fora do escopo deste repositório;
   exige validação dimensional própria, nunca apenas aprovação visual do CAD.

## 8. Checklist de validação por peça

- [ ] `EditRebuild3`/reconstrução sem erro reportado pelo recurso.
- [ ] `Check3.Count == 0` conferido separadamente (não coberto pelas macros
      de exemplo).
- [ ] Diâmetros, eixos, profundidades e fundos medidos com a ferramenta Medir.
- [ ] Contagem de loops/contornos e ausência de duplicatas conferidas.
- [ ] Unidades confirmadas em milímetros.
- [ ] Volume comparado como sinal adicional, não como única prova.
- [ ] Exportação reaberta como documento novo e comparada à origem.
- [ ] Nenhuma edição manual aprovada foi sobrescrita por uma regeneração.
