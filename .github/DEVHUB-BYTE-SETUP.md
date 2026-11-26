# DEVHUB Byte – setup for approved code changes

Byte's analysis workflow is read-only. Applying a patch is a separate, explicitly approved workflow.

## Required repository secret

In the DEVHUB repository, open **Settings → Secrets and variables → Actions → New repository secret**.

Create:

- Name: `PROJECTS_GITHUB_TOKEN`
- Value: a fine-grained GitHub token that has access to every project repository Byte may modify.
- Required repository permissions: **Contents: Read and write** and **Pull requests: Read and write**.
- Keep Actions workflow permissions in DEVHUB limited to the existing app token's ability to dispatch workflows. Do not add write permissions to the analysis workflow.

The secret is used only by `.github/workflows/apply-byte-patch.yml` to create a branch and pull request in the selected project. It is never passed to the OpenAI API or included in the patch prompt.

## Safety checks

The apply workflow checks the exact base commit, requires the target `main` branch to still point at that commit, validates patch paths, runs `git apply --check`, and creates a separate `byte/approved-*` branch. It opens a pull request and never merges it.

If `main` has moved, the workflow stops. Byte must generate a fresh proposal against the current project state.

## Build and test validation

The apply workflow does not claim that project-specific tests passed. Those checks must be supplied by each project's CI workflow and reviewed on the resulting pull request.
