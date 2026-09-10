# Prompt 3 — Validação e exportação

Use depois que uma peça sintética foi criada/editada no SOLIDWORKS, antes de
considerar o trabalho concluído.

```
A peça foi criada/editada. Antes de considerar isso concluído, confirme
comigo cada item abaixo (não marque nada como feito sem checar de fato):

1. EditRebuild3 (ou reconstrução manual) rodou sem erro reportado pelo
   recurso.
2. Check3.Count == 0 foi conferido separadamente — isso NÃO é coberto
   automaticamente pela reconstrução nem pelas macros de exemplo deste kit.
3. Diâmetros, eixos, profundidades e presença de fundo dos furos foram
   medidos com a ferramenta Medir (não estimados pelo esboço).
4. Contagem de loops/contornos conferida, sem duplicatas.
5. Unidades confirmadas em milímetros.
6. Volume comparado como sinal adicional — nunca como única prova.
7. Se houve exportação (SLDPRT/STEP/DXF): cada arquivo foi reaberto como
   documento novo e comparado à origem (volume, dimensões, contagem de
   loops/corpos) — nunca aceito "de olho" sem reabrir.
8. Se houve edição manual minha na peça: essa versão salva é agora a fonte
   de verdade — não regenere por cima dela com uma macro antiga.

Reporte item a item o que foi checado, o que não foi, e o que ficou como
"não testado". Não afirme que uma validação foi feita se não foi executada
de fato nesta sessão.
```

Detalhes de cada critério em [VALIDACAO.md](../VALIDACAO.md). Para registrar
evidência de um teste local real, copie
[SMOKE-TEST.md](../SMOKE-TEST.md) para fora do controle de versão
compartilhado e preencha lá — nunca deixe o modelo em branco passar por
"aprovado".
