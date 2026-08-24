#!/usr/bin/env bash

set -Eeuo pipefail

if [[ -z "${ACTIONS_ID_TOKEN_REQUEST_URL:-}" || -z "${ACTIONS_ID_TOKEN_REQUEST_TOKEN:-}" ]]; then
  echo "ERROR: GitHub no proporcionó acceso al token OIDC"
  exit 1
fi

response="$(
  curl --fail --silent --show-error \
    --header "Authorization: bearer ${ACTIONS_ID_TOKEN_REQUEST_TOKEN}" \
    "${ACTIONS_ID_TOKEN_REQUEST_URL}&audience=sts.amazonaws.com"
)"

jwt="$(jq -er '.value' <<< "$response")"
payload="$(cut -d '.' -f 2 <<< "$jwt")"
payload="${payload//-/+}"
payload="${payload//_/\/}"

case $((${#payload} % 4)) in
  0) ;;
  2) payload="${payload}==" ;;
  3) payload="${payload}=" ;;
  *)
    echo "ERROR: el payload OIDC tiene un formato inválido"
    exit 1
    ;;
esac

printf '%s' "$payload" \
  | base64 --decode \
  | jq '{aud, sub, repository, ref}'
