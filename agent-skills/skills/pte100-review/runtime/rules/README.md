# Regras PTE-100

`rules.yaml` é a fonte estruturada canônica das 50 regras da versão 0.1. `catalog.md` é a vista normativa para leitura e revisão humana.

## Categorias

| Código | Categoria | Nível mínimo |
|---|---|---|
| R001–R010 | léxico | PTE-Claro |
| R011–R020 | frase | PTE-Claro |
| R021–R030 | procedimento | PTE-Claro |
| R031–R036 | alerta | PTE-Estrutura |
| R037–R042 | dados | PTE-Estrutura |
| R043–R046 | estrutura | PTE-Estrutura |
| R047–R050 | IA | PTE-IA |

## Campos de lint

- `mode`: `automatic`, `assisted` ou `manual`;
- `engine`: família de análise, sem vincular a uma implementação;
- `selector`: unidades avaliadas;
- `condition`: condição normalizada do diagnóstico;
- `parameters`: limites configuráveis;
- `autofix`: `none`, `suggested` ou `safe`;
- `message`: mensagem padrão com variáveis entre chaves.

O bloco de lint especifica comportamento portátil, não um algoritmo completo. Implementações devem publicar versões, testes e limitações.

