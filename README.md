# Setup for Custom Open Web UI + Ollama

1. Create a docker network

```shell
# docker network create <network_name>
```

```shell
docker network create ulht-web-ui_default # Meter ambos os containers na mesma network
```

2. Create volumes

```shell
# docker volume create <volume_name>
```

```shell
docker volume create open-webui-volume # volume para open web ui
```

```shell
docker volume create ollama-volume # volume para ollama
```

3. Run docker compose dentro de cada directoria

```shell

cd open-web-ui

docker compose -f docker-compose.yaml -f docker-compose.searxng.yaml up -d # sem ollama

# or 

docker compose -f docker-compose.yaml -f docker-compose.searxng.yaml -f docker-compose.ollama.yaml up -d

```

```shell

cd ollama

docker compose up -d

```