#!/bin/bash

echo "Booyah from port ${server_port}" > index.html
nohup busybox httpd -f -p "${server_port}" &