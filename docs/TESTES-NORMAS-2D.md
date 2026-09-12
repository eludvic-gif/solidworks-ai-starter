# Verificação da publicação normativa 2D

Data: **2026-09-12**. Escopo: atualização pública de documentação e verificador offline; nenhum comando de modelagem, conexão ou fechamento CAD foi executado para publicar este módulo.

## Resultados observados

- **79 testes Python passaram**: 48 preexistentes e 31 novos (24 do crivo estruturado e 7 de CLI/publicação). O teste de despacho do laboratório não foi copiado: o kit expõe CLI própria.
- Testes de CLI: exemplo retorna review_required/NOT_AUTHORIZED; entrada inválida, NaN, chaves duplicadas, referência malformada e arquivo excessivo bloqueados; saída existente preservada.
- Registro: 20 entradas e 8 sucessões; URLs oficiais, sem caminhos/hashes de evidência privada ou PDFs incorporados.
- Word anterior conferido contra a fonte já commitada antes da substituição. Novo Word gerado com python-docx 1.2.0; igualdade de texto/tabelas e hash da fonte passaram, sem macros/embeds/relacionamentos externos.
- Scanner heurístico de conteúdo/tipos passou; revisão manual dos novos arquivos e diff complementou o scanner. Scanner não prova ausência de todo segredo possível.
- PowerShell: parse e **11 testes de política** passaram. **Compilação C# pulada** nesta atualização (sem ConfigPath), pois não houve alteração no cliente COM.
- A primeira execução teve uma falha de teste documental por buscar “não mede geometria” quando o texto dizia “nem mede geometria”. A asserção foi corrigida para o texto equivalente; a execução seguinte passou integralmente.

## Não verificado / não alegado

- Nenhuma norma integral foi lida; não há validação completa ISO/ASME/ABNT.
- O verificador não extrai medidas do CAD nem autentica afirmações em JSON.
- Não houve nova execução CAD, exportação/reimportação ou ensaio físico para esta publicação.
- Não houve inspeção visual da paginação do Word; validação foi estrutural/textual.
- Exit 0, testes verdes e review_required não autorizam fabricação.

## Reproduzir

Na raiz do kit:

```powershell
python -m unittest discover -s tests -v
python tools/scan_release.py
powershell.exe -NoProfile -File tools/check-offline.ps1
# Após selecionar explicitamente os arquivos revisados para staging:
python tools/scan_release.py --tracked
```

Não substituir a revisão do diff e do staging por estas checagens. Não publicar relatórios de peças reais, configurações privadas ou conteúdo de normas por inferência da licença MIT do kit.
