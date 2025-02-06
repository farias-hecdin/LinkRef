local M = {}
local notify = require("LinkRef.notify")
local json = require("LinkRef.json_manager")
local utils = require("LinkRef.utils")

--- Capturar un ID en funcion a un patron dado
--- @return table|nil
function M.capture_pattern(prefix, length, collect_all, show_warning)
  local captured = {}
  local pattern = "%f[%a]"..prefix.."%-"..string.rep("[%a%d]", length)
  local lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)

  for _, line in ipairs(lines) do
    if collect_all then
      for match in line:gmatch(pattern) do
        table.insert(captured, match)
      end
    else
      local match = line:match(pattern)
      if match then
        return match
      end
    end
  end

  if collect_all then
    if #captured == 0 and show_warning then
      notify.warn("No se han encontrado IDs válidos.")
      return nil
    end
    return captured
  end
  return nil
end

function M.capture_id()
  return M.capture_pattern("R", 21, false, false)
end


--- Verificar que el archivo exista y tenga el respetivo ID
--- @return string|nil
function M.verify_file_match()
  local captured_text = M.capture_id()
  if not captured_text then
    notify.error("No se encontró texto precedido por 'R-'.")
  end

  local target = captured_text .. ".json"

  -- Extraer el directorio del archivo desde los datos del enrutador
  local router_path = vim.fs.joinpath(vim.fn.stdpath('data'), 'LinkRef', 'g-router.json')
  local router_data = json.read_json_file(router_path) or {}
  local target_path, _ = utils.extract_value_and_index(router_data, captured_text)

  -- Buscar el archivo en el directorio especificado
  if vim.fs.find(target, {path = target_path, type = 'file', limit = 1})[1] then
    return vim.fs.joinpath(target_path, target)
  else
    notify.error("ID no encontrado: '"..captured_text.."'\n".. "Buscado en: "..dir)
    return
  end
end

return M
