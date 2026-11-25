# DEVHUB

**Developer command center for independent projects.**

DEVHUB is a project-agnostic workspace for tracking software projects, development activity, releases, roadmap progress, analytics and revenue — without depending on App Store Connect.

## Product direction
- Dark, premium, responsive interface.
- iPhone-friendly web app; PWA capabilities planned.
- GitHub is the first integration and source of truth for development activity.
- Revenue providers (Stripe and others) connect per project.
- iOS, tvOS, web, internal tools and experiments are all supported.

## Foundation 0.1.0
- [x] Responsive dashboard shell and navigation
- [x] Initial project portfolio seeded from existing studio repositories
- [x] Project progress cards and overview metrics
- [x] Basic interactive task list
- [x] Honest placeholder states for integrations not yet connected

## Roadmap

### Phase 1 — Workspace
- [ ] Persistent project CRUD and metadata
- [ ] Project detail pages, milestones and notes
- [ ] Persistent tasks and roadmap

### Phase 2 — GitHub
- [ ] Secure GitHub App/OAuth integration (server-side credentials only)
- [ ] Repository mapping per project
- [ ] Commits, branches, pull requests, issues and releases
- [ ] CI/workflow status and deployment activity

### Phase 3 — Business intelligence
- [ ] Stripe revenue integration
- [ ] MRR, ARR, refunds, fees and customer counts
- [ ] Hosting/service costs by project
- [ ] Profitability and revenue history

### Phase 4 — Analytics and automation
- [ ] Privacy-conscious product analytics integrations
- [ ] Notifications for failed builds and releases
- [ ] Weekly studio digest and exportable reports

## Architecture principles
Start with a responsive web application. Keep provider credentials on a server-side integration layer. Do not display fabricated live data or imply an integration is connected when it is not. Add persistence and integrations incrementally.

## Repository
https://github.com/72cbbw422f-alt/devh
