# claude-box

`cb` runs Claude Code in a throwaway Docker container - a *box* - with the
current directory mounted in. Every invocation is a fresh `docker run --rm`: the
box lives exactly as long as the claude (or shell) it was started for, and
several boxes can run for the same checkout at once.

What survives a run lives outside the container:

- **`~/.claude`** from the host is bind-mounted into every box, so login,
  `settings.json`, plugins and per-project history are set up once and shared.
- **The checkout** is mounted at `/workspaces/<name>`, unique per repo, so
  Claude keeps transcripts, memory and trust per project as it does on the host.
- **Shell history** is a Docker volume per checkout (`cb-history-<hash>`).
- **Playwright browsers** are one volume shared by every box (`cb-playwright`).

The image is based on `node:26-trixie-slim` with git, gh, build-essential,
cmake and the usual command-line tools. Heavier toolchains are opt-in
[image features](#image-features-cb-image-config).

## Install

```sh
git clone https://github.com/twiebe/claude-box.git ~/.local/share/claude-box
~/.local/share/claude-box/install.sh
```

`install.sh` symlinks `bin/cb` into `~/.local/bin` and the zsh completion
`completions/_cb` into `~/.local/share/zsh/site-functions`. Override the
targets with `CB_BIN_DIR` and `CB_COMPLETION_DIR`. For the completion to load,
that directory has to be on `fpath` before `compinit` runs:

```zsh
fpath=("${XDG_DATA_HOME:-$HOME/.local/share}/zsh/site-functions" $fpath)
```

`install.sh` is safe to run again. To update, `git pull` in the checkout - the
links point into it. `uninstall.sh` removes the links and lists what cb created
(images, volumes, settings) without touching it.

Requirements: Python 3 and Docker with BuildKit - Docker Desktop, OrbStack, or
docker plus buildx on Linux. Rootless podman via podman-docker works too.

## Quick start

```sh
cd ~/git/myproject
cb enable git ~/git   # allow boxes at the top of any git checkout under ~/git
cb                    # builds the image on first use, then starts claude
```

Arguments cb does not know, or anything after `--`, go to claude:

```sh
cb --continue         # same as cb run --continue
cb -- -p "fix the failing test"
cb shell              # zsh instead of claude
```

## Where boxes may start

A box hands the directory it is started in to an agent, so starting one in the
wrong place - `$HOME`, `/`, wherever a stray `cd` landed - is the expensive
mistake. cb refuses unless a tag file (`.CLAUDEBOXDIR.TAG`) in the directory or
one of its parents allows it:

```sh
cb enable all [DIR]   # boxes anywhere in DIR and below
cb enable git [DIR]   # only in directories that are the top of a git checkout
cb disable [DIR]      # nowhere in DIR and below, whatever is above
cb untag [DIR]        # remove DIR's tag; the next one up applies again
cb enabled [DIR]      # whether a box may start here, and which tag decides
```

DIR defaults to the current directory, and the nearest tag wins. `--force`
skips the check for one run; `cb config force true` skips it for every run in
this directory.

## Box settings: `cb config`

Each directory has its own settings, stored under
`~/.local/state/claude-box/projects/`. A flag applies to that run only;
`cb config` makes it stick. Flag beats stored setting beats default (all off).

A directory is identified by its real path, with every symlink resolved, so
`/home/you/repo` and `/var/home/you/repo` on Fedora Atomic desktops are one box
with one set of settings. The same goes for `cb enable` tags: the ones that count
sit at or above the real directory, not above a symlink leading to it.

| Setting     | Flag                             | Effect                                                                                           |
| ----------- | -------------------------------- | ------------------------------------------------------------------------------------------------ |
| `docker`    | `--docker` / `--no-docker`       | Runs a Docker daemon inside the box, as a privileged container. Needs the `docker` image feature. |
| `ssh-agent` | `--ssh-agent` / `--no-ssh-agent` | Forwards the host's ssh agent, so `git push` over ssh works. Keys stay in the agent. macOS only.  |
| `force`     | `--force`                        | Starts even where no tag allows it.                                                              |

```sh
cb config                  # every setting for this directory, and where its value comes from
cb config docker           # one setting
cb config docker true      # remember it
cb config --prune          # drop settings of directories that no longer exist
```

`cb config` also shows how many mounts and ports are remembered, and which
features and tool versions the current image was built with.

## Extra mounts: `cb mount` and `-v`

The checkout is always mounted. Other directories - a sibling repo, a data
directory - are added per run with `-v`, or remembered for every run in this
directory with `cb mount`:

```sh
cb -v ../shared-lib                      # this run only
cb mount add ../shared-lib               # every run started here
cb mount add --ro ~/datasets/big         # read-only
cb mount add ~/notes:/notes              # at an explicit path in the box
cb mount ls
cb mount rm ../shared-lib                # by source or by target
```

The spec is `SRC[:DST][:ro]`, close to docker's `-v`. Relative sources are
resolved against the current directory. Without `DST` a mount lands at
`/workspaces/<name of SRC>` - the path it would have in its own box, so
Claude's per-project state lines up between the two. A `-v` on a remembered
target replaces that mount for one run, for example to make it read-only once.

## Published ports: `cb port` and `--port`

To reach a dev server in the box from the host, publish its port. Specs use
docker's `-p` syntax, `[IP:][HOST:]CONTAINER[/PROTO]`, ranges allowed:

```sh
cb --port 3000                           # this run; docker picks a free host port
cb port add 127.0.0.1:8080:8080          # every run, fixed host port, localhost only
cb port add 5173:5173
cb port ls
cb port rm 8080                          # by spec or by host port
```

Without an IP the port listens on every interface of the host. Without a host
port docker picks one, and `docker port <box>` shows which. Remembered ports
apply to every box of the checkout, so a second box fails on a fixed host port
the first one holds.

## Image features: `cb image-config`

All boxes share one image, `claude-box:latest`, which is Claude Code on top of
`claude-box:base`. Toolchains are features of the base image, all off by
default:

| Feature           | Adds                                                                     |
| ----------------- | ------------------------------------------------------------------------ |
| `docker`          | docker engine and buildx, for `cb --docker`                              |
| `ffmpeg`          | ffmpeg                                                                   |
| `go`              | Go, newest release at build time                                         |
| `kubernetes`      | kubectl (upstream, current) and kustomize                                |
| `pandoc`          | pandoc                                                                   |
| `playwright-deps` | the system libraries Chromium needs for Playwright, not Playwright itself |
| `python`          | python3, pip, venv, uv and IPython                                       |
| `rust`            | rustup with the stable toolchain, clang, cbindgen                        |
| `sqlx`            | sqlx-cli; needs `rust`                                                   |
| `tofu`            | OpenTofu, newest release at build time                                   |

`cb image-config` only records what the next build should contain. Nothing is
rebuilt until asked:

```sh
cb image-config                # every feature, and where the image on disk differs
cb image-config rust true
cb image-config sqlx true
cb rebuild-image               # build with the recorded features
```

Or in one step, which records the choice as well:

```sh
cb rebuild-image --with-rust --with-sqlx --without-go
cb rebuild-image --no-cache    # from scratch, e.g. for newer apt packages
```

The choice is kept in `~/.local/state/claude-box/image.json`. The image also
carries it as a label, so `docker inspect` remains the authority on what was
actually built.

`cb update-claude` installs the newest Claude Code on top of the existing base
image - seconds instead of a full rebuild. Running boxes keep their version
until they exit.

## Working with running boxes

```sh
cb ls [DIR]              # running boxes, all or those of DIR
cb exec CMD…             # run CMD in this directory's box
cb exec -n NAME CMD…     # in a specific box, by name or its last 4 characters
```

## Housekeeping

```sh
cb volume prune playwright   # empty the shared browser cache
cb volume prune all          # that, plus shell history of checkouts that are gone
cb mv SRC DST                # move a checkout along with its settings, mounts,
                             # shell history and Claude history
```

`--dry-run` makes any command print what it would run instead of running it;
`-y` answers prompts with yes. `cb --help` has the full reference.

## Repository layout

- `bin/cb` - the CLI; finds `image/` relative to its own real path
- `image/` - the Dockerfiles and the scripts copied into the image
- `completions/_cb` - zsh completion
- `tests/` - `python3 -m unittest discover -s tests`
- `install.sh`, `uninstall.sh`
