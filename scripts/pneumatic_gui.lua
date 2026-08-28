-- Pneumatic tube GUI: the network purge button.
--
-- Anchored to the pneumatic pipe window, where vanilla puts the fluid flush
-- button on a regular pipe.  The panel is built on open and destroyed on
-- close, so no element state has to survive anywhere else.

local pneumatic = require("scripts.pneumatic")

local M = {}

local PURGE_PANEL = "administratorio-tube-purge-panel"
local PURGE_BUTTON = "administratorio-tube-purge"

local PIPE_NAMES = {"pneumatic-pipe", "pneumatic-pipe-to-ground"}

-------------------------------------------------------------------------------
-- PIPE PURGE PANEL
-------------------------------------------------------------------------------

local function build_purge_panel(player, entity)
  local net_id = pneumatic.network_id_at(entity)

  local frame = player.gui.relative.add{
    type = "frame",
    name = PURGE_PANEL,
    direction = "vertical",
    caption = {"gui.tube-info-title"},
    anchor = {
      gui = defines.relative_gui_type.pipe_gui,
      position = defines.relative_gui_position.right,
      names = PIPE_NAMES,
    },
  }
  local body = frame.add{type = "frame", style = "inside_shallow_frame_with_padding", direction = "vertical"}

  body.add{type = "label", caption = {"gui.tube-purge-contents", net_id and pneumatic.get_network_total(net_id) or 0}}
  body.add{
    type = "button",
    name = PURGE_BUTTON,
    style = "red_button",
    caption = {"gui.tube-purge"},
    tooltip = {"gui.tube-purge-tooltip"},
    enabled = net_id ~= nil,
  }.style.top_margin = 4
end

-------------------------------------------------------------------------------
-- EVENT HANDLING
-------------------------------------------------------------------------------

local function destroy_panels(player)
  local existing = player.gui.relative[PURGE_PANEL]
  if existing then existing.destroy() end
end

local function is_pneumatic_pipe(entity)
  for _, name in ipairs(PIPE_NAMES) do
    if entity.name == name then return true end
  end
  return false
end

function M.on_gui_opened(event)
  local player = game.get_player(event.player_index)
  if not player then return end
  destroy_panels(player)

  local entity = event.entity
  if entity and entity.valid and is_pneumatic_pipe(entity) then
    build_purge_panel(player, entity)
  end
end

function M.on_gui_closed(event)
  local player = game.get_player(event.player_index)
  if player then destroy_panels(player) end
end

--- The pneumatic pipe whose window a panel element belongs to, or nil.
local function opened_pipe(player)
  if player.opened_gui_type ~= defines.gui_type.entity then return nil end
  local entity = player.opened
  if entity and entity.valid and is_pneumatic_pipe(entity) then return entity end
  return nil
end

--- Returns true when the click was ours.
function M.on_gui_click(event)
  local element = event.element
  if not element or not element.valid or element.name ~= PURGE_BUTTON then return false end

  local player = game.get_player(event.player_index)
  local entity = player and opened_pipe(player)
  if not entity then return true end

  local destroyed = pneumatic.purge_network(pneumatic.network_id_at(entity))
  player.print({"gui.tube-purged", destroyed})
  destroy_panels(player)
  build_purge_panel(player, entity)
  return true
end

return M
