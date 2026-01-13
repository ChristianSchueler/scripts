#!/bin/bash

KEY="$1"
SERVER="$2"
PATH="/"

/usr/bin/ssh -i "$KEY" -o BatchMode=yes "$SERVER" "df -P -B1 '$PATH' | awk 'NR==2 {print \$5}'"
