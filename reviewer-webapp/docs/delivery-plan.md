# Plano de entrega

## Progresso atual

O Marco 1 foi implementado nesta pasta: cliente estático, serviço Ruby em loopback, integração com `PteLint::Runner`, contrato de revisão, filtros, exportação JSON, controles de sessão/origem e testes automatizados do serviço. O conversor local de PDF com camada de texto também foi antecipado, usando a mesma implementação Ruby pura em macOS e Windows. OCR e empacotamento desktop permanecem para etapas posteriores.

## Princípio de sequência

Primeiro validar utilidade e paridade com o motor existente; depois ampliar formatos e inteligência local. Cada marco termina com um incremento demonstrável e critérios de saída objetivos.

## Marco 0 — protótipo de experiência

**Objetivo:** validar a leitura e a tomada de decisão antes de criar a infraestrutura.

Entregas:

- protótipo navegável da entrada e da tela de revisão;
- exemplos com nenhum achado, muitos achados e erro de arquivo;
- teste com 3 a 5 documentos técnicos representativos;
- decisão sobre quantidade de contexto e navegação entre ocorrências;
- texto de privacidade e limitações revisado.

Critério de saída: participantes localizam um achado, entendem a sugestão e identificam que o documento não foi alterado nem enviado.

## Marco 1 — fluxo local ponta a ponta

**Objetivo:** importar Markdown/TXT/PDF textual e mostrar diagnósticos reais.

Entregas:

- SPA acessível com upload, nível e localidade;
- serviço Ruby em loopback com token efêmero;
- `capabilities`, `reviews`, `rules/:id` e `health`;
- integração direta com `PteLint::Runner`;
- resumo, lista, filtros e painel de contexto;
- exportação JSON;
- testes de contrato e paridade com a CLI.

Critérios de saída:

- zero conexões externas no teste ponta a ponta;
- resposta válida contra `schemas/diagnostic.schema.json`;
- paridade total com o motor para o mesmo texto e configuração;
- arquivo original permanece byte a byte inalterado;
- fluxo completo utilizável apenas com teclado;
- mensagens úteis para UTF-8 inválido, extensão não aceita e limite excedido.

## Marco 2 — robustez e distribuição

**Objetivo:** tornar o MVP simples de iniciar e seguro para uso recorrente.

Entregas:

- comando único de inicialização;
- build de produção sem recursos remotos;
- tratamento de porta ocupada e encerramento limpo;
- limites de tamanho, tempo e concorrência;
- testes em macOS, Linux e Windows;
- documentação de instalação e solução de problemas;
- auditoria de acessibilidade e ameaça local.

Critérios de saída:

- instalação limpa reproduzida nos três sistemas suportados;
- 100 mil palavras analisadas dentro da meta do PTE-Lint em máquina de referência;
- nenhuma sobra de conteúdo em logs, cache do aplicativo ou temporários;
- falha segura quando o serviço não consegue ligar apenas em loopback.

## Marco 3 — formatos ricos

**Objetivo:** aceitar documentos comuns sem comprometer a precisão da localização.

Ordem sugerida:

1. DOCX sem macro;
2. AsciiDoc e HTML;
3. OCR local, opcional e separado.

Cada adaptador precisa preservar origem suficiente para mostrar página, bloco ou seção. Arquivos externos, macros, links ativos e recursos incorporados não são executados ou buscados.

Critério de saída: corpus específico do formato cobre extração, posições, tabelas, cabeçalhos, listas, código e arquivos hostis.

## Marco 4 — assistência local opcional

**Objetivo:** ampliar explicações ou reformulações sem depender de nuvem.

Entregas possíveis:

- detecção explícita e consentida de runtime local;
- comparação entre sugestão de regra e sugestão generativa;
- metadados de modelo e prompt no relatório;
- cancelamento, timeout e limite de contexto;
- avaliação publicada em corpus licenciado.

Critério de saída: o produto continua plenamente útil sem modelo; nenhuma saída generativa é apresentada como correção segura.

## Backlog priorizado do MVP

### P0 — necessário

- definir fachada pública da biblioteca PTE-Lint;
- criar contrato da API local e erros estáveis;
- implementar importação Markdown/TXT/PDF textual;
- renderizar diagnósticos com localização confiável;
- validar `Origin`, `Host`, token, corpo e timeout;
- implementar filtros e estados vazios/de erro;
- exportar JSON conforme schema;
- testar paridade, privacidade e teclado.

### P1 — importante

- deep link local para uma regra;
- copiar sugestão e diagnóstico;
- opção de relatório sem evidência;
- preservar preferências não sensíveis de nível/localidade;
- tema de alto contraste e preferência de movimento reduzido;
- comando único para iniciar e abrir o navegador.

### P2 — posterior

- relatório HTML local;
- múltiplos documentos;
- comparação antes/depois;
- aplicação de correções `safe` com prévia de diff;
- DOCX e OCR para PDF digitalizado;
- modelo local opcional.

## Casos de aceite essenciais

1. **Documento limpo:** apresenta zero achados e não sugere conformidade técnica.
2. **Documento com achados:** contagens e ordem coincidem com a CLI.
3. **Sugestão ausente:** a UI explica a regra sem inventar substituição.
4. **Correção `review`:** exige decisão humana e nunca é aplicada automaticamente.
5. **Arquivo inválido:** é recusado antes de chegar ao motor, com orientação recuperável.
6. **Serviço encerrado:** a UI informa indisponibilidade sem tentar um host externo.
7. **Origem maliciosa:** a chamada ao loopback é recusada mesmo com rota válida.
8. **Remover documento:** conteúdo, seleção e diagnósticos desaparecem da sessão.
9. **Exportar:** só cria arquivo após ação explícita e avisa quando inclui trechos.
10. **Offline:** todas as funções do MVP continuam operando sem internet.

## Riscos de produto

| Risco | Resposta |
|---|---|
| “upload” ser entendido como envio à nuvem | usar “Importar do dispositivo” e exibir o destino local |
| regras automáticas parecerem revisão completa | mostrar cobertura, modo e limitações do PTE-Lint 0.1 |
| posição imprecisa em formatos ricos | adiar formato até existir mapa de origem testado |
| instalação local ser complexa | validar comando único antes de investir em empacotamento desktop |
| modelo local consumir muitos recursos | mantê-lo opcional, separado e fora do caminho crítico |
| UI divergir da CLI | testes de paridade como gate de release |

## Definição de pronto do MVP

O MVP está pronto quando um novo usuário consegue instalar, iniciar, importar um Markdown/TXT/PDF textual, compreender e exportar os diagnósticos, inteiramente offline; quando a saída é equivalente ao PTE-Lint e válida no schema; e quando testes demonstram que o produto não transmite nem retém o documento.
