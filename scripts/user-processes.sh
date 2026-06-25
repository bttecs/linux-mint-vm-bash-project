#!/usr/bin/env bash
set -euo pipefail

current_user="${USER:-$(id -un)}"
ps_command="${PS_COMMAND:-ps aux}"

echo "Processes running for user: $current_user"
$ps_command | awk -v user="$current_user" 'NR == 1 || $1 == user'
