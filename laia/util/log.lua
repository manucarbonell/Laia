--
-- log.lua
--
-- Copyright (c) 2016 rxi, jpuigcerver
--
-- This library is free software; you can redistribute it and/or modify it
-- under the terms of the MIT license. See LICENSE for details.
--
-- LICENSE:
-- Permission is hereby granted, free of charge, to any person obtaining a copy
-- of this software and associated documentation files (the "Software"), to deal
-- in the Software without restriction, including without limitation the rights
-- to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
-- copies of the Software, and to permit persons to whom the Software is
-- furnished to do so, subject to the following conditions:
--
-- The above copyright notice and this permission notice shall be included in
-- all copies or substantial portions of the Software.
--
-- THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
-- IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
-- FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
-- AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
-- LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
-- OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
-- SOFTWARE.

local term_ok, term = pcall(require, 'term')
local isatty = term_ok and term.isatty(io.stderr)

local log = { _version = "0.1.0-laia" }

-- If true, use colors when logging to stderr
log.usecolor = true
-- If not nil, write log messages to this file instead of stderr
log.logfile = nil
-- All events with level lower than this are ignored.
log.loglevel = "trace"
-- Copy log messages at or above this level to stderr in addition to logfile
log.logstderrthreshold = "error"

local modes = {
  { name = "trace", color = "\27[34m", },
  { name = "debug", color = "\27[36m", },
  { name = "info",  color = "\27[32m", },
  { name = "warn",  color = "\27[33m", },
  { name = "error", color = "\27[31m", },
  { name = "fatal", color = "\27[35m", },
}

local levels = {
  ['trace'] = 1,
  ['debug'] = 2,
  ['info']  = 3,
  ['warn']  = 4,
  ['error'] = 5,
  ['fatal'] = 6,
}

-- Utility function to register logging options, common to all tools.
log.registerOptions = function(parser, advanced)
  advanced = advanced or false
  local loglevels = {
    ['trace'] = 'trace',
    ['debug'] = 'debug',
    ['info']  = 'info',
    ['warn']  = 'warn',
    ['error'] = 'error',
    ['fatal'] = 'fatal'
  }
  -- loglevel, binds value directly to log.loglevel
  parser:option(
    '--log_level',
    'All log messages bellow this level are ignored. Valid levels are ' ..
      'trace, debug, info, warn, error, fatal.', log.loglevel, loglevels)
    :argname('<level>')
    :bind(log, 'loglevel')
    :advanced(advanced)
  -- logfile, binds value directly to log.logfile
  parser:option(
    '--log_file',
    'Write log messages to this file instead of stderr.')
    :argname('<file>')
    :bind(log, 'logfile')
    :advanced(advanced)
  -- logalsostderr, binds value directly to log.logstderrthreshold
  parser:option(
    '--log_also_to_stderr',
    'Copy log messages at or above this level to stderr in addition to the ' ..
      'logfile.', log.logstderrthreshold, loglevels)
    :argname('<level>')
    :bind(log, 'logstderrthreshold')
    :advanced(advanced)
end


local round = function(x, increment)
  increment = increment or 1
  x = x / increment
  return (x > 0 and math.floor(x + .5) or math.ceil(x - .5)) * increment
end


local _tostring = tostring

local tostring = function(...)
  local t = {}
  for i = 1, select('#', ...) do
    local x = select(i, ...)
    if type(x) == "number" then
      x = round(x, .01)
    end
    t[#t + 1] = _tostring(x)
  end
  return table.concat(t, " ")
end


for i, x in ipairs(modes) do
  local nameupper = x.name:upper()
  log[x.name] = function(msg, ...)

    -- Return early if we're below the log level
    if i < levels[log.loglevel] then
      return
    end
    local getinfo_level, arg = nil, nil
    if type(msg) == 'table' then
      getinfo_level = msg.level or 2
      arg = msg.arg
      msg = tostring(msg.fmt)
      if arg then msg = msg:format(unpack(arg)) end
    else
      getinfo_level, arg = 2, {...}
      msg = tostring(msg)
      if #arg > 0 then msg = string.format(msg, unpack(arg)) end
    end
    local info = debug.getinfo(getinfo_level, "Sl")
    local lineinfo = info.short_src .. ":" .. info.currentline

    -- Output to console
    if log.logfile == nil or log.logfile == '' or
    i >= levels[log.logstderrthreshold] then
      io.stderr:write(string.format("%s[%s%6s]%s %s: %s\n",
				    isatty and log.usecolor and x.color or "",
				    os.date("%Y-%m-%d %H:%M:%S"),
				    nameupper,
				    isatty and log.usecolor and "\27[0m" or "",
				    lineinfo,
				    msg))
      if nameupper == 'FATAL' then
	io.stderr:write(debug.traceback('', getinfo_level) .. '\n')
      end
      io.stderr:flush()
    end

    -- Output to log file
    if log.logfile and log.logfile ~= '' then
      local fp = io.open(log.logfile, "a")
      fp:write(string.format("[%s%6s] %s: %s\n",
			     os.date("%Y-%m-%d %H:%M:%S"),
			     nameupper,
			     lineinfo, msg))
      if nameupper == 'FATAL' then
	fp:write(debug.traceback('', getinfo_level) .. '\n')
      end
      fp:close()
    end

    -- If level was FATAL, terminate program and show traceback
    if nameupper == 'FATAL' then os.exit(1) end
  end
end


return log
