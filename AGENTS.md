# Guia operacional para agentes

## Source of truth

- `rules/rules.yaml`: fonte canônica dos campos das regras; `rules/catalog.md`: publicação humana gerada.
- `spec/`: especificação que governa a interpretação das regras.
- `schemas/`: contratos públicos; `vocabulary/`: vocabulários e seu schema.
- Preserve as convenções existentes e alterações de outros colaboradores.

## Required verification

Use Ruby 3.3.x (referência: 3.3.12) e Bundler 2.6.9. Na raiz do repositório, instale as dependências e execute `rake verify` antes de concluir:

```sh
BUNDLE_GEMFILE=reviewer-webapp/Gemfile bundle install
BUNDLE_GEMFILE=reviewer-webapp/Gemfile bundle exec rake verify
```

Para alterações no website, use Node.js 22 e execute `npm ci` e `ASTRO_TELEMETRY_DISABLED=1 npm run build` em `website/`. Consulte [tools/README.md](tools/README.md) e o workflow de verificação para os checks completos. Informe comandos, resultados e limitações; não declare sucesso sem execução.

## Normative changes

Não altere silenciosamente obrigações normativas, severidade, estado de regra, semântica de conformidade ou governança. Essas mudanças exigem o processo de [CONTRIBUTING.md](CONTRIBUTING.md) e [GOVERNANCE.md](GOVERNANCE.md), com impacto declarado e revisão. Agentes não aprovam mudanças normativas por conta própria.

## Generated artifacts

Execute na raiz e revise o diff dos artefatos:

| Artefato | Fonte | Comando |
|---|---|---|
| `rules/catalog.md` | `rules/rules.yaml` | `ruby tools/generate_catalog.rb` |
| `corpus/fixtures/positive/*.md` e `corpus/fixtures/negative/*.md` | `corpus/cases.yaml` | `ruby tools/generate_corpus.rb` |

Atualize fontes e derivados juntos. Após registrar as alterações esperadas, regenere e use `git diff --exit-code` para verificar a consistência.

## Network

Os testes normais devem funcionar offline após a instalação de dependências. Não inclua downloads de corpus nos checks obrigatórios. Baixe corpus externo apenas quando solicitado explicitamente, seguindo [docs/corpus-sources.md](docs/corpus-sources.md).

## Language

Português é normativo. `README.en.md` é informativo e deve refletir os mesmos fatos do README principal.

## Safety of claims

PTE-100 v0.1 é uma proposta pública experimental. Lint não equivale a certificação de segurança, correção técnica, conformidade estável ou cumprimento de requisitos legais. Não invente adoção, métricas, validação externa ou apoio institucional.
