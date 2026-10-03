# Modelo de documento

## Unidade mínima

Uma unidade de conteúdo tem `id`, `type`, `title`, `locale`, `revision`, `status` e corpo. Tipos centrais: `concept`, `reference`, `procedure`, `alert`, `troubleshooting` e `glossary`.

## Procedimento

```yaml
id: PROC-PUMP-017
type: procedure
title: Substituir o filtro da bomba
locale: pt-BR
revision: 3
status: approved
applies_to: [PUMP-X2]
prerequisites: [POWER-OFF]
```

O corpo contém objetivo, materiais, alertas, passos e resultado esperado. Cada passo tem uma ação principal e pode conter condição, limite e verificação.

## Conteúdo literal

Código, comandos, mensagens de interface, nomes legais, caminhos e citações devem ser marcados pelo formato de origem. Regras linguísticas não analisam conteúdo literal por padrão, mas regras de segurança e segredo podem fazê-lo.

## Inclusão e referência

Conteúdo reutilizado deve ser incluído por ID e versão ou por referência imutável. Expressões como “acima”, “abaixo” e “na página anterior” não substituem uma referência estável.

## Acessibilidade

Estrutura semântica não depende apenas de tipografia ou cor. Imagens informativas têm texto alternativo; tabelas têm cabeçalhos; alertas têm palavra-sinal textual; links descrevem o destino.

