# Escrita para agentes de IA

## Objetivo

Conteúdo recuperável por IA deve conservar contexto suficiente para não depender de uma janela de conversa, posição de página ou inferência sobre o produto.

## Unidade autônoma

Inclua o nome do componente, variante, pré-condição e versão quando afetarem a ação. Não repita contexto irrelevante: autonomia não significa duplicar o manual inteiro.

## Proveniência

Registre origem, revisão, aprovador, validade e produto aplicável em metadados estruturados. Um índice vetorial pode perder cabeçalhos ancestrais; o pipeline de ingestão deve anexar esses campos a cada fragmento.

## Fronteiras

Marque claramente:

- conteúdo normativo e informativo;
- texto do autor e conteúdo externo;
- instrução e exemplo;
- comando literal e descrição;
- dado confirmado e hipótese.

Essa separação reduz a chance de um agente executar um exemplo ou tratar citação como instrução.

## Fragmentação

O fragmento recomendado corresponde a uma unidade de conteúdo, não a um número arbitrário de tokens. Um alerta nunca deve ser separado do passo que controla. Relações são preservadas por `parent_id`, `requires` e `applies_to`.

## Resposta segura

Metadados PTE ajudam o agente a citar fontes e detectar versões, mas não concedem autoridade para executar ações. O MCP inicial oferece leitura e validação; qualquer escrita futura deve produzir diff e exigir aprovação humana.

