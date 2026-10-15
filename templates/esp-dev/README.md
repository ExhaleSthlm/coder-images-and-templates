# ESP development Coder template

Creates a workspace in `coder-workspaces` with:

- an Intel i915 accelerated XFCE/Selkies desktop
- the full ESP toolchain available to VS Code and the Coder agent
- a replicated LINSTOR PVC mounted at `/config`
- labels consumed by the daily Velero volume snapshot backup
- path-based access through `https://coder.myk8s.se`

## Publish

Authenticate the Coder CLI and push the template:

```bash
coder login https://coder.myk8s.se
coder templates push esp-dev --directory templates/esp-dev
```

The image should be changed from `:main` to an immutable digest after the first
successful GHCR build.
