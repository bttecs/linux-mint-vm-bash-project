#!/usr/bin/env bash
set -euo pipefail

ARTIFACT_URL="https://node-envvars-artifact.s3.eu-west-2.amazonaws.com/bootcamp-node-envvars-project-1.0.0.tgz"
APP_ENV="${APP_ENV:-dev}"
DB_USER="${DB_USER:?DB_USER must be set before running this script}"
DB_PWD="${DB_PWD:?DB_PWD must be set before running this script}"
APP_USER="myapp"
WORK_DIR="/tmp/bootcamp-node-envvars"
LOG_DIR_INPUT="${1:-app-logs}"

require_root() {
  if [[ "$(id -u)" -ne 0 ]]; then
    echo "Run this script with sudo because it installs packages and creates a service user." >&2
    exit 1
  fi
}

install_node() {
  if command -v apt-get >/dev/null 2>&1; then
    apt-get update
    apt-get install -y nodejs npm curl tar
  elif command -v apt >/dev/null 2>&1; then
    apt update
    apt install -y nodejs npm curl tar
  else
    echo "This script currently supports apt/apt-get systems such as Linux Mint." >&2
    exit 1
  fi

  echo "NodeJS version: $(node --version)"
  echo "NPM version: $(npm --version)"
}

prepare_log_dir() {
  mkdir -p "$LOG_DIR_INPUT"
  LOG_DIR="$(cd "$LOG_DIR_INPUT" && pwd)"
  export LOG_DIR
  echo "LOG_DIR=$LOG_DIR"
}

download_app() {
  rm -rf "$WORK_DIR"
  mkdir -p "$WORK_DIR"
  curl -fsSL "$ARTIFACT_URL" -o "$WORK_DIR/app.tgz"
  tar -xzf "$WORK_DIR/app.tgz" -C "$WORK_DIR"

  APP_DIR="$(find "$WORK_DIR" -maxdepth 2 -type f -name package.json -exec dirname {} \; | head -n 1)"
  if [[ -z "$APP_DIR" ]]; then
    echo "Could not find package.json after extracting the artifact." >&2
    exit 1
  fi
  export APP_DIR
  echo "Application directory: $APP_DIR"
}

create_service_user() {
  if id "$APP_USER" >/dev/null 2>&1; then
    echo "Service user $APP_USER already exists."
  else
    useradd -m -s /bin/bash "$APP_USER"
    echo "Created service user: $APP_USER"
  fi

  chown -R "$APP_USER:$APP_USER" "$APP_DIR" "$LOG_DIR"
}

run_as_app_user() {
  local command="$1"
  runuser -u "$APP_USER" -- bash -lc "$command"
}

start_app() {
  run_as_app_user "cd '$APP_DIR' && npm install"
  run_as_app_user "cd '$APP_DIR' && APP_ENV='$APP_ENV' DB_USER='$DB_USER' DB_PWD='$DB_PWD' LOG_DIR='$LOG_DIR' nohup node server.js > '$LOG_DIR/app-console.log' 2>&1 &"
  sleep 3
}

print_status() {
  local pid
  local port

  pid="$(pgrep -u "$APP_USER" -f 'node server.js' | head -n 1 || true)"
  if [[ -z "$pid" ]]; then
    echo "Node application did not start successfully." >&2
    echo "Console log:"
    cat "$LOG_DIR/app-console.log" 2>/dev/null || true
    exit 1
  fi

  echo "Application process:"
  ps -p "$pid" -o user,pid,ppid,%cpu,%mem,command

  port="$(
    ss -ltnp 2>/dev/null |
      awk -v pid="$pid" '$0 ~ "pid=" pid "," {print $4}' |
      awk -F: '{print $NF}' |
      head -n 1
  )"

  if [[ -n "$port" ]]; then
    echo "Application is listening on port: $port"
  else
    echo "Application is running, but the listening port could not be detected with ss."
  fi
}

require_root
install_node
prepare_log_dir
download_app
create_service_user
start_app
print_status
