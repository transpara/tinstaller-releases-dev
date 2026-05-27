# Transpara Installer — Dev Releases

Internal **prerelease** (DevRelease) builds of tinstaller, cut on demand from
any branch. See `transpara/tinstaller` → `docs/adr/0002-dev-releases.md`.

> **Not for production.** These are unreleased, possibly-broken builds.
> Requires the GitHub CLI (`gh`), authenticated with access to this private
> repo (`gh auth login`).

# Quickstart

## Install k3s

```bash
bash <(gh api repos/transpara/tinstaller-releases-dev/contents/get-and-run.sh -H "Accept: application/vnd.github.raw") install-k3s
```

## Install tsystem and essentials

```bash
source ~/.bashrc && bash <(gh api repos/transpara/tinstaller-releases-dev/contents/get-and-run.sh -H "Accept: application/vnd.github.raw") install-tsystem
```

The latest dev release is used by default. To pin a specific one, append
`--version <X.Y.Z-dev.N>`, e.g. `install-k3s --version 0.281.0-dev.1`.

# Uninstall

Uninstall is repo-agnostic — use the standard public scripts.

## Clean up system (uninstall k3s and remove leftovers)

```bash
curl -sfL https://github.com/transpara/tinstaller-releases/releases/latest/download/uninstall.sh | bash -s -- --nuke-k3s
```

## Remove transpara components without affecting the rest of the cluster

```bash
curl -sfL https://github.com/transpara/tinstaller-releases/releases/latest/download/uninstall.sh | bash -s --
```
