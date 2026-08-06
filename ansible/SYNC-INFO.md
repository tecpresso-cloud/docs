# Ansible - Synced Upstream Docs

**Sources:** `ansible/ansible` (core), `ansible-community/ansible-build-data` (package), `ansible/ansible-documentation` (porting guides)
**Synced:** 2026-08-06 04:32 UTC
**Files:** 8 (4 core, 4 package) + `.synced-versions`

---

## 🔴 SCOPE BOUNDARY - read this before adding anything here

| Tree | Owns | Does NOT own |
|---|---|---|
| **`docs/ansible/`** (this tree) | **Upstream version tracking ONLY** - changelogs, porting guides, the support matrix | Any how-to, any of our playbooks, any narrative guidance |
| `~/workspace/KnowledgeBase/devops-and-iac/ansible/` | Our own material - 89 entries of how-to, playbook patterns, troubleshooting, cPanel sequences, lint tooling | Upstream release schedules, EOL dates, changelogs |

**Neither duplicates the other.** If you are about to copy something from one into the other, stop - that is
how a second source of truth is created, and it is the failure mode this boundary exists to prevent.

---

## What we actually run (why these four branches, and no others)

| | ansible-core | ansible (package) |
|---|---|---|
| **Runner** (`vm-deployment-runner`, AlmaLinux 10.2) | **2.20.4** | **13.5.0** |
| **Controller** (axiom, macOS) | **2.21.2** | **14.2.0** |

Both are `pip3 --user` installs, so parity is achievable and is simply not configured. **We lint on the
controller and execute on the runner**, which is why both branches are tracked rather than just the one in
production.

Full parity analysis, including install methods and what the upgrade playbook can and cannot move:
`~/workspace/KnowledgeBase/repo-actions-files/vps-module-development/cardinal-docs/axiom-macOS-vs-runner-packages.md`

---

## Why the marker is multi-line

`terraform-providers/*/.synced-version` holds a single version string because each provider has exactly one
"latest". **Ansible does not.** We track **four branches of one project simultaneously**, and GitHub's
`/releases/latest` API returns a single non-prerelease answer (`v2.21.2` today) that describes none of our
2.20 state.

So `.synced-versions` is `key=value`, and `sync-ansible-docs.sh` **does not call the GitHub API at all** -
it reads the newest stable release out of the changelog document itself:

```
grep -E "^v2\.20\.[0-9]+$" core/CHANGELOG-v2.20.rst | head -1
```

The recorded version therefore can never disagree with the document it came from.

---

## 🔴 What absence of an entry does and does not prove

Before concluding "X did not change" from a grep against these files:

1. **Changelogs omit the `trivial` fragment category.** `antsibull-changelog` supports `breaking_changes`,
   `security_fixes` and `trivial`; a change filed as `trivial` never reaches the published changelog.
2. **Porting guides are a SUBSET, not a second opinion.** They are auto-generated from only four
   categories: `major_changes`, `breaking_changes`, `deprecated_features`, `removed_features`. A
   `bugfixes` entry never appears in one.
3. **Collection changelog policy is set per collection**, not by Ansible. Completeness varies by
   maintainer.

**So absence is strong evidence, not proof.** Say so when citing it.

---

## Usage

- **Changelog** answers *what changed*.
- **Porting guide** answers *what you must DO before upgrading*. For an upgrade decision this is the
  operative document, and it is the one people skip.
- Before trusting a local `ansible-lint` result as evidence about production, read `core/` across the
  controller-runner gap. See the parity doc, §5.2.

## Maintenance

Re-run `../scripts/sync-ansible-docs.sh` after any Ansible version change on either machine, and before any
finalflight. The script rewrites `.synced-versions` and prints a diff of what moved. **It does not rewrite
this file** - the scope boundary and the caveats above are hand-maintained deliberately.
