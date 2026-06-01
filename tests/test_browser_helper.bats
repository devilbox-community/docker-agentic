#!/usr/bin/env bats

@test "dvl-open-host writes URL to configured FIFO and exits zero" {
  tmpdir="$(mktemp -d)"
  fifo="${tmpdir}/url"
  helper="${tmpdir}/bin/dvl-open-host"
  profile="${tmpdir}/profile.d/dvl-browser.sh"

  DVL_OPEN_HOST_BIN="${helper}" \
    DVL_BROWSER_PROFILE="${profile}" \
    DVL_OAUTH_DIR="${tmpdir}/oauth" \
    DVL_OAUTH_FIFO="${fifo}" \
    Dockerfiles/base/data/startup.1.d/10-oauth-helper.sh

  DVL_OAUTH_FIFO="${fifo}" "${helper}" https://example.com &
  helper_pid="$!"

  IFS= read -r written <"${fifo}"
  wait "${helper_pid}"
  status="$?"

  rm -rf "${tmpdir}"

  [ "${status}" -eq 0 ]
  [ "${written}" = "https://example.com" ]
}

@test "startup exports BROWSER with production default path" {
  grep -q '/usr/local/bin/dvl-open-host' Dockerfiles/base/data/startup.1.d/10-oauth-helper.sh
}
