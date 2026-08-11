# claude_scripts

Scripts de apoio ao desenvolvimento local do gem `conexa`. Não fazem parte do gem
publicado.

Para rodar a suíte em todas as versões de Ruby suportadas use `rake spec:all` —
é uma rake task, não um script daqui, porque o entry point padrão de um gem Ruby
é o `rake`.

| Pasta | O que faz |
|-------|-----------|
| [sanitize_cassettes/](sanitize_cassettes/) | Anonimiza cassettes do VCR gravadas contra um tenant real (token + PII de clientes). |
