#!/bin/bash

set -e

SSH_PATH="$HOME/.ssh"

mkdir -p "$SSH_PATH"
touch "$SSH_PATH/known_hosts"

echo "$PRIVATE_KEY" > "$SSH_PATH/id_rsa"
echo "$PUBLIC_KEY" > "$SSH_PATH/id_rsa.pub"

chmod 700 "$SSH_PATH"
chmod 600 "$SSH_PATH/known_hosts"
chmod 600 "$SSH_PATH/id_rsa"
chmod 600 "$SSH_PATH/id_rsa.pub"

eval "$(ssh-agent)"

echo $PUBLIC_KEY | sed 's/./& /g'
echo "adding deploy key..."

ssh-add "$SSH_PATH/id_rsa"

echo "adding host address to known hosts..."

ssh-keyscan -t rsa "$HOST" >> "$SSH_PATH/known_hosts"

echo "checkout git branch...$BRANCH"

git checkout "$BRANCH"

echo "calling deploy scripts.."

APP_NAME=$(echo $BRANCH | cut -d'/' -f 2)

echo "REVIEW APP= $REVIEW_APP"
if [ "$REVIEW_APP" = false ]; then
  APP_NAME="${PROJECT}"
else
  APP_NAME="${PROJECT}-${APP_NAME}"
fi

echo "APP NAME=$APP_NAME"

CREATE_APP_COMMAND="sh ./scripts/deploy.sh $APP_NAME"

SET_VARIABLES_COMMAND="bash ./scripts/variables.sh $PROJECT $APP_NAME"
POST_DEPLOY_COMMAND="sh ./scripts/after_deploy.sh $APP_NAME"

echo "======== $PROJECT_TYPE project ========"
echo $CREATE_APP_COMMAND
echo $SET_VARIABLES_COMMAND
echo "======================================="

ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$HOST $CREATE_APP_COMMAND
ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$HOST $SET_VARIABLES_COMMAND

if [ "$POSTGRES" = true ]; then
  CREATE_POSTGRES_COMMAND="sh ./scripts/postgres.sh $APP_NAME"
  echo "Configurando instancia POSTGRES...aguarde!"
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$HOST $CREATE_POSTGRES_COMMAND
fi

if [ "$REDIS" = true ]; then
  CREATE_REDIS_COMMAND="sh ./scripts/redis.sh $APP_NAME"
  echo "Configurando instancia REDIS...aguarde!"
  ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$HOST $CREATE_REDIS_COMMAND
fi


GIT_SSH_COMMAND="ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no" git push -f root@"$HOST":"$APP_NAME" "$BRANCH":main

ssh -o UserKnownHostsFile=/dev/null -o StrictHostKeyChecking=no root@$HOST $POST_DEPLOY_COMMAND
