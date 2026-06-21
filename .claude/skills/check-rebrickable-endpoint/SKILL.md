---
name: check-rebrickable-endpoint
description: Verify the real request/response shape of a Rebrickable API v3 endpoint before implementing or trusting code against it. Use before adding any new RebrickableRepository method, or when a CollectionStatus.unknown / decoding error appears and the cause isn't obvious.
---

# Verifying a Rebrickable API endpoint

`https://rebrickable.com/api/v3/swagger/?format=openapi` lists every path but **omits response
schemas and most form-body parameter details** (confirmed by inspection — paths show
`"responses": {"200": {"description": ""}}` with nothing else). Do not implement against it
blind; it will tell you an endpoint exists without telling you what it actually needs or
returns, and that gap has already caused at least two real bugs in this codebase (a decode
failure from an unexpectedly-nested response, and a silently-ignored `list_id` parameter that
doesn't exist on the endpoint being called).

## Get the real shape

Cross-check against the community-maintained spec, which has fuller (though still not 100%
complete) parameter documentation, pulled from the same backend:

```bash
git clone --depth 1 https://github.com/rienafairefr/pyrebrickable.git /tmp/pyrebrickable_check
grep -n '"/api/v3/users/{user_token}/YOUR_PATH' /tmp/pyrebrickable_check/rebrickable.json
# then read the surrounding ~100 lines for that path's parameters/description
sed -n '<line>,<line+100>p' /tmp/pyrebrickable_check/rebrickable.json
```

Read the `description` field carefully — it's prose, not structured, but it's often the *only*
place that mentions things like "list_id and include_spares may not be accurate unless the set
only exists in a single Set List" or nested response shapes.

If that still doesn't answer it (e.g. you need actual field names in a 200 response body, which
neither spec documents structurally), use WebSearch for the endpoint path plus a couple of
expected field names in quotes — third-party API client READMEs and forum posts have leaked the
real shape for most of the collection-management endpoints already.

## Before writing code against what you found

- If the endpoint is a path like `/users/{user_token}/setlists/{list_id}/sets/{set_num}/`,
  note that `list_id` is a **path** parameter there — a sibling endpoint at
  `/users/{user_token}/sets/{set_num}/` (no list_id in the path) will NOT let you target a
  specific list via a body/form parameter of the same name. Check which path you're actually
  calling.
- If a response nests data under a named key (Rebrickable does this for sets returned alongside
  collection metadata — see `UserSet` in `APIModels.swift` for the precedent), get the *exact*
  key name and structure before writing the `Codable` model — guessing field names here is what
  caused the original bug.
- Add or update a `MockURLProtocol`-based test in `Tests/BrickScanTests/RebrickableRepositoryTests.swift`
  that exercises a *successful* decode of the real shape, not just error-path tests — the
  nested-`UserSet` bug existed for a long time because no test ever decoded a real 200 response.
