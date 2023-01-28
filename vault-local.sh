#!/usr/bin/bash

# Make folder with secrets on local computer
mkdir $(pwd)/secrets
echo '{"secret1":"value1","secret2":"value2"}' > $(pwd)/secrets/secrets.json

# start local Vault instance with token value equals 'token'
docker run -d --cap-add=IPC_LOCK -e 'VAULT_LOCAL_CONFIG={"storage": {"file": {"path": "/vault/file"}}, "ui": true}' -e 'VAULT_DEV_ROOT_TOKEN_ID=token' -p 8200:8200 -v $(pwd)/secrets:/secrets --name vault-server vault server -dev

# Wait for the start of the container
until [ "`docker inspect -f {{.State.Status}} vault-server`"=="running" ]; do
    sleep 0.11;
done;
sleep 5

# Upload secrets to the Vault
docker exec -it vault-server sh -c 'export VAULT_TOKEN="token" VAULT_ADDR="http://127.0.0.1:8200" && export && vault kv put -mount=secret foo/bar/bas @/secrets/secrets.json'

# stop local Vault instance
docker stop vault-server && docker rm vault-server && docker ps -a

# Remove secrets
rm -r $(pwd)/secrets
