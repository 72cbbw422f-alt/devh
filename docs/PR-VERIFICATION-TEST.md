# DEVHUB PR verification test

This documentation-only change is used to validate the GitHub pull-request verification workflow.

Expected behavior:
- An open pull request must not verify a task.
- A merged pull request with successful checks may verify a task.
- Failed or incomplete checks must block verification.

No application source code is changed by this test.
