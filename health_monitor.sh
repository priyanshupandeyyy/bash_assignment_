#!/usr/bin/env bash
# =============================================================================
# health_monitor.sh — Production-grade service health monitor
# Author  : DevOps Engineer
# Usage   : ./health_monitor.sh [--dry-run]
# =============================================================================

set -euo pipefail

# ── Configuration ─────────────────────────────────────────────────────────────
SERVICES_FILE="services.txt"
LOG_FILE="/var/log/health_monitor.log"
RESTART_WAIT=5          # seconds to wait after restart attempt
DRY_RUN=false

# ── Colour / formatting helpers ───────────────────────────────────────────────
RED='\033[0;31m';  GREEN='\033[0;32m'; YELLOW='\033[1;33m'
CYAN='\033[0;36m'; BOLD='\033[1m';     RESET='\033[0m'

# ── Counters ──────────────────────────────────────────────────────────────────
total=0; healthy=0; recovered=0; failed=0

# ── Parse flags ───────────────────────────────────────────────────────────────
for arg in "$@"; do
  [[ "$arg" == "--dry-run" ]] && DRY_RUN=true
done

# ── Logging helper ────────────────────────────────────────────────────────────
log() {
  # log <SEVERITY> <SERVICE> <MESSAGE>
  local severity="$1" service="$2" message="$3"
  local timestamp
  timestamp=$(date '+%Y-%m-%dT%H:%M:%S%z')
  local entry="[$timestamp] [${severity}] service=${service} msg=\"${message}\""

  # Write to log file (skip if no write permission — warn but continue)
  if ! echo "$entry" >> "$LOG_FILE" 2>/dev/null; then
    echo -e "${YELLOW}[WARN] Cannot write to ${LOG_FILE} — check permissions.${RESET}" >&2
  fi

  # Mirror to stdout with colour
  case "$severity" in
    INFO)    echo -e "${CYAN}${entry}${RESET}" ;;
    WARN)    echo -e "${YELLOW}${entry}${RESET}" ;;
    ERROR)   echo -e "${RED}${entry}${RESET}" ;;
    OK)      echo -e "${GREEN}${entry}${RESET}" ;;
    *)       echo "$entry" ;;
  esac
}

# ── Banner ────────────────────────────────────────────────────────────────────
print_banner() {
  echo -e "\n${BOLD}${CYAN}╔══════════════════════════════════════════════╗"
  echo -e "║       🩺  Service Health Monitor             ║"
  echo -e "╚══════════════════════════════════════════════╝${RESET}"
  echo -e "  User    : $(whoami)@$(hostname)"
  echo -e "  Date    : $(date '+%A, %d %B %Y  %H:%M:%S')"
  echo -e "  Log     : ${LOG_FILE}"
  $DRY_RUN && echo -e "  ${YELLOW}Mode    : DRY-RUN (no actual restarts)${RESET}"
  echo
}

# ── Validate services file ────────────────────────────────────────────────────
validate_services_file() {
  if [[ ! -f "$SERVICES_FILE" ]]; then
    log "ERROR" "N/A" "services.txt not found — nothing to monitor."
    echo -e "${RED}[ERROR] '${SERVICES_FILE}' does not exist. Create it with one service name per line.${RESET}\n"
    exit 0          # graceful exit, not a crash
  fi

  # Strip blank lines and comments; count real entries
  mapfile -t SERVICES < <(grep -Ev '^\s*$|^\s*#' "$SERVICES_FILE" || true)

  if [[ ${#SERVICES[@]} -eq 0 ]]; then
    log "WARN" "N/A" "services.txt is empty — nothing to monitor."
    echo -e "${YELLOW}[WARN] '${SERVICES_FILE}' is empty.${RESET}\n"
    exit 0
  fi
}

# ── Check & recover one service ───────────────────────────────────────────────
process_service() {
  local svc="$1"
  (( total++ )) || true

  local status
  status=$(systemctl is-active "$svc" 2>/dev/null || true)

  if [[ "$status" == "active" ]]; then
    log "OK" "$svc" "Service is healthy (active)."
    (( healthy++ )) || true
    return
  fi

  # ── Service is not active ──────────────────────────────────────────────────
  log "WARN" "$svc" "Service is ${status}. Attempting recovery…"

  if $DRY_RUN; then
    log "INFO" "$svc" "[DRY-RUN] Would execute: systemctl restart ${svc}"
    log "WARN" "$svc" "[DRY-RUN] Simulated FAILED (no actual restart performed)."
    (( failed++ )) || true
    return
  fi

  # Real restart
  if systemctl restart "$svc" 2>/dev/null; then
    log "INFO" "$svc" "restart command issued — waiting ${RESTART_WAIT}s…"
    sleep "$RESTART_WAIT"

    local new_status
    new_status=$(systemctl is-active "$svc" 2>/dev/null || true)

    if [[ "$new_status" == "active" ]]; then
      log "OK" "$svc" "RECOVERED — service is now active."
      (( recovered++ )) || true
    else
      log "ERROR" "$svc" "FAILED — service still ${new_status} after restart."
      (( failed++ )) || true
    fi
  else
    log "ERROR" "$svc" "FAILED — systemctl restart returned a non-zero exit code."
    (( failed++ )) || true
  fi
}

# ── Summary table ─────────────────────────────────────────────────────────────
print_summary() {
  local sep="──────────────────────────────────────────"
  echo
  echo -e "${BOLD}${CYAN}╔══════════════════════════════════════════╗"
  echo -e "║           📊  Monitoring Summary          ║"
  echo -e "╠══════════════════════════════════════════╣${RESET}"
  printf  "${BOLD}${CYAN}║${RESET}  %-22s  %14s  ${BOLD}${CYAN}║${RESET}\n" "Metric" "Count"
  echo -e "${BOLD}${CYAN}╠══════════════════════════════════════════╣${RESET}"
  printf  "${BOLD}${CYAN}║${RESET}  %-22s  %14s  ${BOLD}${CYAN}║${RESET}\n" "Total Checked"   "$total"
  printf  "${GREEN}${BOLD}║${RESET}  %-22s  %14s  ${GREEN}${BOLD}║${RESET}\n" "Healthy"         "$healthy"
  printf  "${YELLOW}${BOLD}║${RESET}  %-22s  %14s  ${YELLOW}${BOLD}║${RESET}\n" "Recovered"      "$recovered"
  printf  "${RED}${BOLD}║${RESET}  %-22s  %14s  ${RED}${BOLD}║${RESET}\n" "Failed"          "$failed"
  echo -e "${BOLD}${CYAN}╚══════════════════════════════════════════╝${RESET}"
  echo
}

# ── Main ──────────────────────────────────────────────────────────────────────
main() {
  print_banner
  validate_services_file

  log "INFO" "monitor" "Starting health check for ${#SERVICES[@]} service(s)."

  for svc in "${SERVICES[@]}"; do
    process_service "$svc"
  done

  log "INFO" "monitor" "Health check complete. total=${total} healthy=${healthy} recovered=${recovered} failed=${failed}"
  print_summary
}

main "$@"
