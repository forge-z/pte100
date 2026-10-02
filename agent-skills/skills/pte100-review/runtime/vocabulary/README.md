# Vocabulário controlado

O diretório contém o núcleo experimental do futuro PTE-200. A versão 0.1 demonstra o modelo de dados; organizações devem criar pacotes separados para seus produtos e domínios.

## Regra de escolha

Um conceito tem um termo preferido por localidade e escopo. Uma entrada pode registrar:

- `preferred`: forma usada na redação;
- `admitted`: variante aceita por interoperabilidade;
- `forbidden`: forma que gera diagnóstico, com substituição;
- `literal_only`: forma permitida apenas como rótulo, código, comando ou citação.

## Exemplo

```yaml
id: PTE-C0001
preferred: verificar
part_of_speech: verb
definition: "Examinar uma condição e comparar o resultado com um critério."
forbidden:
  - term: checar
    replacement: verificar
```

## Extensão

IDs organizacionais usam namespace reverso, por exemplo `br.org.exemplo-C0001`. Um pacote declara dependências, localidade e versão. Definição e termo preferido não podem mudar de sentido em versão compatível; crie outro ID para outro conceito.

Valide `core.yaml` com `schema.json`. Termos de segurança e domínio só devem ser publicados após revisão de especialistas.

