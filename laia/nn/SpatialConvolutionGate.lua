-- Implement a Spatial Convolution Gate, inspired by the work of T. Bluche
-- and R. Messina, described in ``Gated Convolutional Recurrent Neural
-- Networks for Multilingual Handwriting Recognition''.
--
-- Note: To implement the same module as the described in the paper, use
-- detphwise = false.

local SpatialConvolutionGate, parent = torch.class(
  'laia.nn.SpatialConvolutionGate', 'nn.Module')


function SpatialConvolutionGate:__init(nInputPlane, kW, kH, depthwise)
  parent.__init(self)
  assert(nInputPlane > 0, 'nInputPlane must be greater than 0')
  assert(kW > 0, 'Kernel width must be greater than 0')
  assert(kH > 0, 'Kernel height must be greater than 0')
  self.nInputPlane = nInputPlane
  self.kW = kW
  self.kH = kH
  self.depthwise = depthwise or false

  -- Spatial convolution that produces an output image of the same size as the
  -- input and the same number of channels.
  local conv = nil
  if self.depthwise then
    -- We use a depth-wise convolution, which processes each input channel
    -- independently.
    -- Number of parameters: (nInputPlane x kW x kH)
    conv = nn.SpatialDepthWiseConvolution(
      self.nInputPlane, 1, kW, kH, 1, 1,
      math.ceil((kW - 1) / 2), math.ceil((kH - 1) / 2))
  else
    -- We use a regular spatial convolution.
    -- Number of parameters: (nInputPlane x nInputPlane x kW x kH)
    conv = nn.SpatialConvolution(
      self.nInputPlane, self.nInputPlane, kW, kH, 1, 1,
      math.ceil((kW - 1) / 2), math.ceil((kH - 1) / 2))
  end

  -- Spatial Convolution module.
  self.module = nn.Sequential()
    :add(nn.ConcatTable()
	   :add(nn.Sequential():add(conv):add(nn.Sigmoid()))
	   :add(nn.Identity()))
    :add(nn.CMulTable())
  self.module:reset()
end

function SpatialConvolutionGate:updateOutput(input)
  self.output = self.module:updateOutput(input)
  return self.output
end

function SpatialConvolutionGate:updateGradInput(input, gradOutput)
  self.gradInput = self.module:updateGradInput(input, gradOutput)
  return self.gradInput
end

function SpatialConvolutionGate:accGradParameters(input, gradOutput, lr)
  self.module:accGradParameters(input, gradOutput, lr)
end

function SpatialConvolutionGate:accUpdateGradParameters(input, gradOutput, lr)
  self.module:accUpdateGradParameters(input, gradOutput, lr)
end

function SpatialConvolutionGate:zeroGradParameters()
  self.module:zeroGradParameters()
end

function SpatialConvolutionGate:updateParameters(learningRate)
  self.module:updateParameters(learningRate)
end

function SpatialConvolutionGate:training()
  self.module:training()
  parent.training(self)
end

function SpatialConvolutionGate:evaluate()
  self.module:evaluate()
  parent.evaluate(self)
end

function SpatialConvolutionGate:share(m, ...)
  self.module:share(m.module, ...)
  return self
end

function SpatialConvolutionGate:reset(stdv)
  self.module:reset(stdv)
end

function SpatialConvolutionGate:parameters()
  return self.module:parameters()
end

function SpatialConvolutionGate:clearState()
  self.module:clearState()
  return self
end

function SpatialConvolutionGate:__tostring__()
  local str = string.format('%s(%d, %dx%d)', torch.type(self),
			    self.nInputPlane, self.kW, self.kH)
  if self.depthwise then
    str = str .. ' depthwise'
  end
  return str
end

return SpatialConvolutionGate
