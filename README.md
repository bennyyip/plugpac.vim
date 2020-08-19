# plugpac

## Overview
Plugpac is a thin wrapper over [minpac][1], leveraging the power of Vim8(and Neovim) native package manager and jobs feature. It's even faster than [vim-plug][2].

In my case, it takes 18ms to start up with 53 out 87 plugins loaded(the rest will be load on demand). While vim-plug takes 35ms.

## Installation
Linux & Vim8:
```
git clone https://github.com/k-takata/minpac.git \
    ~/.vim/pack/minpac/opt/minpac
curl -fLo ~/.vim/autoload/plugpac.vim --create-dirs \
    https://raw.githubusercontent.com/bennyyip/plugpac.vim/master/plugpac.vim
```

## Sample vimrc
```vim
call plugpac#begin()

" minpac
Pack 'k-takata/minpac', { 'type': 'opt' }

Pack 'junegunn/vim-easy-align'

" On-demand loading
Pack 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Pack 'tpope/vim-fireplace', { 'for': 'clojure' }
Pack 'ntpeters/vim-better-whitespace', { 'event': 'CursorHold' }
" String or List support
Pack 'pangloss/vim-javascript', { 'for': ['javascript', 'javascript.jsx'] }
Pack 'neoclide/coc.nvim', { 'event': ['InsertEnter', 'CursorMoved'] }

" Using a non-master branch
Pack 'rdnetto/YCM-Generator', { 'branch': 'stable' }

" Post-update hook
Pack 'Yggdroot/LeaderF', { 'do': {-> system('./install.sh')} }

" Sepcify commit ID, branch name or tag name to be checked out.
Pack 'tpope/vim-sensible', { 'rev': 'v1.2' }

" Only valid if conditions are met
Pack 'nvim-treesitter/nvim-treesitter', { 'if': has('nvim') }

" After VimEnter, the timer_start function packadd plugins
Pack 'andymass/vim-matchup', { 'type': 'lazy' }

call plugpac#end()
```
Reload .vimrc and `:PackInstall` to install plugins.
`Pack` command just handles `for` , `on` , `event` and `if` options(i.e. lazy load, implies `'type': 'opt'`).
If `'type': 'lazy'` is set, it will be asynchronously packadded by the timer_start function after the VimEnter event.

Other options are passed to `minpac#add` directly. See [minpac][1] for more imformation.

## Commands
- PackInstall: Install newly added plugins.(`minpac#update()`)
- PackUpdate: Install or update plugins.(`minpac#update()`)
- PackClean: Uninstall unused plugins.(`minpac#clean()`)
- PackStatus: See plugins status.(`minpac#status()`)
- PackDisable: Move a plugin to `minpac/opt`.(`minpac#update` would move plugin back to `minpac/start`, unless the plugin is explicitly optional. Useful for disabling a plugin temporarily)

## Plugin config path

If you set `g:plugpac_cfg_path`, the plugin settings will be automatically sourced.

```vim
let g:plugpac_cfg_path = '~/.vim/rc'

call plugpac#begin()

" source ~/.vim/rc/nerdtree.vim if exists
Pack 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
" source ~/.vim/rc/coc.nvim if exists
Pack 'neoclide/coc.nvim', { 'event': ['InsertEnter', 'CursorMoved'] }
" source ~/.vim/rc/LeaderF.vim if exists
Pack 'Yggdroot/LeaderF', { 'do': {-> system('./install.sh')} }
" source ~/.vim/rc/vim-matchup.vim if exists
Pack 'andymass/vim-matchup', { 'type': 'lazy' }

" It will be asynchronously source by the timer_start function after the VimEnter event.
Pack 'haya14busa/vim-edgemotion', { 'type': 'lazyall' }

call plugpac#end()
```

## Credit
K.Takata(as the author of [minpac][1])
Junegunn Choi(as the author of [vim-plug][2])

[1]: https://github.com/k-takata/minpac
[2]: https://github.com/junegunn/vim-plug

## License
MIT
