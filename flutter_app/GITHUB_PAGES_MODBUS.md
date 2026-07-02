# GitHub Pages com Modbus TCP

O navegador não abre conexão TCP Modbus diretamente. No GitHub Pages a tela
Flutter Web conversa por WebSocket com um bridge, e o bridge fala Modbus TCP
com o equipamento.

Fluxo:

```text
GitHub Pages (HTTPS) -> WSS bridge -> IP:porta Modbus do equipamento
```

## Campos configuráveis na tela

- `IP do CLP ou gateway`: IP do equipamento Modbus.
- `Porta Modbus do equipamento`: porta real do equipamento. Não precisa ser
  `502`; pode ser `4000`, `1502` ou outra porta configurada.
- `Unit ID`: endereço do escravo.
- `Bridge WebSocket para uso web`: endpoint do bridge. Em produção via
  GitHub Pages prefira `wss://...`, porque a página é HTTPS.

## Query string

A página também aceita configuração por URL:

```text
https://seu-usuario.github.io/seu-repo/?bridge=wss://bridge.seudominio.com:4000&ip=192.168.0.10&modbusPort=4000&unit=1&period=1000
```

Aliases aceitos:

- Bridge: `bridge`, `bridgeUrl`, `ws`
- IP: `ip`, `host`
- Porta Modbus: `modbusPort`, `mbport`, `targetPort`, `port`
- Unit ID: `unit`, `unitId`
- Período: `period`, `poll`, `pollMs`

Os valores também ficam salvos no `localStorage` do navegador.

## Bridge local para teste

```powershell
dart run bin/modbus_bridge.dart --bind 127.0.0.1 --port 4000
```

## Bridge em rede/produção

Para publicar a tela no GitHub Pages e acessar de outros computadores,
execute o bridge em um servidor acessível pela rede e coloque TLS/reverse proxy
na frente dele para expor `wss://`.

Exemplo de execução sem TLS, útil apenas em rede/local:

```powershell
dart run bin/modbus_bridge.dart --bind 0.0.0.0 --port 4000
```

Para GitHub Pages, o recomendado é expor essa porta como `wss://` usando
Nginx, Caddy, Traefik ou outro proxy com certificado.
