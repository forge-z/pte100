# Arquitetura de vocabulário

## Conceito antes da palavra

O registro identifica o conceito primeiro e associa formas linguísticas por localidade. Isso permite que `bateria` em um domínio elétrico e `bateria` em um domínio musical tenham IDs diferentes, enquanto traduções compartilham uma ponte conceitual.

## Resolução

Pacotes são aplicados nesta ordem: núcleo, localidade, domínio, organização e produto. O pacote mais específico pode escolher outra forma preferida, mas não mudar a definição do conceito herdado. Conflito de definição exige novo ID.

## Distribuição futura PTE-200

Um pacote terá manifesto, conceitos, assinatura ou digest, licença e changelog. Um lockfile registrará as versões exatas usadas pelo lint. Registros públicos aceitarão pacotes federados; vocabulários privados continuarão possíveis.

## Tradução

Equivalentes ligam conceitos, não apenas strings. Uma relação declara localidade de destino, termo, estado da revisão e observação de domínio. Ausência de equivalente deve permanecer explícita; ferramentas não inventam equivalência normativa.

