#!/bin/sh
cd /app
npm start &
nginx -g "daemon off;"