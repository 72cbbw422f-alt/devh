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
- Version: `1.0.0 (3)`

## Visual identity
- Midnight / Indigo Premium design system
- Deep navy background, indigo primary accent, blue and cyan secondary accents
- Rounded elevated surfaces, restrained gradients, clear progress and status indicators
- Dedicated vector app icon source at `DEVHUB/Resources/AppIcon.svg`; CI rasterizes it to the 1024px iOS AppIcon asset before building

## Current foundation
- [x] Native SwiftUI app shell and tab navigation
- [x] Midnight / Indigo Premium visual system
- [x] Initial six-project portfolio
- [x] Overview hero, project count and average planned progress
- [x] Premium project cards with status and progress indicators
- [x] Project list and project detail screens
- [x] Create custom projects with name, description, platform, category, status, accent color and optional GitHub repository
- [x] Edit existing project metadata
- [x] Archive and restore projects without deleting their data
- [x] Persist project records and task checklists locally with SwiftData
- [x] Per-project milestone roadmap and interactive task checklist (task completion and custom tasks persisted locally with SwiftData)
- [x] GitHub repository deep links
- [x] Native AI assistant workspace UI
- [x] GitHub Actions unsigned IPA build workflow
- [x] Serverless GitHub Actions workflow for read-only AI project analysis

## Project portfolio
Familjen, Watchlist, Antikspanaren, Regnvakt, Hemma and DEVHUB.

Project progress values and milestone examples are still planning data until live repository synchronization is implemented. Project records and task checklists are stored locally with SwiftData. GitHub repository metadata and cross-device project synchronization are not yet connected. Custom projects can be added from the plus button in the Projects tab; existing projects can be edited or archived with swipe actions, and archived projects can be restored from the archive view.

## Serverless AI assistant architecture
No separately hosted backend or database is required for the first version:
- DEVHUB dispatches a workflow in this repository through the GitHub REST API.
- GitHub Actions checks out the selected public project and prepares a bounded source snapshot.
- The workflow calls the OpenAI Responses API using the `OPENAI_API_KEY` GitHub Actions secret.
- The result is written to the GitHub Actions run summary.
- The initial workflow is strictly read-only. It cannot push commits, change files or create pull requests.

The iOS app keeps the GitHub fine-grained personal access token in the iOS Keychain, never in source code or UserDefaults. The token is used to dispatch and read workflow runs. For dispatch, GitHub requires the repository Actions permission set to write.

### First-time setup
1. Create an OpenAI API key in the OpenAI developer platform.
2. In this repository, open Settings → Secrets and variables → Actions.
3. Add a repository secret named `OPENAI_API_KEY`.
4. Create a fine-grained GitHub personal access token restricted to this repository, with Actions: Read and write.
5. Do not paste either key into issues, source files, chat messages or commits.

## Safety model
The initial AI workflow is read-only. Later code-writing support will use a separate workflow that creates a branch and pull request. DEVHUB will require explicit approval before any code-writing run, merge, release or other consequential action. No automatic push to the default branch.

## Roadmap
1. Persistent milestone editing and optional iCloud synchronization.
2. Shared GitHub client and live repository status, commits, branches, PRs, issues, releases and CI.
3. Connect roadmap and project health to real repository signals.
4. Approved code changes on isolated branches with pull requests.
5. Studio analytics and optional financial integrations.

Repository: https://github.com/72cbbw422f-alt/devh
