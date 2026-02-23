# KB Docs - Mintlify Setup Tasks

## Credentials / Access Needed
- [x] Mintlify dashboard login (connect this repo at mintlify.com/start)
- [x] Install Mintlify GitHub App on `tecpresso-cloud/docs`
- [x] Custom domain setup (`docs.webhostingm.com` via CNAME to `cname.mintlify-dns.com`)
- [ ] Logo SVGs for `/logo/dark.svg` and `/logo/light.svg`
- [x] Favicon SVG at `/favicon.svg`

## Phase 1: Mintlify Setup
- [x] Connect repo to Mintlify dashboard
- [x] Install GitHub App on tecpresso-cloud Org
- [x] Migrate content from kb-docs to docs repo
- [x] Convert mint.json to docs.json (current format)
- [x] Configure custom domain (docs.webhostingm.com)
- [x] Add noindex meta tag (internal KB)
- [x] Add custom 404 page
- [ ] Install Mintlify CLI locally (`npm i -g mint`)
- [ ] Verify local preview with `mint dev`
- [ ] Add logo assets

## Phase 2: Populate Content from KnowledgeBase
- [ ] Infrastructure section: migrate from `~/workspace/KnowledgeBase/TECPRESSO_CloudOps/`
- [ ] Terraform runbook: migrate from `~/workspace/KnowledgeBase/best-practices/terraform/`
- [ ] cPanel references: curate from `~/workspace/KnowledgeBase/references/cpanel/`
- [ ] WHMCS references: curate from `~/workspace/KnowledgeBase/references/whmcs-ref/`
- [ ] CloudLinux references: curate from `~/workspace/KnowledgeBase/references/cloudlinux-os/`
- [ ] SakuraCloud references: curate from `~/workspace/KnowledgeBase/references/sakuracloud/`
- [ ] Vultr references: curate from `~/workspace/KnowledgeBase/references/terraform/vultr-terraform/`
- [ ] Vultr WHMCS VPS module integration docs
- [ ] Server deployment runbook: consolidate from DEPLOYMENT.md files
- [ ] WHMCS deployment runbook: consolidate from rsync docs

## Phase 3: Freshness Automation
- [x] Add GitHub Actions workflow for weekly freshness check (check-freshness.yml)
- [x] Add Vultr and Cloudflare to check-references.sh
- [ ] Update script with current provider versions after each TF upgrade
- [ ] Monitor vendor doc sites for `llms.txt` availability
- [ ] When WHMCS enables llms.txt, add auto-pull script for `/llms-full.txt`
- [ ] Add llms.txt pull for any vendor that exposes it

## Phase 4: Cross-Machine Sync
- [ ] Clone repo on other workstations
- [ ] Create Obsidian vault pointing to `~/workspace/docs/` on each machine
- [ ] Verify git pull/push workflow across machines

## Notes
- Mintlify auto-generates `/llms.txt` and `/llms-full.txt` for our own docs
- MDX frontmatter is Obsidian-compatible (renders as YAML in Obsidian)
- Private repo = llms.txt NOT publicly accessible (auth required)
- Repo moved from metacogni/kb-docs → tecpresso-cloud/docs (2026-02-22)
- Vultr is an official partner — Terraform provider + WHMCS VPS module(s) planned
