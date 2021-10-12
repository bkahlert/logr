# Changelog

## [Unreleased]
### Added
*none*

### Changed
*none*

### Deprecated
*none*

### Removed
*none*

### Fixed
*none*

## [0.1.0] - 2021-10-12

### Added
- `logr COMMAND` with the following commands supported:
  ```shell
  ✱︎ new
  ▪︎ item
  ↗︎ https://github.com/bkahlert/logr
  ↗︎ file:///home/bkahlert/dev/logr.sh:42:10
  ✔︎ success
  ℹ︎ info
  ⚠︎ warn
  ✘︎ error
  ⚡︎ fail
  ☐︎ task
  ⠏︎ running task
  ✔︎ succeeded task
  ⚠︎ failed task with warning
  ✘︎ bash -c; ...; exit 2
    error log
    of failed task
  ```

- to-do list like execution of tasks
- spinner based visual feedback
- hyperlink support
- stacktrace on error
  ```shell
  ✘ foo bar failed: baz expected
      at foo(/home/bkahlert/dev/demo:32)
      at main(/home/bkahlert/dev/demo:34)
    Usage: foo baz
  ```

[unreleased]: https://github.com/bkahlert/logr/compare/v0.1.0...HEAD
[0.1.0]: https://github.com/bkahlert/logr/releases/tag/v0.1.0
