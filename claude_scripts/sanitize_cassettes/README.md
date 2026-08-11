# sanitize_cassettes

Anonimiza cassettes do VCR que foram gravadas contra um tenant real do Conexa.

## Por que existe

`spec/cassettes/customer.yml` foi gravada em 2024-10-18 contra o tenant de
**produção** `checkbits.conexa.app` e commitada num repositório **público**. Ela
carregava:

- um Bearer token de API válido (3 ocorrências);
- ~120 clientes reais — razão social, CNPJ/CPF, e-mails, telefones e endereços.

O token foi rotacionado e a cassette saneada. Este script é o que fez o saneamento
e fica versionado para poder ser rodado de novo caso alguém regrave uma cassette
contra dados reais.

## Uso

```bash
ruby claude_scripts/sanitize_cassettes/sanitize.rb spec/cassettes/customer.yml
```

Reescreve o arquivo no lugar. É idempotente: as substituições são determinísticas,
derivadas do `customerId` de cada registro, então rodar duas vezes dá o mesmo
resultado e as expectativas dos specs continuam estáveis.

## O que muda e o que não muda

| Muda | Fica |
|------|------|
| host `checkbits.conexa.app` → `test.conexa.app` | ids, `companyId`, `customerId` |
| token de 64 hex → `test_token` | booleanos, datas, `pagination` |
| razão social, nome fantasia, nome | cidade e estado (`address.state`) |
| CNPJ, CPF (formato válido, dígitos sintéticos) | estrutura do JSON: chaves, tipos, `null`s |
| e-mails, telefones, login, website | `taxDeductions` e demais dados de referência |
| logradouro, número, bairro, CEP, complemento | |

Preservar a forma exata do JSON é o ponto: os specs continuam exercitando a mesma
estrutura de resposta, só que sobre dados sintéticos.

## Prevenção

`spec/spec_helper.rb` agora tem
`config.filter_sensitive_data("<API_TOKEN>") { Conexa.configuration&.api_token }`
no bloco do VCR, para que gravações futuras não repitam o vazamento do token.
Isso não cobre PII do corpo da resposta — para isso, rode este script.
