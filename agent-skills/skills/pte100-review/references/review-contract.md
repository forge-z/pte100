# Contrato de revisão local

## Privacidade e formatos

O PTE-Lint incluído usa biblioteca padrão Ruby e não realiza chamadas de rede. A skill é uma instrução para o agente; **não torna o modelo offline**. Um agente com modelo remoto pode enviar conteúdo, nomes, trechos e diagnósticos ao provedor. Para documentos confidenciais, use um runtime/modelo local configurado sem ferramentas de rede ou uma política aprovada para o provedor. Não prometa privacidade apenas porque os arquivos estão no computador. Não publique relatórios/trechos nem use serviços externos sem autorização; relatórios também podem conter dados confidenciais.

Markdown e texto UTF-8 são entradas diretas. A CLI não aceita bytes PDF, DOCX ou imagem. O revisor do repositório extrai PDFs com camada de texto, com gems adicionais, e não vem instalado no pack. Se houver ferramenta de extração local já autorizada, mantenha original e extração separados e confira tabelas, ordem e alertas contra o original. OCR, DOCX, HTML/AsciiDoc e layout visual não são cobertos pelo motor do pack. Sem leitura confiável, marque trechos não avaliados.

## Evidência e relatório

Declare arquivos efetivamente lidos, exclusões, nível/localidade e suas premissas. Registre versão PTE-100:0.1, versão do motor, configuração, SHA-256 das fontes usadas (manifest.json do pack), comandos e exit codes. Não registre hash de documento confidencial em logs públicos.

Use este formato para cada achado:

| Campo | Conteúdo |
|---|---|
| Localização | arquivo + linha/seção/ID; página do original apenas se conferida |
| Evidência | trecho mínimo, sem dados desnecessários |
| Base | ID, nível, severidade e modo canônicos; cite a referência local |
| Origem | automático / avaliação do agente / pergunta ao especialista |
| Proposta | alteração mínima e efeito esperado; incertezas técnicas |
| Estado | pendente / resolvido após validação / desvio proposto / fora do escopo |

Distinga severidade da regra de prioridade editorial. Confiança do agente não é `confidence` do motor. Liste regras avaliadas, regras não avaliadas e limitações; não use um placar de “50 regras aprovadas” sem evidência individual. Uma regra automática pode precisar de revisão humana por falsos positivos/negativos.

## Limites do MVP incluído

- 21 regras automáticas; 29 assistidas especificadas, sem motor de PLN. Esses números não medem precisão.
- Configuração automática só no diretório atual; `--config` evita deriva. Não há configuração resolvida/cascata, explain, fix ou plugins.
- `pte-ignore`, exceções aprovadas e expiração não são processados; suppressed permanece zero. Não desative regra para ocultar problema nem crie aprovação.
- R046/R048/R050 são condicionais ao frontmatter. Zero achados sem frontmatter não valida metadados, IDs únicos, proveniência ou vigência.
- O suporte a literais não é um parser Markdown completo; confira exclusões como código indentado e HTML. Diagnósticos continuam heurísticos em algumas regras.
- O exit code depende de `fail_on` e regras desativadas. Exit 0 nunca significa segurança, correção técnica, cumprimento legal ou conformidade completa.

O publicador decide o piloto após revisão humana e evidências, conforme a norma. Não substitua a taxonomia de alerta por outra sem perfil explícito e autoridade documentada.
