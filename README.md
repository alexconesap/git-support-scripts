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
[ -f .repos ] || cp .repos.example .repos
```

## Git scripts

### Clone all repositories

Clones all repositories listed in .repos.

Useful for quickly setting up environments (development, testing, production, etc.).

```shell
./support/git_clone.sh
```

### Update all repositories

Pulls updates for all repositories.

Useful for keeping a system fully synchronized.

```shell
./support/git_update.sh
```

### Commit local changes

Commits changes across all repositories at once.
Useful when working on multiple repositories simultaneously.

```shell
./support/git_commit_all.sh
```

### Check repository status

Displays the status of all repositories to identify pending changes.

```shell
./support/git_status.sh
```

## C/C++ repositories maintenance

### Format Source Files

Formats C/C++ files using `clang-format` and the project’s `.clang-format` configuration.

```shell
./support/format_c_files.sh lib lib_display
```

## Optional alias

Example shortcut:

```shell
alias gss='./support/git_status.sh'
```
