---
id: PROC-PUMP-017
type: procedure
title: Substituir o filtro da bomba X2
locale: pt-BR
revision: 3
status: approved
source: ENG-PUMP-42
reviewed_at: 2026-08-06
valid_until: 2027-08-06
applies_to:
  - product: PUMP-X2
    versions: ">=2.1 <3.0"
requires:
  - LOCKOUT-001
---

# Substituir o filtro da bomba X2

## Objetivo

Substituir o filtro quando o diferencial de pressão for maior que 80 kPa.

## Pré-requisitos

- Autorizar a ordem de serviço.
- Desligar a bomba X2.
- Executar LOCKOUT-001 — Bloquear a energia da bomba X2.
- Obter um filtro F-X2, uma chave T-40 e um recipiente de 2 L.

> **ADVERTÊNCIA — Pressão residual**  
> A liberação de fluido pressurizado pode causar lesão grave. Feche as válvulas V1 e V2. Confirme pressão de 0 kPa no indicador PI-02 antes de remover a tampa.

## Procedimento

1. Posicione o recipiente abaixo do alojamento do filtro.
2. Remova os quatro parafusos da tampa com a chave T-40.
3. Remova a tampa.
4. Remova o filtro usado.
5. Verifique se o alojamento tem partículas visíveis.
6. Se houver partículas, execute PROC-CLN-002 — Limpar o alojamento do filtro.
7. Instale o filtro F-X2 no alojamento.
8. Instale a tampa.
9. Aperte os quatro parafusos em sequência cruzada a 12 N·m ± 1 N·m.
10. Execute LOCKOUT-001 — Remover o bloqueio da bomba X2.
11. Ligue a bomba X2.
12. Confirme que o diferencial de pressão é menor ou igual a 20 kPa.

## Resultado esperado

A bomba X2 opera sem vazamento, e o diferencial de pressão permanece menor ou igual a 20 kPa por no mínimo 2 minutos.

## Registro

Registre o número de série do filtro e o diferencial de pressão na ordem de serviço.

