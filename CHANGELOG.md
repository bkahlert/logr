# Changelog

## [Unreleased]

### Added

*none*

### Changed

- use [Bats Wrapper GitHub action](https://github.com/marketplace/actions/bats-wrapper)

### Deprecated

*none*

### Removed

*none*

### Fixed

*none*


## [0.6.2] - 2021-12-09

### Fixed

- do nothing if sourced multiple times


## [0.6.1] - 2021-11-27

### Fixed

- `$TMPDIR` will be created if it does not exist


## [0.6.0] - 2021-11-22

### Added

- support for `NO_COLOR` and `MY_APP_NO_COLOR`

### Changed

- `failr` is replaced by `logr error`; arguments are unchanged

## [0.5.0] - 2021-10-24

### Added

- Further banner animations
- SVG terminal sessions recordings
  [![recorded terminal session demonstrating the logr library](https://github.com/bkahlert/logr/raw/5c3eb8eab973efe19b0d4d8c02d1500ccff7e21b/docs/logr.svg "logr library")](https://github.com/bkahlert/logr/raw/5c3eb8eab973efe19b0d4d8c02d1500ccff7e21b/docs/logr.svg)
- Support for synonyms (e.g. `logr task` == `logr job` == `logr work`)
- Utility remove_ansi to remove any type of ANSI escapes

### Changed

- `failr` only prints stacktrace if invoked with `-x` or `--stacktrace`
- `errexit` disabled

## [0.4.0] - 2021-10-15

### Added

- `tracr` in order to facilitate print debugging
  ```shell
  tracr
  tracr foo
  tracr "$@"
  ```  
  ```text
  0               ↗ file:///home/john/logr.sh#947
  'foo' 1         ↗ file:///home/john/logr.sh#948
  'foo' 'bar' 2   ↗ file:///home/john/logr.sh#949
  ```
- Default question for `prompt4` using `-`
  ```shell
  prompt4 Y/n '%s\n' "This is a message." -
  ```  
  ```text
     This is a message.
     Do you want to continue?
  ```
- Customizable banner with a colon separated list of properties
    - `char`/`c`: character to use instead of default one
    - `state`/`s`: `0` corresponds to dimmed color; otherwise default
  ```shell
  banr --static='c=>:c=<:c=>:c=<:c=>:c=<:c=>' fooBar baz
  ```  
  ```text
  ><><><> FOO BAR BAZ
  ```
- Animated banner if no --static flag is used

### Changed

- renamed util function `print_line` to `print`
- renamed util function `reprint_line` to `reprint`
- terminal related features are now located in `esc`

## [0.3.0] - 2021-10-13

### Added

- `banr` function to print iconic banner
  ```shell
  $ banr
  ▒▒▒▒▒▒▒
  
  $ banr foo
  ▒▒▒▒▒▒▒ FOO
  
  $ banr fooBar
  ▒▒▒▒▒▒▒ FOO BAR
  
  $ banr fooBar baz
  ▒▒▒▒▒▒▒ FOO BAR BAZ
  ```

## [0.2.0] - 2021-10-12

### Added

- Support for yes-no prompts
  ```shell
  $ prompt4 Y/n
  
    Do you want to continue? [Y/n]
  
  # Hit enter
  ✔ Do you want to continue? [Y/n] yes
  ```
  ```shell
  $ prompt4 Y/n "How about an alternative question?"
  
    How about an alternative question? [Y/n]
  
  # Hit escape
  ✘︎ How about an alternative question? [Y/n] no 
  ```

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
  ϟ︎ fail
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

[unreleased]: https://github.com/bkahlert/logr/compare/v0.6.2...HEAD

[0.6.2]: https://github.com/bkahlert/logr/compare/v0.6.1...v0.6.2

[0.6.1]: https://github.com/bkahlert/logr/compare/v0.6.0...v0.6.1

[0.6.0]: https://github.com/bkahlert/logr/compare/v0.5.0...v0.6.0

[0.5.0]: https://github.com/bkahlert/logr/compare/v0.4.0...v0.5.0

[0.4.0]: https://github.com/bkahlert/logr/compare/v0.3.0...v0.4.0

[0.3.0]: https://github.com/bkahlert/logr/compare/v0.2.0...v0.3.0

[0.2.0]: https://github.com/bkahlert/logr/compare/v0.1.0...v0.2.0

[0.1.0]: https://github.com/bkahlert/logr/releases/tag/v0.1.0
