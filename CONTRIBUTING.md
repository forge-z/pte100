# Como contribuir

O PTE-100 aceita contribuições de redação técnica, linguística, tradução, engenharia de software, acessibilidade e diferentes domínios industriais. Discussões podem ocorrer em qualquer variedade do português; texto normativo deve seguir o perfil editorial do projeto.

## Antes de propor uma mudança

1. Procure uma discussão ou proposta existente.
2. Explique o problema observável, o público afetado e um caso real anonimizado.
3. Separe preferências estilísticas de requisitos que possam ser verificados.
4. Para mudanças normativas, descreva o impacto em autores, tradutores e ferramentas.

## Tipos de contribuição

- **Correção editorial:** ortografia, link ou exemplo sem mudança de significado.
- **Esclarecimento:** melhora a interpretação sem alterar obrigação.
- **Mudança normativa:** adiciona, remove ou modifica um `DEVE`, `NÃO DEVE` ou critério de conformidade.
- **Vocabulário:** adiciona termo, sentido, forma evitada ou perfil de domínio.
- **Ferramenta:** schema, regra de lint, fixture ou contrato de integração.

## Proposta de regra

Uma proposta de regra deve incluir:

- identificador provisório (`P-AAAA-NNN`), título e categoria;
- corpus ou exemplos que demonstrem o problema;
- descrição e justificativa;
- exemplo incorreto e correto;
- limites e exceções;
- severidade sugerida;
- detecção automática, revisão humana ou combinação das duas;
- risco de falso positivo e estratégia de migração.

Os códigos `R001` a `R999` são atribuídos por mantenedores e nunca são reutilizados. Regra removida permanece reservada com estado `retired`.

## Fluxo de trabalho

1. Crie uma issue para mudanças normativas ou arquiteturais.
2. Faça uma alteração pequena e coerente em uma branch.
3. Atualize a fonte YAML e o catálogo Markdown no mesmo pull request.
4. Adicione ou ajuste exemplos e fixtures.
5. Execute as validações locais indicadas em `tools/README.md`.
6. Abra o pull request e declare incompatibilidades.

Pull requests normativos ficam abertos por pelo menos 14 dias. Mudanças editoriais podem ser integradas assim que houver revisão suficiente.

## Commits e pull requests

Use mensagens objetivas, por exemplo `rules: esclarecer uso de pronomes` ou `schema: adicionar campo de localidade`. Ao contribuir, você concorda que sua contribuição será licenciada sob Apache-2.0, conforme a cláusula 5 da licença.

## Fonte canônica

`rules/rules.yaml` é a fonte estruturada das regras. `rules/catalog.md` é a publicação humana correspondente. Um pull request que alterar apenas um deles não está completo. Schemas em `schemas/` definem contratos públicos e seguem versionamento semântico.

## Decisões e recursos

Uma decisão pode ser contestada com novas evidências no mesmo ciclo. Um recurso formal deve apontar violação de processo, conflito de interesse ou evidência material ignorada. O Conselho Técnico responde publicamente, conforme `GOVERNANCE.md`.

