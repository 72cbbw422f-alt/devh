# DEVHUB

**Native iPhone and iPad command center for an independent app studio.**

DEVHUB is a SwiftUI app for tracking every project regardless of distribution channel. App Store Connect is optional, never the foundation.

## Platform and build
- Native SwiftUI for iPhone and iPad
- iOS 17+
- XcodeGen project specification
- GitHub Actions builds an unsigned IPA artifact for signing and sideloading with FlareStore
- No Mac required locally; CI uses a hosted macOS runner
- Bundle ID: `se.niklas.devhub`
- Version: `1.0.0 (1)`

## Current foundation
- [x] Native SwiftUI app shell and tab navigation
- [x] Midnight dark theme with lime accents
- [x] Initial project portfolio
- [x] Overview metrics and project cards
- [x] Project list and detail screen
- [x] GitHub repository deep links
- [x] GitHub Actions unsigned IPA build workflow
- [x] First CI build completed successfully and IPA package structure verified
- [ ] Install and test on iPhone/iPad through FlareStore

## Project portfolio
Regnvakt, VITAL, Familjen, Antikspanaren, BingeLog, NEWSFLOW, NEXUS and ORBIT.

## Roadmap
1. Persistent project register: create, edit, archive, categories, status and progress.
2. GitHub integration: repositories, commits, branches, PRs, issues, releases and CI status.
3. Roadmap and task management: milestones, features, bugs, notes and project history.
4. Business dashboard: revenue providers (Stripe first), subscriptions, costs and profit by project.
5. Analytics and notifications.

## Security
Never store GitHub personal access tokens, Stripe secrets or other provider credentials in the iOS app. Integrations must use a secure server-side broker.

Repository: https://github.com/72cbbw422f-alt/devh
