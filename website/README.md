# Website do PTE-100

Landing page pública e temporária do PTE-100, publicada pelo GitHub Pages em:

<https://forge-z.github.io/pte100>

## Desenvolvimento local

```sh
cd website
npm install
npm run dev
```

Abra o endereço mostrado pelo Astro. Para gerar a versão de produção:

```sh
npm run build
npm run preview
```

O site é um projeto estático. O conteúdo normativo continua nos diretórios `spec/`, `rules/`, `vocabulary/` e `docs/`; a landing page não é uma segunda fonte da norma.

## Publicação

O workflow `.github/workflows/deploy-website.yml` executa o build e publica `website/dist` no GitHub Pages a cada alteração em `website/` na branch `main`.
