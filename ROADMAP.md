# Roteiro

Datas são metas, não promessas. O Conselho Técnico pode reordenar itens com justificativa pública.

## Fase 0 — Fundação (2026, terceiro trimestre)

- publicar PTE-100 v0.1 e as 50 regras experimentais;
- coletar corpus de documentação com licenças adequadas;
- manter um corpus piloto reproduzível com fontes, licenças, hashes e anotações;
- validar schemas, referências e equivalência YAML/Markdown;
- executar pilotos em software, manutenção e academia;
- estabelecer Conselho Técnico provisório e canal privado de conduta.

Critério de saída: três pilotos públicos, pelo menos 1.000 frases avaliadas, anotações revisadas e relatório de falsos positivos por regra automatizável. O primeiro snapshot contém 215 unidades de três fontes; ele é uma base de calibração, não ainda um conjunto estatístico suficiente.

## Fase 1 — Ferramentas de referência (2026, quarto trimestre)

- [x] disponibilizar MVP offline do PTE-Lint CLI em modo análise para as 21 regras automáticas;
- [ ] transformar o MVP em pacote versionado com instalação documentada;
- publicar pacote de schemas e API de biblioteca;
- fornecer saída texto, JSON e SARIF;
- lançar extensão VS Code experimental;
- manter conjunto de conformidade com fixtures positivas e negativas.

Critério de saída: execução reproduzível, cobertura de todas as regras automáticas e nenhuma alteração destrutiva por padrão.

O MVP atual cobre a execução reproduzível, o piloto de corpus real e tem uma fixture positiva e negativa por regra. Ainda não cobre instalação como pacote, anotações humanas do corpus, análise assistida nem os cinco casos por regra previstos para a saída da fase.

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
