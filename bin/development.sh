#!/bin/sh

# variables
export NODE_ENV=development
export HOST=localhost:3000
export PORT=3000
export MONGO_URL="mongodb://localhost:27017/kbase"
export REDIS_HOST=localhost
export REDIS_PORT=6379

# flush the redis cache
echo "Flushing Redis: `redis-cli flushdb`"

# start the server
echo "Starting the server with Nodemon...\n"
nodemon start.js