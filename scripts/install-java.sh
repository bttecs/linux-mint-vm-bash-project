#!/usr/bin/env bash
set -euo pipefail

JAVA_COMMAND="${JAVA_COMMAND:-java}"
CHECK_ONLY=false

if [[ "${1:-}" == "--check-only" ]]; then
  CHECK_ONLY=true
fi

run_as_root() {
  if [[ "$(id -u)" -eq 0 ]]; then
    "$@"
  elif command -v sudo >/dev/null 2>&1; then
    sudo "$@"
  else
    echo "This command requires root privileges and sudo is not installed." >&2
    return 1
  fi
}

install_java() {
  if command -v apt-get >/dev/null 2>&1; then
    run_as_root apt-get update
    run_as_root apt-get install -y default-jdk
  elif command -v apt >/dev/null 2>&1; then
    run_as_root apt update
    run_as_root apt install -y default-jdk
  elif command -v dnf >/dev/null 2>&1; then
    run_as_root dnf install -y java-latest-openjdk
  elif command -v yum >/dev/null 2>&1; then
    run_as_root yum install -y java-11-openjdk
  elif command -v zypper >/dev/null 2>&1; then
    run_as_root zypper --non-interactive install java-11-openjdk
  elif command -v apk >/dev/null 2>&1; then
    run_as_root apk add openjdk17
  else
    echo "No supported package manager found." >&2
    return 1
  fi
}

java_version_output() {
  "$JAVA_COMMAND" -version 2>&1 || true
}

java_major_version() {
  awk -F '"' 'NR == 1 {print $2}' |
    awk -F '.' '{if ($1 == 1) print $2; else print $1}'
}

check_java() {
  local output
  local major

  if ! command -v "$JAVA_COMMAND" >/dev/null 2>&1; then
    echo "Java is not installed or not available in PATH."
    return 1
  fi

  output="$(java_version_output)"
  echo "$output"

  major="$(printf '%s\n' "$output" | java_major_version)"
  if [[ -z "$major" || ! "$major" =~ ^[0-9]+$ ]]; then
    echo "Java is installed, but the version could not be detected."
    return 1
  fi

  if (( major < 11 )); then
    echo "Java version $major is installed, but it is older than Java 11."
    return 1
  fi

  echo "Java installation successful. Java version $major is 11 or higher."
  return 0
}

if [[ "$CHECK_ONLY" != true ]]; then
  echo "Installing latest available Java package..."
  install_java
fi

echo "Checking Java installation..."
check_java
