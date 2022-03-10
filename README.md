# Implementação personalizada do dokku para GitHub Actions

Implante um aplicativo no servidor dokku por SSH.

## Uso

Para usar a ação, adicione as seguintes linhas ao seu `.github/workflows/main.yml`

```yaml
name: deploy

on: pull_request

jobs:
  deploy:
    runs-on: ubuntu-18.04
    steps:
      - uses: actions/checkout@v1
      - name: Deploy the application
        uses: joathan/deploy-dokku-action@main
        with:
          PRIVATE_KEY: ${{ secrets.SSH_PRIVATE_KEY }}
          PUBLIC_KEY: ${{ secrets.SSH_PUBLIC_KEY }}
          HOST: ${{ secrets.DOKKU_HOST }}
          PROJECT: nome-projeto
          BRANCH: ${{ github.head_ref }}
          PROJECT_TYPE: ruby
```
