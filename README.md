# Introduction

Dotfiler has three main functionalities. 

1. Linking dotfiles from a common repository to your system
2. Installing the applications you need to start working on an new/empty machine
3. Full Cross platform functionality

# Story

My main OS is Windows and I was getting tired of manually installing and setting up my dev tools over and over again on a clean windows install.

I started using [scoop](https://github.com/lukesampson/scoop/) as a package manager stand-in for the installing part and started looking into dotfile managers. There are some solutions but none of them fulfilled my need for easy and full cross platform support which is why I created my own dotfile manager. ([related xkcd](https://xkcd.com/927/))

# Installation

Install the PowerShell module: 

```pwsh
Install-Module Dotfiler
```

## Requirements

* [PowerShell](https://microsoft.com/PowerShell) >= 5.x (PowerShell Core is supported)

## Run

Run `Get-Command -Module dotfiler` to see all commands dotfiler has.

You can then use `Get-Help -Full <command>` to view the fill command help.


> ***Note:** You may need to run `Import-Module dotfiler` (consider adding this to your `Profile.ps1`).*

# Configuration

Dotfiler uses a git repo containing the`dotfiles` and [`yaml`](https://yaml.org/) files for configuration.

This git repo should be located at `~/.dotfiler`. Different paths can be specified using the `-DotfilesPath` cli flag or in the Dotfiler config file `~/.config/dotfiler/config.yaml` like this:

```yaml
path: ~./dotfiles
```

Each managed application has a subfolder containing its `dotfiles` and a `dot.yaml` file.

> ***Example:***
> ```
> └── vscode
>     ├── dot.yaml
>     ├── keybindings.json
>     └── settings.json
> ```

The file `dot.yaml` contains information about how to install and update the application and where to link the dotfiles.

## `dot.yaml`

The `dot.yaml` file consists of four optional keys:

| key        | requirement | function                                              |
|------------|-------------|-------------------------------------------------------|
| `links`    | `optional`  | Defines where to link which `dotfile`                 |
| `installs` | `optional`  | Defines the install command and install dependencies. |
| `updates`  | `optional`  | Defines the update command and update dependencies.   |
| `depends`  | `optional`  | Defines dependencies this application needs to work.  |

### `links`

The `links` section specifies where the dotfiles should be linked. **Command `Link-Dots`**

It consists of multiple `key: value` pairs where the `key` is the filename of the `dotfile` and the `value` is the link path.

> ***Example:***
>
> *`vscode/dot.yaml`*
> ```yaml
> ...
> links:
>   keybindings.json: ~\AppData\Roaming\Code\User\keybindings.json
>   settings.json: ~\AppData\Roaming\Code\User\settings.json
> ```

### `installs`

The `installs` section contains the install command and optional install dependencies. **Command `Install-Dots`**

It can either be a `string` containing the install command or have two sub keys.

| key       | requirement | function                           |
|-----------|-------------|------------------------------------|
| `cmd`     | `required`  | Contains the install command.      |
| `depends` | `optional`  | Contains an array of dependencies. |

> ***Examples:***
>
> *`nodejs/dot.yaml`*
> ```yaml
> ...
> installs:
>   cmd: scoop install nodejs
>   depends: [scoop]
> ```
> *`scoop/dot.yaml`*
>
> ```yaml
> ...
> installs: iex (new-object net.webclient).downloadstring('https://get.scoop.sh')
> ```

### `updates`

The `updates` section contains the update command and optional update dependencies. **Command `Update-Dots`**

It works exactly like the `installs` key described above.

> ***Example:***
>
> *`nodejs/dot.yaml`*
> ```yaml
> ...
> updates:
>   cmd: scoop update nodejs
>   depends: [scoop]
> ```

### depends

The `depends` section contains an array of dependencies needed for the application to work correctly.

These dependencies will also be installed/updated when the application is installed/updated.

> ***Example:***
>
> *`zsh/dot.yaml`*
> ```yaml
> ...
> depends: [starship]
> ```

## Defaults

The repo can also contain a default file `dots.yaml` in the root folder of the repo.

This file contains defaults which are automatically used for empty keys in the `dot.yaml` files.

You can use template strings (`{{ name }}`) to substitute the name of the application (the name of the folder the `dot.yaml` file is located in).

> ***Example:***
>
> *`dots.yaml`*
> ```yaml
> installs:
>   cmd: scoop install {{ name }}
>   depends:
>     - scoop
>     - extras
> updates:
>   cmd: scoop update {{ name }}
>   depends:
>     - scoop
> ```

## OS Specifics

You can specify different behaviors per OS in all configuration files.

Dotfiler can differentiate between Windows, Linux and MacOS.

To specify OS Specific behavior you need to add top level keys named `linux`, `windows`, `darwin` (for MacOS) and `general` (applied to all OSs).

> ***Examples:***
>
> *`dots.yaml`*
> ```yaml
> windows:
>   installs:
>     cmd: scoop install {{ name }}
>     depends:
>       - scoop
>       - extras
>   updates:
>     cmd: scoop update {{ name }}
>     depends:
>       - scoop
> darwin:
>   installs:
>     cmd: brew install {{ name }}
>     depends:
>       - brew
>   updates:
>     cmd: brew upgrade {{ name }}
>     depends:
>       - brew
> ```
> *`neovim/dot.yaml`*
> ```yaml
> windows:
>   links:
>     ginit.vim: ~\AppData\Local\nvim\ginit.vim
>     init.vim: ~\AppData\Local\nvim\init.vim
>     
> global:
>   links:
>     ginit.vim: ~/.config/nvim/init.vim
>     init.vim: ~/.config/nvim/ginit.vim
> ```

You can also combine multiple OSs per key separating them with a `|`.

> ***Example:***
>
> *`dots.yaml`*
> ```yaml
> windows:
>   installs:
>     cmd: scoop install {{ name }}
>     depends:
>       - scoop
>       - extras
> darwin|linux:
>   installs:
>     cmd: brew install {{ name }}
>     depends:
>       - brew
> ```


## Example Repository

You can see all of this functionality used in my [own dotfiles repository](https://github.com/volllly/.dotfiles).

# Contribute

Feel free to create pull requests and issues for bugs, features or questions. 
