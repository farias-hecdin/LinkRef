local M = {}
local utils = require("Linkref.utils")

-- Abrir el enlace en el navegador
function M.open_in_browser(URL)
  local apps = {}
  if vim.fn.has("unix") == 1 then
    apps = {"xdg-open", "gvfs-open", "gnome-open", "wslview"}
  elseif vim.fn.has("mac") == 1 then
    apps = {"open"}
  elseif vim.fn.has("win32") == 1 then
    apps = {"start"}
  else
    utils.notify("error", "Unsupported operating system")
  end

  local url = URL or ""
  for _, app in ipairs(apps) do
    if vim.fn.executable(app) == 1 then
      local command = ("%s %s"):format(app, vim.fn.shellescape(url))
      -- Ejecutar el comando
      vim.fn.jobstart(command, {detach = true,
        on_exit = function(_, code, _)
          if code ~= 0 then
            utils.notify("error", "Failed to open '%s'", url)
          else
            utils.notify("info", "Opening '%s'", url)
          end
        end,
      })
      return
    end
  end
end

return M
