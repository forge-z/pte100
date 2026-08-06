# Arquitetura da norma

## Visão geral

O ecossistema separa conteúdo normativo, dados linguísticos, perfis de domínio e implementação. A separação permite que a norma evolua sem acoplar usuários a uma CLI específica.

```text
PTE-100 Core ─────┬── PTE-200 Vocabulary ── vocabulários organizacionais
                  ├── PTE-300 Domínios ───── software, manutenção, saúde...
                  └── contratos públicos ─── schemas e fixtures
                                             │
                     ┌───────────────────────┼───────────────────────┐
                     ▼                       ▼                       ▼
                  PTE-Lint              MCP Server               API REST
                     │
                     ├── CLI
                     ├── VS Code / LSP
                     └── CI / SARIF
```

## Camadas

### PTE-100 Core

Define princípios, gramática, estrutura, alertas, escrita para IA e conformidade. Deve mudar lentamente depois da v1.0.

### PTE-200 Vocabulary

Definirá o modelo federado de conceitos, resolução de conflito, publicação de pacotes, tradução conceitual e compatibilidade. Organizações poderão manter registros privados que estendam o núcleo.

### PTE-300 Domínios

Perfis versionados acrescentam termos, padrões documentais e regras de setores. Um perfil declara dependência de uma versão do núcleo e não altera silenciosamente uma regra central.

### Ferramentas

PTE-Lint é o motor local. CLI, LSP, extensão, MCP e API são adaptadores. Todos consomem os mesmos pacotes de regras, vocabulários e contratos de diagnóstico.

## Identidade e versionamento

| Artefato | Exemplo | Política |
|---|---|---|
| norma | `PTE-100:0.1` | `MAJOR.MINOR` |
| pacote de regras | `pte-core-rules@0.1.0` | SemVer |
| vocabulário | `pte-core@0.1.0` | SemVer |
| perfil | `pte-software@0.1.0` | SemVer |
| schema | URL com versão principal | compatível dentro da versão principal |

IDs de regra e conceito são permanentes. Renomear um título não muda o ID. Remover um item reserva seu ID.

## Fluxo de validação

1. O adaptador reconhece formato e extrai texto, blocos literais e metadados.
2. O núcleo resolve configuração, herança de perfil e exceções.
3. O segmentador identifica unidades, frases, passos, alertas e referências.
4. As regras automáticas e assistidas geram diagnósticos normalizados.
5. A saída apresenta evidência, sugestão, confiança e origem da regra.
6. A declaração de conformidade registra diagnósticos bloqueadores e desvios aceitos.

## Escolhas e trade-offs

**YAML como fonte de regras:** é legível em revisão e suporta comentários, mas requer parser seguro. JSON Schema valida sua forma e JSON é oferecido nos contratos de API.

**Núcleo pan-lusófono com localidade explícita:** aumenta inclusão e reutilização, mas exige perfis antes de validar ortografia. A alternativa de fixar apenas `pt-BR` seria simples no início e cara para desfazer.

**Regras híbridas:** heurísticas ampliam cobertura, mas não podem fingir certeza. Por isso cada regra declara `automatic`, `assisted` ou `manual`, e diagnósticos assistidos incluem confiança.

**MCP somente leitura na primeira versão:** reduz risco de agentes modificarem documentação sem revisão. Operações de correção ficam para uma fase posterior, com diff e aprovação explícita.

## Extensões

Campos desconhecidos com prefixo `x-` podem ser preservados. Extensões não podem mudar o significado de campos centrais. Plugins são identificados por URI reversa, por exemplo `org.exemplo.pte-regra`.

