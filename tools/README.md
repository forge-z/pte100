# Ferramentas de manutenção

Estas ferramentas mantêm os artefatos editoriais da proposta. O MVP do linter está em `bin/pte-lint` e `lib/pte_lint.rb`.

```sh
ruby tools/generate_catalog.rb
ruby tools/generate_corpus.rb
ruby tools/validate_repo.rb
rake verify
```

`generate_catalog.rb` recria o catálogo Markdown a partir do YAML canônico. `generate_corpus.rb` recria as 42 fixtures anotadas. `validate_repo.rb` verifica quantidade, ordem, unicidade, campos obrigatórios, YAML e sintaxe dos JSON Schemas, sem percorrer dependências ou saídas de build. `rake verify` executa a suíte Minitest do motor, a CLI, o revisor local e a validação editorial.

Ruby 2.6 ou mais recente, com bibliotecas padrão, é suficiente. O CI deve executar a geração e falhar quando houver diferença não versionada.
