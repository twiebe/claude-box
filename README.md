# claude-box

`cb` starts a fresh container per run with Claude Code in it, mounted on the
current directory.

## Install

```sh
git clone https://github.com/twiebe/claude-box.git ~/.local/share/claude-box
~/.local/share/claude-box/install.sh
```

`install.sh` symlinks `bin/cb` into `~/.local/bin` and the zsh completion
`completions/_cb` into `~/.local/share/zsh/site-functions`. Override with
`CB_BIN_DIR` and `CB_COMPLETION_DIR`. The completion directory has to be on
`fpath` before `compinit` runs.

It is safe to run again; to update, `git pull` in the checkout. `uninstall.sh`
removes the links and lists what cb created (images, volumes, settings) without
touching it.

The image is built on the first `cb` run. `cb --help` lists the commands.

## Layout

- `bin/cb` — the CLI; finds `image/` relative to its own real path
- `image/` — the Dockerfiles and the scripts copied into the image
- `completions/_cb` — zsh completion
- `tests/` — `python3 -m unittest discover -s tests`
