# Handoff — validar a 0.2.1 antes de publicar

Este documento é para quem vai **testar o gem contra o Conexa de verdade**, a
partir do repositório, antes de a 0.2.1 ir para o RubyGems.

Não precisa conhecer o histórico. O que você precisa saber é: a 0.1.1 estava
quebrada em produção, a 0.2.0 corrigiu dez defeitos, e a 0.2.1 corrige mais três
que só apareceram quando alguém perguntou à API em vez de ler a documentação.
Queremos que a mesma coisa aconteça mais uma vez antes de publicar.

---

## 1. Apontar o seu projeto para o repositório

No `Gemfile` do projeto que consome o gem, troque a linha do `conexa` por:

```ruby
gem "conexa", github: "guilhermegazzinelli/conexa-ruby", branch: "main"
```

Ou, para testar antes do merge:

```ruby
gem "conexa", github: "guilhermegazzinelli/conexa-ruby",
              branch: "fix/contract-predicates-issue-23"
```

Depois `bundle install`. Se preferir trabalhar com o gem na mão:

```bash
git clone git@github.com:guilhermegazzinelli/conexa-ruby.git
cd conexa-ruby
bundle install
bundle exec rspec          # 666 exemplos, deve dar 0 falhas
```

> Se o `bundle install` reclamar de `io-console`, rode
> `bundle config set --local without development` — é um debugger opcional que
> não compila em alguns Ruby, e nada da suíte depende dele.

---

## 2. Ligue o modo somente-leitura antes de qualquer coisa

Esta é a parte mais importante do handoff. O gem fala com o sistema de cobrança:
`Charge#settle` movimenta dinheiro e pode emitir NF-e. **Comece testando sem
poder escrever.**

```ruby
Conexa.configure do |config|
  config.api_host  = "https://seutenant.conexa.app"
  config.api_token = ENV["CONEXA_API_TOKEN"]
  config.read_only = true
end
```

Ou, sem tocar no código, exporte `CONEXA_READ_ONLY=1` no ambiente.

Com isso ligado, qualquer requisição que não seja `GET` levanta
`Conexa::ReadOnlyError` **antes de sair do processo** — não chega ao seu tenant.
A única exceção é `POST /auth`, sem a qual não daria para obter token.

Confira que está valendo antes de continuar:

```ruby
Conexa.read_only?                  # => true
Conexa::Charge.settle(1)           # => Conexa::ReadOnlyError
```

Para um trecho específico sem reconfigurar tudo: `Conexa.read_only { ... }`.
Atenção: o bloco é fiber-local e **não alcança** uma `Thread` criada dentro dele.
Para qualquer coisa concorrente, use `config.read_only`, que é global.

---

## 3. O que mudou e o que testar

### 3.1 Contrato: saber se está ativo

**O que estava errado:** `Contract#active?` comparava um campo `status` que
contrato nunca teve. Respondia `false` para contrato ativo.

Isso importa porque a pergunta que esse predicado responde é *"este cliente já
tem contrato ativo?"* — a guarda entre não fazer nada e **criar um contrato
duplicado**.

```ruby
contrato = Conexa::Contract.find(SEU_ID)
contrato.active?     # true para aberto, false para encerrado
contrato.ended?
contrato.is_active   # o campo cru que a API manda
```

**Como validar:** pegue um contrato que você sabe estar ativo e um encerrado, e
confira que os predicados concordam com a tela do Conexa.

**Cuidado que vale conhecer:** um contrato **ativo** pode ter `end_date` no
futuro — encerramento agendado não é encerramento. Se o seu código deduz
"encerrado" da presença de `end_date`, ele está invertendo a resposta.

Se `active?` devolver `nil`, significa que a resposta não trouxe `is_active` —
o gem prefere admitir que não sabe a chutar. Nos reporte se isso acontecer.

### 3.2 Cobrança: saber se está em aberto

**O que estava errado:** `Charge#pending?` e `#overdue?` comparavam valores que a
API rejeita. Ambos respondiam `false` sempre.

O estado em aberto chama-se **`unpaid`**:

```ruby
cobranca.unpaid?      # em aberto  <- era pending?
cobranca.paid?
cobranca.cancelled?
Conexa::Charge::STATUSES   # a lista completa que a API aceita
```

`pending?` continua funcionando como alias deprecado (avisa no stderr).
`overdue?` avisa e devolve `false`: a API não tem esse estado — cobrança vencida
é `unpaid` com `due_date` no passado, e a comparação de data é sua.

**Como validar:** se você tem régua de cobrança, o teste que importa é
*"não cobrar quem já pagou"*. Rode a consulta que a régua faz e confira que
`unpaid?` separa certo.

### 3.3 Cartão de crédito virou somente escrita

A API v2 não expõe leitura de cartão. `CreditCard.all` e `.find` agora levantam
`Conexa::RequestError` explicando isso, em vez de devolver um 404 que parece
"esse cartão não existe". `CreditCard.create` continua funcionando normalmente.

**Se você usa `CreditCard.find`, seu código vai quebrar** — mas ele já não
funcionava; só falhava de um jeito menos claro.

### 3.4 Vindo da 0.1.1? Estas mudanças quebram

Se o projeto ainda está na 0.1.1, além do acima:

| Antes | Agora |
|---|---|
| `Contract.end_contract(id, end_date: ...)` | `date:` — `end_date:` funciona com aviso |
| `.all(page: 2, size: 50)` | convertido para `limit`/`offset` automaticamente |
| escrita com corpo vazio levantava `NoMethodError` | retorna normalmente |
| listagem podia devolver `nil` | sempre devolve `Conexa::Result` |
| Ruby 2.6+ | Ruby 3.1+ |
| `Conexa::TokenManager`, `Client`, `Authenticator`, `OrderCommon` | removidos (não funcionavam) |

Mensagens de erro ficaram utilizáveis:

```ruby
rescue Conexa::ResponseError => e
  e.api_error_codes      # ["CHARGE_11"] — dá para decidir com isso
  e.api_error_messages   # texto legível, das duas formas de erro da API
end
```

---

## 4. Quando for testar escrita

Só depois que a leitura estiver validada. Desligue o modo leitura **para o trecho
específico**, não globalmente:

```ruby
Conexa.configuration.read_only = false
# ... a operação
Conexa.configuration.read_only = true
```

O que mais vale testar, em ordem de risco:

1. **`Contract.set_end_date(id, date: "...")`** — o método antes mandava `POST` e
   dava 404. Confira que encerra e que a data bate. Lembre que o mesmo endpoint
   **reabre** um contrato encerrado se receber data futura.
2. **`Contract.create`** — se o cliente já tem contrato, **não mande `due_day`**;
   a API rejeita com `CONTRACT_RECURRING_SALE_10`. Só o primeiro contrato aceita.
3. **`Charge.settle`** — o mais arriscado. Antes mandava `POST` e dava 404; agora
   manda `PATCH` e funciona. Teste numa cobrança que possa ser quitada de
   verdade, e confira o extrato depois.
4. **Payloads com arrays** (`complementary_services`, `devices`, `product_quotas`)
   — antes eram rejeitados; agora devem passar.

---

## 5. O que nos reportar

Abra issue em <https://github.com/guilhermegazzinelli/conexa-ruby/issues>. O que
mais ajuda:

- o método chamado e os parâmetros
- o que você esperava e o que aconteceu
- a mensagem da exceção
- se der, o corpo cru da resposta — **sem token e sem dado de cliente**

Um relato que já sabemos ser útil: *"a API devolveu um campo que o gem não
modela"* ou *"o gem lê um campo que a API não manda"*. Foi assim que a #23
apareceu, e é o tipo de coisa que só quem usa encontra.

---

## 6. Coisas que ainda não sabemos

Preferimos dizer do que você descobrir sozinho:

- **Se uma escrita bem-sucedida pode responder `200 {}`** em vez de `204` sem
  corpo. O gem trata os dois, mas nunca vimos o primeiro.
- **`CreditCard#save` e `#destroy`** não são documentados e não foram
  verificados. Continuam no gem; um 404 deles é esperado, não bug.
- **A collection omite campos** que a API devolve — `isActive`, `firstDueDate` e
  `extraFields` no `GET /contract/:id`. Já reportamos ao time do Conexa.

---

## 7. Se quiser ir mais fundo

O repositório carrega a documentação viva do projeto em `.okf/` — um conceito por
defeito, com a verificação que o confirmou, mais o contrato da API e as decisões.
Vale como referência quando algo surpreender:

- `.okf/api/conexa-api-v2.md` — o que a API faz e o que só descobrimos sondando
- `.okf/defects/` — os dez defeitos, o que cada um causava, como foi provado
- `.okf/operations/validating-against-the-api.md` — como checar uma dúvida sobre
  a API sem tenant de teste, com a lista do que nunca é tocado

E `claude_scripts/probe_api_shapes/` é uma sonda somente-leitura que responde
"que forma tem a resposta deste endpoint?" sem risco algum.
