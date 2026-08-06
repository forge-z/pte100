# Corpus e fixtures do PTE-Lint

Este corpus inicial é uma suíte de regressão sintética, não uma amostra representativa da língua portuguesa. Ele existe para testar o contrato do MVP antes dos pilotos com documentação real.

- `cases.yaml` é a fonte anotada dos casos;
- `fixtures/positive/` contém um caso que DEVE produzir diagnóstico da regra indicada;
- `fixtures/negative/` contém um caso que NÃO DEVE produzir diagnóstico da regra indicada;
- `tools/generate_corpus.rb` recria os arquivos derivados;
- `test/test_pte_lint.rb` executa a suíte.

Cada caso declara `rule`, `class`, `text` e `note`. A anotação não afirma que a frase inteira viola somente uma regra; o teste verifica a presença ou ausência do ID esperado.

## Limite de uso

Não use estes números para medir precisão linguística. O corpus não contém amostragem de setor, localidade, nível de letramento ou severidade real. O ponto 5 do plano de adoção deve substituir progressivamente fixtures sintéticas por frases licenciadas e anotadas por especialistas.

## Corpus externo real

As fontes abertas selecionadas para os primeiros testes estão em [`sources.yaml`](sources.yaml), com URL, licença, estratégia de snapshot e estado da tradução. A arquitetura e o fluxo de ingestão estão documentados em [`docs/corpus-sources.md`](../docs/corpus-sources.md).

Use `ruby tools/ingest_corpus.rb list` para confirmar o manifesto. O comando `fetch-and-convert` baixa as fontes para `.pte-cache/corpus/` e cria unidades JSONL locais; esse cache não é versionado. Use `ruby tools/lint_corpus.rb CAMINHO.jsonl` para executar o PTE-Lint sobre uma fonte.
