vim9script
# Author:  Ben Yip (yebenmy@gmail.com)
# URL:     http//github.com/bennyyip/plugpac.vim
# Version: 2.0
#
# Copyright (c) 2023 Ben Yip
#
# MIT License
#
# Permission is hereby granted, free of charge, to any person obtaining
# a copy of this software and associated documentation files (the
# "Software"), to deal in the Software without restriction, including
# without limitation the rights to use, copy, modify, merge, publish,
# distribute, sublicense, and/or sell copies of the Software, and to
# permit persons to whom the Software is furnished to do so, subject to
# the following condition
#
# The above copyright notice and this permission notice shall be
# included in all copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
# EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
# MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
# NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
# LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
# OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
# WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
# ---------------------------------------------------------------------

var lazy = { 'ft': {}, 'map': {}, 'cmd': {}, 'delay': {} }
var repos = {}
var delay_repos = []

var cached_installed_plugins = {}

const plugpac_plugin_conf_path = get(g:, 'plugpac_plugin_conf_path', '')

export def Begin()

  lazy = { 'ft': {}, 'map': {}, 'cmd': {}, 'delay': {}}
  repos = {}
  delay_repos = []

  if exists('#PlugPac')
    augroup PlugPac
      autocmd!
    augroup END
    augroup! PlugPac
  endif

  call Setup_command()
enddef

export def End()
  for [name, cmds] in items(lazy.cmd)
    for cmd in cmds
      execute printf("command! -nargs=* -range -bang %s packadd %s | call DoCmd('%s', \"<bang>\", <line1>, <line2>, <q-args>)", cmd, name, cmd)
    endfor
  endfor

  for [name, maps] in items(lazy.map)
    for _map in maps
      for [_mode, map_prefix, key_prefix] in
            \ [['i', '<C-O>', ''], ['n', '', ''], ['v', '', 'gv'], ['o', '', '']]
        execute printf(
               '%snoremap <silent> %s %<C-U>packadd %s<bar>call DoMap(%s, %s, "%s")<CR>',
                _mode, _map, map_prefix, name, string(_map), _mode != 'i', key_prefix)
      endfor
    endfor
  endfor

  runtime! OPT ftdetect/**/*.vim
  runtime! OPT after/ftdetect/**/*.vim

  for [name, fts] in items(lazy.ft)
    augroup PlugPac
      execute printf('autocmd FileType %s packadd %s', fts, name)
    augroup END
  endfor
enddef

export def Add(repo: string, opts: dict<any> = {})
  var name = substitute(repo, '^.*/', '', '')
  var default_type = get(g:, 'plugpac_default_type', 'start')
  var type = get(opts, 'type', 'delay')
  if type == 'delay'
    call add(delay_repos, name)
  endif

  # `for` and `on` implies optional
  if has_key(opts, 'for') || has_key(opts, 'on') || type == 'delay'
    opts['type'] = 'opt'
  endif

  if has_key(opts, 'for')
    var ft = type(opts.for) == v:t_list ? join(opts.for, ',') : opts.for
    lazy.ft[name] = ft
  endif

  if has_key(opts, 'on')
    for cmd in ToArray(opts.on)
      if cmd =~? '^<Plug>.\+'
        if empty(mapcheck(cmd)) && empty(mapcheck(cmd, 'i'))
          call Assoc(lazy.map, name, cmd)
        endif
      elseif cmd =~# '^[A-Z]'
        if exists(":" .. cmd) != 2
          call Assoc(lazy.cmd, name, cmd)
        endif
      else
        call Err('Invalid `on` option: ' .. cmd ..
                 '. Should start with an uppercase letter or `<Plug>`.')
      endif
    endfor
  endif

  if plugpac_plugin_conf_path != '' && has_key(GetInstalledPlugins(), name)
    var pre_rc_path = expand(plugpac_plugin_conf_path .. '/pre-' .. substitute(name, '\.n\?vim$', '', '') .. '.vim')
    var rc_path = expand(plugpac_plugin_conf_path .. '/' .. substitute(name, '\.n\?vim$', '', '') .. '.vim')
    if filereadable(pre_rc_path)
        execute printf('source %s', pre_rc_path)
    endif
    if filereadable(rc_path)
      if type == 'delay'
        lazy.delay[name] = rc_path
      else
        execute printf('source %s', rc_path)
      endif
    endif
  endif

  if type == 'delay' && !has_key(lazy.delay, name)
    lazy.delay[name] = ''
  endif

  repos[repo] = opts
enddef

export def HasPlugin(plugin: string): bool
  return has_key(GetInstalledPlugins(), plugin)
enddef

def Assoc(dict: dict<any>, key: string, val: any)
  dict[key] = add(get(dict, key, []), val)
enddef

def ToArray(v: any): list<string>
  return type(v) == v:t_list ? v : [v]
enddef

def Err(msg: any)
  echohl ErrorMsg
  echom '[plugpac] ' .. msg
  echohl None
enddef


def DoCmd(cmd: any, bang: any, start_: any, end_: any, args_: any)
  execute printf('%s%s%s %s', (start_ == end_ ? '' : (start_.','.end_)), cmd, bang, args_)
enddef

def DoMap(map_: any, with_prefix: any, prefix: any)
  let extra = ''
  while 1
    let c = getchar(0)
    if c == 0
      break
    endif
    extra .= nr2char(c)
  endwhile

  if with_prefix
    let prefix = v:count ? v:count : ''
    let prefix .= '"' .. v:register .. prefix
    if mode(1) == 'no'
      if v:operator == 'c'
        let prefix = "\<esc>" . prefix
      endif
      let prefix .= v:operator
    endif
    call feedkeys(prefix, 'n')
  endif
  call feedkeys(substitute(map_, '^<Plug>', "\<Plug>", '') . extra)
enddef

def Setup_command()
  command! -bar -nargs=+ Pack call Add(<args>)

  command! -bar PackInstall call Init() | call minpac#update(keys(filter(copy(minpac#pluglist), (k, v) => !isdirectory(v.dir .. '/.git'))))
  command! -bar PackUpdate  call Init() | call minpac#update('', {'do': 'call minpac#status()'})
  command! -bar PackClean   call Init() | call minpac#clean()
  command! -bar PackStatus  call Init() | call minpac#status()
  command! -bar -nargs=1 -complete=customlist,StartPluginComplete PackDisable call DisableEnablePlugin(<q-args>, v:true)
  command! -bar -nargs=1 -complete=customlist,OptPluginComplete PackEnable call DisableEnablePlugin(<q-args>, v:false)
enddef

def Init()
  packadd minpac

  minpac#init()
  for [repo, opts] in items(repos)
    call minpac#add(repo, opts)
  endfor

  cached_installed_plugins = {}
enddef

def DisableEnablePlugin(plugin: string, disable: bool)
  var src_ = 'opt'
  var dst = 'start'

  if disable
    src_ = 'start'
    dst = 'opt'
  endif

  const plugins = GetInstalledPlugins(src_)
  if !has_key(plugins, plugin)
    Err(plugin .. ' does not exists.')
    return
  endif

  var plugin_dir = plugins[plugin]

  const dst_dir = substitute(plugin_dir, '[/\\]' .. src_ .. '[/\\]\ze[^/]\+$', '/' .. dst .. '/', '')
  if isdirectory(dst_dir)
    Err(dst_dir .. 'exists.')
    return
  endif
  call rename(plugin_dir, dst_dir)
enddef

def StartPluginComplete(A: string, L: string, P: number): list<string>
  const plugins = GetInstalledPlugins('start')
  return filter(keys(plugins), 'v:val =~ "' .. A .. '"')
enddef


def OptPluginComplete(A: string, L: string, P: number): list<string>
  const plugins = GetInstalledPlugins('opt')
  return filter(keys(plugins), 'v:val =~ "' .. A .. '"')
enddef

def GetInstalledPlugins(type_: string = 'all'): dict<string>
  if has_key(cached_installed_plugins, type_)
    return cached_installed_plugins[type_]
  endif

  var t = type_
  if type_ == 'all'
    t = '*'
  endif

  const pat = 'pack/minpac/' .. t .. '/*'
  final plugin_paths = filter(globpath(&packpath, pat, 0, 1), (k, v) => isdirectory(v))
  var result = {}
  for p in plugin_paths
    result[substitute(p, '^.*[/\\]', '', '')] = p
  endfor

  cached_installed_plugins[type_] = result
  return result
enddef


def DelayLoad()
  for name in delay_repos
    const rc = lazy.delay[name]

    execute 'packadd ' .. name
    if rc != ''
      execute printf('source %s', rc)
    endif
  endfor
enddef

autocmd VimEnter * call timer_start(0, (timer) => DelayLoad())

