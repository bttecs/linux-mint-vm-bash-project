#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d)"
trap 'rm -rf "$TMP_DIR"' EXIT

pass_count=0

pass() {
  pass_count="$((pass_count + 1))"
  echo "PASS: $1"
}

assert_contains() {
  local output="$1"
  local expected="$2"
  local label="$3"

  if [[ "$output" != *"$expected"* ]]; then
    echo "FAIL: $label" >&2
    echo "Expected to find: $expected" >&2
    echo "Actual output:" >&2
    printf '%s\n' "$output" >&2
    exit 1
  fi

  pass "$label"
}

echo "Running syntax checks..."
for script in "$ROOT_DIR"/scripts/*.sh; do
  bash -n "$script"
done
pass "all scripts pass bash syntax checks"

cat > "$TMP_DIR/java17" <<'SCRIPT'
#!/usr/bin/env bash
echo 'openjdk version "17.0.10" 2024-01-16' >&2
SCRIPT
chmod +x "$TMP_DIR/java17"

output="$(JAVA_COMMAND="$TMP_DIR/java17" "$ROOT_DIR/scripts/install-java.sh" --check-only)"
assert_contains "$output" "Java installation successful. Java version 17 is 11 or higher." "Java 17 is accepted"

cat > "$TMP_DIR/java8" <<'SCRIPT'
#!/usr/bin/env bash
echo 'java version "1.8.0_392"' >&2
SCRIPT
chmod +x "$TMP_DIR/java8"

set +e
output="$(JAVA_COMMAND="$TMP_DIR/java8" "$ROOT_DIR/scripts/install-java.sh" --check-only 2>&1)"
status="$?"
set -e
if [[ "$status" -eq 0 ]]; then
  echo "FAIL: Java 8 should fail the Java 11 requirement" >&2
  exit 1
fi
assert_contains "$output" "older than Java 11" "Java 8 is rejected"

cat > "$TMP_DIR/mock-ps" <<'SCRIPT'
#!/usr/bin/env bash
cat <<'PS'
USER       PID %CPU %MEM COMMAND
alice        1  0.1  1.5 first
bob          2  9.9  0.2 other
alice        3  4.2  3.0 second
PS
SCRIPT
chmod +x "$TMP_DIR/mock-ps"

output="$(USER=alice PS_COMMAND="$TMP_DIR/mock-ps" "$ROOT_DIR/scripts/user-processes.sh")"
assert_contains "$output" "alice        1" "process list includes current user process"
if [[ "$output" == *"bob          2"* ]]; then
  echo "FAIL: process list included another user's process" >&2
  exit 1
fi
pass "process list excludes other users"

output="$(printf 'cpu\n1\n' | USER=alice PS_COMMAND="$TMP_DIR/mock-ps" "$ROOT_DIR/scripts/user-processes-limited.sh")"
assert_contains "$output" "alice        3" "CPU sort returns highest CPU process"
if [[ "$output" == *"alice        1"* ]]; then
  echo "FAIL: limited process output included more rows than requested" >&2
  exit 1
fi
pass "limited process output respects requested count"

echo "Tests passed: $pass_count"
