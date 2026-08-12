# probe_api_shapes

Pergunta à API o que ela realmente devolve, em vez de inferir da collection.

## Por que existe

Toda decisão sobre forma de resposta na 0.2.0 foi inferida. A collection
documenta `204` com corpo vazio para `PATCH /charge/settle/:id`, mas *"um write
pode responder `200 {}`"* e *"uma lista pode responder com array de topo"* eram
**hipóteses minhas**, não fatos. Uma delas se mostrou errada, e uma correção
inteira foi justificada com uma premissa falsa:

> `Conexa::Company.all` emite `/companys` e **não pode funcionar** contra um
> tenant real.

Falso. A API roteia as duas grafias. A correção continua certa — alinhar com a
documentação —, mas a severidade estava inventada. Este script existe para que a
próxima afirmação dessas seja verificada antes de virar release note.

## Uso

```bash
CONEXA_API_HOST=https://seutenant.conexa.app \
CONEXA_API_TOKEN=... \
ruby claude_scripts/probe_api_shapes/probe.rb
```

Para o tenant da Checkbits, a chave está no Passbolt (recurso `Conexa`, na nota)
e a skill `/ckbt-conexa` já a busca sozinha — use `conexa.py raw "/rota"` para
consultas pontuais em vez de exportar a chave à mão.

## Segurança

**Só leitura.** Três camadas, deliberadamente redundantes porque isso fala com
produção:

1. `config.read_only = true` — o guard do próprio gem recusa qualquer verbo que
   não seja `GET` antes de a requisição sair do processo;
2. o script só constrói requisições `GET`;
3. nenhum endpoint que move dinheiro aparece na lista.

**Não existe modo de escrita, e isso é intencional.** A skill `ckbt-conexa`
estabelece a regra para este tenant: *"Nada aqui escreve — se precisar escrever,
faça pela interface, conscientemente."* Chegou-se a desenhar um nível 2 que
sondaria writes com id inexistente (a API distingue "rota não existe" de "recurso
não existe", o que confirmaria as correções de verbo sem executar nada). Foi
descartado: respondia **uma** pergunta em aberto, contra o risco de quebrar essa
regra com a chave de produção.

**Só imprime forma.** Status, se o corpo é vazio, tipo de topo, nomes de chaves,
contagens. Nunca valores. Ids lidos da listagem são usados na URL do probe
seguinte e nunca impressos. A saída é segura de commitar.

**60 requisições por minuto** é o limite da API (`x-rate-limit-limit`); o script
espera 1,1s entre chamadas.

## Resultado de 2026-08-12

| Pergunta | Resposta |
|---|---|
| Envelope das listas | `{data, pagination:{hasNext, limit, offset}}`, uniforme |
| Alguma lista devolve array de topo? | **Não** — o tratamento no gem é defensivo, não observado |
| `/companys` vs `/companies` | **As duas roteiam**; a API não é permissiva em geral (`/companyzzz` dá 404) |
| `/accounts`, `/suppliers`, `/serviceCategories` | Existem, apesar de ausentes da collection |
| Leituras de `/creditCard` | **Não existem** — só `POST /creditCard` é real |
| Formas de erro | `400 {message, errors:[{field, messages}]}` e `404 {message}` |

Em aberto, porque exige escrita: se um write bem-sucedido chega a responder
`200 {}` em vez de `204` sem corpo. O gem trata os dois.
