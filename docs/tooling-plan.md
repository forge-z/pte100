# Plano de ferramentas

## Estratégia

Um núcleo compartilhado evita cinco implementações divergentes. A opção sustentável é um motor portátil com API de biblioteca e protocolo LSP; CLI, extensão, MCP e serviço REST são adaptadores finos.

## PTE-Lint Core e CLI

**Primeiro marco:** parser Markdown/texto, R004, R005, R012, R014, R017, R018, R021, R029, R031, R037–R042, R045 e R046. Esses casos dão valor sem exigir modelo estatístico.

**Segundo marco:** análise morfossintática local e regras assistidas, com métricas por localidade. O motor deve permitir substituir o analisador linguístico sem mudar diagnósticos públicos.

**Terceiro marco:** adaptadores AsciiDoc e HTML, cache incremental, SARIF e API de plugin isolada.

## Extensão VS Code

Arquitetura: cliente TypeScript + servidor LSP iniciado localmente.

Recursos planejados:

- sublinhado e explicação da regra;
- ação rápida apenas para correções `safe`;
- prévia de diff para sugestões semânticas;
- painel de vocabulário e inserção de termo preferido;
- seleção de localidade e nível por workspace;
- status de pacote e configuração resolvida;
- comandos “explicar regra” e “suprimir com justificativa”.

A extensão não deve baixar modelos nem enviar texto sem consentimento. A primeira versão não aplica correções em lote.

## MCP Server

O servidor inicial é local, somente leitura e usa `stdio`. Ferramentas propostas:

| Ferramenta | Entrada principal | Saída |
|---|---|---|
| `pte_check_text` | texto, localidade, nível | diagnósticos |
| `pte_check_file` | caminho permitido, configuração | diagnósticos |
| `pte_explain_rule` | ID e versão | regra e exemplos |
| `pte_lookup_term` | termo, localidade, domínio | conceito e forma preferida |
| `pte_list_rules` | categoria, nível, modo | metadados de regras |
| `pte_validate_metadata` | objeto de metadados | erros de schema |

Recursos MCP expõem snapshots versionados de especificação, regras e vocabulário. Prompts podem orientar revisão, mas não são normativos.

Controles de segurança: raízes de arquivo explícitas, limite de tamanho, sem rede por padrão, sem escrita, logs sem conteúdo e versão fixada. Uma futura ferramenta `pte_apply_fixes` será separada, retornará diff e exigirá aprovação do cliente.

## API REST

Endpoints propostos:

```text
POST /v1/check
POST /v1/metadata/validate
GET  /v1/rules
GET  /v1/rules/{id}
GET  /v1/vocabularies/{package}/concepts/{id}
GET  /v1/health
```

Requisições de validação incluem versão, localidade, nível, conteúdo e formato. Respostas usam o schema de diagnóstico. A API aplica autenticação, limite de carga, tempo máximo, retenção zero por padrão e `Idempotency-Key` apenas quando necessário. O serviço publica região de processamento e política de dados.

## Sequência escolhida

1. schemas e fixtures;
2. motor e CLI;
3. LSP e VS Code;
4. MCP local;
5. API REST hospedada.

Construir a API antes do motor local criaria dependência de serviço e risco de privacidade. Construir a extensão antes do protocolo duplicaria lógica. A sequência escolhida mantém o padrão utilizável offline e testa contratos antes de expor rede.

## Repositórios futuros

Enquanto a API ainda muda, tudo permanece neste monorepositório. Depois da primeira versão estável, artefatos com ciclos independentes podem migrar para `pte-lint`, `pte-vscode` e `pte-mcp`, mantendo schemas em `pte-spec`. A migração só ocorrerá quando reduzir, e não aumentar, custo de contribuição.

