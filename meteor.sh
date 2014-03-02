#!/bin/bash -e
#
[ -z "$APP_HOST" ] && { echo "Need to set APP_HOST"; exit 1; }
[ -z "$APP_NAME" ] && { echo "Need to set APP_NAME"; exit 1; }
[ -z "$PORT" ] && { echo "Need to set PORT"; exit 1; }

# You usually don't need to change anything below this line
NODE_ENV=production
ROOT_URL=http://$APP_HOST:$PORT
APP_DIR="~/$APP_NAME"
MONGO_URL=mongodb://localhost:27017/$APP_NAME
SSH_HOST=$APP_HOST SSH_OPT=""
if [ -d ".meteor/meteorite" ]; then
    METEOR_CMD=mrt
  else
    METEOR_CMD=meteor
fi

case "$1" in
deploy )
echo Deploying...
$METEOR_CMD bundle bundle.tgz
scp $SSH_OPT bundle.tgz $SSH_HOST:/tmp/
rm bundle.tgz
ssh $SSH_OPT $SSH_HOST NODE_ENV=$NODE_ENV PORT=$PORT MONGO_URL=$MONGO_URL ROOT_URL=$ROOT_URL APP_DIR=$APP_DIR 'bash -s' <<'ENDSSH'
if [ ! -d "$APP_DIR" ]; then
mkdir -p $APP_DIR
fi
forever stop $APP_DIR/bundle/main.js
pushd $APP_DIR
rm -rf bundle
tar xfz /tmp/bundle.tgz -C $APP_DIR
rm /tmp/bundle.tgz
pushd bundle/programs/server/node_modules
rm -rf fibers
npm install fibers@1.0.1
popd
popd
forever start $APP_DIR/bundle/main.js
ENDSSH
echo Your app is deployed and serving on: $ROOT_URL
;;
restart )
echo Restarting...
ssh $SSH_OPT $SSH_HOST NODE_ENV=$NODE_ENV PORT=$PORT MONGO_URL=$MONGO_URL ROOT_URL=$ROOT_URL APP_DIR=$APP_DIR 'bash -s' <<'ENDSSH'
forever stop $APP_DIR/bundle/main.js
forever start $APP_DIR/bundle/main.js
ENDSSH
;;
* )
cat <<'ENDCAT'
./meteor.sh [action]

Available actions:

  deploy - Deploy the app to the server
  restart - Restart the app on the server
ENDCAT
;;
esac
