#!/usr/bin/env bash
set -euo pipefail

echo "== Distribution =="
if [[ -r /etc/os-release ]]; then
  . /etc/os-release
  echo "Name: ${NAME:-unknown}"
  echo "Version: ${VERSION:-unknown}"
  echo "ID: ${ID:-unknown}"
else
  echo "Could not read /etc/os-release"
fi

echo
echo "== Package Managers =="
for manager in apt apt-get yum; do
  if command -v "$manager" >/dev/null 2>&1; then
    echo "$manager: installed at $(command -v "$manager")"
  else
    echo "$manager: not installed"
  fi
done

echo
echo "== CLI Editors =="
for editor in nano vi vim; do
  if command -v "$editor" >/dev/null 2>&1; then
    echo "$editor: installed at $(command -v "$editor")"
  else
    echo "$editor: not installed"
  fi
done

echo
echo "== Configured Editor =="
echo "EDITOR: ${EDITOR:-not set}"
echo "VISUAL: ${VISUAL:-not set}"

echo
echo "== Software Manager =="
if command -v mintinstall >/dev/null 2>&1; then
  echo "Software Manager: mintinstall at $(command -v mintinstall)"
else
  echo "Software Manager: mintinstall not found"
fi

echo
echo "== User Shell =="
current_user="${USER:-$(id -un)}"
if command -v getent >/dev/null 2>&1; then
  shell_path="$(getent passwd "$current_user" | cut -d: -f7)"
else
  shell_path="$(awk -F: -v user="$current_user" '$1 == user {print $7}' /etc/passwd)"
fi

echo "User: $current_user"
echo "Shell: ${shell_path:-unknown}"
