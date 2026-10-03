# Pack de skills PTE-100

Duas skills para agentes locais: `pte100-review` (revisão documental com lint opcional) e `pte100-pilot` (evidências, escopo e desvios de piloto). São instruções e fontes da proposta experimental 0.1, não um modelo, instalador, certificador ou revisão técnica de engenharia.

## Download e instalação manual

No [site público](https://forge-z.github.io/pte100/#skills), use “Baixar pack de skills”. O ZIP é gerado a partir deste diretório e das fontes canônicas no build. O SHA-256 publicado verifica integridade; não substitui a confiança no repositório. A mudança só estará no site público após aprovação, merge e publicação.

1. Extraia `pte100-skills.zip` numa pasta de sua escolha. Confira `manifest.json` e `pte100-skills.zip.sha256` se necessário.
2. Copie **as duas pastas completas** de `pte100-skills/skills/` para `.agents/skills/` no projeto de documentos, ou para o diretório de skills configurado pelo seu agente. Não sobrescreva skills existentes sem comparar versões. Não copie só SKILL.md. Guarde também o `manifest.json` da raiz extraída e o arquivo SHA-256 do ZIP para registrar versão e integridade; eles não ficam dentro das pastas instaladas.
3. Inicie uma sessão do agente que reconheça Agent Skills. Em outros agentes, peça que leia explicitamente o SKILL.md no caminho instalado; a descoberta automática depende do runtime.

Exemplo POSIX para um projeto novo, após extrair o ZIP:

```sh
mkdir -p "/meu projeto/.agents/skills"
cp -R pte100-skills/skills/pte100-review "/meu projeto/.agents/skills/"
cp -R pte100-skills/skills/pte100-pilot "/meu projeto/.agents/skills/"
```

No Windows, copie as mesmas pastas pelo explorador. Não existe instalação automática, alteração de configuração global ou download de modelos.

## Uso

```text
Use $pte100-review para revisar docs/manual.md em pt-BR, nível pte-claro.
Leia a skill instalada e suas referências. Preserve o original e entregue
achados com regra, localização, evidência, proposta e limitações.

Use $pte100-pilot para avaliar a declaração e o relatório em relatorios/.
Verifique escopo, versões, amostragem e desvios. Registre revisão humana
pendente; não aprove em meu nome.
```

Não é preciso clonar o repositório para usar o ZIP. `pte100-review/runtime/` inclui CLI, motor, regras, vocabulário, schemas e referências; Ruby 3.3.x é opcional para lint e usa apenas biblioteca padrão, sem gems. Sem Ruby, a revisão pelo agente continua possível, com lint marcado como não executado. Leia o [contrato de revisão](skills/pte100-review/references/review-contract.md) e o [exemplo sintético](skills/pte100-review/references/example-review.md).

## Privacidade e limites

Arquivos locais não tornam um modelo remoto offline: o agente pode enviar conteúdo ao provedor. Para confidencialidade estritamente local, use modelo/runtime local configurado sem rede. O CLI incluído não envia dados à rede. Relatórios também podem conter dados sensíveis. Não envie documentos, trechos, nomes ou diagnósticos a terceiros sem autorização.

O MVP analisa Markdown/texto UTF-8, 21 regras automáticas; 29 regras assistidas precisam de avaliação e evidência. PDFs textuais exigem extração local separada; sem OCR, DOCX ou validação de layout no pack. Não há correção automática, explain/config/fix, processamento de pte-ignore ou aprovação de desvios. Exit 0 não significa conformidade. Conteúdo crítico exige revisão humana integral.

## Manutenção e reprodução

Use Node.js 22 (já usado pelo website), sem dependências adicionais:

```sh
node tools/build-skills.mjs --sync
node tools/build-skills.mjs --out tmp/skills-download
node --test test/test_skills_pack.mjs
```

`--sync` atualiza apenas as cópias geradas em `runtime/` e `references/pte/`. Revise/versione fontes e snapshots juntos. Sem `--sync`, o build falha se uma cópia divergir da fonte canônica. O texto das fontes é preservado; links opcionais fora das referências incluídas apontam para GitHub e exigem rede apenas se abertos. As fontes necessárias à revisão estão incluídas. O ZIP usa ordem, data e permissões fixas; inclui manifesto SHA-256 dos arquivos, versão do motor/norma e licença Apache-2.0/NOTICE em cada skill. Não inclui documentos do usuário, caches, credenciais, gems ou corpus externo. Para usar o diretório versionado sem ZIP, copie as duas pastas completas como acima.
