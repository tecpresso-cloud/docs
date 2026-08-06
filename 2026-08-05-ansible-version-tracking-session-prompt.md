# Next-Session Prompt - Ansible Version Tracking in `~/workspace/docs`

**Created:** 2026-08-05 (Eastern)
**Author:** Team TECPRESSO
**Target repo:** `tecpresso-cloud/docs` (`~/workspace/docs`, Mintlify site)
**Goal of next session:** stand up `docs/ansible/` as the upstream Ansible version-tracking tree, with a sync script and drift check, mirroring the existing `docs/terraform-providers/` pattern.

> **Zero-pause contract.** This file is written so the next session can start work without asking a single
> question. Every path, every number, every unknown is stated. Where something is genuinely unknown, it says
> so and gives the exact command that resolves it. If you find yourself about to ask the operator a
> question, the answer is probably in section 3, 5 or 9 - read those first.

---

## 0. READ THIS FIRST - working rules

**Do NOT inline the pre-flight rules here or anywhere else.** They live in exactly one place:

`~/workspace/ProjectGenesis/CLAUDE/vps-session-preflight.md`

That file is auto-loaded into every ProjectGenesis session via `@CLAUDE/vps-session-preflight.md`, so it is
already in context before any tool call. Read it there. Never copy it. The duplication ban was added
2026-07-27 after two drifted copies caused a malformed shell command.

The rules that bite hardest on this particular task, restated only as pointers:

- ONE tool call per turn. Present, pause for `/copy`, wait for go-ahead. Reads included.
- No parallel tool-call blocks. No background agents. Sequential only.
- Claude never runs `rm`. The operator does all deletions.
- Claude runs all git. The operator runs Terraform, Ansible, rsync, WHMCS admin actions and VM power.
- Never create a file or folder without explicit approval. Check with `ls` first, every time.
- Redact credentials, IPs, emails and IDs to first-2 / last-2.
- Never print the customer-VM Terraform state bucket name. It lives only in gitignored tfvars and the
  Ansible inventory host var.
- No em dashes. No double spaces. Commit subjects 50 chars max, body wrapped at 72.
- No AI attribution in commits. No "Team TECPRESSO" appellation in commit bodies.
- Use `type`, never `which`.

---

## 1. WHY THIS TASK EXISTS

On 2026-08-05, during the SakuraCloud finalflight, `phase_hostname_post` failed with:

```
Reboot command failed. Error was: 'Failed to schedule shutdown: Access denied,
Shared connection to <redacted> closed.'
```

The natural next question was "has the `ansible.builtin.reboot` module changed its handling of this error
across ansible-core releases?" We could not answer it, because we hold **no Ansible release notes locally**.

Confirmed by direct search on 2026-08-05:

```
find ~/workspace/docs -maxdepth 3 -iname '*ansible*' -print
```

returned **nothing**. `~/workspace/docs/` contains only:

```
docs.json  favicon.svg  infrastructure  introduction.mdx  logo
references  runbooks  scripts  TASKS.md  terraform-providers
```

We track eight Terraform providers meticulously and zero Ansible versions, while Ansible is what actually
provisions every customer VM across all five clouds. That asymmetry is the gap this task closes.

---

## 2. SCOPE BOUNDARY - the single most important design decision

`~/workspace/KnowledgeBase/devops-and-iac/ansible/` **already exists** and is substantial: 89 entries,
including `ansible-issues/`, `ansible-modules/`, `ansible-config/`, `ansible-best-practices/`,
`ansible-collections/`, `ansible-examples/`, `ansible-playbooks/`, plus large single files such as
`Ansible.md` (355 KB) and `Ansible Collection Environment Variables.md` (411 KB).

**If `docs/ansible/` duplicates any of that, we have created a second source of truth.** That is the exact
failure mode we spent the week of 2026-07-27 through 2026-08-05 eliminating across the VPS docs.

The boundary, to be stated in the new `docs/ansible/README.md` in both directions:

| Tree | Owns | Does NOT own |
|---|---|---|
| `KnowledgeBase/devops-and-iac/ansible/` | Our own how-to material, playbook patterns, troubleshooting, cPanel sequences, lint tooling notes | Upstream release schedules, EOL dates, changelogs |
| `docs/ansible/` | Upstream version tracking ONLY: support matrix, EOL dates, core changelogs, porting guides, collection versions we pin | Any how-to, any of our own playbooks, any narrative guidance |

Write the boundary into **both** trees. A one-way pointer decays.

---

## 3. SOURCE MATERIAL - already downloaded, do not re-fetch

Both reference files are on disk at `~/workspace/KnowledgeBase/devops-and-iac/ansible/`:

| File | Size | Status |
|---|---|---|
| `2026-08-05 Releases and maintenance - Ansible Community Documentation.md` | 26,055 bytes | **READ 2026-08-05.** Content summarised in section 4 below. |
| `Generating changelogs and porting guide entries in a collection - Ansible Community Documentation.md` | 5,073 bytes | **NOT YET READ.** Read it first thing next session. |

Upstream URLs, if a refresh is ever needed:

- https://docs.ansible.com/projects/ansible/latest/reference_appendices/release_and_maintenance.html
- https://docs.ansible.com/projects/ansible/latest/dev_guide/developing_collections_changelogs.html

---

## 4. FACTS EXTRACTED FROM THE RELEASE-AND-MAINTENANCE DOC

These are transcribed from the local file, not recalled. Re-verify against it before publishing.

### 4.1 Two projects, two versioning schemes

| Ansible community package | ansible-core |
|---|---|
| New versioning (2.10, then 3.0.0) | Classic versioning (2.11, then 2.12) |
| Follows semantic versioning | Does NOT use semantic versioning |
| Maintains only ONE version at a time | Maintains latest plus TWO older versions |
| Language, runtime, selected Collections | Language, runtime, builtin plugins |
| Developed in Collection repos | Developed in `ansible/ansible` |

### 4.2 ansible-core support matrix as of 2026-08-05

| Version | Support phase | EOL | Control-node Python | Target Python |
|---|---|---|---|---|
| **2.21** | GA May 2026, Critical Nov 2026, Security May 2027 | Nov 2027 | 3.12 - 3.14 | 3.9 - 3.14, PS 5.1 - 7 |
| **2.20** | GA 03 Nov 2025, Critical 18 May 2026, Security 02 Nov 2026 | May 2027 | 3.12 - 3.14 | 3.9 - 3.14, PS 5.1 |
| **2.19** | GA 21 Jul 2025, Critical 03 Nov 2025, **Security since 18 May 2026** | **Nov 2026** | 3.11 - 3.13 | 3.8 - 3.13, PS 5.1 |
| 2.18 | GA 04 Nov 2024 | **EOL May 2026 - already past** | 3.11 - 3.13 | 3.8 - 3.13 |
| 2.17 and older | - | EOL | - | - |

**Read the support phases literally.** The newest release gets general bug fixes. One behind gets
critical-only. Two behind gets **security-only**. Maintenance is three releases deep and the tail is thin.

**If the runner is on 2.19, we are on a security-only branch with a Nov 2026 EOL.** That is under four
months from the date of writing and is a production planning item, not housekeeping.

### 4.3 Community package status

| Release | Status | Core dependency |
|---|---|---|
| 14.0.0 | In development, unreleased | 2.21 |
| 13.x | **Current, latest** | 2.20 |
| 12.x | EOL Dec 2025 | 2.19 |
| 11.x | EOL Dec 2025 | 2.18 |
| 10.x and older | Unmaintained, end of life | 2.17 and older |

### 4.4 Cadence and cycle rules

- ansible-core major release approximately every 6 months, in **May and November**.
- Patch releases on a **4-week** schedule for each maintained version.
- Community package: two major versions per year, minor every 4 weeks.
- **Deprecation cycle in ansible-core is 4 feature releases.** Deprecated in 2.10 means removed in 2.13.
  Tracking is tied to the count of releases, not the numbering.
- Control-node Python: since 2.12, each release supports the **3 most recent** Python versions.
- Target-node Python: since 2.16, the **6 most recent**, and **7** on every 6th release (2.16, 2.22, ...).
- Release candidates: RC1 runs about 5 business days, RC2 about 2, repeating until clean.

**Consequence for our backlog:** the `INJECT_FACTS_AS_VARS` deprecation cleanup, recorded in
`ProjectGenesis/CLAUDE.md` as "ansible-core 2.24 prep", is correctly scoped. 2.24 is dated **Nov 2027** in
the PowerShell LTS table. Not urgent. Do not let it displace the EOL question above, which is real.

### 4.5 Stable changelog URL patterns

These are the URLs a sync script consumes. Both are stable and predictable.

- ansible-core: `https://github.com/ansible/ansible/blob/stable-2.XX/changelogs/CHANGELOG-v2.XX.rst`
  - raw form: `https://raw.githubusercontent.com/ansible/ansible/stable-2.XX/changelogs/CHANGELOG-v2.XX.rst`
- Community package: `https://github.com/ansible-community/ansible-build-data/blob/main/13/CHANGELOG-v13.md`
  - note the extension changed from `.rst` to `.md` at version 10 and later

Porting guides:
- core: https://docs.ansible.com/projects/ansible/latest/porting_guides/core_porting_guides.html
- package: https://docs.ansible.com/projects/ansible/latest/porting_guides/porting_guides.html

Older releases archive: https://releases.ansible.com/ansible/

---

## 5. RUNNER ANSIBLE VERSIONS - RESOLVED 2026-08-05, do not re-derive

Measured on the runner on 2026-08-05. These are readings, not recollections.

```
ansible [core 2.20.4]
ansible python module location = /home/headsup/.local/lib/python3.12/site-packages/ansible
```

Installed package set, with install dates from `ls --time-style=long-iso`:

| Package | Version | Installed |
|---|---|---|
| `ansible` (community package) | **13.5.0** | 2026-04-19 04:12 |
| `ansible-core` | **2.20.4** | 2026-04-19 03:23 |
| `ansible-lint` | 26.4.0 | 2026-04-19 04:15 |
| `ansible-compat` | 26.3.0 | 2026-04-19 03:23 |
| `ansible_collections` | (bundled) | 2026-04-19 04:12 |

### 5.1 Reading against the support matrix

| Fact | Value | Interpretation |
|---|---|---|
| Core branch | **2.20** | GA 03 Nov 2025 |
| Support phase | **Critical-fix**, since 18 May 2026 | Middle row. NOT security-only |
| Core EOL | **May 2027** | Roughly 21 months out from writing |
| Control-node Python | 3.12 | 2.20 supports 3.12 - 3.14, so we sit on the OLDEST supported |
| Community package | 13.5.0 | 13.x is Current-Latest, core dependency 2.20 |

**The pairing is correct and healthy.** Community package 13.x depends on core 2.20, and that is exactly what
is installed. This is not a mismatched or EOL combination.

**Correction to an earlier draft of this file:** an earlier revision warned about a Nov 2026 EOL. That
applies to core **2.19**, not to us. We are on 2.20 with a **May 2027** EOL. Do not carry the 2.19 warning
forward.

### 5.2 The open question that remains - patch currency

**Both packages were installed 2026-04-19 and have not moved since.** As of 2026-08-05 that is nearly four
months.

- ansible-core patches ship on a **4-week** cadence. We are on `2.20.4`.
- Community package minors ship on a **4-week** cadence. We are on `13.5.0`.

Four months at a four-week cadence implies roughly four releases each may have shipped since. **This is an
inference, not a measured fact.** Do not state it as one. The synced changelogs will settle it in seconds,
and settling it is one of the deliverables of this task.

**Frame it correctly when reporting.** The risk here is not drift; it is **stasis**. We have been frozen on
April versions with no visibility either way. Neither drift nor stasis is a decision. Both are simply the
absence of tracking, which is what this task exists to fix.

### 5.3 A hypothesis this evidence KILLED - do not re-open it

During the 2026-08-05 Sakura forensics a hypothesis was raised: that
`upgrade-runner-components.yml` (documented in `~/workspace/CLAUDE/conventions.md` as covering "Cloud CLIs,
brew, pip3/pipx packages") might have upgraded ansible-core between svc #98 (2026-07-07, passed) and
svc #106 (2026-08-05, failed), meaning the provisioning **engine** changed even though our **playbooks** did
not. `ansible.builtin.reboot` ships inside ansible-core, not in our roles, so this was material.

**The install dates falsify it outright.** `ansible_core-2.20.4.dist-info` is dated **2026-04-19**, eleven
weeks before svc #98 and sixteen before svc #106. **ansible-core was identical across both runs.**

Two consequences worth carrying:

1. The svc #106 "our code did not cause this" ruling now holds for the right reason. The original three
   proofs (`diff -rq`, `git log`, `git diff`) all covered **our playbook code only** and left the engine
   version unexamined. It has now been examined.
2. `upgrade-runner-components.yml` either has not run since April, or does not touch ansible. **Read it
   during this task** for the upgrade-planning half of the work, but it is no longer forensically relevant.

### 5.4 ANSWERED 2026-08-05 - `upgrade-runner-components.yml` CANNOT upgrade Ansible

`upgrade-runner-components.yml` was read in full (652 lines) on 2026-08-05. Its pip block runs against an
**explicit three-package allowlist**:

```yaml
pip3_user_packages_to_upgrade:
  - boto3
  - google-cloud-secret-manager
  - linode-cli
```

Ansible is not among them. All four upgrade paths in that playbook were checked, not just the obvious one:

| Block | Scope | Reaches ansible? |
|---|---|---|
| Play 1, imported `apply-linux-package-updates.yml` | `dnf` OS packages | **No.** Ansible is pip3 `--user`, not an RPM |
| Block A, `brew upgrade` with no args | ALL outdated formulae | **No.** Brew lives at `/home/linuxbrew/.linuxbrew/`; ansible is at `~/.local/lib/python3.12/site-packages/` |
| Block B, `ansible.builtin.pip` | The 3-package allowlist above | **No** |
| Block C, `pipx upgrade-all` | ALL pipx packages | **No.** pipx uses `~/.local/share/pipx/venvs/`; ansible is in the pip3 `--user` site-packages tree |
| Block D, AWS CLI v2 installer | AWS CLI only | No |

**Conclusion: Ansible has NO automated upgrade path anywhere in our tooling.** It was installed once on
2026-04-19 and nothing in the runner playbook set can move it. The four-month freeze is **structural, not
incidental** - it is a property of how the automation is written, not an oversight in when it was last run.

**This is the strongest argument for this whole task, and it is narrower than "we should track versions".**
Any Ansible upgrade will be a **deliberate manual act**, performed by a human who must know what changed
between 2.20.4 and the target before touching the engine that provisions every customer VM on five clouds.
Right now that decision has **no inputs at all**. The tracked changelogs are the prerequisite for ever
moving off 2.20.4 safely, not a convenience.

**Secondary observation worth knowing before the next components run:** `brew upgrade` (Block A) and
`pipx upgrade-all` (Block C) are both **unbounded** - no allowlist, they upgrade everything outdated. That
is a different and larger risk class than the tightly-scoped pip block. Not urgent, but do not assume the
whole playbook is as conservative as its pip section.

**A non-finding, recorded so it is not re-raised:** line 350 uses `which pipx`, which appears to breach our
"never `which`, always `type`" convention. It does not. That convention is a **local macOS controller** rule.
`which` is a real binary on Linux and works correctly; `type` is a shell builtin and would fail inside
`ansible.builtin.command`, which runs without a shell. Leave it alone.

### 5.5 Still to capture

- [ ] `ansible-galaxy collection list` on the runner - determines which collections are worth syncing.
      Never captured; the 2026-08-05 session was interrupted by the live Sakura test
- [ ] Controller Mac versions, for skew comparison: `ansible --version | head -4` plus
      `type ansible-playbook` (on the Mac, `type` is correct)
- [ ] Design the upgrade path itself, given 5.4. Options: extend the pip allowlist to include
      `ansible-core` and `ansible`, or keep Ansible deliberately manual and document the procedure. Both
      are defensible; the current state - no path and no tracking - is not

Runner access: IAP-tunnel only, **NOT** in `~/.ssh/config`. Use the gcloud form. Power state first via
`zsh -ic 'describerunner'` - invoke the alias, never reconstruct the command.

Controller tooling paths, per `~/workspace/CLAUDE/conventions.md`:

| Tool | Path |
|---|---|
| `yamllint` | `/opt/homebrew/bin/yamllint` (Homebrew) |
| `ansible-playbook --syntax-check` | `~/.local/bin/ansible-playbook` (pip3 --user) |
| `ansible-lint` | `~/.local/bin/ansible-lint` (pip3 --user) |

Lint config: `~/workspace/tecpresso-cloud-ops/.ansible-lint` (no `profile:` directive, so it defaults to
`production`). Target output: `Passed: 0 failure(s), 0 warning(s) ... 'production'`.

**A version skew between controller and runner is itself a finding.** Record it either way.

Also capture the **controller Mac** version for comparison, since our lint toolchain runs locally:

```
type ansible-playbook; ansible --version 2>&1 | head -4
```

Controller tooling paths, per `~/workspace/CLAUDE/conventions.md`:

| Tool | Path |
|---|---|
| `yamllint` | `/opt/homebrew/bin/yamllint` (Homebrew) |
| `ansible-playbook --syntax-check` | `~/.local/bin/ansible-playbook` (pip3 --user) |
| `ansible-lint` | `~/.local/bin/ansible-lint` (pip3 --user) |

Lint config: `~/workspace/tecpresso-cloud-ops/.ansible-lint` (no `profile:` directive, so it defaults to
`production`). Target output: `Passed: 0 failure(s), 0 warning(s) ... 'production'`.

**A version skew between controller and runner is itself a finding.** Record it either way.

---

## 6. THE PATTERN TO MIRROR - `docs/terraform-providers/`

Confirmed structure on 2026-08-05:

```
~/workspace/docs/
├── docs.json                 # Mintlify navigation - new trees may need registering here
├── TASKS.md                  # precedent for a working file at the repo root
├── infrastructure/
├── references/
├── runbooks/
├── scripts/
│   ├── check-references.sh   # drift detection
│   └── sync-terraform-docs.sh
└── terraform-providers/
    ├── aws/  azurerm/  cloudflare/  google/  google-beta/
    ├── linode/  sakuracloud/  vultr/
```

Per `~/workspace/CLAUDE/terraform-provider-versions.md`, provider changelogs land at
`~/workspace/docs/terraform-providers/{provider}/changelog/CHANGELOG.md`.

**Read `sync-terraform-docs.sh` and `check-references.sh` before writing anything.** The Ansible script
should be an adaptation of a proven script, not a new invention. Chesterton's Fence applies: if the
existing script does something that looks unnecessary, find out why before dropping it.

**Check `docs.json` before creating pages.** If `terraform-providers` is registered in the Mintlify
navigation, `ansible` must be too, or the pages exist on disk but are unreachable in the rendered site. If
it is deliberately unregistered and treated as a raw reference tree, mirror that instead. Determine which,
do not assume.

---

## 7. PROPOSED STRUCTURE - approved in principle 2026-08-05, confirm before creating

```
docs/ansible/
├── README.md                 # scope boundary, both directions, per section 2
├── support-matrix.md         # tables from 4.2 and 4.3, with a "verified on" date
├── core/
│   ├── 2.19/changelog/CHANGELOG-v2.19.rst
│   ├── 2.20/changelog/CHANGELOG-v2.20.rst
│   └── 2.21/changelog/CHANGELOG-v2.21.rst
├── porting-guides/           # core porting guides for versions we run
└── collections/              # ONLY collections we actually use - see section 5 output
```

Plus:
- `docs/scripts/sync-ansible-docs.sh`
- an Ansible arm added to `docs/scripts/check-references.sh`

**Do not sync all 85+ community collections.** Sync only what `ansible-galaxy collection list` on the runner
shows we actually use. A tree nobody maintains becomes a claim nobody can defend, which is the same rule
already written into `provisioning-speed-benchmarks.md`.

**`support-matrix.md` must carry a `Last verified: YYYY-MM-DD` line and a staleness rule.** Releases land in
May and November on a 6-month cadence, with patches every 4 weeks. A matrix without a verification date is
indistinguishable from a stale one.

---

## 8. TASK CHECKLIST

- [ ] Read `Generating changelogs and porting guide entries in a collection - ...md` (5,073 bytes, unread)
- [ ] Resolve the runner ansible-core version (section 5) and the controller version
- [ ] Record any controller-to-runner version skew as a finding
- [ ] Read `docs/scripts/sync-terraform-docs.sh` and `check-references.sh` in full
- [ ] Inspect `docs.json` to determine whether new trees require navigation registration
- [ ] Get explicit approval for the final `docs/ansible/` structure
- [ ] Create `docs/ansible/README.md` with the two-way scope boundary
- [ ] Create `docs/ansible/support-matrix.md` from section 4, with verification date and staleness rule
- [ ] Sync the core changelogs for the versions we actually run
- [ ] Write `docs/scripts/sync-ansible-docs.sh` modelled on the Terraform script
- [ ] Extend `check-references.sh` to cover Ansible drift
- [ ] Add the reciprocal pointer in `KnowledgeBase/devops-and-iac/ansible/` back to `docs/ansible/`
- [ ] Answer the originating question: did `ansible.builtin.reboot` error handling change across the
      versions in play? Cite the changelog entry, not a recollection
- [ ] Commit and push (Claude runs git; `docs` is a `tecpresso-cloud` org repo, so Team TECPRESSO identity)
- [ ] Update `~/workspace/GLOBAL_TASKS.md` (it is a SYMLINK to `KnowledgeBase/GLOBAL_TASKS.md` - resolve
      with `realpath` and edit the real target; Edit refuses symlinks)

---

## 9. OPERATIONAL STATUS AT HANDOFF - 2026-08-05, late evening Eastern

### 9.1 SakuraCloud finalflight, service #106 - GRADED FAILED, retry was in flight at handoff

**This is the single most time-sensitive item. Verify its outcome before anything else.**

| Field | Value |
|---|---|
| Job | 57 |
| Service | #106 |
| Cloud | SakuraCloud |
| Tier | t3 dedicated |
| Zone | **is1c** - the Region radio stayed on the default rather than the intended is1b |
| VM IP | `15****.4` (redacted) |
| cPanel | 11.136.0.32 |
| OS | AlmaLinux 10.2 (Lavender Lion) |

Phase timings recorded:

| Phase | Duration |
|---|---|
| Terraform apply | 3m 37s |
| `phase_platform` | 1m 13s |
| `phase_prepare` | 5m 11s |
| `phase_install` | **15m 54s** |
| `phase_hostname_post` | **FAILED on attempt 1** |

Failure at 21:49:28 UTC:

```
fatal: [<redacted>]: FAILED! => {"msg": "Reboot command failed. Error was:
'Failed to schedule shutdown: Access denied, Shared connection to <redacted> closed.'",
"rebooted": false}
```

`whmapi1 sethostname` had **succeeded** before this (`rc: 0`, `result: 1`, "Updating cPanel
license...Done. Update succeeded.", delta 2m 36s). The reboot, not the hostname set, is what failed.

**Retry attempt 2 of 5** was claimed at 22:06 UTC. Checkpoint-resume correctly skipped `phase_platform`,
`phase_prepare` and `phase_install`, resuming at `phase_hostname_post` at 22:06:38. The reboot **succeeded**
on attempt 2, confirmed by SSH port 22 returning `Connection refused` at approximately 22:12 UTC while the
VM cycled.

**Grade: FAILED as a finalflight.** It required operator intervention. The bar is a clean flight. The retry
bought a diagnosis, not a pass.

**Outcome beyond the reboot was unknown at handoff.** Verify with:

```
gcloud compute ssh vm-deployment-runner --zone us-central1-a --project tp-proj2311 --tunnel-through-iap --command='sudo tail -n 40 /var/log/runner-service/runner.log'
```

### 9.2 Forensics established, and what was ruled out

**Causation by our own changes is ruled out, three independent ways:**

1. `diff -rq` between the previously deployed Ansible archive and the current one: **empty**.
2. `git log f579b13..HEAD -- platform_sakura provision_whm.yml`: **empty**.
3. `git diff` of `hostname_post.yml`: **empty**.

The code is **byte-identical to what service #98 ran successfully on 2026-07-07**.

**Evidence gathered from the guest:**

- Guest journal at the moment of failure contains **no polkit and no logind denial**. The only entry is
  Ansible's own `find` probe:
  `paths=['/sbin','/bin','/usr/sbin','/usr/bin','/usr/local/sbin'] patterns=['shutdown']` at 06:49:28 JST.
  A polkit denial is normally logged. Its absence points away from a policy evaluation.
- `systemctl list-jobs` showed **`httpd.service start` still in `running` state** - an unfinished job in the
  systemd transaction queue. A pending job that never completes is a credible mechanism for systemd
  refusing to enqueue a shutdown transaction, and it fits the transient signature exactly: once httpd
  settled, the reboot enqueued without complaint.
- `systemd-logind` and `dbus` were both active, `loginctl` worked, `systemctl --dry-run reboot` returned no
  error, and uptime was 35 minutes, so `phase_prepare`'s earlier reboot had succeeded on the same box.

**Environment deltas from the passing service #98 run:**

| | svc #98 (passed) | svc #106 (failed then retried) |
|---|---|---|
| cPanel | 11.136.0.**27** | 11.136.0.**32** - five builds newer |
| OS | AlmaLinux 10.2 | AlmaLinux 10.2 - same |
| Tier | t1 shared | t3 dedicated |

**Leading hypothesis, not yet proven:** a pending systemd job blocks the shutdown transaction, producing
`Access denied` without a polkit log entry. **The proposed fix is a bounded retry with a readiness gate** -
wait for `systemctl list-jobs` to drain before requesting shutdown, then retry the reboot 2 to 3 times with
a short backoff. Same shape as the F16 IM360 retry and the Vultr reserved-IP detach retry. This converts a
coin-flip into a contract.

**Safe reproduction command, if the VM still exists:** `shutdown -k +99 test` sends a wall message and does
**not** halt or reboot; `shutdown -c` cancels it. This exercises the same authorisation path without risk.

**cPanel log paths are documented** at
`~/workspace/KnowledgeBase/security/ssh/ssh-aliases/aliases cPanel DNSOnly.md`. Use that file. Do not guess
at log locations.

### 9.3 A separate defect found tonight - misleading failure surface

**WHMCS surfaces the Ansible timing-summary tail as the failure message, not the `fatal:` line.** On this
run it displayed text naming "Fail clearly if cPanel sethostname failed" - a task that had **SKIPPED** - and
was truncated mid-word. That caused an initial misdiagnosis as a licensing error.

The failure surface must show the `fatal:` line. Until fixed, **always read the runner log directly** and
never diagnose from the WHMCS message alone.

### 9.4 Code shipped this session

**Commit `9543351` - "fix(whmcs): fail closed on invalid VM hostname"** - deployed to the runner via the
Ansible sync playbook and verified byte-identical.

- Added `_HOSTNAME_RE` and `_require_valid_hostname()` to
  `~/workspace/ProjectGenesis/whmcs-customizations/runner-service/runner/executor.py`
- Applied at **five CREATE call sites** (GCP, AWS, Vultr, Linode, SakuraCloud)
- **Four DESTROY sites deliberately unchanged** - they keep the `server-<id>.webcomm.dev` fallback, because
  a destroy must never be blocked by a bad hostname
- Regex bounds the terminal label at `[a-z]{2,63}`. An earlier draft used unbounded `{2,}`; the 64-character
  test case had exercised a **non-terminal** label and therefore tested the wrong boundary
- Rejects non-ASCII with a punycode hint. WHMCS supports IDN at the **second level only**, not top level

**Known remaining instance of the same defect:** `hooks.php:132`,
`webhostingm_deployments_sanitize_nameserver()`, still carries the unbounded `[a-z]{2,}` terminal label.
Separate review packet required.

### 9.5 Documentation shipped this session

| File | Change |
|---|---|
| `cardinal-docs/SakuraCloud-...-Deployment-Sequence.md` | New `## 0. PRE-FLIGHT FAST PATH` (§0.0 - §0.6). Existing `## 0. HARD RULES` numbering deliberately left alone, it is cited elsewhere |
| `catalog-specs/sakura-vm-tier-and-storage-spec.md` | Six corrections, each struck through rather than deleted |
| `webhostingm-mainsite/docs/standards/provisioning-speed-benchmarks.md` | **NEW.** Fleet timings with per-figure citations |
| `ProjectGenesis/CLAUDE.md` | Benchmarks row added to the standards table, so it auto-loads every session |
| `cardinal-docs/AUTHORITATIVE-INFRA-STATE-v7.md` and index | New headline entry plus 8 DECIDED entries |
| `KnowledgeBase/GLOBAL_TASKS.md` | Two new pending sections, Last Updated chain, session-prompt pointer |

### 9.6 Runner state

At handoff the runner was **ARMED** (`RUNNER_DRY_RUN=false`) because the Sakura retry was live.

**Claude arms and disarms the runner. The operator only powers the VM up and down.**

Session close requires, in order:

- [ ] Disarm: `RUNNER_DRY_RUN=true`, restart `runner-service`, verify via the live env probe
- [ ] Stop the runner and any test VM
- [ ] Push memory: `~/workspace/bin/claude-memory-sync.sh push`

**Never run the blanket `grep -E "^RUNNER_"` env probe.** It prints the state bucket name and the HMAC
secret. That leaked on 2026-07-29 and again on 2026-08-02. Use the five-key allowlist form in
`vps-session-preflight.md` section 5, verbatim.

---

## 10. CARRIED PENDING TASKS - not part of this task, do not lose them

- [ ] **F13 reboot hardening** - bounded retry plus `systemctl list-jobs` readiness gate in
      `phase_hostname_post`. Arises directly from tonight's failure
- [ ] **Failure-surface fix** - WHMCS must display the `fatal:` line, not the timing-summary tail
- [ ] **CPU-class copy** in `cloud_vm_option_descriptions.php` - explain Shared versus Dedicated. Market as
      "guaranteed cores", **never** "bare metal" or "dedicated server". Affects Sakura, Linode and Vultr.
      Vultr matters because its **shared** High Frequency CPU outperformed two **dedicated** ones
- [ ] **Soften the Sakura speed-claim wording** in `provisioning-speed-benchmarks.md` and `GLOBAL_TASKS.md`
      to options-with-evidence. The operator overrode the blanket "Sakura must NOT appear in a speed claim"
      on 2026-08-05: "we are not building or updating the pages yet ... must not reject what will help."
      The one constraint that **stands on fact** is that Sakura's dedicated tiers are not bare metal
- [ ] **Per-provider runner pre-flight scripts** - mine every convo file for the questions we needed
      answered and the commands that answered them, then build one script per provider to fetch it all in
      a single call. Operator: "I dislike this time sink"
- [ ] **`hooks.php:132`** unbounded nameserver terminal label - separate Codex packet
- [ ] **Job 55** still shows a live Retry button on a terminated service. Must be made non-resumable
- [ ] **Codex blockers still open:** cancellation contract, A1/A8 lifecycle contract, order-tuple
      pre-submit confirmation
- [ ] **Old state bucket revocation** - still open since 2026-07-29

---

## 11. FLEET CONTEXT - for anyone arriving cold

| Cloud | State |
|---|---|
| GCP | DEV-PROD-READY. svc #100, 2026-07-22 |
| AWS | DEV-PROD-READY. svc #102, 2026-07-29, 41m 30s. Not GA |
| Linode | DEV-PROD-READY. svc #103, 2026-07-31, 42m 27s |
| Vultr | DEV-PROD-READY. svc #104, 2026-08-02, 43m 19s wall / 34m 03s machine |
| SakuraCloud | t1 proven 2026-07-07 (svc #98). svc #105 aborted by us. **svc #106 graded FAILED 2026-08-05** |
| Azure | INACTIVE. MPN subscription retired 2026-05-11 |

**GCP, AWS, Linode and Vultr are COMPLETE and will NOT be retested before production.** Operator ruling,
2026-08-05. There is no time.

`phase_install` timings, for reference, since this is where Ansible version differences would surface first:

| Cloud | Tier | CPU class | `phase_install` |
|---|---|---|---|
| Vultr | t3 `vhf-2c-4gb`, `nrt` | High Frequency, shared | 8m 48s |
| AWS | t4 `m7i.large`, Seoul | Intel, full-performance | 8m 54s |
| Linode | t3 `g6-dedicated-2`, `jp-tyo-3` | Dedicated | 8m 55s |
| GCP | N2D, Tokyo | AMD EPYC, full-performance | 10m 22s |
| SakuraCloud | t3, `is1c` | Dedicated | 15m 54s |

---

## 12. KEY PATHS INDEX

| What | Path |
|---|---|
| Pre-flight rules, CANONICAL | `~/workspace/ProjectGenesis/CLAUDE/vps-session-preflight.md` |
| Infra state, paginated series | `.../vps-module-development/cardinal-docs/AUTHORITATIVE-INFRA-STATE.md` then latest `-vN` (v7 current) |
| Per-cloud sequences | `.../cardinal-docs/{GCP,AWS,Vultr,Linode,SakuraCloud}-...-Deployment-Sequence.md` |
| Sakura fast path | SakuraCloud sequence doc, `## 0. PRE-FLIGHT FAST PATH` |
| Ansible references, ours | `~/workspace/KnowledgeBase/devops-and-iac/ansible/` |
| Ansible playbook reference | `~/workspace/KnowledgeBase/references/ansible/` |
| cPanel log paths | `~/workspace/KnowledgeBase/security/ssh/ssh-aliases/aliases cPanel DNSOnly.md` |
| Customer-VM roles | `~/workspace/ProjectGenesis/whmcs-customizations/ansible-playbooks/customer-vm/` |
| Runner service code | `~/workspace/ProjectGenesis/whmcs-customizations/runner-service/runner/` |
| Runner deploy playbooks | `tecpresso-cloud-ops/environments/**production**/ansible/playbooks/infrastructure/runner/` |
| Speed benchmarks | `~/workspace/ProjectGenesis/webhostingm-mainsite/docs/standards/provisioning-speed-benchmarks.md` |
| Global tasks (SYMLINK) | `~/workspace/GLOBAL_TASKS.md` to `KnowledgeBase/GLOBAL_TASKS.md` - edit the real target |
| Review packet template | `.../codex-gemini-reviews/REVIEW-PROMPT-TEMPLATE.md` - never hand-roll a packet |
| Memory index | `~/.claude/projects/-Users-headsup-workspace-ProjectGenesis/memory/MEMORY.md` plus `MEMORY-ARCHIVE.md` |

**Runner deploy reminder:** you MUST `cd ~/workspace/tecpresso-cloud-ops/environments/production/ansible`
first. `ansible.cfg` only auto-loads from the current working directory, and running from the repo root
fails with `The role 'maintenance_common' was not found`. Read each playbook's own Usage header rather than
reconstructing the command. Reconstructing it took the runner down on 2026-07-26.

---

## 13. METHOD

Prioritise exhaustive accuracy over speed. Do not skip lines or files. Triple-check assumptions before
stating them as facts. Ground every claim in evidence, not recollection. Verify, do not assert - run the
thing. Never hand-count; take counts from the tool. Use System 2, slow and deliberative.

Slow is smooth and smooth is fast.

---

**Last Updated:** 2026-08-05
