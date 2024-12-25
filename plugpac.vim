vim9script
# Author:  Ben Yip (yebenmy@gmail.com)
# URL:     https://github.com/bennyyip/plugpac.vim
# Version: 2.3
#
# Copyright (c) 2024 Ben Yip
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

var cached_installed_plugins = {}

var minpac_init_opts = {}

var package_name = "minpac"
var quiet = v:false

const plugpac_plugin_conf_path = get(g:, 'plugpac_plugin_conf_path', '')

export def Begin(opts: dict<any> = {})
  lazy = { 'ft': {}, 'map': {}, 'cmd': {}, 'delay': {} }
  repos = {}

  minpac_init_opts = opts

  package_name = get(opts, 'package_name', 'minpac')
  quiet = get(opts, 'quiet', v:false)

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
      execute printf("command! -nargs=* -range -bang %s call DoCmd('%s', '%s', \"<bang>\", <line1>, <line2>, <q-args>)", cmd, name, cmd)
    endfor
  endfor

  for [name, maps] in items(lazy.map)
    for map_ in maps
      for [mode_, map_prefix, key_prefix] in
        [['i', '<C-\><C-O>', ''], ['n', '', ''], ['v', '', 'gv'], ['o', '', '']]
        execute printf(
          '%snoremap <silent> %s %s:<C-U>call <SID>DoMap("%s", %s, v:%s, "%s")<CR>',
          mode_, map_, map_prefix, name, string(map_), mode_ != 'i', key_prefix)
      endfor
    endfor
  endfor

  runtime! OPT ftdetect/**/*.vim
  runtime! OPT after/ftdetect/**/*.vim

  for [name, fts] in items(lazy.ft)
    autocmd_add([{
      event: 'FileType',
      pattern: fts,
      group: 'PlugPac',
      once: true,
      cmd: $'packadd {name}',
    }])
  endfor

  for name in keys(lazy.delay)
    autocmd_add([{
      event: 'VimEnter',
      pattern: '*',
      group: 'PlugPac',
      once: true,
      cmd: $'timer_start(lazy.delay["{name}"].delay, (_) => lazy.delay["{name}"].load())',
    }])
  endfor

  timer_start(0, (timer) => {
    for [k, v] in items(lazy.delay)
      if !v.done
        return
      endif
    endfor
    doautocmd VimEnter
    timer_stop(timer)
  }, { repeat: -1 })

enddef

export def Add(repo: string, opts: dict<any> = {})
  const name = substitute(repo, '^.*/', '', '')
  const default_type = get(g:, 'plugpac_default_type', 'start')
  var type = get(opts, 'type', default_type)
  if opts->has_key('delay')
    type = 'delay'
  endif

  # `for` and `on` implies optional and override delay
  if has_key(opts, 'for') || has_key(opts, 'on')
    type = 'opt'
    opts['type'] = 'opt'
  endif

  if type == 'delay'
    opts['type'] = 'opt'
  endif

  repos[repo] = opts

  if !HasPlugin(name)
    timer_start(20, (_) => {
      if !quiet
        echow $'Missing plugin `{repo}`. Run :PackInstall to install it.'
      endif
    })
    return
  endif

  if has_key(opts, 'for')
    const ft = type(opts.for) == v:t_list ? join(opts.for, ',') : opts.for
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

  const pre_rc_path = GetRcPath(name, true)
  const rc_path = GetRcPath(name, false)
  if filereadable(pre_rc_path)
    execute $'source {pre_rc_path}'
  endif
  if filereadable(rc_path)
    if type == 'delay' || type == 'start'
      lazy.delay[name] = {
        delay: opts->get('delay', 0),
        done: false,
        load: () => {
          execute $'packadd {name}'
          execute $'source {rc_path}'
          lazy.delay[name].done = true
        }
      }
    endif
  endif

  if type == 'delay' && !has_key(lazy.delay, name)
    lazy.delay[name] = {
      delay: opts->get('delay', 0),
      done: false,
      load: () => {
        execute $'packadd {name}'
        lazy.delay[name].done = true
      }
    }
  endif
enddef

def GetRcPath(plugin: string, is_pre: bool = false): string
  if plugpac_plugin_conf_path != '' && HasPlugin(plugin)
    const prefix = is_pre ? 'pre-' : ''
    return expand(plugpac_plugin_conf_path .. '/' .. prefix .. substitute(plugin, '\.n\?vim$', '', '') .. '.vim')
  else
    return ''
  endif
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


def DoCmd(plugin: string, cmd: any, bang: any, start_: number, end_: number, args_: any)
  execute $'delcommand {cmd}'
  execute $'packadd {plugin}'

  const rc_path = GetRcPath(plugin)
  if filereadable(rc_path)
    execute $'source {rc_path}'
  endif

  execute printf('%s%s%s %s', (start_ == end_ ? '' : $":{start_},{end_}"), cmd, bang, args_)
enddef

def DoMap(plugin: string, map_: any, with_prefix: any, prefix_: any)
  execute $'unmap {map_}'
  execute $'iunmap {map_}'
  execute $'packadd {plugin}'

  const rc_path = GetRcPath(plugin)
  if filereadable(rc_path)
    execute $'source {rc_path}'
  endif

  var extra = ''
  while 1
    const c = getchar(0)
    if c == 0
      break
    endif
    extra = extra .. nr2char(c)
  endwhile


  if with_prefix
    var prefix = v:count > 0 ? v:count : ''
    prefix ..= '"' .. v:register .. prefix_
    if mode(1) == 'no'
      if v:operator == 'c'
        prefix = "\<esc>" .. prefix
      endif
      prefix ..= v:operator
    endif
    feedkeys(prefix, 'n')
  endif
  feedkeys(substitute(map_, '^<Plug>', "\<Plug>", '') .. extra)
enddef

def Setup_command()
  command! -bar -nargs=+ Pack call Add(<args>)
  command! -bar PackInstall call Init() |
        \ call minpac#update(
        \ minpac#pluglist
        \ ->copy()
        \ ->filter((k, v) => !isdirectory(v.dir .. '/.git'))
        \ ->keys()
        \ )
  command! -bar PackUpdate  call Init() | call minpac#update('', {'do': 'call minpac#status()'})
  command! -bar PackClean   call Init() | call minpac#clean()
  command! -bar PackStatus  call Init() | call minpac#status()
  command! -bar -nargs=1 -complete=customlist,StartPluginComplete PackDisable call DisableEnablePlugin(<q-args>, v:true)
  command! -bar -nargs=1 -complete=customlist,OptPluginComplete PackEnable call DisableEnablePlugin(<q-args>, v:false)
enddef

export def Init()
  packadd minpac

  minpac#init(minpac_init_opts)
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

  const plugin_dir = plugins[plugin]

  const dst_dir = substitute(plugin_dir, '[/\\]' .. src_ .. '[/\\]\ze[^/]\+$', '/' .. dst .. '/', '')
  if isdirectory(dst_dir)
    Err(dst_dir .. 'exists.')
    return
  endif
  call rename(plugin_dir, dst_dir)
enddef

def Matchfuzzy(l: list<string>, str: string): list<string>
  if str == ''
    return l
  else
    return matchfuzzy(l, str)
  endif
enddef

def StartPluginComplete(A: string, L: string, P: number): list<string>
  const plugins = GetInstalledPlugins('start')->keys()
  return plugins->Matchfuzzy(A)
enddef

def OptPluginComplete(A: string, L: string, P: number): list<string>
  const plugins = GetInstalledPlugins('opt')->keys()
  return plugins->Matchfuzzy(A)
enddef

def GetInstalledPlugins(type_: string = 'all'): dict<string>
  if has_key(cached_installed_plugins, type_)
    return cached_installed_plugins[type_]
  endif

  var t = type_
  if type_ == 'all'
    t = '*'
  endif

  const pat = $'pack/{package_name}/{t}/*'
  final plugin_paths = filter(globpath(&packpath, pat, 0, 1), (k, v) => isdirectory(v))
  final result = {}
  for p in plugin_paths
    result[substitute(p, '^.*[/\\]', '', '')] = p
  endfor

  cached_installed_plugins[type_] = result
  return result
enddef
