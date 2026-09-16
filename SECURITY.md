# Segurança

## Escopo

Esta política cobre o software existente: PTE-Lint/CLI, reviewer local, conversão de PDF, ferramentas de corpus e dependências. Falhas de execução de código, leitura indevida de arquivos, negação de serviço, injeção por documentos ou exposição de dados são questões de segurança de software. MCP Server, API REST pública e extensão ainda são planejados.

## Como iniciar um relato

Na verificação de 16 de setembro de 2026, o **GitHub Private Vulnerability Reporting estava desativado** neste repositório. Não há outro canal privado confirmado nesta política. A presença de `SECURITY.md` na aba Security do GitHub não significa que o recebimento privado esteja habilitado.

Até que um canal seja confirmado, abra uma [issue](https://github.com/forge-z/pte100/issues/new) solicitando ao [mantenedor](MAINTAINERS.md) um contato privado, **sem descrever a falha**. Não publique prova de conceito, arquivos afetados, dados pessoais, segredos ou detalhes de exploração. Aguarde a indicação do canal antes de transmitir essas informações. Essa alternativa segue a [orientação do GitHub para repositórios sem relato privado habilitado](https://docs.github.com/en/code-security/how-tos/report-and-fix-vulnerabilities/report-privately).

O mantenedor deve atualizar esta política ao disponibilizar um canal. Este documento não publica endereço de e-mail pessoal.

## Compromisso

Após receber o relato por um canal privado confirmado, o projeto buscará confirmar o recebimento em 3 dias úteis, avaliar severidade em 10 dias úteis e coordenar correção antes da divulgação. Esses prazos são metas comunitárias, não acordo de nível de serviço.

## Limites da norma

Conformidade com PTE-100 mede propriedades linguísticas e estruturais. Ela não certifica a segurança, a legalidade ou a exatidão de um procedimento técnico.

Falsos positivos, falsos negativos e propostas de redação devem seguir [CONTRIBUTING.md](CONTRIBUTING.md), com exemplos anonimizados, salvo quando também revelarem uma vulnerabilidade de software.
