#!/usr/bin/env bash
set -euo pipefail

current_user="${USER:-$(id -un)}"
ps_command="${PS_COMMAND:-ps aux}"

read -r -p "Sort processes by memory or cpu? " sort_choice

case "$sort_choice" in
  memory|mem)
    sort_column=4
    label="memory"
    ;;
  cpu)
    sort_column=3
    label="CPU"
    ;;
  *)
    echo "Invalid sort option. Use memory or cpu." >&2
    exit 1
    ;;
esac

echo "Processes running for user $current_user sorted by $label:"
$ps_command |
  awk -v user="$current_user" 'NR == 1 || $1 == user' |
  awk -v column="$sort_column" 'NR == 1 {print; next} {print | "sort -k" column "," column " -nr"}'
