# Catálogo de regras PTE-100 v0.1

> **Normativo.** Este arquivo é gerado de `rules/rules.yaml`. Não o edite diretamente; execute `ruby tools/generate_catalog.rb`.

Cada seção apresenta código, obrigação, justificativa, exemplos e a representação YAML portátil para lint. Os exemplos demonstram a regra em foco, não conformidade integral.

## Léxico

### R001 — Use um termo preferido por conceito

- **Descrição:** Use o termo preferido do vocabulário ativo sempre que o conceito correspondente aparecer.
- **Justificativa:** Uma forma estável reduz ambiguidade, variação de tradução e dispersão na busca.
- **Nível mínimo:** `pte-claro`
- **Severidade padrão:** `error`

**Incorreto**

> Faça a checagem da bateria. Depois, cheque a bateria.

**Correto**

> Verifique a bateria. Depois, registre o estado da bateria.

**Representação YAML para lint**

```yaml
id: R001
lint:
  mode: automatic
  engine: terminology
  selector: prose
  condition: forbidden_or_nonpreferred_term
  parameters:
    respect_literal_spans: true
  autofix: suggested
  message: Use '{preferred}' no lugar de '{term}' para o conceito {concept_id}.
```

### R002 — Use uma palavra com um só sentido no mesmo escopo

- **Descrição:** Não use a mesma palavra para conceitos diferentes dentro de uma unidade de conteúdo.
- **Justificativa:** A polissemia local faz leitores e sistemas associarem uma ação ao objeto errado.
- **Nível mínimo:** `pte-claro`
- **Severidade padrão:** `error`

**Incorreto**

> Abra a porta e abra a válvula com a chave.

**Correto**

> Abra a porta e destrave a válvula com a chave.

**Representação YAML para lint**

```yaml
id: R002
lint:
  mode: assisted
  engine: word_sense
  selector: content_unit
  condition: same_lemma_multiple_concepts
  parameters:
    confidence: 0.8
  autofix: none
  message: O termo '{term}' pode ter mais de um sentido nesta unidade.
```

### R003 — Evite sinônimos não registrados

- **Descrição:** Não alterne entre sinônimos para variar o estilo; registre uma variante antes de usá-la.
- **Justificativa:** Variação ornamental prejudica correspondência terminológica e memória de tradução.
- **Nível mínimo:** `pte-claro`
- **Severidade padrão:** `warning`

**Incorreto**

> Remova a tampa. Retire a cobertura lateral.

**Correto**

> Remova a tampa. Remova a tampa lateral.

**Representação YAML para lint**

```yaml
id: R003
lint:
  mode: assisted
  engine: terminology
  selector: document
  condition: unregistered_synonym_cluster
  parameters:
    confidence: 0.85
  autofix: suggested
  message: Os termos {terms} parecem nomear o mesmo conceito; use o termo preferido.
```

### R004 — Expanda a sigla na primeira ocorrência

- **Descrição:** Escreva o nome completo seguido da sigla entre parênteses na primeira ocorrência de cada unidade autônoma.
- **Justificativa:** A expansão torna a unidade compreensível fora do documento de origem.
- **Nível mínimo:** `pte-claro`
- **Severidade padrão:** `error`

**Incorreto**

> Conecte o CLP à rede.

**Correto**

> Conecte o controlador lógico programável (CLP) à rede.

**Representação YAML para lint**

```yaml
id: R004
lint:
  mode: automatic
  engine: abbreviation
  selector: content_unit
  condition: acronym_before_definition
  parameters:
    allowlist: []
  autofix: suggested
  message: Expanda a sigla '{term}' na primeira ocorrência desta unidade.
```

### R005 — Não abrevie por economia de espaço

- **Descrição:** Use abreviação somente quando ela estiver registrada, for necessária e ocorrer novamente.
- **Justificativa:** Abreviações ocasionais aumentam o esforço de leitura e podem coincidir com outros códigos.
- **Nível mínimo:** `pte-claro`
- **Severidade padrão:** `warning`

**Incorreto**

> Verifique a temp. amb.

**Correto**

> Verifique a temperatura ambiente.

**Representação YAML para lint**

```yaml
id: R005
lint:
  mode: automatic
  engine: abbreviation
  selector: prose
  condition: unregistered_abbreviation
  parameters:
    ignore_patterns:
    - url
    - version
    - unit
  autofix: suggested
  message: A abreviação '{term}' não está registrada.
```

### R006 — Use verbo específico em vez de expressão nominal

- **Descrição:** Substitua construções como 'efetuar a verificação' pelo verbo que nomeia a ação.
- **Justificativa:** Verbos diretos encurtam a frase e tornam a ação detectável.
- **Nível mínimo:** `pte-claro`
- **Severidade padrão:** `warning`

**Incorreto**

> Efetue a realização do teste.

**Correto**

> Teste o circuito.

**Representação YAML para lint**

```yaml
id: R006
lint:
  mode: automatic
  engine: phrase_map
  selector: prose
  condition: nominalization_in_registry
  parameters:
    registry: pte-core
  autofix: suggested
  message: Prefira o verbo direto '{replacement}'.
```

### R007 — Evite verbos genéricos sem complemento preciso

- **Descrição:** Não use 'fazer', 'realizar', 'colocar' ou 'processar' quando um verbo técnico mais preciso estiver disponível.
- **Justificativa:** Verbos genéricos escondem o tipo de transformação ou movimento.
- **Nível mínimo:** `pte-claro`
- **Severidade padrão:** `warning`

**Incorreto**

> Faça o cabo no terminal.

**Correto**

> Conecte o cabo ao terminal X1.

**Representação YAML para lint**

```yaml
id: R007
lint:
  mode: assisted
  engine: generic_verb
  selector: prose
  condition: generic_verb_low_specificity
  parameters:
    verbs:
    - fazer
    - realizar
    - colocar
    - processar
  autofix: none
  message: O verbo '{term}' pode ser impreciso; nomeie a ação técnica.
```

### R008 — Use nomes técnicos explícitos

- **Descrição:** Nomeie o componente, o material ou o dado; não o substitua por expressão vaga.
- **Justificativa:** Expressões vagas dependem de contexto que pode desaparecer na tradução ou recuperação.
- **Nível mínimo:** `pte-claro`
- **Severidade padrão:** `error`

**Incorreto**

> Remova a coisa que prende o tubo.

**Correto**

> Remova a abraçadeira do tubo.

**Representação YAML para lint**

```yaml
id: R008
lint:
  mode: assisted
  engine: vague_language
  selector: prose
  condition: vague_noun_phrase
  parameters:
    terms:
    - coisa
    - negócio
    - elemento
    - parte
  autofix: none
  message: A expressão '{term}' não identifica um objeto técnico preciso.
```

### R009 — Marque palavras estrangeiras e literais

- **Descrição:** Marque comando, rótulo de interface, código e termo estrangeiro que precise permanecer literal.
- **Justificativa:** A marcação impede tradução ou correção indevida e separa linguagem de conteúdo executável.
- **Nível mínimo:** `pte-claro`
- **Severidade padrão:** `warning`

**Incorreto**

> Clique em Save as.

**Correto**

> Selecione **Save as** (Salvar como).

**Representação YAML para lint**

```yaml
id: R009
lint:
  mode: assisted
  engine: language_id
  selector: prose
  condition: unmarked_foreign_or_literal_span
  parameters:
    min_length: 2
  autofix: suggested
  message: Marque '{term}' como literal ou forneça equivalente em português.
```

### R010 — Evite referência pronominal ambígua

- **Descrição:** Repita o nome técnico quando um pronome ou demonstrativo puder ter mais de um antecedente.
- **Justificativa:** Antecedente explícito impede que uma ação seja aplicada ao componente errado.
- **Nível mínimo:** `pte-claro`
- **Severidade padrão:** `error`

**Incorreto**

> Remova o módulo da base e limpe-a.

**Correto**

> Remova o módulo da base e limpe a base.

**Representação YAML para lint**

```yaml
id: R010
lint:
  mode: assisted
  engine: coreference
  selector: sentence_pair
  condition: ambiguous_pronoun_antecedent
  parameters:
    max_candidates: 1
    confidence: 0.75
  autofix: none
  message: O referente de '{term}' pode ser ambíguo.
```

## Frase

### R011 — Expresse uma ação principal por frase

- **Descrição:** Em instruções, escreva uma ação principal por frase, exceto ações inseparáveis registradas.
- **Justificativa:** Ações separadas permitem confirmar ordem, resultado e falha de cada etapa.
- **Nível mínimo:** `pte-claro`
- **Severidade padrão:** `error`

**Incorreto**

> Abra a tampa, retire o filtro e limpe o alojamento.

**Correto**

> Abra a tampa. Remova o filtro. Limpe o alojamento.

**Representação YAML para lint**

```yaml
id: R011
lint:
  mode: assisted
  engine: dependency_parse
  selector: instruction_sentence
  condition: multiple_independent_actions
  parameters:
    allowed_pairs: []
  autofix: suggested
  message: A frase contém {count} ações principais; divida a instrução.
```

### R012 — Limite a frase a 25 palavras

- **Descrição:** Use no máximo 25 palavras por frase, salvo literal indivisível ou exceção de segurança justificada.
- **Justificativa:** Frases curtas reduzem carga de memória e erro de segmentação.
- **Nível mínimo:** `pte-claro`
- **Severidade padrão:** `warning`

**Incorreto**

> Antes de iniciar a operação, que somente deve ser feita por pessoal autorizado, verifique se todos os cabos que foram instalados durante a etapa anterior estão firmes e sem danos visíveis.

**Correto**

> Somente pessoal autorizado pode iniciar a operação. Antes da operação, verifique todos os cabos instalados. Confirme que os cabos estão firmes e sem danos visíveis.

**Representação YAML para lint**

```yaml
id: R012
lint:
  mode: automatic
  engine: word_count
  selector: sentence
  condition: word_count_exceeds
  parameters:
    maximum: 25
    exclude:
    - code
    - url
    - identifier
  autofix: none
  message: A frase tem {actual} palavras; o limite é {maximum}.
```

### R013 — Prefira voz ativa

- **Descrição:** Identifique o agente e use voz ativa quando o agente for relevante para a ação.
- **Justificativa:** A voz ativa mostra responsabilidade e reduz omissão do agente.
- **Nível mínimo:** `pte-claro`
- **Severidade padrão:** `warning`

**Incorreto**

> O relatório deve ser aprovado antes do envio.

**Correto**

> O supervisor deve aprovar o relatório antes do envio.

**Representação YAML para lint**

```yaml
id: R013
lint:
  mode: assisted
  engine: morphosyntax
  selector: prose
  condition: passive_voice_with_missing_agent
  parameters:
    confidence: 0.8
  autofix: none
  message: Identifique o agente desta ação ou justifique a voz passiva.
```

### R014 — Coloque a condição antes da ação

- **Descrição:** Quando uma condição determinar a execução, escreva a condição antes da ação.
- **Justificativa:** O leitor precisa decidir a aplicabilidade antes de começar uma ação.
- **Nível mínimo:** `pte-claro`
- **Severidade padrão:** `error`

**Incorreto**

> Substitua o fusível se o indicador permanecer apagado.

**Correto**

> Se o indicador permanecer apagado, substitua o fusível.

**Representação YAML para lint**

```yaml
id: R014
lint:
  mode: automatic
  engine: syntax_pattern
  selector: instruction_sentence
  condition: trailing_execution_condition
  parameters:
    markers:
    - se
    - caso
  autofix: suggested
  message: Mova a condição de execução para antes da ação.
```

### R015 — Diferencie se, quando e enquanto

- **Descrição:** Use 'se' para possibilidade, 'quando' para evento esperado e 'enquanto' para simultaneidade.
- **Justificativa:** Conectores condicionais diferentes codificam estados operacionais diferentes.
- **Nível mínimo:** `pte-claro`
- **Severidade padrão:** `warning`

**Incorreto**

> Quando ocorrer uma falha eventual, registre o código.

**Correto**

> Se ocorrer uma falha, registre o código.

**Representação YAML para lint**

```yaml
id: R015
lint:
  mode: assisted
  engine: semantic_marker
  selector: sentence
  condition: condition_marker_semantic_mismatch
  parameters:
    markers:
    - se
    - quando
    - enquanto
  autofix: suggested
  message: Verifique se '{term}' expressa a relação temporal ou condicional correta.
```

### R016 — Explicite o escopo da negação

- **Descrição:** Posicione 'não' junto do verbo afetado e reescreva negativas que admitam mais de um escopo.
- **Justificativa:** Negação ambígua pode inverter uma condição ou proibição.
- **Nível mínimo:** `pte-claro`
- **Severidade padrão:** `error`

**Incorreto**

> Não desligue e remova o cabo.

**Correto**

> Mantenha o equipamento ligado. Remova o cabo de dados.

**Representação YAML para lint**

```yaml
id: R016
lint:
  mode: assisted
  engine: dependency_parse
  selector: sentence
  condition: negation_with_coordinated_predicates
  parameters:
    confidence: 0.75
  autofix: none
  message: A negação pode afetar mais de uma ação; explicite seu escopo.
```

### R017 — Evite dupla negação

- **Descrição:** Não combine duas formas negativas quando uma formulação positiva preservar o sentido.
- **Justificativa:** Dupla negação aumenta esforço e pode ser interpretada como proibição.
- **Nível mínimo:** `pte-claro`
- **Severidade padrão:** `warning`

**Incorreto**

> Não use um cabo que não esteja intacto.

**Correto**

> Use somente um cabo intacto.

**Representação YAML para lint**

```yaml
id: R017
lint:
  mode: automatic
  engine: negation_count
  selector: sentence
  condition: multiple_negative_markers
  parameters:
    minimum: 2
  autofix: suggested
  message: Reescreva a dupla negação como uma instrução direta.
```

### R018 — Use modalidade normativa padronizada

- **Descrição:** Use 'deve', 'não deve', 'deveria' e 'pode' conforme obrigação, proibição, recomendação e permissão.
- **Justificativa:** Um conjunto fechado torna a força da instrução verificável.
- **Nível mínimo:** `pte-claro`
- **Severidade padrão:** `error`

**Incorreto**

> Convém que o técnico talvez registre a leitura.

**Correto**

> O técnico deve registrar a leitura.

**Representação YAML para lint**

```yaml
id: R018
lint:
  mode: automatic
  engine: phrase_map
  selector: normative_prose
  condition: nonstandard_modality
  parameters:
    allowed:
    - deve
    - não deve
    - deveria
    - pode
  autofix: suggested
  message: Use uma modalidade normativa padronizada; '{term}' é impreciso.
```

### R019 — Evite futuro para expressar obrigação

- **Descrição:** Não use futuro do presente ou futuro perifrástico para criar requisito.
- **Justificativa:** O futuro descreve previsão e não distingue obrigação de resultado esperado.
- **Nível mínimo:** `pte-claro`
- **Severidade padrão:** `error`

**Incorreto**

> O operador registrará o número de série.

**Correto**

> O operador deve registrar o número de série.

**Representação YAML para lint**

```yaml
id: R019
lint:
  mode: assisted
  engine: morphosyntax
  selector: normative_prose
  condition: future_tense_as_requirement
  parameters:
    confidence: 0.8
  autofix: suggested
  message: Use 'deve' se a frase expressar obrigação.
```

### R020 — Evite gerúndio com relação lógica indefinida

- **Descrição:** Substitua gerúndio quando ele não deixar claro se a ação é simultânea, posterior, causal ou resultante.
- **Justificativa:** A relação implícita entre ações pode alterar a sequência operacional.
- **Nível mínimo:** `pte-claro`
- **Severidade padrão:** `warning`

**Incorreto**

> Feche a válvula, interrompendo o fluxo.

**Correto**

> Feche a válvula. Confirme que o fluxo parou.

**Representação YAML para lint**

```yaml
id: R020
lint:
  mode: assisted
  engine: morphosyntax
  selector: sentence
  condition: ambiguous_gerund_clause
  parameters:
    confidence: 0.7
  autofix: none
  message: Explique a relação entre a oração no gerúndio e a ação principal.
```

## Procedimento

### R021 — Inicie cada passo com uma ação

- **Descrição:** Comece o passo com verbo no imperativo ou com condição seguida imediatamente da ação.
- **Justificativa:** O padrão facilita leitura por varredura e extração da ação.
- **Nível mínimo:** `pte-claro`
- **Severidade padrão:** `error`

**Incorreto**

> A remoção da tampa deve ser feita.

**Correto**

> Remova a tampa.

**Representação YAML para lint**

```yaml
id: R021
lint:
  mode: automatic
  engine: step_grammar
  selector: procedure_step
  condition: missing_leading_action
  parameters:
    allow_leading_condition: true
  autofix: suggested
  message: Inicie o passo com uma ação no imperativo.
```

### R022 — Identifique o objeto da ação

- **Descrição:** Declare o objeto direto ou o alvo técnico de cada ação, salvo quando o verbo não exigir alvo.
- **Justificativa:** Uma ação sem alvo pode ser aplicada ao componente incorreto.
- **Nível mínimo:** `pte-claro`
- **Severidade padrão:** `error`

**Incorreto**

> Instale com cuidado.

**Correto**

> Instale o anel de vedação no alojamento.

**Representação YAML para lint**

```yaml
id: R022
lint:
  mode: assisted
  engine: dependency_parse
  selector: procedure_step
  condition: transitive_action_without_object
  parameters:
    confidence: 0.8
  autofix: none
  message: Identifique o objeto ou alvo do verbo '{verb}'.
```

### R023 — Preserve a ordem de execução

- **Descrição:** Apresente passos na ordem de execução e numere-os quando a sequência for obrigatória.
- **Justificativa:** Ordem textual diferente da ordem real aumenta omissões e retornos perigosos.
- **Nível mínimo:** `pte-claro`
- **Severidade padrão:** `error`

**Incorreto**

> Depois de instalar o filtro, antes disso limpe o alojamento.

**Correto**

> 1. Limpe o alojamento. 2. Instale o filtro.

**Representação YAML para lint**

```yaml
id: R023
lint:
  mode: assisted
  engine: temporal_consistency
  selector: procedure
  condition: temporal_marker_conflicts_with_order
  parameters:
    require_numbering: true
  autofix: none
  message: A relação temporal não corresponde à ordem dos passos.
```

### R024 — Separe ações simultâneas das sequenciais

- **Descrição:** Declare explicitamente quando duas ações devem ocorrer ao mesmo tempo; caso contrário, use passos separados.
- **Justificativa:** Coordenação simples não informa se as ações são simultâneas ou sequenciais.
- **Nível mínimo:** `pte-claro`
- **Severidade padrão:** `error`

**Incorreto**

> Pressione o botão e gire a chave.

**Correto**

> Enquanto mantém o botão pressionado, gire a chave para LIGADO.

**Representação YAML para lint**

```yaml
id: R024
lint:
  mode: assisted
  engine: action_relation
  selector: procedure_step
  condition: coordinated_actions_without_relation
  parameters:
    confidence: 0.75
  autofix: none
  message: Informe se as ações são simultâneas ou sequenciais.
```

### R025 — Declare pré-requisitos antes do procedimento

- **Descrição:** Liste estado inicial, permissão, ferramenta e material necessários antes do primeiro passo.
- **Justificativa:** Pré-requisitos tardios causam interrupção, improviso e execução em estado inseguro.
- **Nível mínimo:** `pte-claro`
- **Severidade padrão:** `error`

**Incorreto**

> 3. Use a chave especial, que deve ser obtida antes do serviço.

**Correto**

> Pré-requisito: obtenha a chave T-40 antes de iniciar o procedimento.

**Representação YAML para lint**

```yaml
id: R025
lint:
  mode: assisted
  engine: document_structure
  selector: procedure
  condition: prerequisite_introduced_after_first_step
  parameters: {}
  autofix: none
  message: Mova o pré-requisito para antes do primeiro passo.
```

### R026 — Informe o resultado verificável

- **Descrição:** Depois de ação cujo sucesso não seja visível, informe o estado ou a medição esperada.
- **Justificativa:** Resultado observável permite detectar execução incompleta.
- **Nível mínimo:** `pte-claro`
- **Severidade padrão:** `warning`

**Incorreto**

> Reinicie o serviço.

**Correto**

> Reinicie o serviço. Confirme que o estado muda para **Ativo** em até 30 segundos.

**Representação YAML para lint**

```yaml
id: R026
lint:
  mode: assisted
  engine: procedure_semantics
  selector: procedure_step
  condition: unverifiable_action_without_expected_result
  parameters:
    action_registry: pte-core
  autofix: none
  message: Inclua um resultado observável para confirmar a ação.
```

### R027 — Forneça limites e tolerâncias

- **Descrição:** Substitua qualificadores subjetivos por valor, faixa ou critério observável quando a execução depender deles.
- **Justificativa:** Termos como 'bem apertado' produzem resultados diferentes entre operadores.
- **Nível mínimo:** `pte-claro`
- **Severidade padrão:** `error`

**Incorreto**

> Aperte bem o parafuso.

**Correto**

> Aperte o parafuso a 12 N·m ± 1 N·m.

**Representação YAML para lint**

```yaml
id: R027
lint:
  mode: assisted
  engine: vague_measure
  selector: procedure_step
  condition: subjective_threshold
  parameters:
    terms:
    - bem
    - pouco
    - bastante
    - adequado
    - suficiente
  autofix: none
  message: Substitua '{term}' por limite ou critério verificável.
```

### R028 — Declare a decisão com ramos explícitos

- **Descrição:** Em uma decisão, escreva cada condição e seu destino; não esconda alternativas em prosa.
- **Justificativa:** Ramos explícitos evitam que o leitor continue pelo caminho errado.
- **Nível mínimo:** `pte-claro`
- **Severidade padrão:** `error`

**Incorreto**

> Se estiver verde continue, do contrário veja o problema ou reinicie.

**Correto**

> Se o indicador estiver verde, vá para o passo 6. Se estiver vermelho, execute PROC-ERR-04.

**Representação YAML para lint**

```yaml
id: R028
lint:
  mode: assisted
  engine: decision_graph
  selector: procedure
  condition: decision_branch_without_unique_target
  parameters: {}
  autofix: none
  message: Associe cada condição a um destino único.
```

### R029 — Use referência estável para outra instrução

- **Descrição:** Ao encaminhar o leitor, cite o identificador e o título da unidade de destino.
- **Justificativa:** Expressões posicionais quebram com paginação, reuso e atualização.
- **Nível mínimo:** `pte-claro`
- **Severidade padrão:** `error`

**Incorreto**

> Faça o procedimento abaixo.

**Correto**

> Execute PROC-014 — Testar a válvula de alívio.

**Representação YAML para lint**

```yaml
id: R029
lint:
  mode: automatic
  engine: reference
  selector: prose
  condition: positional_or_unresolved_procedure_reference
  parameters:
    require_id_and_title: true
  autofix: suggested
  message: Substitua a referência posicional por ID e título estáveis.
```

### R030 — Não misture explicação com comando

- **Descrição:** Mantenha o passo como comando e coloque explicação necessária em frase ou nota separada.
- **Justificativa:** Separação preserva a ação durante varredura, tradução e extração.
- **Nível mínimo:** `pte-claro`
- **Severidade padrão:** `warning`

**Incorreto**

> Remova o filtro, que normalmente acumula partículas porque fica antes da bomba.

**Correto**

> Remova o filtro. NOTA: O filtro retém partículas antes da bomba.

**Representação YAML para lint**

```yaml
id: R030
lint:
  mode: assisted
  engine: clause_role
  selector: procedure_step
  condition: explanatory_relative_clause_in_command
  parameters:
    confidence: 0.75
  autofix: suggested
  message: Separe a explicação do comando principal.
```

## Alertas

### R031 — Use palavra-sinal registrada

- **Descrição:** Inicie cada alerta com PERIGO, ADVERTÊNCIA, CUIDADO ou AVISO, salvo perfil regulado declarado.
- **Justificativa:** Taxonomia fechada permite reconhecer e priorizar risco.
- **Nível mínimo:** `pte-estrutura`
- **Severidade padrão:** `error`

**Incorreto**

> IMPORTANTE: Há alta tensão.

**Correto**

> ADVERTÊNCIA — Tensão elétrica

**Representação YAML para lint**

```yaml
id: R031
lint:
  mode: automatic
  engine: alert_structure
  selector: alert
  condition: invalid_signal_word
  parameters:
    allowed:
    - PERIGO
    - ADVERTÊNCIA
    - CUIDADO
    - AVISO
  autofix: none
  message: Use uma palavra-sinal registrada e confirme a classificação do risco.
```

### R032 — Nomeie o risco

- **Descrição:** Identifique a fonte ou a natureza do risco no título ou na primeira frase do alerta.
- **Justificativa:** A palavra-sinal sozinha não informa o que deve ser evitado.
- **Nível mínimo:** `pte-estrutura`
- **Severidade padrão:** `error`

**Incorreto**

> CUIDADO: Tenha atenção.

**Correto**

> CUIDADO — Superfície quente

**Representação YAML para lint**

```yaml
id: R032
lint:
  mode: assisted
  engine: alert_structure
  selector: alert
  condition: missing_hazard
  parameters:
    confidence: 0.8
  autofix: none
  message: Identifique o risco neste alerta.
```

### R033 — Declare a consequência

- **Descrição:** Explique a lesão, o dano, a perda ou a interrupção que pode ocorrer.
- **Justificativa:** A consequência sustenta a urgência e ajuda a avaliar o comportamento seguro.
- **Nível mínimo:** `pte-estrutura`
- **Severidade padrão:** `error`

**Incorreto**

> ADVERTÊNCIA: Não toque nos terminais.

**Correto**

> ADVERTÊNCIA: O contato com os terminais pode causar lesão grave.

**Representação YAML para lint**

```yaml
id: R033
lint:
  mode: assisted
  engine: alert_structure
  selector: alert
  condition: missing_consequence
  parameters:
    confidence: 0.8
  autofix: none
  message: Declare a consequência possível do risco.
```

### R034 — Declare como evitar o risco

- **Descrição:** Forneça uma ação preventiva específica e executável.
- **Justificativa:** Reconhecer o risco sem saber como evitá-lo não protege o leitor.
- **Nível mínimo:** `pte-estrutura`
- **Severidade padrão:** `error`

**Incorreto**

> ADVERTÊNCIA: Há risco de choque elétrico.

**Correto**

> ADVERTÊNCIA: Desligue o disjuntor Q3 e confirme tensão de 0 V antes de tocar nos terminais.

**Representação YAML para lint**

```yaml
id: R034
lint:
  mode: assisted
  engine: alert_structure
  selector: alert
  condition: missing_avoidance_action
  parameters:
    confidence: 0.8
  autofix: none
  message: Inclua uma ação específica para evitar o risco.
```

### R035 — Coloque o alerta antes da ação perigosa

- **Descrição:** Posicione o alerta específico imediatamente antes do primeiro passo ao qual ele se aplica.
- **Justificativa:** Um alerta posterior chega tarde demais; um alerta distante pode ser ignorado.
- **Nível mínimo:** `pte-estrutura`
- **Severidade padrão:** `error`

**Incorreto**

> 1. Remova a tampa. ADVERTÊNCIA: A tampa protege terminais energizados.

**Correto**

> ADVERTÊNCIA: Desligue o disjuntor Q3. 1. Remova a tampa.

**Representação YAML para lint**

```yaml
id: R035
lint:
  mode: assisted
  engine: document_structure
  selector: procedure
  condition: alert_after_or_detached_from_hazardous_step
  parameters:
    maximum_gap_blocks: 0
  autofix: suggested
  message: Posicione o alerta imediatamente antes da ação perigosa.
```

### R036 — Não use nota para comunicar risco

- **Descrição:** Use alerta, e não NOTA ou dica, quando houver lesão, dano, perda de dados ou interrupção relevante.
- **Justificativa:** Notas têm prioridade visual e semântica menor e podem ser omitidas no reuso.
- **Nível mínimo:** `pte-estrutura`
- **Severidade padrão:** `error`

**Incorreto**

> NOTA: O eixo pode prender sua mão.

**Correto**

> ADVERTÊNCIA — Movimento do eixo: Afaste as mãos antes de ligar o motor.

**Representação YAML para lint**

```yaml
id: R036
lint:
  mode: assisted
  engine: hazard_language
  selector: note
  condition: hazard_in_nonalert_block
  parameters:
    confidence: 0.85
  autofix: none
  message: Este conteúdo pode descrever risco; converta-o em alerta e classifique-o.
```

## Dados, números e unidades

### R037 — Use unidade do SI ou unidade declarada pelo domínio

- **Descrição:** Expresse medidas em unidades do SI, salvo unidade setorial registrada e declarada.
- **Justificativa:** Unidades previsíveis reduzem conversões e erros de escala.
- **Nível mínimo:** `pte-estrutura`
- **Severidade padrão:** `error`

**Incorreto**

> Mantenha distância de 10 inches.

**Correto**

> Mantenha distância de 250 mm.

**Representação YAML para lint**

```yaml
id: R037
lint:
  mode: automatic
  engine: units
  selector: prose_and_tables
  condition: unregistered_or_nonprofile_unit
  parameters:
    system: SI
  autofix: none
  message: A unidade '{unit}' não pertence ao perfil ativo.
```

### R038 — Separe número e símbolo de unidade

- **Descrição:** Use um espaço inquebrável entre o número e o símbolo da unidade, exceto para grau angular, minuto e segundo de arco.
- **Justificativa:** A separação segue convenção metrológica e evita quebra entre valor e unidade.
- **Nível mínimo:** `pte-estrutura`
- **Severidade padrão:** `error`

**Incorreto**

> Ajuste para 24V e 30°C.

**Correto**

> Ajuste para 24 V e 30 °C.

**Representação YAML para lint**

```yaml
id: R038
lint:
  mode: automatic
  engine: units
  selector: prose_and_tables
  condition: missing_nbsp_between_value_and_unit
  parameters:
    exceptions:
    - degree_angle
    - arcminute
    - arcsecond
  autofix: safe
  message: Insira espaço inquebrável entre {value} e {unit}.
```

### R039 — Use símbolo de unidade invariável

- **Descrição:** Não pluralize símbolos, não acrescente ponto e preserve maiúsculas e minúsculas padronizadas.
- **Justificativa:** A forma do símbolo distingue unidades e independe do plural gramatical.
- **Nível mínimo:** `pte-estrutura`
- **Severidade padrão:** `error`

**Incorreto**

> Use 5 kgs. e 12 v.

**Correto**

> Use 5 kg e 12 V.

**Representação YAML para lint**

```yaml
id: R039
lint:
  mode: automatic
  engine: units
  selector: prose_and_tables
  condition: malformed_unit_symbol
  parameters:
    registry: SI
  autofix: safe
  message: Use o símbolo padronizado '{replacement}'.
```

### R040 — Declare faixa sem ambiguidade

- **Descrição:** Escreva limites inclusivos ou exclusivos e repita a unidade quando a omissão puder confundir.
- **Justificativa:** Hífens e expressões abertas não informam inclusão dos extremos.
- **Nível mínimo:** `pte-estrutura`
- **Severidade padrão:** `error`

**Incorreto**

> Aceitável: 5-10 V.

**Correto**

> A tensão deve ser maior ou igual a 5 V e menor ou igual a 10 V.

**Representação YAML para lint**

```yaml
id: R040
lint:
  mode: automatic
  engine: numeric_range
  selector: prose_and_tables
  condition: ambiguous_range_notation
  parameters:
    patterns:
    - hyphen_range
    - open_ended_between
  autofix: suggested
  message: Declare se os limites da faixa {range} são inclusivos.
```

### R041 — Use data não ambígua

- **Descrição:** Em prosa, escreva dia, mês por extenso e ano; em dados, use RFC 3339.
- **Justificativa:** Datas numéricas mudam de interpretação entre localidades.
- **Nível mínimo:** `pte-estrutura`
- **Severidade padrão:** `error`

**Incorreto**

> Revisão: 03/04/26.

**Correto**

> Revisão: 3 de abril de 2026.

**Representação YAML para lint**

```yaml
id: R041
lint:
  mode: automatic
  engine: date
  selector: prose
  condition: ambiguous_numeric_date
  parameters:
    machine_format: RFC3339
  autofix: suggested
  message: Escreva a data por extenso ou use RFC 3339 em campo de dados.
```

### R042 — Use separador decimal do perfil

- **Descrição:** Use o separador decimal definido pela localidade e não misture convenções no mesmo documento.
- **Justificativa:** Mistura de ponto e vírgula pode alterar valores por fator de mil.
- **Nível mínimo:** `pte-estrutura`
- **Severidade padrão:** `error`

**Incorreto**

> Ajuste A para 1,250 V e B para 1.250 V.

**Correto**

> No perfil pt-BR, ajuste A para 1,250 V e B para 1,250 V.

**Representação YAML para lint**

```yaml
id: R042
lint:
  mode: automatic
  engine: number_format
  selector: prose_and_tables
  condition: decimal_separator_mismatch_or_mixed
  parameters:
    from_locale: true
  autofix: none
  message: O número '{value}' não segue o separador decimal de {locale}.
```

## Estrutura

### R043 — Use título que identifique tarefa ou objeto

- **Descrição:** Escreva título específico com verbo no infinitivo para tarefa ou nome técnico para referência.
- **Justificativa:** Título previsível melhora navegação, busca e classificação automática.
- **Nível mínimo:** `pte-estrutura`
- **Severidade padrão:** `warning`

**Incorreto**

> Informações gerais

**Correto**

> Calibrar o sensor de pressão

**Representação YAML para lint**

```yaml
id: R043
lint:
  mode: assisted
  engine: heading
  selector: heading
  condition: vague_or_type_mismatched_title
  parameters:
    procedure_form: infinitive
  autofix: none
  message: Torne o título específico para a tarefa ou o objeto.
```

### R044 — Use listas com elementos paralelos

- **Descrição:** Inicie itens equivalentes com a mesma classe gramatical e mantenha o mesmo tipo de informação.
- **Justificativa:** Paralelismo revela diferenças reais e reduz leitura regressiva.
- **Nível mínimo:** `pte-estrutura`
- **Severidade padrão:** `warning`

**Incorreto**

> Pré-requisitos: desligar a energia; a tampa está fechada; luvas.

**Correto**

> Pré-requisitos: desligar a energia; fechar a tampa; vestir as luvas.

**Representação YAML para lint**

```yaml
id: R044
lint:
  mode: assisted
  engine: list_parallelism
  selector: list
  condition: nonparallel_item_openings
  parameters:
    confidence: 0.75
  autofix: none
  message: Os itens desta lista não têm estrutura paralela.
```

### R045 — Dê texto descritivo a links e referências

- **Descrição:** Faça o texto do link identificar o destino; não use apenas 'aqui', URL ou posição.
- **Justificativa:** Texto descritivo funciona fora do layout e melhora acessibilidade.
- **Nível mínimo:** `pte-estrutura`
- **Severidade padrão:** `warning`

**Incorreto**

> Para calibrar, clique aqui.

**Correto**

> Consulte PROC-022 — Calibrar o sensor.

**Representação YAML para lint**

```yaml
id: R045
lint:
  mode: automatic
  engine: link_text
  selector: link
  condition: non_descriptive_link_text
  parameters:
    forbidden:
    - aqui
    - saiba mais
    - link
  autofix: none
  message: Descreva o destino deste link.
```

### R046 — Atribua identificador persistente à unidade

- **Descrição:** Dê identificador único e persistente a procedimento, conceito, alerta reutilizável e tópico autônomo.
- **Justificativa:** IDs estáveis suportam referência, rastreabilidade, tradução e atualização.
- **Nível mínimo:** `pte-estrutura`
- **Severidade padrão:** `error`

**Incorreto**

> ## Troca do filtro

**Correto**

> id: PROC-FILTER-003; title: Substituir o filtro

**Representação YAML para lint**

```yaml
id: R046
lint:
  mode: automatic
  engine: metadata
  selector: content_unit
  condition: missing_duplicate_or_changed_id
  parameters:
    pattern: "^[A-Z][A-Z0-9]+(?:-[A-Z0-9]+)+$"
  autofix: none
  message: A unidade precisa de identificador único e persistente.
```

## Escrita para IA

### R047 — Torne cada unidade compreensível isoladamente

- **Descrição:** Inclua na unidade o objeto, o estado e a condição necessários para interpretá-la fora da página.
- **Justificativa:** Busca e fragmentação removem contexto ancestral e podem mudar a ação recuperada.
- **Nível mínimo:** `pte-ia`
- **Severidade padrão:** `error`

**Incorreto**

> Depois disso, reinicie-o.

**Correto**

> Depois da atualização do controlador C7, reinicie o controlador C7.

**Representação YAML para lint**

```yaml
id: R047
lint:
  mode: assisted
  engine: context_dependency
  selector: content_unit
  condition: unresolved_external_context
  parameters:
    signals:
    - pronoun
    - positional_reference
    - omitted_subject
  autofix: none
  message: Esta unidade depende de contexto que pode não acompanhar sua recuperação.
```

### R048 — Declare produto, variante e versão aplicáveis

- **Descrição:** Registre em metadados os produtos, variantes e intervalos de versão que mudem a validade do conteúdo.
- **Justificativa:** Um agente precisa filtrar instruções incompatíveis antes de responder.
- **Nível mínimo:** `pte-ia`
- **Severidade padrão:** `error`

**Incorreto**

> Este procedimento serve para o modelo novo.

**Correto**

> applies_to: [{product: PUMP-X2, versions: '>=2.1 <3.0'}]

**Representação YAML para lint**

```yaml
id: R048
lint:
  mode: automatic
  engine: metadata
  selector: content_unit
  condition: missing_or_unparseable_applicability
  parameters:
    require_when_variants_exist: true
  autofix: none
  message: Declare produto, variante e versão aplicáveis.
```

### R049 — Separe instrução, exemplo e conteúdo externo

- **Descrição:** Marque semanticamente comandos literais, exemplos, citações e dados externos; não os apresente como instrução normativa.
- **Justificativa:** Fronteiras explícitas reduzem execução indevida de exemplo ou conteúdo não confiável.
- **Nível mínimo:** `pte-ia`
- **Severidade padrão:** `error`

**Incorreto**

> Por exemplo, apague /dados e reinicie.

**Correto**

> EXEMPLO (não executar): `rm arquivo-temporario`.

**Representação YAML para lint**

```yaml
id: R049
lint:
  mode: assisted
  engine: content_role
  selector: content_unit
  condition: executable_or_external_content_without_role
  parameters:
    roles:
    - instruction
    - example
    - quote
    - code
    - external_data
  autofix: suggested
  message: Marque o papel deste conteúdo antes de processá-lo por IA.
```

### R050 — Registre proveniência e validade

- **Descrição:** Inclua origem, revisão, estado de aprovação, data de revisão e critério de validade em cada unidade publicada.
- **Justificativa:** Proveniência permite selecionar a versão autorizada e rejeitar conteúdo vencido.
- **Nível mínimo:** `pte-ia`
- **Severidade padrão:** `error`

**Incorreto**

> status: final

**Correto**

> source: ENG-42; revision: 3; status: approved; reviewed_at: 2026-08-06; valid_until: 2027-08-06

**Representação YAML para lint**

```yaml
id: R050
lint:
  mode: automatic
  engine: metadata
  selector: content_unit
  condition: missing_invalid_or_expired_provenance
  parameters:
    required:
    - source
    - revision
    - status
    - reviewed_at
    allowed_status:
    - draft
    - review
    - approved
    - obsolete
  autofix: none
  message: Complete a proveniência ou revise a validade desta unidade.
```

