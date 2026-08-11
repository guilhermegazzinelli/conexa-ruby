# multi_ruby_specs

Roda a suíte em todas as versões de Ruby suportadas, localmente, antes de empurrar
para o CI.

## Por que existe

O gemspec declara `required_ruby_version >= 3.1` e o CI cobre a matriz 3.1–3.4.
Descobrir uma incompatibilidade pelo CI custa um ciclo de push; rodar as quatro
localmente custa alguns minutos.

## Uso

```bash
claude_scripts/multi_ruby_specs/run.sh           # specs em 3.1.7, 3.2.9, 3.3.10, 3.4.7
claude_scripts/multi_ruby_specs/run.sh --lint    # e também o rubocop na primeira
RUBIES="3.1.7 3.4.7" claude_scripts/multi_ruby_specs/run.sh
```

Sai com status diferente de zero se qualquer versão falhar, e imprime um resumo
com uma linha por versão. Versões não instaladas são marcadas `SKIP` em vez de
derrubar a execução — instale com `mise install ruby@X.Y.Z`.

## Detalhes que importam

- **`BUNDLE_PATH` por versão** (`vendor/bundle-3.1.7`, ...). Extensões nativas não
  são portáveis entre versões de Ruby; compartilhar `vendor/bundle` faz cada
  execução sobrescrever a anterior e produz erros confusos.
- **`BUNDLE_WITHOUT=development`**, que pula `debug`/`byebug`. A cadeia
  `debug → irb → reline → io-console` tem extensão nativa que não compila em
  algumas combinações de Ruby/GCC — foi exatamente o que impedia
  `bundle exec rspec` de subir no Ruby 3.1.7 aqui. Nada da suíte depende deles.
- Requer o `mise`. Sem ele, defina `RUBIES` para versões já no `PATH`.
