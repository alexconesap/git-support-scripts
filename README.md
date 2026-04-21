# Support Scripts

> Maintained by Alex Conesa

This repository provides utility scripts to manage multiple Git repositories simultaneously. It eliminates the need to clone, update, or commit each repository individually.

The primary use case is handling shared libraries across multiple projects. This is not a replacement for Git submodules, but a practical approach for managing multiple local repositories that are actively developed and reused across projects.

All repositories are defined in a `.repos` file.

## .repos file structure

```text
# URL | directory | group
https://github.com/alexconesap/repo1.git|the_local_folder_for_repo1|base
https://github.com/alexconesap/repo2.git|folder_repo2|tools
```

Each entry specifies:

- Repository URL
- Local directory name
- Group label (used for filtering or grouping)

Check the `git_update.sh` script below for more details.

A [sample file](.repos.example) is provided.

## Setup

Clone this repository into the root directory containing your libraries (e.g., support) and make the scripts executable:

```shell
git clone https://github.com/alexconesap/git-support-scripts support
chmod +x ./support/*sh
```

Copy the default `.repos.example` file and edit it to define your own repositories.

```shell
[ -f .repos ] || cp ./support/.repos.example .repos
```

## Git scripts

### Clone all repositories

Clones all repositories listed in .repos.

Useful for quickly setting up environments (development, testing, production, etc.).

```shell
./support/git_clone.sh # Clones ALL repositories defined at the .repos file
./support/git_clone.sh --tools # Clones the repos belonging to the 'base' group and to the 'tools' group
./support/git_clone.sh --tools --extra # Clones the repos belonging to the 'base' group and to the 'tools' and 'extra' groups
```

### Update repositories

Pulls updates for all, or group-based, repositories.

Useful for keeping a system fully synchronized.

```shell
./support/git_update.sh # Updates ALL repositories defined at .repos
./support/git_update.sh --tools # Updates the repos belonging to the 'base' group and to the 'tools' group
./support/git_update.sh --tools --extra # Updates the repos belonging to the 'base' group and to the 'tools' and 'extra' groups
```

### Commit local changes

Commits, and optionally `--push` changes across all repositories at once.
Useful when working on multiple repositories simultaneously.

```shell
./support/git_commit_all.sh
./support/git_commit_all.sh "Updated URL"
./support/git_commit_all.sh "Updated URL" --push
```

### Check repository status

Displays the status of all repositories to identify pending changes.

```shell
./support/git_status.sh
```

## C/C++ repositories maintenance

### Format Source Files

Formats C/C++ files using `clang-format` and each library's own `.clang-format` configuration.

```shell
./support/format_c_files.sh                         # List libraries with a .clang-format and ask before formatting all
./support/format_c_files.sh lib lib_display         # Format only the given directories
./support/format_c_files.sh src/ tests/test_x.cpp   # Mix of directories and individual files
```

When run with no arguments, the script discovers every sibling folder that contains a `.clang-format` file (skipping `tests/vendor/`), prints the list, and asks `Do you want to process all of them? [y/N]`. Anything other than `y`/`yes` aborts.

### Run tests

Runs the test suite of every sibling repository that contains a `tests/` directory with a `2_run.sh` script.

```shell
./support/run_tests.sh                       # Run tests for ALL repositories
./support/run_tests.sh lib lib_display       # Run tests only for the listed folders
./support/run_tests.sh --clean               # Wipe tests/build and rebuild (1_build.sh) before running
./support/run_tests.sh --clean lib_hal       # Clean build + run, limited to lib_hal
```

Options:

- `--clean`: removes each repo's `tests/build` directory and invokes `1_build.sh` before `2_run.sh`.
- Any non-flag argument is treated as a folder name filter. Unknown flags (starting with `-`) are rejected.

### Bump a library version and publish a tag

Bumps a library to a new version, commits the change, creates an annotated tag `v<version>`, and pushes both to `origin`.

```shell
./support/set_tag_version.sh lib_motor 2.0.3
./support/set_tag_version.sh lib_display 1.1.0
```

Actions performed:

1. Updates the `version=` line in `<lib>/library.properties`
2. Writes the version into `<lib>/.version`
3. Commits with message `chore: bump version to <version>`
4. Creates annotated tag `v<version>`
5. Pushes the current branch and the new tag to `origin`

The commit is authored by the git user configured on the host (`git config user.name` / `user.email`) — the script never overrides it. The script refuses to run if the tag already exists locally or remotely, or if the target library has unrelated uncommitted changes.

## Optional alias

Example shortcut:

```shell
alias gss='./support/git_status.sh'
```

## Acknowledgements

Thanks to Claude and ChatGPT for helping on generating this documentation.

## License

MIT License — see [LICENSE](license.txt) file.
