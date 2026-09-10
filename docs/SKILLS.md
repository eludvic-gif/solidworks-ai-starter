# Skills externas opcionais

Este kit funciona sem nenhuma skill de terceiros — os `docs/prompts/`, o
[guia completo](GUIA-COMPLETO.md) e as macros de `examples/` já bastam. As
skills abaixo são referências comunitárias **opcionais**, citadas apenas
informativamente. Nenhuma delas é instalada, baixada ou executada por este kit. Houve revisão seletiva de referências em experimentos anteriores; isso não equivale a redistribuição ou instalação integral. Instalação futura exige revisão e autorização explícita. Ver também
[THIRD_PARTY_NOTICES.md](../THIRD_PARTY_NOTICES.md).

Nenhum item abaixo tem ganho de desempenho medido nesta entrega — cite
apenas o que está documentado pelo próprio projeto de origem, nunca uma
estimativa.

## 1. `wzyn20051216/solidworks-automation-skill`

- Commit de referência: `5287d2e3d100dedb10e94910523f294a46176c54`.
- Licença: MIT.
- Escopo: automação SOLIDWORKS via COM, comunitária, não afiliada à
  Dassault/SOLIDWORKS.
- Riscos conhecidos a revisar antes de qualquer uso: uso de `ActiveDoc` como
  fallback em vez de referência explícita ao documento; dependência de
  templates globais (preferências do usuário) em vez de caminho explícito;
  chamadas de encerramento de aplicação (`ExitApp`/equivalentes) que podem
  fechar o SOLIDWORKS com trabalho não salvo.
- Se algum dia adotada: tratar como código de terceiros em quarentena,
  revisar linha a linha, nunca executar por inferência.

## 2. `K-Dense-AI/scientific-agent-skills` (módulo `lab-hardware-cad`)

- Commit de referência: `9cf7d9aea7d84754db4c167ab04b299d33c444bc`.
- Licença: MIT.
- Escopo: geração de peças/CAD para hardware de laboratório.
- Risco conhecido: os modelos fornecidos são scripts `.py` que executam
  código arbitrário ao rodar — não há sandbox embutido no projeto de
  origem. Qualquer script desse tipo deve ser lido integralmente antes de
  executar, e rodado apenas num ambiente já isolado por você.

## 3. `flowful-ai/cad-skill`

- Commit de referência: `fe4215970d39f388ff1afc411fac49a9c5f79756`.
- Licença: PolyForm Noncommercial — **evite** para qualquer uso comercial;
  releia os termos exatos antes de decidir.
- Escopo: geração/consulta de CAD assistida por IA.

## 4. `github/awesome-copilot` — scripts FreeCAD

- Apenas como referência de leitura (lista curada de prompts/scripts para
  FreeCAD); não é instalado nem executado neste kit.
- Útil apenas se seu fluxo real usar FreeCAD em vez de SOLIDWORKS — os dois
  não compartilham API/COM.

## Links para as revisões citadas

- https://github.com/wzyn20051216/solidworks-automation-skill/tree/5287d2e3d100dedb10e94910523f294a46176c54
- https://github.com/K-Dense-AI/scientific-agent-skills/tree/9cf7d9aea7d84754db4c167ab04b299d33c444bc
- https://github.com/flowful-ai/cad-skill/tree/fe4215970d39f388ff1afc411fac49a9c5f79756
- https://github.com/github/awesome-copilot/tree/7568a482ce2df38f8965ab5336a3220db796a4ba

A licença do wrapper não define a licença do motor CadQuery. Nos geradores de laboratório revisados, também há caminhos que sobrescrevem arquivos e escrevem saídas antes de concluir validação: não executá-los automaticamente. Normas/dimensões de assets precisam de fonte primária e revisão, mesmo quando rotuladas como verificadas.

## 5. Antes de instalar qualquer uma

1. Confirme licença e commit exato (nunca `main`/`latest` sem pin).
2. Leia o código-fonte completo, não apenas o README do projeto.
3. Rode primeiro num ambiente isolado, sem documentos reais abertos.
4. Não presuma que a skill respeita as mesmas guardas deste kit (parede
   positiva antes do corte, identidade COM correta, timeout sem repetição
   etc.) — releia as guardas dela.
5. Registre a decisão (instalada/rejeitada e por quê) fora deste
   repositório, se for relevante ao seu processo.
