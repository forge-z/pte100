# Dogfooding do PTE-Lint

O repositório executa o MVP sobre [examples/procedure-pte.md](../examples/procedure-pte.md), um procedimento normativo escrito para ser um exemplo conforme. Essa é a primeira verificação contínua do padrão sobre conteúdo produzido pelo próprio projeto.

## Escopo atual

O alvo é deliberadamente pequeno e não inclui README, especificação ou catálogo porque esses arquivos contêm exemplos incorretos, metalinguagem e identificadores que não representam um documento técnico de usuário. Lintar esses arquivos sem um modo `meta` misturaria diagnósticos esperados com falsos positivos.

O dogfood atual é um gate: qualquer erro ou aviso no procedimento canônico falha a CI. A saída JSON é preservada apenas durante a execução da CI e não é tratada como métrica de precisão.

## Expansão planejada

1. adicionar um modo `meta` que reconheça exemplos normativos e blocos de especificação;
2. incluir documentos de `examples/` sem conteúdo deliberadamente incorreto;
3. criar baseline versionada para diagnósticos conhecidos de documentação normativa;
4. só então ampliar o gate para `docs/` e `spec/`.

Dogfooding demonstra estabilidade de integração; não substitui os três pilotos com conteúdo real descritos no [ROADMAP](../ROADMAP.md).

