#!/usr/bin/env th

require 'laia'
assert(rnn2d ~= nil, 'rnn2d is required by create-model-aachen')

local parser = laia.argparse(){
  name = 'create-model-aachen.lua',
  description = 'Model described in ``Handwriting Recognition with Large '..
    'Multidimensional Long Short-Term Memory Recurrent Neural Networks\'\', ' ..
    'by P.Voigtlaender, P. Doetsch and H. Ney.'
}

parser:option(
  '--cnn_num_units', 'Number of feature in each conv layer, n >= 0',
  {15, 45, 75, 105, 120}, laia.toint)
  :argname('<n>')
  :args('+')
  :ge(0)            -- Number of features must be >= 0

parser:option(
  '--rnn_num_units', 'Number of features in each LSTM layer, n >= 0.',
  {30, 60, 90, 120, 120}, laia.toint)
  :argname('<n>')
  :args('+')
  :ge(0)            -- Number of features must be >= 0

parser:option(
  '--batch_norm',
  'Batch normalization before the activation in each conv layer.',
  {false}, laia.toboolean)
  :argname('<bool>')  -- Placeholder
  :args('+')          -- Option with >= 1 arguments

parser:option(
  '--cnn_dropout',
  'Dropout probability at the input of each conv layer, 0 <= p < 1.',
  {0, 0.25, 0.25, 0.25, 0.25}, tonumber)
  :argname('<p>')
  :args('+')
  :ge(0.0):lt(1.0)  -- Dropout must be in the range [0, 1)

parser:option(
  '--rnn_dropout',
  'Dropout probability at the input of each LSTM layer, 0 <= p < 1.',
  {0.25, 0.25, 0.25, 0.25, 0.25}, tonumber)
  :argname('<p>')
  :args('+')
  :ge(0.0):lt(1.0)  -- Dropout must be in the range [0, 1)

parser:option(
  '--linear_dropout',
  'Dropout probability at the input of the final linear layer, 0 <= p < 1.',
  0, tonumber)
  :argname('<p>')
  :ge(0.0):lt(1.0)

parser:option(
  '--spatial_dropout',
  'Use spatial dropout instead of the regular dropout.',
  {false}, laia.toboolean)
  :argname('<bool>')
  :args('+')

parser:option(
  '--maxpool_size', 'Max pooling size after each conv layer. Separate ' ..
  'each dimension with commas (order: width,height).',
  {{2,2}, {2,2}, {2,2}, {0}, {0}}, laia.tolistint)
  :argname('<size>')
  :args('+')
  :assert(function(t) return table.all(t, function(x) return x >= 0 end) end)
  :tostring(function(x) return table.concat(table.map(x, tostring), ',') end)

parser:option(
  '--cnn_kernel_size', 'Kernel size of each conv layer. Separate each ' ..
  'dimension with commas (order: width,height).',
  {{3,3}, {3,3}, {3,3}, {3,3}, {3,3}}, laia.tolistint)
  :argname('<size>')
  :args('+')
  :assert(function(t) return table.all(t, function(x) return x > 0 end) end)
  :tostring(function(x) return table.concat(table.map(x, tostring), ',') end)

parser:option(
  '--cnn_type',
  'Type of the activation function in each conv layer, valid types are ' ..
  'relu, tanh, prelu, rrelu, leakyrelu, softplus.',
  {'tanh'}, {relu = 'relu',
	     tanh = 'tanh',
	     prelu = 'prelu',
	     rrelu = 'rrelu',
	     leakyrelu = 'leakyrelu',
	     softplus = 'softplus'})
  :argname('<type>')
  :args('+')

parser:option(
  '--collapse_type',
  'Type of the collapse function after the last block, valid types are ' ..
  'avg, max, sum.',
  'sum', {sum = 'sum', avg = 'avg', max = 'max'})
  :argname('<type>')

parser:option(
  '--seed -s', 'Seed for random numbers generation.',
  0x012345, laia.toint)

-- Arguments
parser:argument(
  'input_channels', 'Number of channels of the input images.')
  :convert(laia.toint)
  :gt(0)
parser:argument(
  'output_size',
  'Number of output symbols. If you are going to use the CTC ' ..
  'loss include one additional element!')
  :convert(laia.toint)
  :gt(0)
parser:argument(
  'output_file', 'Output file to store the model')

-- Register laia.Version options
laia.Version():registerOptions(parser)
-- Register logging options
laia.log.registerOptions(parser)

local opt = parser:parse()

-- Number of blocks is determined by the number of elements in either
-- --cnn_num_units or --rnn_num_units, which should be the same.
local cnn_layers = #opt.cnn_num_units
local rnn_layers = #opt.rnn_num_units
assert(cnn_layers == rnn_layers,
       'Please, specify the same number of CNN and RNN layers. If you wish ' ..
       'to omit one of these layers at some block, place a 0 in the number ' ..
       'of units in that position.')


-- Ensure that all options for the convolutional layers have the same length
-- (equal to the number of specified layers). The last option in a list is
-- copied to extend the list until a size of cnn_layers is achieved.
table.append_last(opt.cnn_kernel_size, cnn_layers - #opt.cnn_kernel_size)
table.append_last(opt.maxpool_size, cnn_layers - #opt.maxpool_size)
table.append_last(opt.batch_norm, cnn_layers - #opt.batch_norm)
table.append_last(opt.cnn_type, cnn_layers - #opt.cnn_type)
table.append_last(opt.spatial_dropout, cnn_layers - #opt.spatial_dropout)
table.append_last(opt.cnn_dropout, cnn_layers - #opt.cnn_dropout)
table.append_last(opt.rnn_dropout, rnn_layers - #opt.rnn_dropout)

-- Kernel sizes must be pairs of integers
opt.cnn_kernel_size = table.map(
  opt.cnn_kernel_size, function(x) return table.append_last(x, 2 - #x) end)

-- Maxpool sizes must be pairs of integers
opt.maxpool_size = table.map(
  opt.maxpool_size, function(x) return table.append_last(x, 2 - #x) end)

-- Initialize random seeds
laia.manualSeed(opt.seed)

-- Auxiliary function to create a CNN + LSTM2D block
local function addBlock(
    -- Input size, number of filters of the cnn and LSTM2D
    depth_in, cnn_size, rnn_size,
    -- Size of the convolution kernels
    kernel_w, kernel_h,
    -- Size of the pooling windows
    pool_w, pool_h,
    -- Dropout at the beginning of the cnn and LSTM2D layers
    cnn_dropout, rnn_dropout, spatial_dropout,
    activation, batch_norm)
  activation = activation or 'tanh'
  batch_norm = batch_norm or false
  cnn_dropout = cnn_dropout or 0
  rnn_dropout = rnn_dropout or 0
  spatial_dropout = spatial_dropout or false
  assert(cnn_size > 0 or rnn_size > 0,
	 'Each block must include either a CNN or a RNN layer.')

  local block = nn.Sequential()

  -- Add convolution block
  if cnn_size > 0 then
    -- Spatial dropout to the input of the convolutional layer
    if cnn_dropout > 0 then
      if spatial_dropout then
	block:add(nn.SpatialDropout(cnn_dropout))
      else
	block:add(nn.Dropout(cnn_dropout))
      end
    end

    -- Spatial 2D convolution. Image is padded with zeroes so that the output
    -- has the same size as the input.
    block:add(nn.SpatialConvolution(
		depth_in, cnn_size,
		kernel_w, kernel_h,
		1, 1,
		(kernel_w - 1) / 2, (kernel_h - 1) / 2))

    -- Batch normalization
    if batch_norm then
      block:add(nn.SpatialBatchNormalization(depth_out))
    end

    -- Max pooling
    if pool_w > 0 and pool_h > 0 then
      block:add(nn.SpatialMaxPooling(pool_w, pool_h, pool_w, pool_h))
    end

    -- Activation function
    if activation == 'relu' then
      block:add(nn.ReLU(true))
    elseif activation == 'tanh' then
      block:add(nn.Tanh())
    elseif activation == 'leakyrelu' then
      block:add(nn.LeakyReLU(true))
    elseif activation == 'softplus' then
      block:add(nn.SoftPlus())
    elseif activation == 'prelu' then
      block:add(nn.PReLU())
    elseif activation == 'rrelu' then
      block:add(nn.RReLU(1.0 / 8.0, 1.0 / 3.0, true))
    else
      error(string.format('Unknown activation function %s', activation))
    end

    -- Update input depth to the LSTM 2D
    depth_in = cnn_size
  end

  -- Add LSTM-2D block
  if rnn_size > 0 then
    -- Spatial dropout to the input of the LSTM-2D layer
    if rnn_dropout > 0 then
      if spatial_dropout then
	block:add(nn.SpatialDropout(rnn_dropout))
      else
	block:add(nn.Dropout(rnn_dropout))
      end
    end

    -- NxCxHxW -> HxCxNxW -> HxWxNxC, which is the format that the LSTM-2D expects
    block:add(nn.Transpose({1, 3}, {2, 4})):add(nn.Contiguous())
    -- Note that the output depth is actually rnn_size x 4
    block:add(rnn2d.LSTM(depth_in, rnn_size))  -- shape: HxWxNx(4*C)
    -- Average the outputs from each of the directions
    block:add(nn.ConcatTable()
		:add(nn.Narrow(4, 0 * rnn_size + 1, rnn_size))
		:add(nn.Narrow(4, 1 * rnn_size + 1, rnn_size))
		:add(nn.Narrow(4, 2 * rnn_size + 1, rnn_size))
		:add(nn.Narrow(4, 3 * rnn_size + 1, rnn_size)))
    block:add(nn.MapTable(nn.Unsqueeze(4)))
    block:add(nn.JoinTable(4))                 -- shape: HxWxNx4xC
    block:add(nn.Mean(4))                      -- shape: HxWxNxC

    -- HxWxNxC -> HxCxNxW -> NxCxHxW, bring the shape of the data back to what the conv nets expect
    block:add(nn.Transpose({1, 3}, {2, 4})):add(nn.Contiguous())
  end

  return block
end


local model = nn.Sequential()
local curr_c = opt.input_channels

-- Append cnn + rnn blocks
for i=1,cnn_layers do
  model:add(addBlock(curr_c, opt.cnn_num_units[i], opt.rnn_num_units[i],
		     opt.cnn_kernel_size[i][1], opt.cnn_kernel_size[i][2],
		     opt.maxpool_size[i][1], opt.maxpool_size[i][2],
		     opt.cnn_dropout[i], opt.rnn_dropout[i],
		     opt.spatial_dropout[i], opt.cnn_type[i],
		     opt.batch_norm[i]))
  if opt.rnn_num_units[i] > 0 then
    curr_c = opt.rnn_num_units[i]
  else
    curr_c = opt.cnn_num_units[i]
  end
end

-- Convert from HxWxNxC to WxNxC, collapsing the Height dimension
if opt.collapse_type == 'avg' then
  model:add(nn.Mean(1))
elseif opt.collapse_type == 'max' then
  model:add(nn.Max(1))
elseif opt.collapse_type == 'sum' then
  model:add(nn.Sum(1))
else
  error(string.format('Unknown collapse type %s', opt.collapse_type))
end

-- Linear projection of each timestep and batch sample (WxNxC -> (W*N)xC)
model:add(nn.Reshape(-1, curr_c, false))
if opt.linear_dropout > 0 then
  model:add(nn.Dropout(opt.linear_dropout))
end
model:add(nn.Linear(curr_c, opt.output_size))
model:float()

-- Save model to disk
local checkpoint = laia.Checkpoint()
checkpoint:setModelConfig(opt)
checkpoint:Best():setModel(model)
checkpoint:Last():setModel(model)
checkpoint:save(opt.output_file)

local p, _ = model:getParameters()
laia.log.info('\n' .. model:__tostring__())
laia.log.info('Saved model with %d parameters to %q',
	      p:nElement(), opt.output_file)
