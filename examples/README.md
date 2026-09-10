# Exemplos VBA

Duas macros independentes, somente com geometria sintética. Os fontes originais foram demonstrados em SOLIDWORKS 2025 SP5; **as adaptações deste repositório não foram compiladas nem executadas no CAD nesta entrega**. Exigem teste local, não certificam resistência ou fabricação.

## O que cada macro faz

- `ConeValidation.bas`: `main` cria **somente o cone** H30 mm, base Ø10 mm. Calcula o pedido de furo Ø5 × 15 mm e informa parede radial zero; não implementa corte algum. `TestGeometryOnly` verifica quatro casos matemáticos sem acessar documentos.
- `ConeBore9.bas`: `RunConeBore9` cria outra peça nova, cone H30/Ø10 e corte por revolução produzindo furo cego Ø5 × 9 mm. `TestBore9Math` verifica quatro casos matemáticos, sem documentos.
- A primeira macro mede cotas, reconstrução, quantidade de corpos e volume. A segunda também confere uma superfície cilíndrica de raio 2,5 mm. Nenhuma mede sozinha todos os critérios BREP, exporta, salva, fecha documentos ou testa resistência.

## Importação e execução

1. No SOLIDWORKS, `Ferramentas > Macro > Nova` (`Tools > Macro > New`). Salve um projeto `.swp` novo em `local/`, nunca em projeto de macro existente.
2. No editor VBA, remova somente o módulo padrão vazio desse projeto recém-criado para não confundir os pontos de entrada. `Arquivo > Importar arquivo` e escolha **um** dos `.bas`.
3. Em `Ferramentas > Referências`, confirme a biblioteca de tipos SOLIDWORKS da versão instalada, sem referências `MISSING`. Compile em `Depurar > Compilar`.
4. Posicione o cursor dentro de `TestGeometryOnly` ou `TestBore9Math` e execute com F5 no editor. Confira a mensagem; isso não cria peça.
5. Posicione o cursor dentro de `main` ou `RunConeBore9` e execute com F5 quando a criação de uma peça sintética estiver autorizada. Alternativamente use `Ferramentas > Macro > Executar`, selecionando o projeto/ponto de entrada correto.
6. Na caixa de entrada, informe o caminho completo de um template `.PRTDOT` vazio e existente, **sem aspas**. Use `Opções > Locais de arquivos > Templates de documento` para localizar a pasta configurada; não altere preferências globais.
7. Vazio/cancelar encerra sem criar documento. Caminho inválido também interrompe: exige caminho absoluto em unidade local, sem aspas, curingas ou caminho UNC de rede. Não há busca automática de template nem leitura de JSON pelo VBA.
8. Confira as cotas propostas se aparecerem caixas de dimensão. Aguarde a mensagem final; depois inspecione árvore, medidas e seção.
9. Para a outra demonstração, crie outro `.swp` novo e repita. Não renomeie `.bas` para `.swp`: fonte de módulo não é projeto executável.

## Configuração e orientação

Cada BAS contém `EXPECTED_REVISION_PREFIX = "33."`. O JSON configura somente o cliente externo: mudar seu prefixo **não altera a macro**. Outra versão exige revisão das assinaturas e teste local, ajustando explicitamente ambos se aprovado. Passar pela guarda da mesma versão principal não prova compatibilidade de todo service pack.

O cone é construído no primeiro plano de referência do template. A base começa na origem do esboço; a altura e a profundidade seguem seu eixo Y local, usado na revolução. Não presuma o mesmo eixo global em templates diferentes. Use template vazio convencional, sem corpos/esboços ou automações próprias.

Os nomes de recursos, mensagens e testes estão vinculados à demonstração fixa. Não basta alterar uma constante e assumir que o restante está generalizado.

## Segurança e limites

- Falha em `NewDocument` nunca usa `ActiveDoc` como alternativa. `RequireActive` compara a referência local VBA com a peça recém-criada e interrompe se mudar. O auxiliar C# usa IUnknown para identidade COM; não use apenas `ReferenceEquals` entre wrappers .NET.
- Não clique, mude seleção/aba ou execute outra automação enquanto a macro roda; chamadas baseadas em seleção não são transações isoladas. As guardas não eliminam toda condição de corrida.
- São lidos os save flags dos documentos preexistentes para detectar mudança de estado; isso não prova que um documento já modificado permaneceu byte a byte inalterado.
- Em falha, preserve a peça parcial para inspeção. Não reexecute automaticamente. Nenhum documento é salvo/fechado automaticamente.
- `AddToDB` é restaurado apenas se seu estado anterior foi capturado. Relações e cotas são aplicadas explicitamente; não se confia em inferência visual.

## Valores de referência

Para H30, Ø10 e furo Ø5 coaxial iniciado na base: parede radial `w(z) = 2,5 − z/6` mm.

- Profundidade 15 mm: zero; corte degenerado, bloqueado. `ConeValidation` não executa nenhum corte.
- Profundidade 9 mm: 1 mm; volume final `193,75π ≈ 608,683576633022 mm³`.
- Profundidade 16 mm: negativo; detectado matematicamente como rompimento.
- Parede radial não é espessura normal mínima da face inclinada nem atestado de resistência.

Testes Python equivalentes e de outras funções, sem CAD:

```powershell
python -m unittest discover -s tests -p test_engineering_checks.py -v
```

Veja o [guia completo](../docs/GUIA-COMPLETO.md), o [checklist de validação](../docs/VALIDACAO.md) e o [registro de smoke test](../docs/SMOKE-TEST.md).
