# PTE-100 Reviewer

## Estado

Este diretório contém um webapp local para revisão de documentos técnicos e seu plano de evolução.

O produto recebe um documento, executa o PTE-Lint no computador da pessoa usuária e apresenta sugestões explicáveis. O documento não deve ser enviado para serviços externos.

## Instalar e iniciar

O revisor requer Ruby 2.6 ou mais recente. As dependências são Ruby puro, sem binários específicos de sistema operacional.

### macOS e Linux

```sh
cd reviewer-webapp
bundle install
bundle exec ruby bin/reviewer-webapp
```

### Windows (PowerShell)

Instale o Ruby com o [RubyInstaller](https://rubyinstaller.org/) e execute:

```powershell
cd reviewer-webapp
bundle install
bundle exec ruby bin/reviewer-webapp
```

Abra `http://127.0.0.1:43100/`. Para escolher outra porta, use `PTE_REVIEWER_PORT=43101 ruby bin/reviewer-webapp`.

O servidor aceita Markdown, texto simples e PDF com camada de texto. Para encerrar, use `Ctrl-C`.

PDF digitalizado não contém texto selecionável e, por isso, precisa de OCR. O MVP informa esse caso sem enviar o arquivo para outro serviço.

Se o navegador mostrar “Não foi possível acessar o site”, o processo local não está ativo. Execute o comando acima em um terminal e atualize `http://127.0.0.1:43100/`. A página não funciona como arquivo estático isolado porque precisa do serviço local para chamar o PTE-Lint.

Testes do serviço:

```sh
bundle exec ruby -Iserver test/reviewer_webapp_test.rb
bundle exec ruby -Iserver test/reviewer_server_test.rb
```

Na raiz do repositório, `rake verify` executa essas verificações junto com os testes do PTE-Lint e a validação editorial.

## Resultado esperado

Uma pessoa deve conseguir:

1. iniciar o aplicativo local;
2. importar um arquivo Markdown, texto simples ou PDF com camada de texto;
3. escolher localidade e nível PTE-100;
4. revisar achados por severidade, regra e posição;
5. comparar o trecho original com a sugestão;
6. exportar o relatório sem alterar o arquivo original.

O produto auxilia a revisão linguística. Ele não certifica a correção técnica ou a segurança do conteúdo e não substitui revisão especializada.

## Decisões para o MVP

- **Execução local:** a interface abre no navegador e acessa somente um serviço ligado a `127.0.0.1`.
- **Motor único:** o serviço usa `lib/pte_lint.rb`; regras e diagnósticos não serão reimplementados em TypeScript.
- **Sem IA remota:** as 21 regras automáticas atuais entregam o primeiro valor. Um modelo local poderá ser um adaptador opcional posterior.
- **Sem escrita automática:** o MVP mostra sugestões e exporta relatórios, mas não sobrescreve o documento.
- **Formatos iniciais:** `.md`, `.markdown`, `.txt` e `.pdf`. O PDF é convertido localmente por uma biblioteca Ruby pura; PDF digitalizado requer OCR e não é aceito no MVP.
- **Sem retenção:** o conteúdo é processado em memória e descartado ao encerrar a revisão ou o processo local.
- **Sem telemetria:** nenhuma analytics, fonte remota, CDN, crash report ou atualização silenciosa.
- **Contrato existente:** a resposta segue `../schemas/diagnostic.schema.json`.

## Experiência principal

```text
iniciar localmente
      ↓
importar documento ──→ validar formato, tamanho e UTF-8
      ↓
selecionar nível/localidade
      ↓
executar PTE-Lint em memória
      ↓
resumo + lista de achados + contexto do trecho
      ↓
filtrar / explicar regra / copiar sugestão / exportar JSON
```

### Tela de entrada

- área de arrastar e soltar e seletor de arquivo;
- aviso persistente “Processamento local — nenhum conteúdo é enviado”;
- formatos e limite de tamanho visíveis antes da importação;
- seleção de `pt-BR` e nível `pte-estrutura`, `pte-claro` ou `pte-ia`;
- link para explicar privacidade e limitações.

### Tela de revisão

- resumo de erros, avisos e informações;
- filtros por severidade e regra;
- lista navegável por teclado, ordenada pela posição no documento;
- painel com trecho, mensagem, sugestão, confiança, modo e link para a regra;
- indicação clara entre correção `safe`, sugestão que exige revisão e item sem correção;
- ações para copiar sugestão, copiar diagnóstico e exportar JSON;
- ação “Remover documento da sessão”.

## Escopo

### Incluído no MVP

- um documento por sessão;
- Markdown e texto simples em UTF-8, além de PDF com camada de texto;
- regras automáticas já suportadas pelo PTE-Lint;
- execução offline depois da instalação;
- diagnóstico conforme o schema público;
- estados de carregamento, arquivo inválido, falha do motor e nenhum achado;
- layout responsivo e navegação completa por teclado;
- exportação de relatório JSON, iniciada explicitamente pela pessoa usuária.

### Fora do MVP

- autenticação, contas, nuvem ou colaboração simultânea;
- histórico de documentos;
- alteração automática do arquivo original;
- análise semântica por modelo remoto;
- DOCX, PDF digitalizado/OCR, HTML e AsciiDoc;
- certificação de conformidade ou de segurança técnica;
- múltiplos arquivos e comparação entre versões.

## Estrutura planejada

```text
reviewer-webapp/
├── README.md
├── docs/
│   ├── architecture.md
│   ├── delivery-plan.md
│   └── privacy.md
├── client/                 # interface estática JavaScript
├── server/                 # adaptador HTTP local Ruby
└── test/                   # testes de contrato e ponta a ponta
```

O MVP executável está em `client/`, `server/` e `bin/`. O diretório continua separado do site institucional; o webapp não é uma segunda fonte das regras normativas.

## Métricas locais de qualidade

Não haverá coleta automática. Durante desenvolvimento e testes, o time deve medir:

- tempo até o primeiro resultado para arquivos de 10 mil e 100 mil palavras;
- correspondência entre a resposta HTTP e a saída do PTE-Lint para a mesma entrada;
- taxa de sucesso na localização do trecho a partir de linha, coluna e offsets;
- acessibilidade automatizada e revisão por teclado/leitor de tela;
- memória liberada após remover o documento e encerrar a sessão.

## Documentos do plano

- [Arquitetura](docs/architecture.md)
- [Privacidade e segurança](docs/privacy.md)
- [Fases, backlog e critérios de aceite](docs/delivery-plan.md)

## Próxima decisão

Validar o fluxo implementado com 3 a 5 documentos representativos. O teste deve confirmar se a unidade correta de navegação é o diagnóstico individual, o parágrafo ou a seção. Essa decisão afeta o modelo de contexto da interface, mas não o contrato do motor.
