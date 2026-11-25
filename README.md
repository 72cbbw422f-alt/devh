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
- Version: `1.0.0 (2)`

## Current foundation
- [x] Native SwiftUI app shell and tab navigation
- [x] Scandinavian Light visual system: warm light grey, white surfaces, navy typography and restrained blue accents
- [x] Initial project portfolio
- [x] Overview metrics and project cards
- [x] Project list and detail screen
- [x] GitHub repository deep links
- [x] Native AI assistant workspace UI
- [x] GitHub Actions unsigned IPA build workflow
- [x] Serverless GitHub Actions workflow for read-only AI project analysis
- [ ] Connect assistant screen to GitHub workflow dispatch
- [ ] Add OpenAI API key as a GitHub Actions repository secret
- [ ] Add approved code-change and pull-request workflow

## Project portfolio
Regnvakt, VITAL, Familjen, Antikspanaren, BingeLog, NEWSFLOW, NEXUS and ORBIT.

## Serverless AI assistant architecture
No separately hosted backend or database is required for the first version:
- DEVHUB will dispatch a workflow in this repository through the GitHub REST API.
- GitHub Actions checks out the selected public project and prepares a bounded source snapshot.
- The workflow calls the OpenAI Responses API using the `OPENAI_API_KEY` GitHub Actions secret.
- The result is written to the GitHub Actions run summary.
- The initial workflow is strictly read-only. It cannot push commits, change files or create pull requests.

The iOS app will keep the GitHub fine-grained personal access token in the iOS Keychain, never in source code or UserDefaults. The token is only used to dispatch and read workflow runs. For dispatch, GitHub requires the repository Actions permission set to write.

### First-time setup
1. Create an OpenAI API key in the OpenAI developer platform.
2. In this repository, open Settings → Secrets and variables → Actions.
3. Add a repository secret named `OPENAI_API_KEY`.
4. Create a fine-grained GitHub personal access token restricted to this repository, with Actions: Read and write. The app integration will use it to dispatch the workflow and inspect its result.
5. Do not paste either key into issues, source files, chat messages or commits.

## Safety model
The initial AI workflow is read-only. Later code-writing support will use a separate workflow that creates a branch and pull request. DEVHUB will require explicit approval before any code-writing run, merge, release or other consequential action. No automatic push to the default branch.

## Roadmap
1. Serverless AI analysis through GitHub Actions.
2. Connect the native assistant UI to workflow dispatch and result polling.
3. Approved code changes on isolated branches with pull requests.
4. GitHub workspace: commits, branches, PRs, issues, releases and CI status.
5. Persistent project register, roadmap and business dashboard.

Repository: https://github.com/72cbbw422f-alt/devh
