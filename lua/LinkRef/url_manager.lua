local M = {}

-- Abrir el enlace en el navegador
function M.open_in_browser(url)
  local apps = nil
  if vim.fn.has("unix") == 1 then
    apps = {"xdg-open", "gvfs-open", "gnome-open", "wslview"}
  elseif vim.fn.has("mac") == 1 then
    apps = {"open"}
  elseif vim.fn.has("win32") == 1 then
    apps = {"start"}
  else
    error("[LinkRef] Sistema operativo no soportado.")
  end

  for _, app in ipairs(apps) do
    if vim.fn.executable(app) == 1 then
      local command = app .. " " .. vim.fn.shellescape(url)
      -- Ejecutar el comando
      vim.fn.jobstart(command, {
        detach = true,
        on_exit = function(_, code, _)
          if code ~= 0 then
            print("[LinkRef] Failed to open: " .. url)
          else
            print("[LinkRef] Opening: " .. url)
          end
        end,
      })
      return
    end
  end
end

return M
