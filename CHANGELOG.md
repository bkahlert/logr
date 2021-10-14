# Changelog

## [Unreleased]
### Added
- `tracr` in order to facilitate print debugging
  ```shell
  tracr
  tracr foo
  tracr "$@"
  ```  
  ```text
  0               ↗ file:///home/john/logr.sh:947
  'foo' 1         ↗ file:///home/john/logr.sh:948
  'foo' 'bar' 2   ↗ file:///home/john/logr.sh:949
  ```
- Default question for `prompt4` using `-`  
  ```shell
  prompt4 Yn '%s\n' "This is a message." -
  ```  
  ```text
     This is a message.
     Do you want to continue?
  ```

### Changed
- renamed util function `print_line` to `print`
- renamed util function `reprint_line` to `reprint`
- terminal related features are now located in `tty`

### Deprecated
*none*

### Removed
*none*

### Fixed
*none*

## [0.3.0] - 2021-10-13

### Added
- `banr` function to print iconic banner
  ```shell
  $ banr
  ░░░░░░░
  
  $ banr foo
  ░░░░░░░ FOO
  
  $ banr fooBar
  ░░░░░░░ FOO BAR
  
  $ banr fooBar baz
  ░░░░░░░ FOO BAR BAZ
  ```

## [0.2.0] - 2021-10-12

### Added
- Support for yes-no prompts
  ```shell
  $ prompt4 Yn
  
    Do you want to continue? [Y/n]
  
  # Hit enter
  ✔ Do you want to continue? [Y/n] yes
  ```
  ```shell
  $ prompt4 Yn "How about an alternative question?"
  
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

[unreleased]: https://github.com/bkahlert/logr/compare/v0.3.0...HEAD
[0.3.0]: https://github.com/bkahlert/logr/compare/v0.2.0...v0.3.0
[0.2.0]: https://github.com/bkahlert/logr/compare/v0.1.0...v0.2.0
[0.1.0]: https://github.com/bkahlert/logr/releases/tag/v0.1.0
