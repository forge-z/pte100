# Conformidade

## Níveis

| Categoria | PTE-Estrutura | PTE-Claro | PTE-IA |
|---|:---:|:---:|:---:|
| estrutura (R043–R046) | obrigatório | obrigatório | obrigatório |
| dados (R037–R042) | obrigatório | obrigatório | obrigatório |
| alertas (R031–R036) | obrigatório | obrigatório | obrigatório |
| léxico (R001–R010) | — | obrigatório | obrigatório |
| frase (R011–R020) | — | obrigatório | obrigatório |
| procedimento (R021–R030) | — | obrigatório | obrigatório |
| IA (R047–R050) | — | — | obrigatório |

`—` significa fora do nível, não proibido. Regras com nível mais baixo também se aplicam aos níveis superiores.

## Resultado

Uma coleção é conforme quando:

- declara metadados válidos;
- não tem diagnóstico `error` sem desvio aprovado;
- revisa ocorrências de regras `assisted` e `manual` por amostragem definida;
- registra versão exata de regras e vocabulários;
- mantém relatório reproduzível.

`warning` não impede conformidade, mas deve ser resolvido ou justificado para conteúdo crítico. `info` é orientação.

## Escopo e amostragem

A declaração identifica arquivos, formatos e exclusões. Conteúdo crítico deve ter revisão humana integral. Para conteúdo não crítico, a organização pode declarar amostragem, nunca inferior a 10% das unidades para regras manuais na versão 0.1.

## Desvios

Cada desvio contém `rule`, `scope`, `reason`, `approved_by`, `approved_at` e `review_after`. Desvio sem prazo é permitido apenas para nomes legais ou interoperabilidade externa permanente.

## Forma recomendada

```yaml
standard: PTE-100
version: "0.1"
level: pte-claro
locale: pt-BR
scope: "docs/**/*.md"
rule_pack_digest: "sha256:<digest>"
result: conformant-with-deviations
errors: 0
approved_deviations: 2
assessed_at: 2026-08-06T15:00:00-03:00
```

O PTE-100 v0.1 não autoriza certificadores nem selo oficial. Declarações são autodeclaradas e devem apontar para a evidência.

