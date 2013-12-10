#!/bin/sh

# variables
export NODE_ENV=production
export HOST=kb.beneaththeink.com
export PORT=8008
export MONGO_URL="mongodb://localhost:27017/kbase"
export REDIS_HOST=localhost
export REDIS_PORT=6379
export REDIS_DB=1
export MAILGUN_USER=postmaster@mg.beneaththeink.com
export MAILGUN_PASS=5dv7xz16lnw5

# start the server
node start.js > ./output.log 2>&1 &

# log PID for stopping
echo $! >> .pid

# logging
echo "PID = $!"
echo "Logging output to ./output.log"
echo "Stop with 'npm stop'"
echo ""