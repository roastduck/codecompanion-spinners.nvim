-- A rich notifier using vim.notify (enhanced by plugins like `noice.nvim`).
--
-- This spinner is a "dumb" renderer. It receives state updates from the
-- central tracker and displays the appropriate notification based on the
-- plugin's configuration.
local M = {}

local config = require("codecompanion._extensions.spinner.config")
local tracker = require("codecompanion._extensions.spinner.tracker")

-- State mapping for content
local state_map = tracker.state_map

local NOTIFICATION_ID = "codecompanion_spinner"

local function show_notification(content, is_done, is_spinning)
  local current_config = require("codecompanion._extensions.spinner.config")
  local cfg = current_config.get()
  if not cfg then
    return
  end
  local default_icon = cfg.default_icon

  local display_icon = content.icon
  local message = string.format("%s%s%s", display_icon, content.spacing, content.message)

  local opts = {
    id = NOTIFICATION_ID,
    title = " CodeCompanion",
    dismiss = false,
  }

  if is_done then
    opts.timeout = 2000
    opts.dismiss = true
    opts.icon = default_icon -- Use default icon for title when done
  elseif is_spinning then
    opts.timeout = 0
    opts.icon = (function()
      local spinner = { "⠋", "⠙", "⠹", "⠸", "⠼", "⠴", "⠦", "⠧", "⠇", "⠏" }
      return spinner[math.floor(vim.uv.hrtime() / (1e6 * 80)) % #spinner + 1]
    end)()
  else
    opts.timeout = 2000
    opts.dismiss = true
    opts.icon = display_icon
  end

  vim.notify(message, "info", opts)
end

--- The main render function called by the plugin's core.
--- @param new_state number The new state from the tracker.
--- @param event string The raw event that triggered the state change.
function M.render(new_state, event)
  if new_state == tracker.State.IDLE then
    local content = config.get_content_for_state("done")
    show_notification(content, true, false)
  else
    local state_name = state_map[new_state] or "idle"
    local content = config.get_content_for_state(state_name)
    show_notification(content, false, true)
  end

  -- Handle one-off notification events that don't have a persistent state
  local state_key = tracker.one_off_events[event]
  if state_key then
    local content = config.get_content_for_state(state_key)
    show_notification(content, true, false)
  end
end

--- One-time setup for this spinner style.
function M.setup()
  -- Check for dependency
  local ok, _ = pcall(require, "noice")
  if not ok then
    vim.notify(
      "Noice spinner requires `noice.nvim` plugin.",
      vim.log.levels.WARN,
      { title = "CodeCompanion Spinners" }
    )
  end
end

return M
