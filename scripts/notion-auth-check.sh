#!/usr/bin/env bash
set -u

# Diagnostic-only check. Do not print raw auth output or token-like values.

if ! command -v ntn >/dev/null 2>&1; then
  echo "status=ntn-missing"
  echo "reason=Notion CLI ntn is not available on PATH."
  exit 2
fi

sandbox="${CODEX_SANDBOX:-}"
network_disabled="${CODEX_SANDBOX_NETWORK_DISABLED:-}"

if [[ -n "$sandbox" ]]; then
  echo "codex_sandbox=$sandbox"
else
  echo "codex_sandbox=none"
fi

if [[ "$network_disabled" == "1" ]]; then
  echo "codex_network=disabled"
else
  echo "codex_network=available_or_unknown"
fi

doctor_output="$(ntn doctor -v 2>&1)"
doctor_status=$?
whoami_output="$(ntn whoami -v 2>&1)"
whoami_status=$?
combined_output="$doctor_output
$whoami_output"

if [[ "$whoami_status" -eq 0 ]]; then
  if [[ "$network_disabled" == "1" ]]; then
    echo "status=sandbox-network-disabled"
    echo "reason=Notion CLI can read auth, but Codex reports sandbox network is disabled."
    exit 4
  fi
  echo "status=ok"
  echo "reason=Notion CLI authentication is visible to this process."
  exit 0
fi

if [[ "$combined_output" =~ seatbelt|sandbox|keychain|Keychain ]]; then
  echo "status=sandbox-keychain-blocked"
  echo "reason=Codex sandbox likely cannot access the macOS Keychain credentials used by ntn."
  if [[ "$network_disabled" == "1" ]]; then
    echo "note=Codex sandbox network is also disabled; Notion API calls need network access."
  fi
  exit 3
fi

if [[ "$network_disabled" == "1" ]]; then
  echo "status=sandbox-network-disabled"
  echo "reason=Codex sandbox network is disabled; Notion API calls need network access."
  exit 4
fi

if [[ "$combined_output" =~ [Nn]o[[:space:]]auth[[:space:]]token|no[[:space:]]token[[:space:]]found|Run[[:space:]]\`ntn[[:space:]]login\` ]]; then
  echo "status=not-logged-in"
  echo "reason=This process cannot find a Notion CLI auth token."
  exit 5
fi

echo "status=unknown-error"
echo "reason=Notion CLI auth check failed for a reason not recognized by this script."
echo "ntn_doctor_exit=$doctor_status"
echo "ntn_whoami_exit=$whoami_status"
exit 6
