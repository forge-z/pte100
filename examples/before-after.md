# Exemplos antes/depois

Os exemplos são informativos. A coluna de regras indica os principais motivos da revisão.

## Procedimento compacto

**Antes**

> O usuário deverá proceder com a abertura do painel e fazer a retirada do filtro, limpando-o se estiver sujo, e depois colocá-lo de volta corretamente.

**Depois**

> 1. Abra o painel.
> 2. Remova o filtro.
> 3. Se o filtro tiver partículas visíveis, limpe o filtro conforme PROC-CLN-002 — Limpar o filtro.
> 4. Instale o filtro no alojamento. Confirme que as duas travas estão fechadas.

**Regras:** R006, R010, R011, R014, R021, R026 e R029.

## Condição

**Antes:** `Acione o alarme caso a pressão suba.`

**Depois:** `Se a pressão for maior que 250 kPa, pressione o botão ALARME.`

**Regras:** R014, R015 e R027.

## Negação

**Antes:** `Não desconecte e desligue o módulo.`

**Depois:** `Mantenha o cabo conectado. Desligue o módulo.`

**Regras:** R011, R016 e R017.

## Requisito de software

**Antes:** `O sistema irá, sempre que possível, tentar fazer a validação dos dados informados pelo usuário.`

**Depois:** `O sistema deve validar cada campo antes de salvar o formulário.`

**Regras:** R006, R018, R019 e R027.

## Unidade e faixa

**Antes:** `A entrada é 10-24V.`

**Depois:** `A tensão de entrada deve ser maior ou igual a 10 V e menor ou igual a 24 V.`

**Regras:** R038, R039 e R040.

## Data

**Antes:** `A licença vence em 05/06/27.`

**Depois:** `A licença vence em 5 de junho de 2027.`

**Regra:** R041.

## Referência

**Antes:** `Veja o procedimento acima e clique aqui para mais detalhes.`

**Depois:** `Consulte PROC-022 — Calibrar o sensor de pressão.`

**Regras:** R029 e R045.

## Alerta

**Antes**

> NOTA: Cuidado ao abrir, pois pode dar choque.

**Depois**

> **ADVERTÊNCIA — Tensão elétrica**  
> O contato com os terminais energizados pode causar lesão grave. Desligue o disjuntor Q3 e confirme tensão de 0 V antes de remover a tampa.

**Regras:** R031, R032, R033, R034 e R036.

## Unidade autônoma para IA

**Antes:** `Depois disso, instale-a e teste novamente.`

**Depois:** `Depois de limpar a válvula V2, instale a válvula V2. Execute TEST-VALVE-008 — Testar a vedação da válvula V2.`

**Regras:** R010, R029 e R047.

## Proveniência

**Antes**

```yaml
title: Reiniciar o controlador
status: final
```

**Depois**

```yaml
id: PROC-CONTROL-011
type: procedure
title: Reiniciar o controlador C7
locale: pt-BR
revision: 3
status: approved
source: ENG-42
reviewed_at: 2026-08-06
valid_until: 2027-08-06
applies_to:
  - product: CTRL-C7
    versions: ">=2.1 <3.0"
```

**Regras:** R046, R048 e R050.

