#!/bin/bash
set -e
mkdir -p /config
mkdir -p /config/plugin_uploads/highway_3d
cp -n /app/demo-assets/highway-bg.mp4 /config/plugin_uploads/highway_3d/current.mp4
exec /usr/bin/supervisord -c /etc/supervisor/conf.d/slopsmith-demo.conf
