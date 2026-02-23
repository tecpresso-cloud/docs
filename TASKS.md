# KB Docs - Mintlify Setup Tasks

## Credentials / Access Needed
- [ ] Mintlify dashboard login (connect this repo at mintlify.com/start)
- [ ] Install Mintlify GitHub App on `metacogni/kb-docs`
- [ ] Custom domain setup (if desired, e.g., `docs.webhostingm.com` or `kb.tecpresso.com`)
- [ ] Logo SVGs for `/logo/dark.svg` and `/logo/light.svg`
- [ ] Favicon SVG at `/favicon.svg`

## Phase 1: Mintlify Setup
- [ ] Connect repo to Mintlify dashboard
- [ ] Install Mintlify CLI locally (`npm i -g mint`)
- [ ] Verify local preview with `mint dev`
- [ ] Add logo and favicon assets
- [ ] Configure custom domain (optional)

## Phase 2: Populate Content from KnowledgeBase
- [ ] Infrastructure section: migrate from `~/workspace/KnowledgeBase/TECPRESSO_CloudOps/`
- [ ] Terraform runbook: migrate from `~/workspace/KnowledgeBase/best-practices/terraform/`
- [ ] cPanel references: curate from `~/workspace/KnowledgeBase/references/cpanel/`
- [ ] WHMCS references: curate from `~/workspace/KnowledgeBase/references/whmcs-ref/`
- [ ] CloudLinux references: curate from `~/workspace/KnowledgeBase/references/cloudlinux-os/`
- [ ] SakuraCloud references: curate from `~/workspace/KnowledgeBase/references/sakuracloud/`
- [ ] Server deployment runbook: consolidate from DEPLOYMENT.md files
- [ ] WHMCS deployment runbook: consolidate from rsync docs

## Phase 3: Freshness Automation
- [ ] Set up launchd plist (macOS) or cron job for weekly `check-references.sh`
- [ ] Update script with current provider versions after each upgrade
- [ ] Monitor vendor doc sites for `llms.txt` availability
- [ ] When WHMCS enables llms.txt, add auto-pull script for `/llms-full.txt`
- [ ] Add llms.txt pull for any vendor that exposes it

## Phase 4: Cross-Machine Sync
- [ ] Clone repo on other workstations
- [ ] Create Obsidian vault pointing to `~/workspace/kb-docs/` on each machine
- [ ] Verify git pull/push workflow across machines

## Notes
- Mintlify auto-generates `/llms.txt` and `/llms-full.txt` for our own docs
- MDX frontmatter is Obsidian-compatible (renders as YAML in Obsidian)
- Private repo = llms.txt NOT publicly accessible (auth required)
