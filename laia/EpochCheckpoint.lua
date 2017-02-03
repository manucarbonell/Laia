local EpochCheckpoint = torch.class('laia.EpochCheckpoint')

-- Utility class to save/load Laia checkpoints from/to disk.
--
-- EpochCheckpoints store (among other things):
-- Epoch number
-- Model
-- Performance on different partitions (e.g. 'train', or 'valid')
-- etc
--
-- It is important that when a model is binded to a checkpoint through
-- setModel(model), the model is cloned to the CPU and all possible cudnn
-- modules are replaced by the nn equivalents.
-- This allows to use the checkpoint on other systems that don't have these
-- packages installed.
--
-- Next, an example of how to use this class to make a checkpoint each time
-- the model is improved during training.
--
-- local checkpoint = laia.EpochCheckpoint()
-- checkpoint:load('epoch_checkpoint.t7')
-- local model = checkpoint:getModel():cuda()
-- local best_cer = checkpoint:getSummary('valid').cer
-- for epoch=(checkpoint:getEpoch()+1),100 do
--   TrainEpoch(model, ...)
--   local summary = ComputeSummary(model, ...)
--
--   -- If the accuracy improves, make a checkpoint of the model.
--   if best_cer == nil or best_cer > summary.cer then
--     checkpoint:setEpoch(epoch)
--     checkpoint:setModel(model)
--     checkpoint:addSummary('valid', summary)
--     best_cer = summary.cer
--   end
-- end

function EpochCheckpoint:__init()
  self._summaries = {}
end

function EpochCheckpoint:clear()
  for k, _ in pairs(self) do
    self[k] = nil
  end
  self._summaries = {}
end

-- Getter/Setter for the last Epoch
function EpochCheckpoint:getEpoch()
  return self._epoch or 0
end
function EpochCheckpoint:setEpoch(epoch)
  self._epoch = epoch
  return self
end

-- Getter/Setter for the last Model
function EpochCheckpoint:getModel()
  return self._model
end
function EpochCheckpoint:setModel(model)
  if model then
    -- Always keep a deep copy of the last model on the CPU
    self._model = EpochCheckpoint._cloneToCPU(model)
    self._model:clearState()
    -- By default, use all the possible nn layers to maximize portability.
    if cudnn then cudnn.convert(self._model, nn) end
  else
    self._model = nil
  end
  return self
end

-- Getter/Setter for the last train summary
function EpochCheckpoint:getSummary(key)
  return self._summaries[key]
end
function EpochCheckpoint:addSummary(key, summary)
  self._summaries[key] = summary
  return self
end

-- Save checkpoint to file
function EpochCheckpoint:save(filename)
  torch.save(filename, self)
end

-- Load checkpoint from file
function EpochCheckpoint:load(filename)
  self:clear()
  local checkpoint = torch.load(filename)
  if torch.isTypeOf(checkpoint, 'laia.EpochCheckpoint') then
    for k, v in pairs(checkpoint) do
      self[k] = v
    end
  elseif torch.isTypeOf(checkpoint, 'nn.Module') then
    self:setEpoch(0)
    self:setModel(checkpoint)
  elseif torch.type(checkpoint) == 'table' then
    self:setEpoch(checkpoint.epoch or 0)
    self:setModel(checkpoint.model)
  else
    laia.log.fatal('Wrong epoch checkpoint data in %q!', filename)
  end
  return self
end

local _cloneToCPU_typemap = {
  ['torch.CudaByteTensor'] = 'torch.ByteTensor',
  ['torch.CudaCharTensor'] = 'torch.CharTensor',
  ['torch.CudaShortTensor'] = 'torch.ShortTensor',
  ['torch.CudaIntTensor'] = 'torch.IntTensor',
  ['torch.CudaLongTensor'] = 'torch.LongTensor',
  ['torch.CudaTensor'] = 'torch.FloatTensor',
  ['torch.CudaDoubleTensor'] = 'torch.DoubleTensor',
  -- Data on the CPU does not change type.
  ['torch.ByteTensor'] = 'torch.ByteTensor',
  ['torch.CharTensor'] = 'torch.CharTensor',
  ['torch.ShortTensor'] = 'torch.ShortTensor',
  ['torch.IntTensor'] = 'torch.IntTensor',
  ['torch.LongTensor'] = 'torch.LongTensor',
  ['torch.FloatTensor'] = 'torch.FloatTensor',
  ['torch.DoubleTensor'] = 'torch.DoubleTensor'
}

function EpochCheckpoint._cloneToCPU(obj, tensorCache)
  tensorCache = tensorCache or {}
  if torch.type(obj) == 'table' then
    local new_obj = {}
    for k, v in pairs(obj) do
      new_obj[k] = EpochCheckpoint._cloneToCPU(v, tensorCache)
    end
    obj, new_obj = new_obj, nil
  elseif
    torch.isTypeOf(obj, 'nn.Module') or
    torch.isTypeOf(obj, 'nn.Criterion')
  then
    local new_obj = {}
    torch.setmetatable(new_obj, torch.typename(obj))
    for k, v in pairs(obj) do
      new_obj[k] = EpochCheckpoint._cloneToCPU(v, tensorCache)
    end
    new_obj._type = _cloneToCPU_typemap[obj._type]
    obj, new_obj = new_obj, nil
  elseif torch.isTensor(obj) then
    if tensorCache[obj] then
      obj = tensorCache[obj]
    else
      local old_type = torch.typename(obj)
      local new_type = _cloneToCPU_typemap[old_type]
      local new_obj = torch.Tensor():type(new_type)
      if obj:storage() then
	local storage_type = new_type:gsub('Tensor', 'Storage')
	local storage_key = torch.pointer(obj:storage())
	if not tensorCache[storage_key] then
	  local new_storage = torch.getmetatable(storage_type).new()
	  if obj:storage():size() > 0 then
	    new_storage:resize(obj:storage():size()):copy(obj:storage())
	  end
	  tensorCache[storage_key], new_storage = new_storage, nil
	end
	assert(torch.type(tensorCache[storage_key]) == storage_type)
	new_obj:set(
	  tensorCache[storage_key],
	  obj:storageOffset(),
	  obj:size(),
	  obj:stride()
	)
      end
      assert(torch.type(new_obj) == new_type)
      tensorCache[obj] = new_obj
      obj, new_obj = new_obj, nil
    end
  end
  return obj
end

return EpochCheckpoint
