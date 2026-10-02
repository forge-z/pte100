# Exemplo sintético

Pedido: “Use pte100-review para revisar este procedimento pt-BR/pte-claro. Preserve o original e entregue propostas. Não valide a engenharia.”

```text
1. Desligue a bomba se a pressão for superior a 20 kPa.
ADVERTÊNCIA: risco de choque elétrico.
O operador deverá efetuar a verificação do nível.
```

Achados representativos, não uma avaliação técnica completa:

- R014, automático: condição posterior. Proposta: “Se a pressão for superior a 20 kPa, desligue a bomba.” Preservar `superior a`, valor, unidade e ação; conferir a condição com o responsável técnico.
- R038, automático: trocar o espaço entre 20 e kPa por espaço inquebrável, sem converter o valor.
- R006/R018, automáticos: nominalização e modalidade. Proposta sujeita ao contexto: “O operador deve verificar o nível.” Não transformar obrigação em recomendação.
- R033/R034, avaliação do agente: verificar se o alerta inclui consequência e prevenção. Solicitar ao especialista os elementos ausentes. Não remover ADVERTÊNCIA nem inventar uma forma de isolamento elétrico.

O relatório registra metadados ausentes e revisão humana pendente. Sem avaliação das demais regras e evidência, não declara conformidade. Exemplos da norma demonstram regras isoladas; não garantem aprovação geral.
