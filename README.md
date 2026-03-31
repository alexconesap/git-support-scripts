# Support Scripts

> Maintained by Alex Conesa

This repository contains utility scripts to manage multiple Git repositories at once.  
It avoids having to clone, update, or commit each repository individually.

All repositories are defined in the `.repos` file.

## Git scripts

First of all clone this repository at the root of your libraries folder. Then make all scripts executable.

```shell
chmod +x ./support/*
```

### Clone all repositories

Clones all repositories listed in `.repos` into the local environment.

Used on deployment machines (development, test, pre-production, production) to set up all required project dependencies.

```shell
./support/git_clone.sh
```

### Update all repositories

Once in a development computer or server, it just pulls all remote repositories changes all at once.

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

Shows the status of all repositories, allowing you to identify which ones have pending changes.

```shell
./support/git_status.sh
```

## C/C++ scripts

### Format files

Formats all C/C++ source files in the specified directories using `clang-format` and the project's `.clang-format` configuration.

```shell
./support/format_c_files.sh lib lib_display
```

## Optional alias

For faster access, as an example:

```shell
alias gss='./support/git_status.sh'
```
