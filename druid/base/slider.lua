--- Druid slider component
-- @module druid.slider

--- Component events
-- @table Events
-- @tfield druid_event on_change_value On change value callback

--- Component fields
-- @table Fields
-- @tfield node node Slider pin node
-- @tfield vector3 start_pos Start pin node position
-- @tfield vector3 pos Current pin node position
-- @tfield vector3 target_pos Targer pin node position
-- @tfield vector3 end_pos End pin node position
-- @tfield number dist Length between start and end position
-- @tfield bool is_drag Current drag state
-- @tfield number value Current slider value


local Event = require("druid.event")
local helper = require("druid.helper")
local const = require("druid.const")
local component = require("druid.component")

local M = component.create("slider", { const.ON_INPUT_HIGH })


local function on_change_value(self)
	self.on_change_value:trigger(self:get_context(), self.value)
end


--- Component init function
-- @function slider:init
-- @tparam node node Gui pin node
-- @tparam vector3 end_pos The end position of slider
-- @tparam[opt] function callback On slider change callback
function M.init(self, node, end_pos, callback)
	self.node = self:get_node(node)

	self.start_pos = gui.get_position(self.node)
	self.pos = gui.get_position(self.node)
	self.target_pos = self.pos
	self.end_pos = end_pos

	self.dist = self.end_pos - self.start_pos
	self.is_drag = false
	self.value = 0

	self.on_change_value = Event(callback)

	assert(self.dist.x == 0 or self.dist.y == 0, "Slider for now can be only vertical or horizontal")
end


function M.on_input(self, action_id, action)
	if action_id ~= const.ACTION_TOUCH then
		return false
	end

	if gui.pick_node(self.node, action.x, action.y) then
		if action.pressed then
			self.pos = gui.get_position(self.node)
			self.is_drag = true
		end
	end

	if self.is_drag and not action.pressed then
		-- move
		self.pos.x = self.pos.x + action.dx
		self.pos.y = self.pos.y + action.dy

		local prev_x = self.target_pos.x
		local prev_y = self.target_pos.y

		self.target_pos.x = helper.clamp(self.pos.x, self.start_pos.x, self.end_pos.x)
		self.target_pos.y = helper.clamp(self.pos.y, self.start_pos.y, self.end_pos.y)

		gui.set_position(self.node, self.target_pos)

		if prev_x ~= self.target_pos.x or prev_y ~= self.target_pos.y then

			if self.dist.x > 0 then
				self.value = (self.target_pos.x - self.start_pos.x) / self.dist.x
			end

			if self.dist.y > 0 then
				self.value = (self.target_pos.y - self.start_pos.y) / self.dist.y
			end

			on_change_value(self)
		end
	end

	if action.released then
		self.is_drag = false
	end

	return self.is_drag
end


--- Set value for slider
-- @function slider:set
-- @tparam number value Value from 0 to 1
-- @tparam[opt] bool is_silent Don't trigger event if true
function M.set(self, value, is_silent)
	value = helper.clamp(value, 0, 1)

	gui.set_position(self.node, self.start_pos + self.dist * value)
	self.value = value
	if not is_silent then
		on_change_value(self)
	end
end


return M
