#!/usr/bin/env bash
set -euo pipefail

policy=$(cat <<-EOF
path "sys/tools/random" {
  capabilities = [ "update" ]
}
EOF
)

provider_config=$(cat <<EOF
{
	"bound_issuer": "https://token.actions.githubusercontent.com",
	"default_role": "default",
	"oidc_discovery_url": "https://token.actions.githubusercontent.com"
}
EOF
)

testing_role=$(cat <<EOF
{
	"role_type": "jwt",
	"bound_audiences": ["https://github.com/ZentriaMC"],
	"user_claim": "repository",
	"bound_claims_type": "glob",
	"bound_claims": {
		"ref_type": "branch",
		"ref": "refs/heads/master",
		"repository_owner": "ZentriaMC",
		"repository": [
			"ZentriaMC/testing-001"
		]
	},
	"policies": ["default", "random"],
	"ttl": "5m"
}
EOF
)

vault policy write random - <<< "${policy}"
if ! [ "$(vault auth list -format=json | jq -r 'to_entries[] | select(.key == "jwt-github/") | true')" ]; then
	vault auth enable -path jwt-github jwt
fi

jq -c <<< "${provider_config}" | vault write auth/jwt-github/config -
jq -c <<< "${testing_role}" | vault write auth/jwt-github/role/testing-001 -
