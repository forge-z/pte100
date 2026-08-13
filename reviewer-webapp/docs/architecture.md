# Arquitetura proposta

## Visão geral

Esta arquitetura já está implementada no MVP em `client/`, `server/` e `bin/`. O cliente é servido pelo mesmo processo Ruby que expõe a API local, reduzindo configuração e mantendo o fluxo sem rede externa.

O webapp será um adaptador local do PTE-Lint. A separação mantém regras, vocabulário, posições e severidades no motor existente e deixa a camada web responsável apenas por importação, configuração e apresentação.

```text
Navegador
  SPA TypeScript
  File Picker / Drag and Drop
        │ HTTP apenas em 127.0.0.1
        ▼
Serviço local Ruby
  valida requisição e limites
  chama PteLint::Runner em memória
        │
        ├── ../lib/pte_lint.rb
        ├── ../rules/rules.yaml
        ├── ../vocabulary/core.yaml
        └── ../schemas/diagnostic.schema.json
```

## Componentes

### Cliente

Proposta: TypeScript, React e Vite. A escolha favorece uma interface de revisão com estados, filtros e painéis interativos, sem acoplar o site institucional Astro ao aplicativo.

Responsabilidades:

- validar extensão e tamanho antes da transmissão local;
- enviar o conteúdo ao serviço local somente após ação explícita;
- renderizar resumo, diagnósticos e contexto;
- preservar quebras de linha e mapear posições com precisão;
- oferecer filtros, explicação e exportação iniciada pela pessoa usuária;
- apagar o estado em memória quando solicitado.

O cliente não interpreta regras, recalcula severidades ou inventa sugestões.

### Serviço local

Proposta: um adaptador Ruby pequeno sobre Rack/Puma, reutilizando diretamente `PteLint::Runner`. Ele deve ligar exclusivamente em `127.0.0.1`, escolher uma porta disponível e abrir a interface com um token efêmero de sessão.

Responsabilidades:

- servir os assets compilados;
- recusar hosts, origens e métodos não esperados;
- aplicar limite de corpo e tempo de processamento;
- aceitar conteúdo em memória e uma configuração permitida;
- normalizar erros sem incluir o documento em logs;
- devolver o objeto de diagnóstico existente;
- expor versão e capacidade do motor.

### Motor

`lib/pte_lint.rb` permanece a fonte única do comportamento linguístico. O webapp deve consumir uma API de biblioteca, não analisar a saída textual da CLI e não manter uma cópia das regras.

Antes do primeiro marco, é recomendável consolidar uma pequena fachada pública para evitar que o adaptador dependa de detalhes internos do `Runner`.

## API local mínima

### `GET /api/v1/capabilities`

Retorna versão, formatos, localidades, níveis e limite de tamanho. Não recebe conteúdo.

### Conversor local

PDF usa `pdf-reader`, uma biblioteca Ruby pura que funciona em macOS e Windows sem Poppler ou outro executável nativo. O arquivo é decodificado e lido em memória. A extração aceita até 5 MB, 200 páginas, 1,5 milhão de caracteres e 20 segundos de processamento.

O conversor trata apenas PDFs com camada de texto. OCR permanece fora do MVP porque adicionaria modelos e binários grandes. A interface informa quando o PDF é digitalizado ou não contém texto selecionável.

### `POST /api/v1/reviews`

Corpo para PDF (Markdown/TXT usam o campo `content` em UTF-8):

```json
{
  "document": {
    "name": "procedimento.md",
    "format": "pdf",
    "data_base64": "JVBERi0xLjQK..."
  },
  "configuration": {
    "locale": "pt-BR",
    "level": "pte-claro"
  }
}
```

Resposta: exatamente o contrato de `schemas/diagnostic.schema.json`. Um identificador aleatório para correlação na sessão é enviado no cabeçalho `X-Request-ID`, sem acrescentar um campo incompatível com o schema. O serviço não mantém um recurso persistente apesar do nome da rota.

Erros usam um envelope mínimo com `code`, `message` e `request_id`. Nunca incluem conteúdo, evidência completa ou stack trace no modo normal.

### `GET /api/v1/rules/:id`

Retorna metadados e exemplos da regra local instalada. Isso permite explicar um achado sem buscar documentação na rede.

### `GET /api/v1/health`

Confirma que cliente e serviço são compatíveis. Não expõe caminhos locais, variáveis de ambiente ou versões desnecessárias do sistema.

## Ciclo do dado

1. O navegador lê o arquivo após seleção explícita.
2. O cliente valida tipo, tamanho e codificação.
3. O conteúdo trafega apenas pelo loopback até o processo local.
4. O serviço cria o documento em memória e chama o motor.
5. O motor retorna diagnósticos; o serviço descarta a referência ao conteúdo.
6. O cliente mantém conteúdo e resultado somente durante a sessão.
7. “Remover documento” limpa a UI; fechar o serviço encerra todo o estado.
8. Somente “Exportar” produz um novo arquivo, via download iniciado no navegador.

## Suporte a formatos

| Fase | Formato | Estratégia local |
|---|---|---|
| MVP | TXT | decodificação UTF-8 e texto integral |
| MVP | Markdown | adaptador atual, preservando blocos literais |
| seguinte | DOCX | extrair XML em processo isolado, sem macros e sem recursos externos |
| MVP | PDF textual | `pdf-reader` em memória; localização por linha do texto extraído |
| futura | PDF digitalizado | OCR local opcional, pacote separado e consentimento explícito |

No PDF, linha e coluna referem-se ao texto extraído, não à posição visual na página. Um futuro mapa de origem poderá acrescentar página e bloco sem alterar o diagnóstico básico. DOCX só entra quando houver isolamento e localização de origem testados.

## Modelo local opcional

Um modelo de linguagem local não é requisito do MVP. Se adicionado, ele será um adaptador desativado por padrão, com:

- endpoint configurável apenas em loopback ou socket local;
- download de modelo separado, explícito e com tamanho/licença informados;
- identificação visual de sugestões determinísticas e generativas;
- saída sempre marcada como `review`, com versão do modelo e confiança não simulada;
- nenhuma alteração automática do documento;
- funcionamento completo das regras automáticas sem o modelo.

## Empacotamento

Começar como dois processos de desenvolvimento (`client` e serviço Ruby). Após validar o fluxo, criar um comando único que inicia o serviço, escolhe a porta e abre o navegador. Empacotamento desktop só deve ser avaliado se instalação do runtime Ruby for uma barreira real; ele não é necessário para validar o produto.

## Testes

- **Unidade:** validação de entrada, mapeamento de diagnóstico e filtros de UI.
- **Contrato:** resposta do serviço validada contra `diagnostic.schema.json`.
- **Paridade:** mesma entrada gera os mesmos diagnósticos na biblioteca, CLI e API local.
- **Integração:** arquivo → revisão → filtro → exportação.
- **Segurança:** origem inválida, corpo excessivo, JSON malformado, arquivo binário e concorrência limitada.
- **Acessibilidade:** foco, leitura de erros, contraste, zoom de 200% e movimento reduzido.
- **Privacidade:** teste automatizado bloqueia qualquer conexão que não seja loopback.

## Decisões em aberto

- limite inicial: proposta de 10 MB e 100 mil palavras;
- distribuição: Ruby instalado pelo usuário ou runtime empacotado;
- suporte inicial apenas a `pt-BR` ou exibição de localidades ainda experimentais;
- como mostrar contexto quando um diagnóstico atravessa múltiplas linhas;
- se o relatório exportado inclui `evidence` por padrão ou somente após confirmação.
