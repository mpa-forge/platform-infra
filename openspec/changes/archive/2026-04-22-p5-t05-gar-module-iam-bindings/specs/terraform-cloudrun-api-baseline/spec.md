## ADDED Requirements

### Requirement: Cloud Run API consumes regional GAR images
The Cloud Run API environment binding SHALL use regional GAR image URI
contracts for API images and SHALL receive repository-scoped Artifact Registry
reader access through its runtime service account.

#### Scenario: API image is deployed from GAR
- **WHEN** the Cloud Run API service uses an image from the environment GAR
  `apps` repository
- **THEN** the image reference MUST use the environment region and project id,
  and the API runtime service account MUST be grantable as a repository-scoped
  reader on that `apps` repository.
