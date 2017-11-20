require 'laia.ClassWithOptions'

local Version, Parent = torch.class('laia.Version', 'laia.ClassWithOptions')

Version.DATE = '$Date: 2017-11-20 14:36:57 $'

function Version:registerOptions(parser)
  parser:flag(
    '--version',
    'Prints the version of Laia and exits.')
    :action(function()
      io.stdout:write(self:short()..'\n')
      os.exit()
    end)
  parser:flag(
    '--version_full',
    'Prints the full version of Laia and exits.')
    :action(function()
      io.stdout:write(self:full()..'\n')
      os.exit()
    end)
    :advanced(true)
end

function Version:short()
  return string.gsub( Version.DATE, "$Date: *(%d+)-(%d+)-(%d+).*", "%1.%2.%3" )
end

function Version:full()
  return string.gsub( Version.DATE, "$Date: *([^ ]+) ([^ ]+).*", "%1 %2" )
end

return Version
