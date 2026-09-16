# Ferramentas de manutenção

Estas ferramentas mantêm os artefatos editoriais da proposta. O MVP do linter está em `bin/pte-lint` e `lib/pte_lint.rb`.

Para manutenção, use Ruby 3.3.x (o CI fixa a versão em `.ruby-version`) e Bundler 2.6.9. Execute na raiz do repositório:

```sh
gem install bundler -v 2.6.9
export BUNDLE_GEMFILE="$PWD/reviewer-webapp/Gemfile"
bundle install
bundle exec rake verify
```

`bundle exec rake verify` executa os testes do motor, CLI, consistência, manifesto e ingestão do corpus, as duas suítes do revisor local e a validação editorial. `validate_repo.rb` verifica quantidade, ordem, unicidade, campos obrigatórios, YAML e sintaxe dos arquivos JSON Schema. Não valida instâncias contra esses schemas e não percorre dependências ou saídas de build.

Para atualizar e conferir os artefatos gerados:

```sh
ruby tools/generate_catalog.rb
ruby tools/generate_corpus.rb
git diff --exit-code
```

`generate_catalog.rb` recria o catálogo Markdown a partir do YAML canônico. `generate_corpus.rb` recria as fixtures anotadas. Revise e versione as diferenças esperadas; o CI falha se a regeneração modificar arquivos versionados.

O workflow `Verify` roda em pull requests, pushes para `main` e acionamento manual, com dependências Ruby congeladas pelo lockfile. Além de `rake verify` e da regeneração, exige zero erros e zero avisos em `examples/procedure-pte.md`. As verificações usam apenas os arquivos locais após instalar as dependências, sem buscar corpus externo.

O job do site usa Node.js 22 e verifica o build sem publicar:

```sh
cd website
npm ci
ASTRO_TELEMETRY_DISABLED=1 npm run build
```
