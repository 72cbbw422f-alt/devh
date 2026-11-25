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
- [x] Scandinavian Light visual system: warm light grey, white surfaces, navy typography and restrained blue accents
- [x] Initial project portfolio
- [x] Overview metrics and project cards
- [x] Project list and detail screen
- [x] GitHub repository deep links
- [x] Native AI assistant workspace UI
- [x] GitHub Actions unsigned IPA build workflow
- [ ] Connect assistant backend and GitHub App
- [ ] Install and test on iPhone/iPad through FlareStore

## Project portfolio
Regnvakt, VITAL, Familjen, Antikspanaren, BingeLog, NEWSFLOW, NEXUS and ORBIT.

## AI assistant architecture
The iOS app must never contain an OpenAI API key or GitHub personal access token. The assistant will call a secure server-side service that uses the OpenAI Responses API and a GitHub App integration.

Planned capabilities:
- Read project files, commits, issues, pull requests and Actions logs
- Explain build failures and propose code changes
- Create issues and prepare branches or pull requests
- Run approved workflows and report their results
- Require explicit confirmation before writes, merges, releases or other consequential actions

## Roadmap
1. Persistent project register: create, edit, archive, categories, status and progress.
2. Secure AI backend and GitHub App integration.
3. GitHub workspace: repositories, commits, branches, PRs, issues, releases and CI status.
4. Roadmap and task management: milestones, features, bugs, notes and project history.
5. Business dashboard: revenue providers, subscriptions, costs and profit by project.
6. Analytics and notifications.

## Security
Never store GitHub personal access tokens, OpenAI API keys, Stripe secrets or other provider credentials in the iOS app. Keep credentials in server-side secrets. Scope GitHub permissions to the minimum required and require user approval for write operations.

Repository: https://github.com/72cbbw422f-alt/devh
