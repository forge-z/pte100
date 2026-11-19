# Plano de execução: extensão VS Code e servidor MCP

Este documento descreve a execução das duas integrações ainda não entregues. A extensão do VS Code e o servidor MCP não existem neste repositório. A CLI `bin/pte-lint` e o revisor local já compartilham o motor em `lib/pte_lint.rb`.

O plano não altera a especificação, `rules/rules.yaml` nem o motor. A arquitetura pretendida continua em [tooling-plan.md](tooling-plan.md); o estado implementado está no [README](../README.md) e as metas, no [ROADMAP](../ROADMAP.md). O contrato atual da CLI está em [pte-lint.md](pte-lint.md).

A primeira extensão chama a CLI que já existe. O Language Server Protocol permanece a integração posterior da Fase 2. O servidor MCP desta execução é local, somente leitura e fala por `stdio`. A API REST beta fica fora deste plano.

## O que o motor já faz

`ruby bin/pte-lint check --format json` analisa Markdown e texto simples em UTF-8. Os comandos implementados são `check` e `version`. `explain`, `config`, `vocab`, `rules` e `fix` respondem que não estão implementados e terminam com código 2.

A saída JSON segue [schemas/diagnostic.schema.json](../schemas/diagnostic.schema.json), versão `1.0`. Cada diagnóstico traz, entre outros campos obrigatórios, `rule`, `severity`, `message`, `file`, `range` e `fingerprint`. `range.start` e `range.end` têm `line` e `column` a partir de 1 e `offset` em bytes UTF-8 a partir de 0. O fim do intervalo é exclusivo. `suggestion` e `fix` são opcionais.

`--format sarif` emite um documento com `version` `2.1.0`, uma execução e, por diagnóstico, `ruleId`, `level`, `message.text`, `startLine` e `startColumn`. Não há schema SARIF em `schemas/`. O emissor copia `severity` para `level`, não envia o fim do intervalo, não envia `suggestion` nem `fix` e não descreve as regras no driver. `info` não é valor de `level` no SARIF 2.1.0. A extensão usa JSON.

O motor executa as 21 regras de `PteLint::AUTOMATIC_RULES`. As outras 29 permanecem `assisted` em `rules/rules.yaml` e não têm método `check_` no motor. O catálogo marca `autofix` como `none`, `suggested` ou `safe`. O motor só preenche `fix` quando há `suggestion` e `fix_safety`. Hoje isso ocorre apenas em R038 e R039, com `fix.safety` igual a `safe` e `fix.replacement` igual à sugestão.

| ID | `autofix` no catálogo | O que o motor emite |
|---|---|---|
| R038 | `safe` | `suggestion` e `fix.safety` `safe`: espaço comum entre valor e símbolo vira U+00A0 |
| R039 | `safe` | `suggestion` e `fix.safety` `safe`: troca o símbolo malformado do registro interno |
| R001, R005, R006 | `suggested` | `suggestion` com o termo de substituição; sem objeto `fix` |
| R004, R014, R017, R018, R021, R029, R040, R041 | `suggested` | diagnóstico sem `suggestion` e sem `fix` |
| R012, R031, R037, R042, R045, R046, R048, R050 | `none` | diagnóstico sem `suggestion` e sem `fix` |

R001 substitui só o termo proibido. R005 usa o registro interno de abreviações (`temp.`, `amb.`, `aprox.`, `qtd.`, `obs.`, `ref.`). R006 usa o registro interno de nominalizações. Nenhum dos três está marcado `safe`.

A configuração reconhecida pela CLI é `.pte-lint.yaml`, `.pte-lint.yml` ou `.pte-lint.json` no diretório de trabalho, ou `--config`. O exemplo versionado é [pte-lint.example.yaml](../pte-lint.example.yaml). Num arquivo ou na entrada padrão, o motor aplica `level` (padrão `pte-claro`), `locale` (padrão `pt-BR`) e a severidade ou `off` de `rules`. `fail_on` só altera o código de saída. As allowlists de `profile_definitions` dependem de `source_id` no contexto do documento; a CLI não envia esse contexto, então essa chamada não as ativa. A allowlist interna de siglas continua valendo. O schema [pte-lint-config.schema.json](../schemas/pte-lint-config.schema.json) também descreve `include`, `exclude`, `exceptions`, `output` e `cache`. O motor não aplica esses campos. Não há cascata por diretório nem leitura de `pte-ignore`. `summary.suppressed` permanece zero.

Códigos de saída usados pela CLI: 0 quando nenhum diagnóstico atinge `fail_on`; 1 quando atinge; 2 para comando desconhecido, opção inválida ou configuração ilegível; 3 para caminho ausente ou leitura impossível. O código 4 está especificado em [pte-lint.md](pte-lint.md) e a CLI atual não o emite.

As 42 fixtures em `corpus/fixtures/positive/` e `corpus/fixtures/negative/` vêm de [corpus/cases.yaml](../corpus/cases.yaml). O teste em `test/test_pte_lint.rb` usa nível `pte-ia`: a fixture positiva precisa conter o ID esperado e a negativa precisa não contê-lo. Outras regras podem disparar no mesmo texto. R048 e R050 são automáticas de nível `pte-ia` e ficam desligadas no padrão `pte-claro`.

## Etapa 1 — Congelar o contrato de saída

Objetivo: a extensão e o servidor MCP dependem do JSON que a CLI já emite. Uma mudança do motor que altere esse formato quebra o teste antes de quebrar o editor.

O schema de diagnóstico já existe. Falta validar instâncias. `tools/validate_repo.rb` só confere que os arquivos em `schemas/` são JSON sintaticamente válido. `test/test_pte_lint.rb` confere `schema_version`, o nome da ferramenta e um ID de regra. O `Gemfile` do revisor não traz biblioteca de JSON Schema.

Trabalho desta etapa:

- validar a saída de `ruby bin/pte-lint check --format json` contra [schemas/diagnostic.schema.json](../schemas/diagnostic.schema.json);
- cobrir as 42 fixtures, um texto sem diagnóstico e um caso com `fix.safety` `safe` (R038 ou R039);
- publicar em `schemas/` o subconjunto SARIF que `bin/pte-lint` emite hoje, com teste de contrato ao lado de `test/test_cli.rb`;
- manter `level` do SARIF como cópia de `severity` (`error`, `warning`, `info`) até uma mudança explícita de formato.

A extensão não consome SARIF. O schema SARIF registra o emissor atual para a CI. Conformidade com o schema oficial SARIF 2.1.0 exige outra versão do contrato: mapear `info` para `note` e passar a enviar fim do intervalo, sugestão e metadados da regra.

Critério de aceite:

- `rake verify` falha se a CLI emitir um campo, um tipo ou uma ausência que o schema JSON proíbe;
- o mesmo vale para o subconjunto SARIF versionado;
- `suggestion` continua opcional; `fix` só aparece com `safety` e `replacement`;
- nenhuma regra, severidade ou obrigação da especificação muda nesta etapa.

## Etapa 2 — Extensão do VS Code

Cliente TypeScript no monorepositório. Não há servidor LSP nesta etapa. A extensão não reimplementa regras: envia o buffer à CLI e traduz o JSON.

Disparo:

- ao salvar, análise imediata do buffer;
- ao digitar, a mesma análise depois de um atraso configurável a partir da última alteração; o valor inicial sugerido é 300 ms;
- uma análise nova cancela o processo Ruby ainda em curso.

Invocação, com o diretório de trabalho na raiz do workspace:

```text
ruby bin/pte-lint check --format json --stdin-filename CAMINHO
```

O texto do editor vai na entrada padrão. `--stdin-filename` recebe o caminho relativo ao workspace, que a CLI devolve em `file`. Passar o caminho como argumento leria o disco e ignoraria o buffer não salvo. Quando existir `.pte-lint.yaml`, `.pte-lint.yml` ou `.pte-lint.json`, a extensão passa esse arquivo em `--config`, na mesma ordem de descoberta da CLI. Sem arquivo, omite `--config` e vale o padrão interno (`pte-claro`, `pt-BR`). A extensão não aplica `include` nem `exclude`: o motor também não aplica. A chamada por arquivo ou entrada padrão também não ativa allowlists de perfil, porque a CLI não define `source_id`.

Tradução para `vscode.Diagnostic`:

| JSON | Editor |
|---|---|
| `severity` `error` | Error |
| `severity` `warning` | Warning |
| `severity` `info` | Information |
| `range.start.line` e `column`, base 1 | posição base 0 |
| `range.end`, exclusivo | fim do intervalo |
| `rule` | `code` |
| `message` | mensagem |
| `documentation` | link já emitido pelo motor |

A coluna do motor conta caracteres Ruby. O editor conta unidades UTF-16. Os testes da extensão incluem texto com acento e com U+00A0, como as fixtures de R038.

O hover usa o ID da regra e lê `title`, `description` e `correct` em [rules/rules.yaml](../rules/rules.yaml). O campo `correct` é o exemplo publicado no catálogo sob **Correto**. Quando o diagnóstico traz `suggestion`, o hover também a mostra. O hover não extrai o exemplo do Markdown gerado.

Códigos 0 e 1 encerram uma análise válida. O código 1 significa que algum diagnóstico atingiu `fail_on`; os diagnósticos continuam visíveis. Códigos 2 e 3 viram erro de execução da ferramenta, não diagnóstico de regra.

Formatos da primeira versão: Markdown e texto simples, os mesmos que [pte-lint.md](pte-lint.md) atribui ao MVP. A extensão não envia o texto à rede, não baixa modelo e não grava o arquivo por conta própria.

Testes com `@vscode/test-electron`, dependência nova só do pacote da extensão. Cada arquivo de `corpus/fixtures/positive/` e `corpus/fixtures/negative/` é aberto no editor de teste. A análise usa `--level pte-ia` e `--locale pt-BR`, como `test/test_pte_lint.rb`. Na fixture positiva, os diagnósticos incluem o ID do arquivo. Na negativa, não incluem. A presença de outro ID não falha o teste.

Critério de aceite:

- salvar e digitar, após o atraso, atualizam os diagnósticos do buffer aberto, inclusive não salvo;
- a configuração do workspace entra por `--config` e altera nível, localidade ou severidade já honrados pela CLI;
- o hover de uma regra automática mostra o exemplo `correct` correspondente;
- a suíte Electron percorre as 42 fixtures com o critério de presença e ausência do ID;
- um Ruby ausente ou um código 2 ou 3 produz erro de ferramenta e não limpa diagnósticos antigos em silêncio.

## Etapa 3 — Code Actions

Code Action só quando o diagnóstico traz `fix.safety` igual a `safe` e `fix.replacement`. No catálogo e no motor atuais, isso é R038 e R039.

A ação substitui o intervalo `range` por `fix.replacement`. Em R038, a substituição é o valor, U+00A0 e o símbolo. Em R039, é o trecho com o símbolo padronizado do registro. A ação é explícita: a pessoa a escolhe no editor. A extensão não reescreve em lote ao salvar e não chama `fix`, comando ausente no MVP.

As outras 19 regras automáticas permanecem diagnóstico, com a severidade que o motor devolveu. R001, R005 e R006 podem exibir `suggestion` no hover e não ganham Code Action: o catálogo as marca `suggested` e o motor não envia `fix`. O valor `review`, previsto no schema e ainda não emitido, também não gera Code Action.

Critério de aceite:

- a fixture positiva de R038 oferece uma ação cuja edição contém U+00A0 entre o número e o símbolo;
- a fixture positiva de R039 oferece uma ação que aplica o símbolo do registro;
- fixtures de R001, R004, R005, R006, R012, R014, R017, R018, R021, R029, R031, R037, R040, R041, R042, R045, R046, R048 e R050 não oferecem Code Action;
- a ação não aparece quando o JSON traz `suggestion` sem `fix`.

## Etapa 4 — Servidor MCP

Processo local, transporte `stdio`, sem rede e sem escrita. Três ferramentas, os mesmos nomes já listados em [tooling-plan.md](tooling-plan.md). `pte_check_file`, `pte_list_rules` e `pte_validate_metadata` continuam só naquele plano.

| Ferramenta | Entrada | Saída |
|---|---|---|
| `pte_check_text` | `text`; `locale` e `level` opcionais; nome de arquivo opcional | documento JSON da CLI, schema `1.0` |
| `pte_explain_rule` | ID `R001`–`R050` | campos de `rules/rules.yaml`: título, descrição, justificativa, `incorrect`, `correct`, severidade, nível, `lint.mode`, `lint.autofix` |
| `pte_lookup_term` | termo | conceito de [vocabulary/core.yaml](../vocabulary/core.yaml): ID, `preferred`, `admitted`, `forbidden` com `replacement`, definição e exemplo |

`pte_check_text` executa `ruby bin/pte-lint check --format json`, com o texto na entrada padrão, `--level` e `--locale` quando informados. O padrão continua `pte-claro` e `pt-BR`. Código 1 é resultado com diagnósticos. Códigos 2 e 3 são erro da ferramenta. O servidor não consulta o revisor HTTP.

`pte_explain_rule` lê as 50 regras do YAML. ID desconhecido é erro e não gera texto inventado. Não há comando `explain` na CLI.

`pte_lookup_term` compara o termo com `preferred`, `admitted` e `forbidden.term`, sem distinção de maiúsculas. O pacote publicado declara a localidade `pt-BR`. Termo ausente volta vazio. Não há comando `vocab` na CLI. A forma do pacote está em [vocabulary/schema.json](../vocabulary/schema.json).

O servidor recusa texto acima de um limite próprio, com erro e sem truncar: truncar deslocaria linha e coluna. O log não inclui o texto analisado. Não há ferramenta de aplicar correção.

Critério de aceite:

- `Faça a checagem da bateria.` em `pte_check_text` devolve R001 no documento validado pelo schema;
- `pte_explain_rule` de R038 devolve `autofix` `safe` e o exemplo correto do catálogo; um ID inexistente falha;
- `pte_lookup_term` de `checar` devolve `PTE-C0001`, preferido `verificar` e a substituição `verificar`;
- uma sessão que só chama as três ferramentas não cria nem altera arquivo do workspace.

## Trabalho contínuo

Promover uma regra `assisted` para `automatic`, uma por vez. As 29 regras sem motor são R002, R003, R007, R008, R009, R010, R011, R013, R015, R016, R019, R020, R022, R023, R024, R025, R026, R027, R028, R030, R032, R033, R034, R035, R036, R043, R044, R047 e R049.

Cada promoção:

1. abre issue antes da mudança, conforme [CONTRIBUTING.md](../CONTRIBUTING.md) e [GOVERNANCE.md](../GOVERNANCE.md);
2. implementa `check_` daquela regra e muda `lint.mode` em `rules/rules.yaml`;
3. acrescenta em `corpus/cases.yaml` uma fixture positiva e um contraexemplo negativo, e regenera `corpus/fixtures/` com `ruby tools/generate_corpus.rb`;
4. atualiza no mesmo PR o catálogo gerado, a tabela de [pte-lint.md](pte-lint.md), `PteLint::AUTOMATIC_RULES` e os contadores de 21 regras e 42 casos em `tools/validate_repo.rb`;
5. mantém `examples/procedure-pte.md` com um arquivo, zero erros e zero avisos.

`autofix` só passa a `safe` quando a substituição é determinística e o motor envia `fix.safety` `safe`. Até lá a regra nova fica em diagnóstico, como as automáticas que hoje são `none` ou `suggested`.

A promoção espera o par sintético e uma amostra revisada em que a regra não dispara nos contraexemplos. As 42 fixtures são regressão do MVP. [corpus/README.md](../corpus/README.md) registra que elas não medem precisão linguística. O snapshot externo não tem anotação humana publicada. O alvo de conformidade em [pte-lint.md](pte-lint.md#conjunto-de-conformidade) continua sendo cinco fixtures positivas, cinco negativas e casos de exclusão literal por regra automática. Um agente não aprova a promoção sozinho.

## Riscos

- Tratar o SARIF atual como contrato do editor perde o fim do intervalo e a sugestão, e usa `info` onde o SARIF 2.1.0 espera `note`.
- Converter coluna Ruby para UTF-16 sem teste em acento e U+00A0 desloca o sublinhado.
- Analisar o caminho em disco durante a digitação ignora o buffer não salvo.
- Código de saída 1 interpretado como falha de processo esconde diagnósticos.
- Code Action em R001, R005 ou R006 altera o texto sem o `safe` do catálogo. A sugestão de R001 é só o termo preferido, não a frase reescrita.
- `safe` no catálogo classifica a substituição, não a ausência de falso positivo no casamento. R038 e R039 continuam heurísticas do MVP; a ação permanece manual.
- Disparar um processo Ruby a cada alteração, mesmo com atraso, pode atrasar o diagnóstico. A análise em curso precisa ser cancelada.
- O fragmento `#r0xx` em `documentation` não é, por si, a âncora do título no catálogo. O hover lê o YAML local.
- Promover regra sem atualizar os contadores de `tools/validate_repo.rb` quebra `rake verify`. Promover várias de uma vez mistura regressões.
- O servidor MCP entrega texto ao agente que o chamou. O processo em si não abre rede; o agente pode enviar o resultado adiante. Documento confidencial segue a política de quem opera o agente.
