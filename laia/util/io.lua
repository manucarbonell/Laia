require 'laia.util.types'

-- read symbols_table file. this file contains
-- two columns: "symbol     id"
function laia.read_symbols_table(filename, sym2int, int2sym, subtract)
  local num_symbols = 0
  sym2int = sym2int or {}  -- If sym2int table is given, update it
  int2sym = int2sym or {}  -- If int2sym table is given, update it
  subtract = subtract or true
  local f = io.open(filename, 'r')
  assert(f ~= nil, ('Unable to read symbols table: %q'):format(filename))
  local ln = 0  -- Line number
  while true do
    local line = f:read('*line')
    if line == nil then break end
    ln = ln + 1
    local sym, id = string.match(line, '^(%S+)%s+(%d+)$')
    assert(sym ~= nil and id ~= nil,
	   ('Expected a string and an integer separated by a space at ' ..
	      'line %d in file %q'):format(ln, filename))
    int = tonumber(id)
    num_symbols = int > num_symbols and int or num_symbols
    if subtract then int = int - 1 end
    sym2int[sym] = int
    table.insert(int2sym, int, sym)
  end
  f:close()
  return num_symbols, sym2int, int2sym
end

function laia.check_contiguous_int2sym(int2sym)
  local ei = 0   -- Expected integer ID
  for i,_ in ipairs(int2sym) do
    ei = ei + 1
    if i ~= ei then return false end
  end
  return true
end

function laia.read_transcripts_table(filename, sym2int, transcripts, sym_count)
  local num_transcripts = 0
  transcripts = transcripts or {}  -- If transcripts table is given, update it
  sym_count = sym_count or {}  -- If counts table is given, update it
  for key,val in pairs(sym2int) do
    if sym_count[val] == nil then
      sym_count[val] = 0
    end
  end
  local f = io.open(filename, 'r')
  assert(f ~= nil, ('Unable to read transcripts table: %q'):format(filename))
  local ln = 0
  while true do
    local line = f:read('*line')
    if line == nil then break end
    ln = ln + 1
    local id, txt = string.match(line, '^(%S+)%s+(%S.*)$')
    assert(id ~= nil and txt ~= nil,
	   ('Wrong transcript format at line %d in file %q')
	     :format(ln, filename))
    transcripts[id] = {}
    num_transcripts = num_transcripts + 1
    for sym in txt:gmatch('%S+') do
      if sym2int ~= nil then
	assert(sym2int[sym] ~= nil,
	       ('Symbol %q is not in the symbols table'):format(sym))
	table.insert(transcripts[id], sym2int[sym])
        local isym = sym2int[sym]
        sym_count[isym] = sym_count[isym] + 1
      else
	assert(laia.isint(sym),
	       ('Token %q is not an integer and no symbols table was given.')
		 :format(sym))
	table.insert(transcripts[id], sym)
      end
    end
  end
  f:close()
  return num_transcripts, transcripts, sym_count
end

-- Load sample files and IDs from list. The IDs are the basenames of the files,
-- i.e., removing directory and extension.
function laia.read_files_list(filename, transcripts, file_list, sample_list)
  local num_samples = 0
  file_list = file_list or {}      -- If file_list table is given, update it
  sample_list = sample_list or {}  -- If sample_list table is given, update it
  local f = io.open(filename, 'r')
  assert(f ~= nil, ('Unable to read image list file: %q'):format(filename))
  local ln = 0
  while true do
    local line = f:read('*line')
    if line == nil then break end
    ln = ln + 1
    local id = string.match(string.gsub(line, ".*/", ""), '^(.+)[.][^./]+$')
    assert(id ~= nil, ('Unable to determine sample ID at line %d in file %q')
	     :format(ln, filename))
    assert(transcripts == nil or transcripts[id] ~= nil,
	   ('No transcription was found for sample ID %q'):format(id))
    table.insert(file_list, line)
    table.insert(sample_list, id)
    num_samples = num_samples + 1
  end
  f:close()
  return num_samples, file_list, sample_list
end
