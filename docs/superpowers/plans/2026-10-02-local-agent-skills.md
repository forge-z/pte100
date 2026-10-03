# Skills locais e revisor offline — plano de execução

**Objetivo:** entregar pack portátil e download no site, auditar limites da revisão documental e verificar o revisor offline com tutorial curto.

**Arquitetura:** duas skills autocontidas, snapshots derivados das fontes canônicas, CLI Ruby opcional e ZIP determinístico gerado em Node no build Astro. Revisor mantém serviço Ruby em loopback e interface existente.

**Restrições:** proposta experimental; não mudar regras/severidades/governança; não declarar lint como certificação; instalação pode usar rede, execução do motor não; agente remoto não se torna offline pelo pack. Branch isolada; sem merge/deploy.

- [x] Inspecionar AGENTS.md, regras, vocabulário, documentação, motor/revisor e website; verificar ausência de .agents/skills.
- [x] Executar cenário de agente sem skill e testes de referência; registrar ausência de falha comportamental em vez de alegar ganho causal.
- [x] Reproduzir falha de literais e escrever testes antes da correção; preservar offsets.
- [x] Criar pte100-review e pte100-pilot com referências, licença, exemplos, instalação manual e limites explícitos.
- [x] Testar ZIP extraído e instalado fora do clone; adicionar geração/checksum e CTA com base /pte100.
- [x] Conferir SKILL.md, todas as referências/manifesto, configuração explícita, caminhos com espaços, exit1 e falhas operacionais.
- [x] Executar agente independente usando somente ZIP extraído; verificar piloto insuficiente e conteúdo malicioso como dados.
- [x] Testar cópia limpa do revisor e serviço HTTP real com saídas de rede de processo controladas; testar interface, PDF textual/OCR recusado e exportação.
- [x] Criar tutorial de instalação/uso e link direto no site; QA desktop/mobile, ZIP HTTP e checks locais equivalentes à CI; execução remota depende do PR.
- [x] Registrar auditoria por gravidade, comandos/evidências e limites; preparar commit/PR draft sem publicar produção.

**Revisão focal:** validade parcial de lint sem metadados; alertas/valores/força normativa; modelo remoto e dados privados; snapshots desatualizados; links/downloads com base de GitHub Pages; instalação separada de runtime offline.

**Conclusão local:** ver [auditoria e evidências](../../audits/2026-10-02-local-skills-review.md). Branch de recuperação preserva as alterações originais; PR em rascunho autorizado, sem merge/deploy.
