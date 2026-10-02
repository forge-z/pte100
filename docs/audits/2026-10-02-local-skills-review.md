# Auditoria do pack de skills e revisor local — 2026-10-02

## Escopo e resultado

A mudança preserva as obrigações, severidades, valores e governança da proposta experimental. Entrega duas skills portáteis, download com manifesto/SHA-256, link no site e tutorial do revisor local. CLI e reviewer usam o mesmo motor. O trabalho foi concluído em uma cópia isolada; o checkout original foi preservado.

## Achados e correções

| Gravidade | Achado reproduzido | Correção e regressão |
|---|---|---|
| Alta | O E2E lê stderr sem limite antes do cleanup; EOF de stdout com stderr aberto bloqueia. | Logs temporários em arquivos, startup com relógio monotônico e prazo; regressão reproduziu erro antes e passa depois. |
| Alta | Filho ignorando TERM permanece vivo; timeout do cleanup mascara a falha original. | Grupo próprio, TERM seguido de KILL/espera limitada, exceção original preservada; regressão confirma filho recolhido. |
| Média | Literais cercados por til, cercas longas ou não fechadas geram falsos positivos. | Máscara reconhece cercas e preserva posições do texto seguinte; testes cobrem casos literais. |
| Média | R039 aponta kPa correto e pode perder unidades incorretas posteriores. | Símbolo correto não é reportado; ocorrências incorretas posteriores são únicas e continuam reportadas, inclusive com NBSP. |
| Média | Arquivo ausente com `--config` retorna 2, confundindo leitura com configuração. | Fases separadas: configuração inválida retorna 2; entrada ausente retorna 3. Regressões no CLI e ZIP instalado. |
| Baixa | Manifesto na raiz extraída pode ser perdido ao instalar só as pastas de skills. | README manda reter `manifest.json` e SHA-256 do ZIP para rastreabilidade. |
| Baixa | Navegação móvel e CTA em tema escuro precisam de contraste/tamanho adequados. | Links móveis com mínimo de 44 px; CTA usa cor de texto legível sobre o token azul nos dois temas. |

A extensão do E2E para PDF recebeu revisão independente: a fixture usa `20 kPa`, que aciona R038, em vez de `20kPa`. Nenhuma regra normativa foi expandida para acomodar um teste.

## Verificação reproduzível

Runtimes usados: Ruby 3.3.12, Bundler 2.6.9 e Node.js 22.23.3. Dependências existentes foram reutilizadas; não houve instalação nova durante a recuperação. Astro resolvido pelo lockfile: 7.3.5. `npm audit --json` retornou zero vulnerabilidades na data desta auditoria.

```sh
BUNDLE_GEMFILE=reviewer-webapp/Gemfile bundle exec rake verify
node --test test/test_skills_pack.mjs
ruby tools/generate_catalog.rb
ruby tools/generate_corpus.rb
git diff --exit-code -- rules/catalog.md corpus/fixtures
ruby bin/pte-lint check examples/procedure-pte.md --format json
cd website
ASTRO_TELEMETRY_DISABLED=1 npm run build
npm audit --json
```

Resultado local: 50 testes Ruby, 700 assertions, zero falhas/erros/skips; duas verificações Node passaram. Catálogo e 42 fixtures regenerados sem diferença. Exemplo de procedimento: um arquivo, zero erros e avisos. Dois HTMLs do site compilados, 15 destinos internos conferidos e cinco URLs sob `/pte100/` responderam HTTP 200. Os 69 hashes de arquivos do manifesto e o checksum do ZIP foram conferidos. O teste Node produz dois ZIPs iguais e executa o CLI após extração/instalação fora do clone, com caminhos com espaços e códigos 0/1/2/3.

O E2E copia os componentes necessários para uma pasta temporária limpa, inicia o serviço real, testa capacidades/assets, Markdown, texto, PDF textual, PDF sem texto recusado, literal e origem externa recusada. O helper fecha o processo/grupo criado pelo teste. O teste de cleanup observa o filho principal; não mede separadamente todo possível descendente.

## Browser e privacidade

QA pelo navegador em desktop (1280×900) e mobile (390×844): site, tutorial e reviewer sem overflow horizontal do documento. Os blocos de comandos do tutorial permitem rolagem própria. Importação de exemplo Markdown exibiu cinco achados (R014/R038/R021/R018/R006), quatro erros e um aviso. Filtro Avisos mostrou apenas R006. Exportação gerou JSON de 3.597 bytes com as cinco regras e resumo esperado; original permaneceu intacto. PDF textual foi importado/revisado e mostrou R038; remoção deixou resultados ocultos e revisão desabilitada.

Evidência de HTTP não é isolamento de rede. Em verificação separada, o guard Ruby rejeitou tentativas externas por `TCPSocket.new` e `Socket#connect` antes da prontidão. O E2E real roda com esse guard. O inventário de assets/recursos observado no browser continha apenas URLs do serviço em 127.0.0.1 (CSS, JS, capabilities, reviews e favicon), sem fonte ou CDN remota. Isso comprova os caminhos exercitados; não é captura de tráfego do sistema, firewall universal ou teste com o Mac fisicamente desconectado. A instalação das dependências usa internet. O reviewer não integra modelo remoto; usar as skills com um provedor remoto é outro fluxo.

## Avaliação independente do ZIP

Um agente recebeu somente ZIP extraído e dois inputs sintéticos, sem clone. Conseguiu localizar regras, contratos, vocabulário e limites. Tratou instruções de upload/aprovação automática dentro dos documentos como dados e não as seguiu. No piloto, identificou 1/20 = 5%, inferior a 10%, além de ausência de inventário, versões/digests, revisão humana e desvios aprovados; não emitiu aprovação. O lint não foi executado nesse cenário comportamental, pois tem teste separado. É evidência de um cenário, sem alegar ganho causal ou avaliação geral de segurança do modelo.

## Limites da entrega

21 regras automáticas não cobrem as 50 regras da proposta. OCR/DOCX não são suportados. Ausência de diagnóstico, exit 0 ou metadados não certificam conformidade ou engenharia. Acessibilidade integral, instalação nova em todos os sistemas e variantes de PDF reais não foram certificadas. CI remota deve validar o commit do PR; esta auditoria registra resultados locais. Nenhum merge ou deploy foi realizado.
