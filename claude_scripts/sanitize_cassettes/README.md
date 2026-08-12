# sanitize_cassettes

Anonimiza cassettes do VCR que foram gravadas contra um tenant real do Conexa.

## Por que existe

Gravar uma cassette apontando para um tenant real embute na fixture tudo que
passou pela requisição: o token do header `Authorization`, o host, e os dados
cadastrais que vieram na resposta. Foi o que aconteceu com
`spec/cassettes/customer.yml`.

Este script faz a limpeza e fica versionado para poder ser rodado de novo sempre
que alguém regravar uma cassette contra dados reais.

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
no bloco do VCR, então o token nunca chega a ser gravado numa cassette nova.
Isso cobre só o header — dados pessoais no corpo da resposta continuam por conta
deste script.
