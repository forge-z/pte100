# Interface pública do PTE-100

A página apresenta um padrão técnico em desenvolvimento: identificação direta,
exemplo de aplicação, níveis, catálogo e ferramenta de revisão.

## Referências consultadas

- [GOV.UK Design System](https://design-system.service.gov.uk/styles/): hierarquia de conteúdo e estrutura de leitura.
- [IBM Carbon — Typography](https://carbondesignsystem.com/elements/typography/overview/): escala tipográfica, texto neutro e azul nas ações.

## Direção implementada

Fundo branco, superfícies cinza claras (#f5f7f9), texto escuro (#202b38), azul
nas ações (#234e78) e divisórias finas (#dce1e6). Fontes nativas do sistema;
monoespaçada apenas para identificadores e diagnóstico. Sem fontes remotas,
texturas, rotações ou sombras decorativas.

Conteúdo limitado a 1160 px. Duas colunas na abertura, comparação antes/depois
em um painel e categorias em linhas. Em telas menores, a ordem de leitura vira
uma coluna e todos os links de navegação continuam disponíveis. Foco visível,
atalho para conteúdo e respeito à preferência por movimento reduzido.

A versão experimental permanece explícita. Exemplos não substituem a fonte
normativa no repositório; o terminal é identificado como ilustração.

## Tema

O seletor nativo oferece Automático, Claro e Escuro. Automático acompanha
`prefers-color-scheme` e informa o tema detectado ao lado do controle; a
preferência escolhida fica salva no navegador para as próximas visitas.
