#!/usr/bin/env bash
set -euo pipefail

# Freshness check of a published image against its upstream base image.
#
# Level 1 (always): ntfy alert, once per new upstream version.
# Level 2 (always): one GitLab issue per new upstream version, never duplicated.
# Level 3 (AUTO_REBUILD=true only): a signed patch tag on main, which starts the
#   normal tag pipeline (build, scan, promote).
#
# A new upstream version waits COOLDOWN_DAYS before it is used, so a release
# that is too fresh cannot break the images. A fixable CRITICAL or HIGH finding
# on the published image skips the wait.
#
# Required environment:
#   UPSTREAM_IMAGE  base image to follow, or empty to read it from the Dockerfile
#   VERSION_ENV     env variable that holds the version (PHP_VERSION, NODE_VERSION)
#   PUBLISHED_IMAGE image to compare (zairakai/php:latest)
#   AUDIT_JSON      trivy report of the published image
#   IMAGE_LABEL     short name used in titles (php, node)
# Optional: COOLDOWN_DAYS (3), AUTO_REBUILD (false), NTFY_URL, ISSUE_ASSIGNEE_ID.

# --- Pure helpers (unit tested) ------------------------------------------------

# True when version $1 is strictly greater than version $2.
version_gt() {
    [[ "$1" != "$2" && "$(printf '%s\n%s\n' "$1" "$2" | sort -V | tail -n1)" == "$1" ]]
}

# Next patch number: 8.4.27 becomes 8.4.28.
next_patch() {
    local version="$1"
    echo "${version%.*}.$((${version##*.} + 1))"
}

# ISO 8601 date to epoch seconds (fractional seconds are accepted).
iso_to_epoch() {
    jq -rn --arg d "$1" '$d | sub("\\.[0-9]+"; "") | fromdateiso8601'
}

# Whole days between an ISO date and now (or the epoch given as $2).
age_days() {
    local created now
    created=$(iso_to_epoch "$1")
    now="${2:-$(date -u +%s)}"
    echo $(((now - created) / 86400))
}

# Base image of the first FROM line, with ARG defaults resolved.
upstream_from_dockerfile() {
    local file="$1" from name value
    from=$(grep -m1 -E '^FROM ' "${file}" | awk '{print $2}')
    while [[ "${from}" =~ \$\{([A-Za-z_]+)\} ]]; do
        name="${BASH_REMATCH[1]}"
        value=$(grep -m1 -E "^ARG ${name}=" "${file}" | cut -d= -f2-)
        from="${from//\$\{${name}\}/${value}}"
    done
    echo "${from}"
}

# Number of CRITICAL or HIGH findings that have a fixed version.
fixable_count() {
    jq '[.Results[]?.Vulnerabilities[]?
         | select((.Severity == "CRITICAL" or .Severity == "HIGH") and ((.FixedVersion // "") != ""))]
         | length' "$1"
}

# Highest x.y.z tag among the lines read on stdin.
latest_release_tag() {
    grep -E '^[0-9]+\.[0-9]+\.[0-9]+$' | sort -V | tail -n1
}

# --- Actions (need the network, not unit tested) -------------------------------

image_env() {
    local config="$1" key="$2"
    jq -r --arg k "${key}" '.config.Env[] | select(startswith($k + "=")) | split("=")[1]' <<<"${config}"
}

gl() {
    curl -fsS --header "PRIVATE-TOKEN: ${GITLAB_TOKEN}" "$@"
}

notify() {
    [[ -n "${NTFY_URL:-}" ]] || return 0
    curl -fsS -m 15 -H "Title: $1" -d "$2" "${NTFY_URL}" >/dev/null || true
}

# True when the last push pipeline of main passed.
main_is_green() {
    local status
    status=$(gl "${API}/pipelines?ref=main&source=push&per_page=1&order_by=id&sort=desc" | jq -r '.[0].status // "none"')
    [[ "${status}" == "success" ]]
}

# True when a release tag was created in the last 24 hours.
recent_tag_exists() {
    local created
    created=$(gl "${API}/repository/tags?per_page=1&order_by=updated&sort=desc" | jq -r '.[0].commit.created_at // empty')
    [[ -n "${created}" ]] && (($(age_days "${created}") < 1))
}

# Open issue with this exact title already exists.
issue_exists() {
    gl --get --data-urlencode "search=$1" --data "state=opened&in=title" "${API}/issues" \
        | jq -e --arg t "$1" 'any(.[]; .title == $t)' >/dev/null
}

create_issue() {
    local title="$1" description="$2" labels="$3"
    gl --request POST "${API}/issues" \
        --data-urlencode "title=${title}" \
        --data-urlencode "description=${description}" \
        --data-urlencode "labels=${labels}" \
        --data "assignee_ids=${ISSUE_ASSIGNEE_ID:-1367462}" | jq -r '.web_url'
}

# Signed tag on the current commit, pushed with the group token.
push_signed_tag() {
    local tag="$1" message="$2" key
    printf '%s' "${GPG_PRIVATE_KEY_B64}" | base64 -d | gpg --batch --quiet --import
    key=$(gpg --list-secret-keys --with-colons | awk -F: '/^fpr/ {print $10; exit}')
    git config user.name "${RELEASE_SIGNER_NAME}"
    git config user.email "${RELEASE_SIGNER_EMAIL}"
    git config user.signingkey "${key}"
    git config gpg.program gpg
    git tag -s "${tag}" -m "${message}"
    git -c "http.extraHeader=PRIVATE-TOKEN: ${GITLAB_TOKEN}" \
        push "${CI_SERVER_URL}/${CI_PROJECT_PATH}.git" "refs/tags/${tag}"
}

main() {
    : "${VERSION_ENV:?}" "${PUBLISHED_IMAGE:?}" "${AUDIT_JSON:?}" "${IMAGE_LABEL:?}"
    local cooldown="${COOLDOWN_DAYS:-3}" auto="${AUTO_REBUILD:-false}"
    local upstream="${UPSTREAM_IMAGE:-}"
    [[ -n "${upstream}" ]] || upstream=$(upstream_from_dockerfile Dockerfile)
    API="${CI_API_V4_URL}/projects/${CI_PROJECT_ID}"

    local up_cfg pub_cfg up_ver pub_ver up_created pub_created
    up_cfg=$(crane config "${upstream}")
    pub_cfg=$(crane config "${PUBLISHED_IMAGE}")
    up_ver=$(image_env "${up_cfg}" "${VERSION_ENV}")
    pub_ver=$(image_env "${pub_cfg}" "${VERSION_ENV}")
    up_created=$(jq -r '.created' <<<"${up_cfg}")
    pub_created=$(jq -r '.created' <<<"${pub_cfg}")

    local age fixable
    age=$(age_days "${up_created}")
    fixable=$(fixable_count "${AUDIT_JSON}")

    echo "Upstream  ${upstream}: ${up_ver} (${age} day(s) old)"
    echo "Published ${PUBLISHED_IMAGE}: ${pub_ver}"
    echo "Fixable CRITICAL/HIGH findings on the published image: ${fixable}"

    # What makes a rebuild useful: a newer upstream version, or a refreshed
    # base while the published image still has fixable findings.
    local reason=""
    if version_gt "${up_ver}" "${pub_ver}"; then
        reason="new upstream version ${up_ver}"
    elif ((fixable > 0)) && [[ "$(iso_to_epoch "${up_created}")" -gt "$(iso_to_epoch "${pub_created}")" ]]; then
        reason="refreshed base image with ${fixable} fixable finding(s)"
    fi
    if [[ -z "${reason}" ]]; then
        echo "Up to date, nothing to do."
        return 0
    fi

    local urgent=false eligible=false
    ((fixable > 0)) && urgent=true
    if [[ "${urgent}" == true ]] || ((age >= cooldown)); then
        eligible=true
    fi

    local title="Rebuild ${IMAGE_LABEL} image: ${up_ver}"
    local labels="Kind::Chore,Area::CI/CD,Automated"
    [[ "${urgent}" == true ]] && labels="Kind::Security,Area::Security,Automated"

    if ! issue_exists "${title}"; then
        local body
        body="Reason: ${reason}.

- Published: \`${PUBLISHED_IMAGE}\` (${pub_ver})
- Upstream: \`${upstream}\` (${up_ver}, ${age} day(s) old)
- Fixable CRITICAL or HIGH findings: ${fixable}
- Cooldown: ${cooldown} day(s)$([[ "${urgent}" == true ]] && echo ", skipped (fixable findings)")
- Automatic rebuild: ${auto}

Pipeline: ${CI_PIPELINE_URL}"
        local url
        url=$(create_issue "${title}" "${body}" "${labels}")
        echo "Issue created: ${url}"
        notify "${IMAGE_LABEL} image: rebuild needed" "${reason}. ${url}"
    else
        echo "Issue already open: ${title}"
    fi

    if [[ "${eligible}" != true ]]; then
        echo "Cooldown not over yet (${age}/${cooldown} days): no rebuild."
        return 0
    fi
    if [[ "${auto}" != true ]]; then
        echo "AUTO_REBUILD is off: tag the release by hand."
        return 0
    fi
    if ! main_is_green; then
        echo "Last pipeline of main is not green: no automatic tag."
        return 0
    fi
    if recent_tag_exists; then
        echo "A tag was created in the last 24 hours: no automatic tag."
        return 0
    fi

    local last tag
    last=$(gl "${API}/repository/tags?per_page=100" | jq -r '.[].name' | latest_release_tag)
    tag=$(next_patch "${last}")
    push_signed_tag "${tag}" "Rebuild on ${IMAGE_LABEL} ${up_ver}"
    echo "Tag ${tag} pushed."
    notify "${IMAGE_LABEL} image: tag ${tag}" "Automatic rebuild started (${reason})."
}

# Run only when executed, so the tests can source the helpers.
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi
