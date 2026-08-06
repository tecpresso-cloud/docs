# ansible-core Support Matrix

**Last verified:** 2026-08-06
**Source:** `~/workspace/KnowledgeBase/devops-and-iac/ansible/2026-08-05 Releases and maintenance - Ansible Community Documentation.md`
**Upstream:** https://docs.ansible.com/projects/ansible/latest/reference_appendices/release_and_maintenance.html

> Transcribed from the local capture of the upstream policy page. **Re-verify at source before acting on a
> date.** Releases land in **May and November** on a ~6-month cadence, with patch releases every 4 weeks.

---

## ansible-core

| Version | Support phase | EOL | Control-node Python | Target Python |
|---|---|---|---|---|
| **2.21** | GA May 2026, Critical Nov 2026, Security May 2027 | Nov 2027 | 3.12 - 3.14 | 3.9 - 3.14 |
| **2.20** | GA 03 Nov 2025, **Critical-fix only since 18 May 2026**, Security 02 Nov 2026 | May 2027 | 3.12 - 3.14 | 3.9 - 3.14 |
| 2.19 | GA 21 Jul 2025, Security-only since 18 May 2026 | Nov 2026 | 3.11 - 3.13 | 3.8 - 3.13 |
| 2.18 | GA 04 Nov 2024 | **EOL May 2026** | 3.11 - 3.13 | 3.8 - 3.13 |
| 2.17 and older | - | EOL | - | - |

**Read the phases literally.** Maintenance is only three releases deep: newest gets general bug fixes, one
behind gets critical-only, two behind gets **security-only**.

## Ansible community package

| Release | Status | Core dependency |
|---|---|---|
| 14.x | **Current** | 2.21 |
| 13.x | Previous major | 2.20 |
| 12.x, 11.x | EOL Dec 2025 | 2.19, 2.18 |

---

## Our position

| | Version | Branch status | Notes |
|---|---|---|---|
| **Runner** core | **2.20.4** | Critical-fix, EOL May 2027 | **3 stable releases behind** - branch is at 2.20.7 |
| **Runner** package | **13.5.0** | Previous major | |
| **Controller** core | **2.21.2** | Current, EOL Nov 2027 | **Current stable on its branch** |
| **Controller** package | **14.2.0** | Current major | |

**Neither branch is EOL.** The problem is not obsolescence - it is that the machine that lints is on a
different major branch from the machine that executes.

---

## 🔴 Discrepancy found 2026-08-06 - policy page vs tag list

The policy page records **2.18 as EOL in May 2026**. The `ansible/ansible` tag list shows **`v2.18.19rc1`
cut on 2026-08-04**, two days before this capture, alongside `v2.19.12rc1`, `v2.20.8rc1` and `v2.21.3rc1`.

Either EOL branches continue to receive releases, or the policy page is stale. **We transcribed the policy
page**, so this note exists to stop anyone treating the table above as settled without checking the tags.
Not operationally relevant to us - we are on 2.20 and 2.21 - but do not repeat the table as fact for older
branches.

---

## Deprecation cycle

**4 feature releases.** Deprecated in 2.10 means removed in 2.13. Tracking is by count of releases, not by
version numbering.

Our open item: `INJECT_FACTS_AS_VARS` cleanup, recorded as "ansible-core 2.24 prep". 2.24 is dated
**Nov 2027**. Correctly scoped; not urgent.
