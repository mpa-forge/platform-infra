# Tasks

- [x] Add a shared `modules/stack` composition module for environment roots
- [x] Replace root-level module toggles with `deployment_preset` and
  `deployment_enabled`
- [x] Add a `single-vps` preset and `modules/vps_stack`
- [x] Default `rc` to `single-vps`
- [x] Default `prod` to `cloudrun-cloudsql`
- [x] Extend Cloud Run, GKE, and secrets modules for shared runtime contracts
- [x] Add preset-aware root outputs and operator documentation
- [x] Validate all roots and modules with `make terraform-validate`
