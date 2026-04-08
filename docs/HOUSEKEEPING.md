# Housekeeping Checklist - Pre-labhost00 Build

## Priority 1: Core Documentation Fixes
- [ ] Fix README.md header - change "homelab-controller" to "homelab-observability"
- [ ] Update GitHub URL in README.md to correct repo
- [ ] Remove scratchpad notes from README.md (lines 36, 38-44)
- [ ] Clean up PORTS.md - remove Python code (lines 25-38)

## Priority 2: File Structure Cleanup
- [ ] Remove or complete placeholder README.md files in tool folders
- [ ] Create proper prompt_style_guide.md or remove placeholder
- [ ] Verify/clean docker-compose.yml files (05-docker-elk, 07-graylog)

## Priority 3: Missing Essential Files
- [ ] Create .env.example with standard variables
- [ ] Create scripts/ folder structure
- [ ] Add .gitignore for sensitive files

## Priority 4: LGTM Stack Decision
- [ ] Decide on 04-lgtm-stack scope (Prometheus + Grafana + Alertmanager + Loki + Tempo?)
- [ ] Create 04-lgtm-stack/docker-compose.yml skeleton
- [ ] Update deployment order if needed

## Priority 5: Alignment with stream-lake Pattern
- [ ] Review stream-lake project structure for consistency
- [ ] Ensure deployment scripts follow same pattern
- [ ] Verify networking approach matches

## Status: Ready for labhost00 Build
- [ ] All housekeeping complete
- [ ] Documentation accurate
- [ ] No placeholder content
- [ ] Repository clean and professional

---
*This checklist will be deleted once housekeeping is complete*
