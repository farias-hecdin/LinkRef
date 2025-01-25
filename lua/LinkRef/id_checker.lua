local M = {}
local notify = require("LinkRef.notify")

function M.verify_file_match()
  -- Capturar el texto precedido por "R-XXX"
  local captured_id = M.capture_id()
  if not captured_id then
    notify.error("[LinkRef] No se encontró texto precedido por 'R-'.")
  end

  -- Encontrar coincidencia
  return M.compare_with_files(captured_id)
end


-- Función para capturar el texto precedido por "TOKEN-XXX"
function M.capture_id()
  local captured_text = nil
  -- Obtener el buffer actual
  local buf = vim.api.nvim_get_current_buf()
  -- Obtener todas las líneas del buffer
  local lines = vim.api.nvim_buf_get_lines(buf, 0, -1, false)
  -- Recorrer todas las líneas y buscar el texto precedido por "TOKEN-XXX"
  for _, line in ipairs(lines) do
    local taken_text = line:match("R%-([%a%d]+)")
    if taken_text then
      captured_text = taken_text
      break
    end
  end

  return captured_text
end


-- Comparar el texto capturado con los nombres de archivos en el directorio nvim/LinkRef
function M.compare_with_files(captured_text)
  local fn = vim.fn
  local fs = vim.fs
  local target = captured_text .. ".json"

  -- Construir path usando API segura
  local dir = fs.joinpath(fn.stdpath('data'), 'LinkRef')
  local file_path = fs.joinpath(dir, target)

  -- Verificación directa del archivo
  if fs.find(target, { path = dir, type = 'file', limit = 1 })[1] then
    return file_path
  end

  -- Manejo de error mejorado
  notify.error("[LinkRef] ID no encontrado: '"..captured_text.."'\n".. "Buscado en: "..dir)
  return nil
end

return M
