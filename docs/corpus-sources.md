# Corpus externo para testes

O PTE-Lint usa dois níveis de corpus:

1. `corpus/cases.yaml` e `corpus/fixtures/`: regressão sintética, versionada no projeto;
2. fontes técnicas reais: baixadas localmente e mantidas em `.pte-cache/corpus/`.

## Fontes v0.1

As três fontes abertas estão descritas em [`corpus/sources.yaml`](../corpus/sources.yaml), com URL, idioma, gênero documental, licença, estratégia de snapshot e estado da tradução. O snapshot baixado atualmente está registrado em [`corpus/sources.lock.yaml`](../corpus/sources.lock.yaml) por hash SHA-256 e quantidade de unidades.

- [O tutorial do Python](https://docs.python.org/pt-br/3/tutorial/index.html): tutorial oficial;
- [HTML — MDN Web Docs](https://developer.mozilla.org/pt-BR/docs/Web/HTML): referência aberta;
- [Instale as ferramentas — Kubernetes](https://kubernetes.io/pt-br/docs/tasks/tools/): procedimento operacional.

O texto integral não deve ser copiado para o repositório Apache-2.0 sem revisão jurídica e atribuição específica. A ingestão padrão grava o texto somente no cache ignorado pelo Git. Fixtures derivados devem conter apenas o trecho mínimo necessário, metadados de origem e licença.

## Fluxo reproduzível

```sh
# Ver as fontes selecionadas
ruby tools/ingest_corpus.rb list

# Baixar as três páginas para .pte-cache/corpus/raw/ e segmentá-las
ruby tools/ingest_corpus.rb fetch-and-convert --source all

# Gerar apenas metadados, sem texto integral no JSONL
ruby tools/ingest_corpus.rb fetch-and-convert --source all --metadata-only

# Executar o lint sobre uma fonte já convertida
ruby tools/lint_corpus.rb .pte-cache/corpus/units/python-tutorial-ptbr.jsonl \
  --config pte-lint.example.yaml \
  --output .pte-cache/corpus/results/python-tutorial-ptbr.json
```

O perfil `mdn-web` demonstra como registrar siglas próprias da fonte sem aumentar a allowlist global. O conversor também informa o elemento HTML (`li`, `h1`, `p` ou `pre`) ao motor; isso permite excluir itens de índice de regras numéricas sem mascarar números em prosa.

O conversor preserva títulos, parágrafos, listas, citações e blocos `pre`. A segmentação é heurística; código, texto de interface, tradução desatualizada e avisos editoriais devem ser confirmados durante a anotação humana.

Para criar uma fila de revisão a partir do resultado do lint:

```sh
ruby tools/prepare_annotations.rb \
  .pte-cache/corpus/results/python-tutorial-ptbr.json \
  --metadata-only
```

O comando cria um JSONL em `.pte-cache/corpus/annotations/` com decisão inicial `uncertain`, diagnósticos reduzidos, hash e campos para revisor. A anotação humana deve preencher `decision`, `applicable_rules` e `rationale`.

## Anotação

Cada unidade possui `source_id`, URL, licença, elemento HTML, ordinal e SHA-256. O texto só aparece quando a execução não usa `--metadata-only`. Uma anotação revisada deve registrar:

- regras PTE aplicáveis;
- severidade observada;
- decisão (`compliant`, `violation`, `not_applicable` ou `uncertain`);
- justificativa humana;
- confirmação da licença e da atribuição.

Textos reais são evidência para calibrar o lint, não uma autoridade automática sobre a norma PTE-100.
