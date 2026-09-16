# Roteiro

Datas são metas, não promessas. Mudanças de prioridade seguem [GOVERNANCE.md](GOVERNANCE.md); os responsáveis atuais estão em [MAINTAINERS.md](MAINTAINERS.md). A previsão de um Conselho Técnico não comprova sua constituição.

O [README](README.md) descreve capacidades e comandos atuais; este roteiro distingue entregas de metas. O [registro de auditoria de 7 de setembro](docs/audits/2026-09-07-improvement-review.md) preserva achados históricos e aponta os limites ainda pendentes. As fases abaixo são do produto, não das revisões de manutenção OSS.

## Fase 0 — Fundação (2026, terceiro trimestre)

- [x] publicar a proposta PTE-100 v0.1 e as 50 regras experimentais, com [prerelease histórica](https://github.com/forge-z/pte100/releases/tag/v0.1);
- [x] registrar fontes, licenças e hashes de um snapshot externo em `corpus/sources.yaml` e `corpus/sources.lock.yaml`;
- [x] verificar sintaxe de YAML/JSON, links locais e equivalência dos artefatos gerados;
- [ ] manter um corpus piloto com anotações humanas revisadas;
- [ ] validar instâncias contra os JSON Schemas;
- [ ] executar pilotos em software, manutenção e academia;
- [ ] estabelecer Conselho Técnico provisório e canal privado de conduta.

Critério de saída: três pilotos públicos, pelo menos 1.000 frases avaliadas, anotações revisadas e relatório de falsos positivos por regra automatizável. O manifesto do snapshot registra 215 unidades de três fontes; os textos ficam em cache externo ao Git. Esses metadados não comprovam pilotos, anotação revisada ou precisão linguística.

## Fase 1 — Ferramentas de referência (2026, quarto trimestre)

- [x] disponibilizar MVP offline do PTE-Lint CLI em modo análise para as 21 regras automáticas;
- [x] disponibilizar o PTE-100 Reviewer local para Markdown, texto simples e PDF com camada de texto;
- [ ] transformar o MVP em pacote versionado com instalação documentada;
- [ ] publicar pacote de schemas e API de biblioteca;
- [x] fornecer saída texto, JSON e SARIF na CLI;
- [x] manter 42 fixtures sintéticas: uma positiva para detecção e uma negativa por regra automática;
- [ ] ampliar o [conjunto de conformidade](docs/pte-lint.md#conjunto-de-conformidade);
- [ ] lançar extensão VS Code experimental.

Critério de saída: execução reproduzível, cobertura de todas as regras automáticas e nenhuma alteração destrutiva por padrão.

O MVP atual tem execução reproduzível, ferramentas de ingestão de corpus e regressões sintéticas. Ainda não cobre instalação como pacote, anotações humanas do corpus, análise assistida nem a meta de cinco fixtures positivas, cinco negativas e casos de exclusão literal por regra. A suíte do revisor testa o serviço e o despacho de requisições com objetos simulados; não demonstra o fluxo completo em navegador, a paridade integral entre adaptadores ou a instalação em todos os sistemas operacionais.

## Fase 2 — Ecossistema (2027, primeiro semestre)

- definir PTE-200 Vocabulary v0.1;
- lançar MCP Server somente leitura e API REST beta;
- publicar perfis PTE-300 para software e manutenção;
- adicionar perfis de localidade lusófonos com revisão comunitária;
- integrar Language Server Protocol à extensão.

## Fase 3 — Estabilização (2027, segundo semestre)

- publicar PTE-100 v1.0 após consulta pública;
- oferecer matriz de conformidade e selo autodeclarado verificável;
- congelar códigos e semântica do núcleo 1.x;
- disponibilizar guias de adoção, tradução e acessibilidade.

## Além da v1

- API REST estável com execução isolada e limites públicos;
- perfis PTE-300 para saúde, energia, governo e manufatura, sempre com especialistas;
- métricas longitudinais de compreensão, tradução e recuperação por IA;
- processo de reconhecimento por organizações de normalização, sem comprometer a licença aberta.

## Fora do escopo imediato

- certificar segurança ou correção técnica do conteúdo;
- substituir revisão humana especializada;
- prescrever uma variedade do português em todos os contextos;
- prometer que conformidade linguística torna um procedimento seguro.
