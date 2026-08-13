# Privacidade e segurança

## Promessa verificável

O modo padrão processa documentos no dispositivo. Nenhum conteúdo, trecho, nome de arquivo ou diagnóstico deve sair do computador. “Local” será uma propriedade testável, não apenas texto de marketing.

## Limites da promessa

O webapp protege contra transmissão pelo próprio produto. Ele não protege contra navegador comprometido, extensões maliciosas, malware, captura de tela, swap do sistema operacional ou acesso de outras contas ao dispositivo. A interface deve explicar esse limite em linguagem simples.

## Ameaças e controles

| Ameaça | Controle mínimo |
|---|---|
| envio acidental para terceiros | CSP restritiva; sem analytics, CDN, fontes ou APIs remotas; teste de rede |
| outro site acessa o serviço local | token efêmero, validação de `Origin` e `Host`, CORS fechado e métodos limitados |
| serviço exposto à rede local | bind exclusivo em `127.0.0.1`/`::1`; falhar se isso não for possível |
| vazamento em logs | logs só com ID, duração, tamanho aproximado e código; nunca conteúdo ou nome completo |
| retenção em temporários | processamento em memória no MVP; nenhum cache de corpo; limpeza ao final da requisição |
| arquivo muito grande | limite antes da leitura completa, timeout, uma análise ativa e fila limitada |
| parser hostil | allowlist de formatos; PDF limitado a tamanho, páginas, caracteres e tempo; DOCX futuro exigirá isolamento adicional |
| conteúdo refletido como HTML | renderização como texto; sanitização; nenhuma execução de HTML do documento |
| dependência comprometida | lockfiles, auditoria, versões fixas, builds reproduzíveis e inventário de dependências |
| relatório exportado expõe trechos | aviso antes da exportação e opção de omitir `evidence` |
| sugestões gerativas parecem fatos | modelo local separado, rotulagem clara e todas as sugestões como revisão humana |

## Requisitos técnicos

- Cabeçalho CSP no mínimo com `default-src 'self'`, sem `unsafe-eval`; exceções precisam de justificativa.
- `connect-src` limitado à origem loopback escolhida para a sessão.
- `Cache-Control: no-store` em endpoints com conteúdo ou diagnóstico.
- `Referrer-Policy: no-referrer` e `X-Content-Type-Options: nosniff`.
- Nenhum service worker no MVP, para evitar retenção involuntária de respostas.
- Token de sessão com entropia adequada, mantido apenas durante o processo.
- Comparação segura do token e invalidação ao encerrar o serviço.
- Mensagens de erro genéricas para o cliente; detalhes técnicos somente em modo de desenvolvimento.
- Dependências do cliente compiladas localmente; nada carregado por URL em tempo de execução.

## Dados permitidos em log

```text
timestamp
request_id aleatório
rota e status
duração
classe de tamanho (pequeno/médio/grande)
versão do motor
código de erro estável
```

Nome do arquivo, conteúdo, evidência, sugestão, caminho local, hash do documento e stack trace não entram no log normal.

## Verificação da privacidade

Antes de cada release:

1. executar os testes ponta a ponta com acesso externo bloqueado;
2. inspecionar todas as requisições do navegador;
3. confirmar que apenas loopback é acessado durante importação, revisão e exportação;
4. pesquisar artefatos de build por URLs externas não aprovadas;
5. verificar diretórios temporários e caches depois de uma revisão;
6. revisar logs com um documento-isca identificável;
7. publicar a versão das regras, do motor e das dependências incluídas.

Critério de falha: qualquer conexão externa durante o fluxo principal bloqueia o release, mesmo que não contenha o documento.

## Futuras integrações locais

Ollama, LM Studio ou outro runtime não deve ser detectado ou acionado sem consentimento. A tela deve mostrar o endereço utilizado e rejeitar, por padrão, hosts que não sejam loopback. Permitir um servidor remoto transforma a promessa de privacidade e exige outro modo de produto, outra comunicação e consentimento específico.
