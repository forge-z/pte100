# Website do PTE-100

Landing page pública da proposta experimental PTE-100 v0.1, publicada pelo GitHub Pages em:

<https://forge-z.github.io/pte100/>

## Desenvolvimento local

Use Node.js 22 e instale as dependências fixadas no lockfile:

```sh
cd website
npm ci
ASTRO_TELEMETRY_DISABLED=1 npm run dev
```

Abra o endereço mostrado pelo Astro. Para gerar a versão de produção:

```sh
ASTRO_TELEMETRY_DISABLED=1 npm run build
ASTRO_TELEMETRY_DISABLED=1 npm run preview
```

O site é estático. O conteúdo normativo continua nos diretórios `spec/`, `rules/`, `vocabulary/` e `docs/`; a landing page não é uma segunda fonte da proposta. O PTE-Lint e o revisor são executados localmente conforme o [Quick Start](../README.md#quick-start) e o [guia do revisor](../reviewer-webapp/README.md); não são serviços hospedados neste site.

## Publicação

O [workflow de deploy](../.github/workflows/deploy-website.yml) executa o build e publica `website/dist` no GitHub Pages em pushes para `main` que alterem `website/**`, `schemas/**`, `rules/catalog.md` ou o próprio workflow. Ele também pode ser acionado manualmente. O [workflow de verificação](../.github/workflows/verify.yml) faz o build em pull requests sem publicar o site.
