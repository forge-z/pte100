# Extensão PTE-100 para VS Code

Extensão experimental, sem publicação no Marketplace. Ela mostra no editor os diagnósticos de `bin/pte-lint` para arquivos Markdown e texto simples. A extensão não reimplementa regras, não envia texto à rede e não grava o arquivo. O desenho está na Etapa 2 de [docs/plano-vscode-mcp.md](../docs/plano-vscode-mcp.md).

Lint não equivale a certificação de segurança, correção técnica ou conformidade estável.

## Funcionamento

- Ao abrir e ao salvar, a extensão analisa o buffer imediatamente. Ao digitar, analisa depois de `pte100.debounceMs` (300 ms por padrão).
- Uma análise nova cancela o processo Ruby anterior do mesmo documento.
- O texto do editor vai na entrada padrão de `ruby bin/pte-lint check --format json --stdin-filename CAMINHO`, com o diretório de trabalho na raiz do workspace. Assim, o buffer não salvo é o texto analisado.
- Quando a raiz do workspace tem `.pte-lint.yaml`, `.pte-lint.yml` ou `.pte-lint.json`, o primeiro encontrado nessa ordem vai em `--config`.
- As colunas do motor (caracteres Ruby, base 1) viram unidades UTF-16 do editor.
- O hover mostra `title`, `description` e `correct` de `rules/rules.yaml` e, quando existe, a `suggestion` do diagnóstico.
- Códigos de saída 2 e 3, JSON inválido ou falha ao iniciar o Ruby aparecem como aviso e no canal de saída **PTE-100**. Os diagnósticos anteriores continuam visíveis.

## Configuração

| Configuração | Padrão | Efeito |
|---|---|---|
| `pte100.rubyPath` | `ruby` | Executável Ruby 3.3 |
| `pte100.cliPath` | `bin/pte-lint` | CLI, relativa à raiz do workspace ou absoluta; `rules/rules.yaml` é lido em `../rules/` a partir dela |
| `pte100.debounceMs` | `300` | Atraso depois da última alteração |
| `pte100.level` | vazio | Força `--level` |
| `pte100.locale` | vazio | Força `--locale` |

## Desenvolvimento

Use Node.js 22 e Ruby 3.3.x. Em `vscode-extension/`:

```sh
npm ci
npm test
xvfb-run -a npm run test:electron
```

`npm test` compila e executa os testes de unidade, offline. `test:electron` baixa o VS Code estável em `.vscode-test/` na primeira execução e abre a raiz do repositório como workspace. A suíte usa `--level pte-ia` e `--locale pt-BR`, analisa as 42 fixtures do corpus e verifica presença do ID na positiva e ausência na negativa. Também cobre um buffer não salvo com emoji, acento e U+00A0, o hover, o cancelamento e a falha da CLI. Em máquina com display, omita `xvfb-run -a`.

Para testar manualmente, execute `npm run compile` e, na raiz do repositório, `code --extensionDevelopmentPath="$PWD/vscode-extension" .`.
