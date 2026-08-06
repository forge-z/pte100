# Especificação PTE-Lint 0.1

## Estado e objetivo

Este documento define o contrato de uma implementação de referência. O repositório agora inclui um **MVP offline** em `bin/pte-lint`, escrito apenas com a biblioteca padrão do Ruby. Ele implementa as 21 regras com modo `automatic`; regras `assisted` continuam especificadas, mas ainda não têm motor de PLN. O MVP recebe texto e configuração, aplica uma versão fixa de regras e produz diagnósticos explicáveis.

## Requisitos funcionais

O PTE-Lint DEVE:

- processar UTF-8 sem enviar conteúdo à rede por padrão;
- resolver configuração e pacotes com versões fixas;
- preservar blocos literais e posições no arquivo de origem;
- informar regra, severidade, trecho, posição, modo e confiança;
- aceitar supressão com regra e justificativa;
- produzir `text` e JSON conforme `schemas/diagnostic.schema.json`;
- oferecer SARIF 2.1.0 para CI;
- retornar códigos de saída estáveis;
- nunca aplicar correção marcada `review` sem confirmação.

O MVP suporta Markdown e texto simples, saída `text`, JSON e SARIF, configuração por YAML/JSON e os comandos `check` e `version`. Ele não reivindica ainda cobertura de AsciiDoc/HTML, análise morfossintática, coreferência, semântica de domínio ou correção automática de significado.

## Pipeline

```text
arquivo → adaptador → árvore de conteúdo → segmentação → análise linguística
       → regras + vocabulário → exceções → diagnósticos → formatador
```

Adaptadores preservam offsets e marcam `prose`, `heading`, `step`, `alert`, `code`, `link`, `table` e metadados. Regras escolhem os tipos que analisam. O motor não deve analisar código como prosa por omissão.

## Configuração

O arquivo padrão é `.pte-lint.yaml`, `.pte-lint.yml` ou `.pte-lint.json`. A forma está em `schemas/pte-lint-config.schema.json`; exemplos estão na raiz do repositório.

Perfis específicos podem declarar vocabulário contextual sem alterar o núcleo. `profile_definitions` contém as opções do perfil e `source_profiles` associa uma fonte identificada pelo adaptador ao perfil aplicável. As allowlists de siglas e termos de um perfil são somadas às regras globais; cada exceção deve ser justificada pelo domínio e pela fonte.

Precedência, da menor para a maior:

1. padrão PTE-100;
2. perfil de conformidade;
3. perfil de localidade;
4. perfil PTE-300;
5. configuração do repositório;
6. configuração do diretório;
7. argumento da linha de comando;
8. diretiva inline válida.

O comando `config --resolved` DEVE mostrar valor final e origem de cada opção.

## Diagnóstico

Posições são baseadas em 1 para linha e coluna e em 0 para offset UTF-8 em bytes. A faixa final é exclusiva. `confidence` é `1` para regra determinística, número entre 0 e 1 para heurística e `null` para revisão manual.

O `fingerprint` combina regra, unidade e evidência normalizada para acompanhar uma ocorrência entre revisões. Não deve conter o texto confidencial em claro.

## Severidade e saída

| Severidade | Significado padrão |
|---|---|
| `error` | impede conformidade do nível |
| `warning` | requer revisão ou justificativa |
| `info` | orientação não bloqueante |
| `off` | regra desativada pela configuração |

Códigos de saída:

| Código | Resultado |
|---:|---|
| 0 | nenhum diagnóstico no limiar de falha |
| 1 | diagnóstico atingiu `fail_on` |
| 2 | configuração, schema ou pacote inválido |
| 3 | erro de leitura ou formato não suportado |
| 4 | falha interna do motor |

## CLI proposta

```text
pte-lint check [PATH...] [--format text|json|sarif] [--stdin-filename FILE]
pte-lint explain RULE
pte-lint config --resolved
pte-lint vocab validate PACKAGE
pte-lint rules list [--level LEVEL]
pte-lint fix [PATH...] --safe
pte-lint version --json
```

`check` e `fix --safe` são separados para evitar alteração acidental. No MVP, `fix` ainda não está implementado; a CLI só sugere substituições no diagnóstico. Quando `fix` for adicionado, ele deverá mostrar diff por padrão e exigir `--write` para persistir.

## Exceções

Arquivo de exceções:

```yaml
version: "1.0"
exceptions:
  - rule: R012
    scope: "docs/legal.md:LEGAL-TERMS"
    reason: "Nome empresarial legal indivisível."
    approved_by: editor-legal
    approved_at: 2026-08-06
    review_after: 2027-08-06
```

Exceção vencida gera diagnóstico. Padrão curinga amplo deve gerar advertência. Comentário inline é aceito apenas quando o formato permite preservação segura.

## Plugins

Plugins executam em processo isolado ou WebAssembly quando possível. O manifesto declara versão de API, permissões, seletores, regras e digest. A CLI não baixa nem executa plugin por simples abertura de documento. Pacotes remotos exigem lockfile e verificação de integridade.

## Desempenho e privacidade

A meta inicial é analisar 100 mil palavras em até 5 segundos em computador de desenvolvimento, excluído o primeiro carregamento de modelo opcional. O modo base não depende de modelo remoto. Telemetria é desativada por padrão e nunca inclui conteúdo.

## Conjunto de conformidade

Cada regra automática terá pelo menos cinco fixtures positivas, cinco negativas e casos de exclusão literal. Regras assistidas terão corpus anotado, precisão, cobertura e limiar publicados por localidade. Uma implementação não pode declarar suporte a uma regra assistida sem informar a versão do modelo e as métricas.

O repositório começa com um caso positivo e um negativo por regra automática em `corpus/cases.yaml`. Esses 42 casos são sintéticos e servem apenas como regressão do MVP; não são evidência de precisão linguística.

## Compatibilidade

O contrato público do motor inclui configuração, diagnóstico, IDs e exit codes. Alterações incompatíveis exigem versão principal nova do schema. Campos experimentais usam prefixo `x-`.
