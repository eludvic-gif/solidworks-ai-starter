# Prompt — desenho 2D e montagem nativos

Preencha os campos com dados sintéticos ou localmente autorizados. Não envie dados privados a um serviço de IA sem verificar política/consentimento. Este prompt não autoriza publicação nem instala ferramentas.

```text
Leia AGENTS.md, docs/GUIA-COMPLETO.md e docs/DESENHOS-2D.md.
Quero um desenho nativo SLDDRW, não uma imitação em SVG/PDF.

Fonte salva e configuração:
Template/formato de desenho autorizado:
Padrão de projeção, unidades e formato de papel:
Material/processo e escopo de fornecimento:
Interfaces críticas e fonte de cada requisito:
Tolerâncias confirmadas versus pendentes:
Geometria que não pode mudar:
Componentes e ordem de montagem (se houver):
Hipóteses de compressão, contato e fixação:
Saídas e pasta nova:
Permissões desta execução:

Primeiro inventarie ambiente/documentos e confirme os caminhos. Copie somente
as fontes autorizadas. Meça BREP e construa matriz característica → vista/cota
→ tolerância → inspeção. Não copie tolerâncias de revisões antigas sem evidência.

Confirme a API/enums da instalação. Prove uma vista e uma cota associativa em
um documento próprio antes de replicar. Localize nomes das vistas; confira
transformações modelo/folha/esboço para cortes e detalhes. Nunca use ActiveDoc
como fallback. Pare e diagnostique uma transação parcial antes de nova execução.

Monte vistas, cortes, detalhes, centros e carimbo legíveis. Na montagem,
confira transformações e apoios reais; não escale para esconder interferência.
Diferencie vista explodida nativa de montagem ilustrativa separada.

Salve nativo e PDF de todas as folhas, reabra cópias e confira referências,
configuração, valores, entidades anexadas, dangling e override. Renderize todas
as páginas e revise sobreposições. Audite o pacote; não declare portabilidade
sem reabertura isolada e resolução correta das referências, inclusive Interconnect.

Mantenha PARA REVISÃO — NÃO LIBERADO PARA FABRICAÇÃO quando houver pendências.
Não invente requisitos, assinaturas ou aprovação. Informe testes realizados e
limites. Se houver autorização de limpeza, revise dependências e recicle apenas
temporários próprios comprovadamente obsoletos, sem tocar originais ou finais.
```

Para vídeo novo, acrescente explicitamente: “Recrie etapas em cópias separadas; capture somente a janela CAD; preserve minhas gravações existentes e entregue clipes identificados como demonstração, sem publicação”.
