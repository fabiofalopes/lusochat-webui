# Setup Custom Open Web UI Docker 
- Carrega os logos da empresa;
- Setup [Web Search](https://docs.openwebui.com/tutorial/web_search/)

```shell
docker compose -f docker-compose.yaml -f docker-compose.searxng.yaml up -d
```