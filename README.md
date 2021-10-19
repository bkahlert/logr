# logr [![Build Status](https://img.shields.io/github/workflow/status/bkahlert/logr/build?label=Build&logo=github&logoColor=fff)](https://github.com/bkahlert/logr/actions/workflows/build-and-publish.yml) [![Repository Size](https://img.shields.io/github/repo-size/bkahlert/logr?color=01818F&label=Repo%20Size&logo=Git&logoColor=fff)](https://github.com/bkahlert/logr) [![Repository Size](https://img.shields.io/github/license/bkahlert/logr?color=29ABE2&label=License&logo=data%3Aimage%2Fsvg%2Bxml%3Bbase64%2CPHN2ZyB4bWxucz0iaHR0cDovL3d3dy53My5vcmcvMjAwMC9zdmciIHZpZXdCb3g9IjAgMCA1OTAgNTkwIiAgeG1sbnM6dj0iaHR0cHM6Ly92ZWN0YS5pby9uYW5vIj48cGF0aCBkPSJNMzI4LjcgMzk1LjhjNDAuMy0xNSA2MS40LTQzLjggNjEuNC05My40UzM0OC4zIDIwOSAyOTYgMjA4LjljLTU1LjEtLjEtOTYuOCA0My42LTk2LjEgOTMuNXMyNC40IDgzIDYyLjQgOTQuOUwxOTUgNTYzQzEwNC44IDUzOS43IDEzLjIgNDMzLjMgMTMuMiAzMDIuNCAxMy4yIDE0Ny4zIDEzNy44IDIxLjUgMjk0IDIxLjVzMjgyLjggMTI1LjcgMjgyLjggMjgwLjhjMCAxMzMtOTAuOCAyMzcuOS0xODIuOSAyNjEuMWwtNjUuMi0xNjcuNnoiIGZpbGw9IiNmZmYiIHN0cm9rZT0iI2ZmZiIgc3Ryb2tlLXdpZHRoPSIxOS4yMTIiIHN0cm9rZS1saW5lam9pbj0icm91bmQiLz48L3N2Zz4%3D)](https://github.com/bkahlert/logr/blob/master/LICENSE)

TODO demo

![tracr function](docs/tracr.svg)
tracr function

> ![tracr function](docs/tracr.svg)
  tracr function

![Semantic description of image](docs/tracr.svg "Image Title")

![Semantic description of image][identifier]

![Semantic description of image](docs/tracr.svg)*My caption*

[![Semantic description of image](docs/tracr.svg "Hello World")*My caption*][about.gitlab.com]

![image alternative text](docs/tracr.svg){: .shadow}


[identifier]: https://example.com "This example has a title
[about.gitlab.com]: https://about.com "This example has a title


<figure><img src="docs/tracr.svg" alt="tracr function" style="width:100%">
 <figcaption align="center"><b>tracr function</b></figcaption></figure>

| ![space-1.jpg](docs/tracr.svg) |
| :--: |
| <b>tracr function</b> |

<p align="center"><img src="docs/tracr.svg"></p>
<p align = "center">tracr function</p>


* yet another bash logger
  ```shell
  ▒▒▒▒▒▒▒ YET ANOTHER BASH LOGGER

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
* prompts
  ```shell
  Continue? [Y/n]

  # Hit ⏎, y, or any other key
  ✔︎ Continue? [Y/n] yes
  
  # Hit ␛, n, or ⌃C
  ✘︎ Continue? [Y/n] no
  ```
* banners
  ```shell
  banr "fooBar baz"
  # ▒▒▒▒▒▒▒ FOO BAR BAZ
  
  banr "fooBar baz" --static='c=>:c=<:c=>:c=<:c=>:c=<:c=>'
  # ><><><> FOO BAR BAZ
  ```  
* to-do list like execution of tasks
* spinner based visual feedback
* hyperlink support
* stacktrace on error
  ```shell
  ✘ foo bar failed: baz expected
      at foo(/home/bkahlert/dev/demo:32)
      at main(/home/bkahlert/dev/demo:34)
    Usage: foo baz
  ```

## Installation

`logr` is a Bash library. 

In order to use it, it needs to be downloaded and put on your `$PATH`
which is exactly what the following line is doing:
```shell
sudo curl -LfsSo /usr/local/bin/logr.sh https://raw.githubusercontent.com/bkahlert/logr/master/logr.sh
```

## Usage

```shell
# logr.sh needs to be sourced to be used
source logr.sh

# sample calls
logr info "logr.sh sourced"
logr task "do some work" -- sleep 2
```

```shell
# invoke as binary for a feature overview
chmod +x logr.sh
./logr.sh

# help
./logr.sh --help
```


## Testing

```shell
git clone https://github.com/bkahlert/logr.git
cd logr

# Use Bats wrapper to run tests
chmod +x ./batsw
./batsw test
```

`batsw` is a wrapper for the Bash testing framework [Bats](https://github.com/bats-core/bats-core).   
It builds a Docker image on-the-fly containing Bats incl. several libraries and runs all tests
contained in the specified directory.

> 💡 To accelerate testing, the Bats Wrapper checks if any test is prefixed with a capital X and if so, only runs those tests.


## Contributing

Want to contribute? Awesome! The most basic way to show your support is to star the project, or to raise issues. You
can also support this project by making
a [Paypal donation](https://www.paypal.me/bkahlert) to ensure this journey continues indefinitely!

Thanks again for your support, it is much appreciated! :pray:


## License

MIT. See [LICENSE](LICENSE) for more details.
