# Prompt 2 — Briefing de uma peça

Use este prompt depois do onboarding, para descrever uma peça sintética
específica antes de qualquer geometria ser criada.

```
Antes de criar ou alterar qualquer geometria, traduza este pedido em:

- Função da peça e onde ela se encaixa (que interface(s) ela toca).
- Datums, eixo de referência e unidade (sempre milímetros).
- Dimensões nominais de cada característica (não uma "estimativa razoável").
- Tolerância (± desvio permitido) de cada cota crítica — não confunda com
  folga/interferência de encaixe.
- Se há mais de uma interface (por exemplo, dois furos que encaixam em
  peças diferentes), trate cada folga/tolerância separadamente; não repita
  o mesmo valor por conveniência.
- Se a peça envolve corte por ferramenta (laser, fresa), pergunte se o kerf
  já é compensado pelo software da máquina antes de aplicar qualquer
  compensação no CAD — nunca aplicar dos dois lados.
- Confirme se algum dado aqui é real ou de projeto real — se for, pare e
  me avise; este ambiente só trabalha com os exemplos sintéticos deste kit
  (cone e placa).

Depois de eu confirmar os pontos acima, aponte que "seção X" do
docs/GUIA-COMPLETO.md ou qual macro de examples/ melhor se aplica, e
pergunte qual template .PRTDOT vazio devo indicar antes de prosseguir.
```

Peça referência: cone H=30mm, base Ø10mm, furo coaxial Ø5mm — ver
`examples/ConeValidation.bas` (só constrói e classifica, nunca corta) e
`examples/ConeBore9.bas` (corta de fato, furo cego de 9mm). Placa
120×80×10mm com 4 furos Ø8mm — ver seção correspondente do
[guia completo](../GUIA-COMPLETO.md).
