require 'laia.ClassWithOptions'

local ProgressTable, Parent = torch.class('laia.ProgressTable',
					  'laia.ClassWithOptions')

function ProgressTable:__init(filename, append)
  Parent.__init(self, {
      cer_confidence_interval = true,
      cer_edit_operations = false
  })
  self:open(filename, append)
end

function ProgressTable:registerOptions(parser, advanced)
  advanced = advanced or false
  parser:option(
    '--progress_table_confidence_interval',
    'If true, print confidence itervals of the CER in the progress table.',
    self._opt.cer_confidence_interval, laia.toboolean)
    :argname('<bool>')
    :bind(self._opt, 'cer_confidence_interval')
    :advanced(advanced)
  parser:option(
    '--progress_table_edit_operations',
    'If true, print details on the edit operations (used to compute CER) in ' ..
      'the progress table.',
    self._opt.cer_edit_operations, laia.toboolean)
    :argname('<bool>')
    :bind(self._opt, 'cer_edit_operations')
    :advanced(advanced)
end

function ProgressTable:checkOptions()
  assert(laia.isboolean(self._opt.cer_confidence_interval))
  assert(laia.isboolean(self._opt.cer_edit_operations))
end

function ProgressTable:open(filename, append)
  if self._file then self:close() end
  if filename and filename ~= '-' then
    append = append or false
    self._written_before = append and io.open(filename 'r') ~= nil
    self._file = append and io.open(filename, 'a') or io.open(filename, 'w')
    self._opened = true
    self._warn_ci = false
  elseif filename == '-' then
    self._written_before = false
    self._file = io.stdout
    self._opened = true
    self._warn_ci = false
  else
    self._written_before = false
    self._file = nil
    self._opened = false
    self._warn_ci = false
  end
end

function ProgressTable:close()
  if self._file ~= io.stdout then
    self._file:close()
  end
  self._opened = false
end

function ProgressTable:write(epoch, train_summary, valid_summary, is_better)
  assert(self._opened, 'You tried to write an entry to a closed ProgressTable')
  assert(epoch ~= nil)
  assert(train_summary ~= nil)
  is_better = is_better or false
  -- Write header
  if not self._written_before then
    local header = '# EPOCH TRAIN_LOSS'
    if valid_summary then header = header .. ' VALID_LOSS' end
    header = header .. ' TRAIN_CER'
    if valid_summary then header = header .. ' VALID_CER' end
    if self._opt.cer_confidence_interval and train_summary.cer_ci and
    valid_summary.cer_ci then
      header = header .. ' TRAIN_CER_LO'
      header = header .. ' TRAIN_CER_UP'
      if valid_summary then
	header = header .. ' VALID_CER_LO'
	header = header .. ' VALID_CER_UP'
      end
    elseif self._opt.cer_confidence_interval then
      laia.log.warn('Confidence interval cannot be written to the progress ' ..
		    'table because your summaries do not include them. ' ..
		      'Please, check your options.')
      self._warn_ci = true
    end
    if self._opt.cer_edit_operations then
      header = header .. ' TRAIN_DEL'
      if valid_summary then header = header .. ' VALID_DEL' end
      header = header .. ' TRAIN_INS'
      if valid_summary then header = header .. ' VALID_INS' end
      header = header .. ' TRAIN_SUB'
      if valid_summary then header = header .. ' VALID_SUB' end
    end
    header = header .. ' TRAIN_ET'
    if valid_summary then header = header .. ' VALID_ET' end
    header = header .. ' BETTER'
    self._file:write(header .. '\n')
    self._written_before = true
  end
  local entry = {}
  -- Epoch number
  self._file:write(('%-7d'):format(epoch))
  -- Train loss
  self._file:write((' %10.6f'):format(train_summary.loss))
  -- Valid loss, if present
  if valid_summary then
    self._file:write((' %10.6f'):format(valid_summary.loss))
  end
  -- Train CER%
  self._file:write((' %9.3f'):format(train_summary.cer * 100))
  -- Valid CER%, if present
  if valid_summary then
    self._file:write((' %9.3f'):format(valid_summary.cer * 100))
  end
  -- Confidence intervals
  if self._opt.cer_confidence_interval and train_summary.cer_ci and
  valid_summary.cer_ci then
    -- Train Lower/Upper intervals
    self._file:write((' %12.3f'):format(train_summary.cer_ci.lower * 100))
    self._file:write((' %12.3f'):format(train_summary.cer_ci.upper * 100))
    -- Valid Lower/Upper interval
    if valid_summary then
      self._file:write((' %12.3f'):format(valid_summary.cer_ci.lower * 100))
      self._file:write((' %12.3f'):format(valid_summary.cer_ci.upper * 100))
    end
  elseif self._opt.cer_confidence_interval and not self._warn_ci then
    laia.log.warn('Confidence interval cannot be written to the progress ' ..
		  'table because your summaries do not include them. ' ..
		    'Please, check your options.')
    self._warn_ci = true
  end
  -- Details about the edit operations
  if self._opt.cer_edit_operations then
    -- Deletion operations
    self._file:write((' %9.3f'):format(train_summary.del_ops * 100))
    if valid_summary then
      self._file:write((' %9.3f'):format(valid_summary.del_ops * 100))
    end
    -- Insertion operations
    self._file:write((' %9.3f'):format(train_summary.ins_ops * 100))
    if valid_summary then
      self._file:write((' %9.3f'):format(valid_summary.ins_ops * 100))
    end
    -- Subtitution operations
    self._file:write((' %9.3f'):format(train_summary.sub_ops * 100))
    if valid_summary then
      self._file:write((' %9.3f'):format(valid_summary.sub_ops * 100))
    end
  end
  -- Elapsed time (in minutes)
  self._file:write((' %8.3f'):format(train_summary.duration / 60))
  if valid_summary then
    self._file:write((' %8.3f'):format(valid_summary.duration / 60))
  end
  -- Model improvement
  if is_better then
    self._file:write((' %6s'):format('*'))
  end
  self._file:write('\n')
  self._file:flush()
end

return ProgressTable
