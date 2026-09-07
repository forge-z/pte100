# Plano de melhoria do PTE-100

Data: 7 de setembro de 2026. Estado: correções P0/P1 implementadas; pilotos e distribuição permanecem planejados.

## Base da análise

Análise do checkout local no commit `f6506e9`, cujo origin é `https://github.com/forge-z/pte100.git`. Não foi possível confirmar o HEAD remoto: a consulta Git falhou por resolução de DNS e a consulta web não retornou a página.

O checkout contém alterações anteriores: exclusões de modelos e do workflow de validação, alteração de `.gitignore` e `reviewer-webapp/` não versionado. As observações sobre o revisor descrevem esse trabalho local, não uma versão publicada. Essas alterações foram preservadas.

Foram examinados especificação, README, arquitetura, conformidade, governança, roadmap, contratos de tooling, corpus, motor, CLI, testes, validador editorial, documentação e implementação do revisor e configuração do site. Não foi executada uma auditoria visual do site ou do revisor.

## Direção recomendada

Consolidar norma, motor e revisor local antes de expandir o ecossistema. O motor compartilhado em Ruby e a interface estática são uma base suficiente. O gargalo atual é confiança nos resultados, consistência documental e evidência de uso, não a quantidade de integrações.

## 1. P0 — Corrigir resultados incorretos do motor

Evidências reproduzidas na revisão independente de `lib/`, `bin/` e `test/`:

- caminho inexistente pode retornar sucesso, com `files=1`;
- em `É 10 V.`, um offset retornado é 2 onde o deslocamento em bytes é 3;
- R014 deixa de aparecer em `# Título\nFaça isso se necessário.`;
- uma expansão de sigla posterior ao primeiro uso pode ocultar a ocorrência anterior.
- opções públicas também precisam de regressão: `fail_on: never` ainda pode produzir saída 1, `--stdin-filename` não altera o nome do diagnóstico e um caminho explícito de configuração ausente é ignorado.

Trabalho: corrigir tratamento de arquivos, coordenadas UTF-8 e segmentação/ordem de análise na origem compartilhada. Conferir todos os consumidores do contrato de posições antes de alterar sua semântica. Acrescentar regressões mínimas para cada reprodução.

Aceite: caminho inválido produz erro operacional e código de saída apropriado; intervalos recuperam o trecho correto com acentos e múltiplas linhas; títulos não ocultam prosa; expansão posterior não satisfaz uma exigência de primeira ocorrência; opções públicas de configuração, stdin e saída são respeitadas. CLI e biblioteca passam pela mesma lógica.

## 2. P0 — Fechar lacunas do revisor local

Evidências em `reviewer-webapp/server/reviewer_server.rb` e `client/app.js`:

- `allowed_origin?` aceita origem construída a partir de `request.host`, sem allowlist independente de Host. Um teste direto com host/origem `evil.example` retornou `true`; isto não equivale a uma exploração completa no navegador;
- o endpoint de capabilities entrega o token sem passar pela validação de sessão/origem;
- `clearDocument()` oculta o painel, mas deixa nome e evidências no DOM;
- importar outro arquivo não invalida o relatório anterior; o nome de exportação deriva do arquivo atualmente selecionado;
- uma resposta em andamento pode atualizar resultados depois da remoção ou troca do documento;
- `file.text()` não permite rejeitar de forma estrita bytes UTF-8 inválidos;
- há timeout de conversão PDF, mas não limite explícito de concorrência e duração de toda a análise.

Trabalho: validar Host contra o endereço/porta de escuta em todas as rotas, validar Origin quando presente e manter token nas operações protegidas; limpar o DOM e invalidar respostas antigas; vincular resultado ao documento analisado; decodificar UTF-8 estritamente; limitar análise simultânea e recursos de processamento. Reutilizar servidor e cliente existentes.

Aceite: teste HTTP recusa Host externo, Origin externo e token inválido; remover documento elimina texto identificável do DOM e impede retorno tardio; relatório nunca recebe nome de outro documento; bytes inválidos são recusados; carga excessiva falha com erro previsível.

## 3. P1 — Tornar a validação reproduzível

`tools/validate_repo.rb` percorre todos os Markdown, incluindo `website/node_modules`; a execução local falhou por links de dependências. O mesmo script analisa JSON sintaticamente, mas isso não prova conformidade das instâncias com JSON Schema. Os sete testes do revisor exercitam `ReviewerService`, sem iniciar HTTP ou navegador.

Trabalho:

- restringir validação editorial aos arquivos do projeto, excluindo dependências e saídas de build;
- validar regras, vocabulário, configuração e diagnósticos contra seus schemas;
- comparar saídas equivalentes da CLI, biblioteca e HTTP;
- integrar a suíte do revisor ao comando de verificação do projeto;
- decidir o destino das exclusões locais do CI antes de propor sua restauração;
- verificar catálogo e fixtures gerados sem diferenças inesperadas;
- acrescentar um fluxo de navegador com importação, revisão, exportação e limpeza, incluindo teclado e inspeção de rede.

Aceite: o mesmo comando passa em checkout limpo e com dependências do site instaladas; um diagnóstico deliberadamente inválido falha; nenhuma conexão externa ocorre no fluxo do revisor; paridade entre adaptadores é comparada, não presumida.

## 4. P1 — Alinhar documentação e conformidade

`GOVERNANCE.md` afirma que regras experimentais não impedem conformidade; o catálogo usa regras experimentais, enquanto `docs/conformance.md` exige ausência de erros sem desvio. A relação entre estado de regra, severidade e resultado precisa de uma decisão normativa explícita.

O README do revisor ainda descreve SPA TypeScript e uma decisão “antes de implementar”, embora exista cliente JavaScript. O plano de entrega declara Marco 1 implementado, mas seus critérios incluem validações HTTP, paridade e teclado ainda não demonstradas pela suíte existente. O roadmap central não incorpora o revisor.

Trabalho: resolver a semântica de conformidade com revisão editorial; separar claramente análise automática de declaração de conformidade; atualizar estados para planejado, implementado e verificado; incluir o revisor no roadmap e documentar limites de formato/localidade. Para PDF, explicitar que posições se referem ao texto extraído enquanto não houver mapa de páginas/blocos.

Aceite: os documentos não fazem promessas contraditórias; cada capacidade declarada como verificada aponta para um teste ou evidência; zero achados não é apresentado como certificação ou revisão integral.

## 5. P1 — Medir qualidade linguística com corpus real

O roadmap registra 215 unidades de três fontes e prevê três pilotos e 1.000 frases avaliadas. As fixtures positivas/negativas são úteis para regressão, mas não demonstram precisão linguística.

Trabalho: usar os scripts existentes para anotar o snapshot; incluir documentos de manutenção e academia além de software; revisar uma amostra também sem diagnósticos para encontrar falsos negativos; registrar decisões por regra e divergências entre revisores; separar material de calibração do conjunto de avaliação. Ampliar casos por regra conforme o critério já documentado, priorizando limites, acentos e estrutura Markdown.

Aceite: relatório por regra com verdadeiros/falsos positivos, falsos negativos, denominadores e limitações; três pilotos e 1.000 frases revisadas para cumprir a saída já prevista. Metas de precisão devem ser fixadas após a primeira medição, sem inventar percentuais.

## 6. P2 — Facilitar adoção e só então ampliar integrações

Trabalho: disponibilizar versão instalável do motor, fachada pública mínima da biblioteca e inicialização simples do revisor; testar instalação limpa nos sistemas anunciados; medir tempo/memória em 10 mil e 100 mil palavras em máquina identificada. Validar a experiência com 3 a 5 documentos e pessoas representativas, incluindo localização de achados e compreensão das sugestões.

Aceite: uma pessoa nova consegue instalar, revisar e exportar offline seguindo apenas a documentação; versões de motor/regras/vocabulário são identificáveis; há medição publicada e limites explícitos.

Depois desses critérios, escolher uma integração com base nos pilotos: SARIF para CI, extensão para autores ou MCP local para agentes. Adiar API hospedada, LSP completo, novos formatos, OCR e IA generativa até existir demanda demonstrada. Não reescrever o motor nem introduzir framework de frontend apenas para executar este plano.

## Sequência e acompanhamento

1. Corrigir P0 do motor e do revisor em entregas separadas, com regressões.
2. Consolidar verificação e estados documentais; iniciar anotação do corpus em paralelo.
3. Encerrar pilotos e medir qualidade; ajustar regras a partir dos resultados.
4. Empacotar e validar adoção; escolher a próxima integração pelo uso observado.

Os critérios de aceite, e não as datas antigas do roadmap, devem liberar cada etapa. A definição normativa e a anotação humana são dependências de revisão especializada; não devem ser substituídas por resultados automáticos.

## Verificação nesta análise

- Suíte principal: 21 testes, 596 assertions, sem falhas, segundo execução da revisão independente.
- Revisor: 7 testes, 26 assertions, sem falhas.
- Validador editorial: falha reproduzida por varredura de links em `node_modules`.
- Validação de origem: reprodução direta da aceitação de host/origem externo na função atual.
- Não verificados: HEAD remoto, CI publicado, build/experiência visual, exploração de segurança ponta a ponta, instalação multiplataforma e precisão em corpus anotado.

As correções de motor, segurança do revisor, testes e validação editorial foram implementadas após esta análise. Pilotos, métricas de corpus, empacotamento e integrações posteriores continuam pendentes.
