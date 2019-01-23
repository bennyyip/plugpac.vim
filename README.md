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
Pack 'k-takata/minpac', {'type': 'opt'}

Pack 'junegunn/vim-easy-align'

" On-demand loading
Pack 'scrooloose/nerdtree', { 'on':  'NERDTreeToggle' }
Pack 'tpope/vim-fireplace', { 'for': 'clojure' }

" Using a non-master branch
Pack 'rdnetto/YCM-Generator', { 'branch': 'stable' }

" Post-update hook
Pack 'Yggdroot/LeaderF', { 'do': {-> system('./install.sh')} }

" Sepcify commit ID, branch name or tag name to be checked out.
Pack 'tpope/vim-sensible', { 'rev': 'v1.2 }

call plugpac#end()
```
Pack just handle `for` and `on` options(i.e. lazy load, implies `'type': 'opt'`). Other options are passed to `minpac#add` directly. See [minpac][1] for more imformation.

## Credit
K.Takata(as the author of [minpac][1])  
Junegunn Choi(as the author of [vim-plug][2])

[1]: https://github.com/k-takata/minpac
[2]: https://github.com/junegunn/vim-plug
