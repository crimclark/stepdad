local FXSequencer = include('timeparty/lib/FXSequencer')

local voice = 1

local SequencersContainer = {}
SequencersContainer.__index = SequencersContainer

function calculate_rate(bpm, beatDivision)
  return (bpm / 60) * beatDivision
end

local rate = 1

function SequencersContainer.new(options)
  local GRID = options.GRID
  local modVals = options.modVals

  -- todo: index sequencers by number?
  local container = {
    sequencers = {
      time = FXSequencer.new{
        grid = GRID,
        modVals = {0.375, 0.5, 0.666, 0.75, 1, 1.333, 1.5, 2},
        set_fx = function(value) softcut.loop_end(voice, value + 1) end,
        visible = true,
      },

      rate = FXSequencer.new{
        grid = GRID,
        modVals = modVals.rateVals,
        set_fx = function(value)
          local newRate = calculate_rate(params:get('bpm'), value)
          local truncated = math.floor(newRate * 100) / 100
          if truncated ~= math.abs(rate) then
            rate = truncated
            softcut.rate(voice, rate)
          end
        end,
      },

      feedback = FXSequencer.new{
        grid = GRID,
        modVals = modVals.equalDivisions,
        set_fx = function(value) softcut.pre_level(voice, value) end,
      },

      mix = FXSequencer.new{
        grid = GRID,
        modVals = modVals.equalDivisions,
        set_fx = function(value)
          audio.level_cut(value)
          audio.level_monitor(1 - value)
        end,
      },
    },
  }
  container.visible = container.sequencers.timeSequencer

  setmetatable(container, SequencersContainer)
  setmetatable(container, {__index = SequencersContainer})

  return container
end

function SequencersContainer:update_tempo()
  for _, v in pairs(self.sequencers) do
    v:update_tempo(params:get('bpm'))
  end
end

function SequencersContainer:start()
  for _, v in pairs(self.sequencers) do v:start() end
end

local t = 0 -- last tap time
local dt = 1 -- last tapped delta

crow.input[1].mode('change', 1, 0.05, 'rising')
crow.input[1].change = function(s)
  local t1 = util.time()
  dt = t1 - t
  t = t1
  params:set('bpm', 60/dt)
end

crow.input[2].mode('change', 1, 0.05, 'rising')
crow.input[2].change = function(s)
  rate = -rate
  softcut.rate(voice, rate)
end

return SequencersContainer
