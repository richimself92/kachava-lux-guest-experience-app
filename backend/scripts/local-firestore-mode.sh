#!/usr/bin/env bash
# ==============================================================================
# Local Firestore safety gate, sourced by run-local.sh.
#
# Google ADC credentials on a developer machine point at the PRODUCTION database,
# so local runs default to the in-memory repositories. Firestore is only allowed when:
#   - FIRESTORE_EMULATOR_HOST is set (Firebase emulator), or
#   - KACHAVA_ALLOW_LIVE_FIRESTORE=1 is set explicitly (live database, at your own risk).
# On return, USE_FIRESTORE / USE_GCP_FIRESTORE are exported with the resolved mode.
# ==============================================================================

resolve_local_firestore_mode() {
  local requested="false"
  if [[ "${USE_FIRESTORE:-false}" == "true" || "${USE_GCP_FIRESTORE:-false}" == "true" ]]; then
    requested="true"
  fi

  export USE_GCP_FIRESTORE="false"
  if [[ "${requested}" != "true" ]]; then
    export USE_FIRESTORE="false"
    echo "  Data mode: IN-MEMORY (seeded demo data, nothing is written to Firestore)"
    return 0
  fi

  if [[ -n "${FIRESTORE_EMULATOR_HOST:-}" ]]; then
    export FIRESTORE_EMULATOR_HOST
    export USE_FIRESTORE="true"
    echo "  Data mode: FIRESTORE EMULATOR (${FIRESTORE_EMULATOR_HOST})"
    return 0
  fi

  if [[ "${KACHAVA_ALLOW_LIVE_FIRESTORE:-}" == "1" ]]; then
    export USE_FIRESTORE="true"
    echo "  Data mode: LIVE FIRESTORE (${FIRESTORE_DATABASE_ID:-kavacha-db}) — WARNING: real data is read and written"
    return 0
  fi

  echo "Refusing to start: USE_FIRESTORE=true would hit the live Firestore database." >&2
  echo "Set FIRESTORE_EMULATOR_HOST to use the emulator, or KACHAVA_ALLOW_LIVE_FIRESTORE=1 to opt in explicitly." >&2
  return 1
}
