# plugpac

## Overview

Plugpac is a plugin manger written in Vim9 based on [minpac][1], leveraging the power of Vim8(and Neovim) native package manager and jobs feature. It's even faster than [vim-plug][2].

In my case, it takes 50ms to start up with 81 plugins. While vim-plug takes 100ms.

## Installation

Linux & Vim9:

```
git clone https://github.com/k-takata/minpac.git \
    ~/.vim/pack/minpac/opt/minpac
curl -fLo ~/.vim/autoload/plugpac.vim --create-dirs \
    https://raw.githubusercontent.com/bennyyip/plugpac.vim/master/plugpac.vim
```

If Vim9 is unavailable:

```
git clone https://github.com/k-takata/minpac.git \
    ~/.vim/pack/minpac/opt/minpac
curl -fLo ~/.vim/autoload/plugpac.vim --create-dirs \
    https://raw.githubusercontent.com/bennyyip/plugpac.vim/master/legacy/plugpac.vim
```

## Sample vimrc

```vim
plugpac#Begin()

" minpac
Pack 'k-takata/minpac', {'type': 'opt'}

Pack 'junegunn/vim-easy-align'

" On-demand loading
Pack 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Pack 'tpope/vim-fireplace', { 'for': 'clojure' }

" Using a non-master branch
Pack 'rdnetto/YCM-Generator', { 'branch': 'stable' }

" Post-update hook
" Execute an Ex command as a hook.
Pack 'Yggdroot/LeaderF', { 'do': "packadd LeaderF \| LeaderfInstallCExtension" }
" Execute a lambda function as a hook.
" Parameters for a lambda can be omitted, if you don't need them.
Pack 'Shougo/vimproc.vim', {'do': () => system('make')}

" Specify commit ID, branch name or tag name to be checked out.
Pack 'tpope/vim-sensible', { 'rev': 'v1.2' }

" Load after `VimEnter` Event
Pack 'tpope/vim-rsi', { 'type': 'delay' }

plugpac#End()
```

Reload .vimrc and `:PackInstall` to install plugins.

`Pack` command just handles `for` and `on` options(i.e. lazy load, implies `'type': 'opt'`). Other options are passed to `minpac#add` directly. See [minpac][1] for more information.

[How it use plugpac.vim](https://github.com/bennyyip/dot-vim/blob/master/pack.vim)

## Options

`g:plugpac_plugin_config_path`: Folder for plugin config. For example, if its value is `~/.vim/plugin_config`, config file for `dense-analysis/ale` would be `~/.vim/plugin_config/ale.vim`. If you want it to be sourced before the plugin is loaded, prefix the file name with `pre-`, e.g. `pre-ale.vim`.

`g:plugpac_default_type`: `type` option default value for plugin. Possible values are `start`, `opt`, `delay`. Default is `start`.

## Commands

- PackInstall: Install newly added plugins.(`minpac#update()`)
- PackUpdate: Install or update plugins.(`minpac#update()`)
- PackClean: Uninstall unused plugins.(`minpac#clean()`)
- PackStatus: See plugins status.(`minpac#status()`)
- PackDisable: Move a plugin to `minpac/opt`.(`minpac#update` would move plugin back to `minpac/start`, unless the plugin is explicitly optional. Useful for disabling a plugin temporarily)
- PackEnable: Move a plugin to `minpac/start`

## History

- 2.1: Fix <Plug> Map
- 2.0: Rewrite in Vim9
- 1.1: Support delay load and plugin config. **BREAKS**: Functions `plugpac#{begin,end,has_plugin}` rename to `plugpac#{Begin,End,HasPlugin}`
- 1.0: Initial version.

## Credit

K.Takata(as the author of [minpac][1])

Junegunn Choi(as the author of [vim-plug][2])

[1]: https://github.com/k-takata/minpac
[2]: https://github.com/junegunn/vim-plug

## License

MIT
