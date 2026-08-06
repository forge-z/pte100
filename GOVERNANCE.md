# Governança do PTE-100

## Valores

O projeto decide em público, registra justificativas, preserva compatibilidade e privilegia evidência sobre preferência pessoal. Interesses comerciais são legítimos, mas devem ser declarados.

## Papéis

### Participante

Qualquer pessoa que discuta, teste ou contribua. Participantes podem propor mudanças e participar de consultas.

### Mantenedor

Responsável por revisão, triagem, lançamentos e integridade dos artefatos. A nomeação exige contribuições sustentadas, adesão ao Código de Conduta e aprovação de dois terços dos mantenedores ativos.

### Editor da norma

Mantém coerência terminológica e normativa. Uma mudança que altere obrigação precisa da revisão de ao menos um editor que não seja seu autor.

### Conselho Técnico

Grupo de 3 a 7 pessoas que resolve impasses, aprova versões estáveis e protege a arquitetura. Mandatos duram dois anos, com no máximo dois mandatos consecutivos e eleição pública pelos mantenedores ativos.

### Comitê de Conduta

Grupo independente de pelo menos três pessoas. Não publica detalhes confidenciais e declara impedimentos.

## Processo decisório

1. O projeto busca consenso documentado.
2. Sem consenso após o período de consulta, mantenedores ativos votam.
3. Mudança editorial exige maioria simples.
4. Mudança normativa compatível exige dois terços.
5. Mudança incompatível, alteração de licença ou dissolução exige três quartos do Conselho Técnico e consulta pública mínima de 30 dias.
6. Empate mantém o estado atual.

Mantenedor ativo é quem revisou, contribuiu ou participou de decisão nos últimos seis meses. A ata registra votos, impedimentos e justificativa.

## Ciclo de uma regra

`proposal` → `experimental` → `active` → `deprecated` → `retired`

- Regras experimentais não impedem conformidade.
- Regras ativas são normativas na versão publicada.
- Regras obsoletas continuam válidas durante a janela anunciada.
- Códigos retirados não são reutilizados.

## Versões

A norma usa `MAJOR.MINOR` e os artefatos de ferramenta usam SemVer.

- **MINOR:** novas regras compatíveis, esclarecimentos e recursos opcionais.
- **MAJOR:** remoção, mudança de significado ou nova obrigação incompatível.
- **errata:** correção editorial publicada sem alterar a versão normativa.

Cada lançamento contém changelog, snapshot imutável de regras e vocabulário, schemas e data de vigência. A linha `0.x` pode mudar com mais rapidez e não promete compatibilidade total.

## Transparência e conflitos

Participantes com vínculo financeiro ou organizacional relevante devem declará-lo na proposta. Uma pessoa não pode ser a única aprovadora de sua própria mudança. Patrocínio não concede voto adicional nem prioridade normativa.

## Sucessão e ativos

Credenciais críticas devem ter pelo menos dois responsáveis. Se o projeto ficar inativo por 12 meses, o Conselho publica um chamado de sucessão. Marcas, domínios e fundos devem permanecer vinculados à missão aberta descrita neste repositório.

