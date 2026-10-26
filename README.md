# DollarApple

Cotação do dólar comercial (e de outras moedas) em reais, na barra superior do macOS.
Mostra `R$ 5,13` ao lado do relógio; ao clicar abre um conversor, o gráfico dos últimos
30 dias e as outras moedas que você escolher. Em português e inglês.

*The US dollar (and other currencies) in Brazilian reais, in the macOS menu bar. English
version of this README is below.*

## Instalação

Requer macOS 14 (Sonoma) ou mais recente, Apple Silicon ou Intel.

Compile a partir do código-fonte (veja Desenvolvimento): `make install` copia para
`/Applications`. O build é assinado ad-hoc, então na primeira abertura clique com o botão
direito em `Abrir`, ou rode `xattr -d com.apple.quarantine /Applications/DollarApple.app`.

Na primeira execução a partir de `/Applications`, o app se registra para abrir junto com o
login. Isso pode ser desligado em Preferências › Geral.

## O que ele faz

- Barra: uma moeda à sua escolha, `R$ 5,13 ▲`, opcionalmente com a variação do dia.
- Popover: cotação grande, variação, horário, botão de copiar, gráfico dos últimos 30 dias,
  conversor nos dois sentidos e a lista das outras moedas ativas (clique para trocar).
- Moedas: USD, EUR, GBP, BTC, ARS, CAD, AUD, JPY, CHF e CNY, sempre em BRL.
- Alertas: notificação do macOS quando uma cotação passa acima ou abaixo de um valor.
  Dispara uma vez e rearma quando a cotação volta.
- Preferências: moeda da barra, variação na barra, intervalo (1/5/15/30 min), moedas ativas,
  alertas, abrir ao iniciar, verificar atualizações.
- Atualização automática pelo Sparkle no build direto. Na App Store, a loja cuida disso.
- Sem conta, sem coleta de dados. A única conexão é com a
  [AwesomeAPI](https://docs.awesomeapi.com.br/api-de-moedas) (e com o GitHub para checar
  atualizações no build direto).

Números seguem o idioma do sistema: um Mac em português mostra `5,13`, um Mac em inglês
`5.13`. Valores abaixo de 1 (peso, iene) usam 4 casas; acima de 10.000 (bitcoin) não mostram
centavos.

## Desenvolvimento

Xcode 26 (Swift 6). Sem projeto Xcode: é um pacote SwiftPM.

```bash
make test        # 54 testes do DollarCore (Swift Testing)
make run         # build direto (com Sparkle), assina ad-hoc e abre dist/DollarApple.app
make install     # copia para /Applications e abre
make app-store   # build sandboxed sem Sparkle em dist/store/
make strings     # regenera os .lproj a partir de Packaging/Localizable.xcstrings
make icon        # regenera Packaging/AppIcon.icns
```

Layout:

- `Sources/DollarCore`: Foundation puro e testado. Moedas, decodificação da API, cache,
  preferências, alertas, formatação, conversão e o `RatesStore`. É a parte portável.
- `Sources/DollarAppleUI`: SwiftUI (`MenuBarExtra`, popover, preferências, notificações) e
  os recursos localizados.
- `Sources/DollarApple` e `Sources/DollarAppleStore`: executáveis finos. O primeiro injeta o
  Sparkle, o segundo um updater vazio.
- `Packaging/`: Info.plists, entitlements, ícone, catálogo de strings.
- `scripts/`: montagem do `.app`, assinatura e geração dos `.lproj`.

Dois detalhes que custaram tempo e estão documentados no código: o `Bundle.module` gerado
pelo SwiftPM aponta para o diretório de build, o que trava um app aberto pelo Finder atrás
de um pedido de permissão da pasta Documentos (resolvido em `L10n.swift`); e o `swift build`
copia o `.xcstrings` sem compilar, então os `.lproj` são gerados por `scripts/gen-strings.py`
e commitados.

## Licença

MIT. Veja `LICENSE`.

---

## English

DollarApple shows the commercial USD/BRL rate (and other currencies against the Brazilian
real) in the macOS menu bar. Click it for a converter, a 30-day chart and your other
currencies. Portuguese and English UI.

**Install**: macOS 14 or newer. Build from source with `make install`. The build is ad-hoc
signed, so right-click › Open on first launch or run
`xattr -d com.apple.quarantine /Applications/DollarApple.app`.

**Features**: one currency in the bar (with optional daily change), popover with quote, copy
button, 30-day sparkline, two-way converter and the other enabled currencies; ten currencies
(USD, EUR, GBP, BTC, ARS, CAD, AUD, JPY, CHF, CNY) priced in BRL; threshold alerts as macOS
notifications; preferences for bar currency, refresh interval, currencies, alerts and launch
at login; Sparkle self-update on the direct build. No accounts, no analytics.

**Develop**: `make test`, `make run`, `make install`, `make app-store`. See the Portuguese
section for the layout.
