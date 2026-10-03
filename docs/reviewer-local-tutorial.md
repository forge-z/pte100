# Revisor local em poucos passos

O site público apresenta o projeto; o revisor roda no computador, em loopback. A instalação precisa de internet. Depois dela, revisão e exportação não precisam de conexão externa.

1. Instale Git e Ruby 3.3.x (referência: 3.3.12). Clone o repositório inteiro, ou extraia o [ZIP do código](https://github.com/forge-z/pte100/archive/refs/heads/main.zip).
2. Abra o terminal e prepare uma vez:

```sh
git clone https://github.com/forge-z/pte100.git
cd pte100/reviewer-webapp
gem install bundler -v 2.6.9
bundle install
```

Se baixou ZIP, pule o clone e entre em `pte100-main/reviewer-webapp`. Não mova apenas a pasta do revisor: ela usa `lib/`, `rules/` e `vocabulary/` da raiz.

3. Inicie e mantenha o terminal aberto:

```sh
bundle exec ruby bin/reviewer-webapp
```

4. Abra <http://127.0.0.1:43100/>. Importe [o exemplo sintético](../examples/reviewer-demo.md), use pt-BR/PTE-Claro e clique em **Iniciar revisão**. O exemplo deve gerar cinco achados: R014, R038, R021, R018 e R006. Confira evidências e propostas; ele não é uma instrução de engenharia aprovada.
5. Use **Exportar JSON** para guardar o relatório, que pode conter trechos do documento. O original permanece intacto. Remova o documento da sessão e use `Ctrl-C` no terminal para encerrar.

Entradas: Markdown/texto UTF-8 ou PDF com texto selecionável, até 5 MB; PDF até 200 páginas; documento até 100 mil palavras. PDF digitalizado/OCR e DOCX não são suportados. Posições de PDF pertencem ao texto extraído e precisam de conferência no original.

Se não abrir, verifique se o processo está ativo e a porta livre. No macOS/Linux, `PTE_REVIEWER_PORT=43101 bundle exec ruby bin/reviewer-webapp` usa outra porta; abra `http://127.0.0.1:43101/`. Consulte a [instalação completa](../reviewer-webapp/README.md) para Windows e os [limites de privacidade](../reviewer-webapp/docs/privacy.md).

O motor verifica 21 regras automáticas, não as 50 regras da proposta. Zero achados não certifica segurança, correção técnica ou conformidade. Revisão humana continua necessária. O revisor não usa modelo remoto; um agente que usa as [skills](../agent-skills/README.md) é outro fluxo e pode enviar dados ao provedor.
