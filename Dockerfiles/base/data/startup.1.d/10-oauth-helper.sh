#!/usr/bin/env sh
#
# 10-oauth-helper.sh — install dvl-open-host shim + OAuth callback FIFO.
#
# Loaded from /opt/agentic-tools/_entrypoint.d/ before user-mounted /startup.1.d/
# so it survives the devilbox cfg/agentic-startup bind-mount over /startup.1.d.
# A copy also lives in /startup.1.d/ for visibility on non-devilbox runs.

set -eu

if [ "$(id -u)" != "0" ] && [ -z "${DVL_OPEN_HOST_BIN:-}" ]; then
  return 0 2>/dev/null || exit 0
fi

bin_path="${DVL_OPEN_HOST_BIN:-/usr/local/bin/dvl-open-host}"
profile_path="${DVL_BROWSER_PROFILE:-/etc/profile.d/dvl-browser.sh}"
oauth_dir="${DVL_OAUTH_DIR:-/var/run/dvl-oauth}"
oauth_fifo="${DVL_OAUTH_FIFO:-${oauth_dir}/url}"

install -d "$(dirname "${bin_path}")" "$(dirname "${profile_path}")" "${oauth_dir}"

if [ ! -e "${oauth_fifo}" ]; then
  mkfifo "${oauth_fifo}"
elif [ ! -p "${oauth_fifo}" ]; then
  printf '%s\n' "${oauth_fifo} exists but is not a FIFO" >&2
  exit 1
fi

cat >"${bin_path}" <<'EOF'
#!/usr/bin/env sh
set -eu

fifo="${DVL_OAUTH_FIFO:-/var/run/dvl-oauth/url}"

if [ "$#" -lt 1 ] || [ -z "${1:-}" ]; then
  printf '%s\n' 'Usage: dvl-open-host <url>' >&2
  exit 1
fi

printf '%s\n' "$1" >"${fifo}"
return 0 2>/dev/null || exit 0
EOF
chmod +x "${bin_path}"

printf 'export BROWSER=%s\n' "${bin_path}" >"${profile_path}"

return 0 2>/dev/null || exit 0
