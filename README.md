# PTE-100 — Português Técnico Essencial

[English overview](README.en.md) · [Site público](https://forge-z.github.io/pte100/)

[![Status: proposta v0.1](https://img.shields.io/badge/status-proposta%20v0.1-f5a623)](spec/PTE-100-v0.1.md)
[![Licença: Apache-2.0](https://img.shields.io/badge/licen%C3%A7a-Apache--2.0-blue)](LICENSE)
[![Idioma: português](https://img.shields.io/badge/idioma-portugu%C3%AAs-009c3b)](docs/architecture.md)

O PTE-100 é um padrão aberto e original para escrever documentação técnica em português com menos ambiguidade, mais consistência e melhor processamento por pessoas, tradutores e agentes de IA.

O projeto não é uma tradução, adaptação oficial nem implementação do ASD-STE100. O PTE-100 parte de problemas universais da comunicação técnica, mas define identidade, regras, taxonomia, modelo de conformidade e arquitetura de ferramentas próprios.

> **Estado do projeto:** a versão 0.1 é uma proposta pública. Use-a em pilotos e envie evidências. Não a trate ainda como padrão estável.

## O que está incluído

- [Especificação PTE-100 v0.1](spec/PTE-100-v0.1.md), com escopo, linguagem normativa e conformidade;
- [50 regras iniciais](rules/catalog.md), também disponíveis como [dados YAML](rules/rules.yaml);
- [vocabulário controlado](vocabulary/README.md) com um núcleo inicial legível por máquina;
- [exemplos antes/depois](examples/before-after.md) e um [procedimento completo](examples/procedure-pte.md);
- [corpus externo de testes](docs/corpus-sources.md), com manifesto, snapshots e ingestão reproduzível;
- contratos para [PTE-Lint](docs/pte-lint.md), CLI, extensão VS Code, MCP Server e API REST;
- governança, processo de contribuição e roteiro público.

## Exemplo rápido

Antes:

> O operador deverá efetuar a verificação do nível e, caso seja necessário, proceder com o completamento do reservatório, sendo que o motor deve estar desligado.

Depois:

> 1. Desligue o motor.
> 2. Verifique o nível do reservatório.
> 3. Se o nível estiver abaixo da marca **MÍN**, adicione fluido e pare quando o nível alcançar a marca **MÁX**.

O texto revisado usa ações diretas, uma condição explícita, termos consistentes e passos verificáveis.

## Comece por aqui

1. Leia os [princípios de projeto](docs/design-principles.md).
2. Consulte a [arquitetura da norma](docs/architecture.md).
3. Selecione um nível de [conformidade](docs/conformance.md).
4. Adote o arquivo [`pte-lint.example.yaml`](pte-lint.example.yaml) no projeto piloto.
5. Registre falsos positivos, exceções e métricas antes/depois.

Para experimentar o MVP localmente:

```sh
bin/pte-lint check examples/procedure-pte.md --format text
bin/pte-lint check corpus/fixtures/positive/R040.md --format json
```

## Arquitetura do ecossistema

| Componente | Responsabilidade | Estado |
|---|---|---|
| PTE-100 Core | linguagem, gramática, estrutura e conformidade | proposta v0.1 |
| PTE-200 Vocabulary | registro e distribuição de vocabulários | planejado |
| PTE-300 Domínios | perfis para setores técnicos | planejado |
| PTE-Lint | analisador e formato de diagnósticos | MVP offline (21 regras automáticas) |
| VS Code Extension | feedback durante a escrita | planejado |
| MCP Server | validação e consulta por agentes | planejado |
| API REST | validação remota e registro de termos | planejado |

## Princípios de manutenção

- uma exigência deve ser testável ou marcada como revisão humana;
- mudanças incompatíveis exigem versão principal nova;
- toda regra nova precisa de motivação, contraexemplo, exemplo correto e estratégia de lint;
- decisões normativas são públicas, rastreáveis e orientadas por evidências;
- perfis de domínio estendem o núcleo sem redefinir o significado de suas regras.

## Estrutura do repositório

```text
.
├── .github/              # modelos e automação de contribuição
├── docs/                 # arquitetura e contratos técnicos
├── website/              # landing page pública no GitHub Pages
├── examples/             # exemplos normativos e informativos
├── corpus/               # fixtures, manifesto e snapshots do corpus externo
├── bin/                  # CLI pte-lint (MVP offline)
├── lib/                  # motor Ruby compartilhado (MVP offline)
├── rules/                # catálogo humano e fonte YAML das regras
├── schemas/              # JSON Schemas públicos
├── spec/                 # versões publicadas da especificação
├── vocabulary/           # vocabulário controlado e seu schema
├── CHANGELOG.md
├── CODE_OF_CONDUCT.md
├── CONTRIBUTING.md
├── GOVERNANCE.md
├── LICENSE
├── NOTICE
├── ROADMAP.md
└── SECURITY.md
```

## Participação

Contribuições são bem-vindas em português. Propostas de regra devem seguir o processo descrito em [CONTRIBUTING.md](CONTRIBUTING.md). Questões de conduta seguem o [Código de Conduta](CODE_OF_CONDUCT.md); decisões e papéis seguem a [Governança](GOVERNANCE.md).

## Licença e atribuição

Código, esquemas, regras, exemplos e documentação são disponibilizados sob a [Apache License 2.0](LICENSE). Consulte também o arquivo [NOTICE](NOTICE).
