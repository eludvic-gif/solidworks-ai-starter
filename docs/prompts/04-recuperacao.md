# Prompt 4 — Recuperação de erro

Use quando uma conexão, macro ou script parar por erro e você não tiver
certeza do estado atual antes de tentar de novo.

```
Algo parou com erro. Antes de tentar de novo ou "corrigir rapidamente":

1. Me diga o texto exato do erro, sem resumir ou reinterpretar.
2. Classifique: é timeout de conexão (para imediatamente, nunca repete
   sozinho), erro de indisponibilidade (MK_E_UNAVAILABLE, 0x800401E3,
   0x80010108, 0x800706BA — só esses são repetíveis automaticamente), ou
   outro erro de despacho/tipo (nunca repetível, causa diferente)? Veja
   docs/TROUBLESHOOTING.md antes de decidir.
3. Verifique quantos processos SLDWORKS existem agora. Se houver mais de
   um, não escolha um "arbitrariamente" — pare e me pergunte, e nunca
   finalize processo algum à força; se algo precisar fechar, salve o
   trabalho pendente primeiro.
4. Se uma peça parcial ficou aberta por causa do erro, não descarte nem
   feche automaticamente — deixe para eu inspecionar.
5. Não reexecute macro/modelagem em loop, mesmo com HRESULT listado acima.
   As tentativas limitadas (padrão 8) pertencem exclusivamente ao probe
   de conexão; geometria parcial nunca é repetida automaticamente.
6. Se o erro menciona um gate de revisão (prefixo tipo "33."), lembre que o
   gate de cada macro .bas é independente do config.local.json — verifique
   os dois separadamente antes de mudar qualquer um.

Depois de eu confirmar o diagnóstico, proponha a próxima ação específica —
não uma tentativa genérica de "rodar de novo".
```

Referência completa de sintomas/causas em
[TROUBLESHOOTING.md](../TROUBLESHOOTING.md).
