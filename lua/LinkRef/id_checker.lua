local M = {}

function M.verify_file_match()
  -- Capturar el texto precedido por "R-XXX"
  local captured_id = M.capture_id()
  if not captured_id then
    error("[LinkRef] No se encontró texto precedido por 'R-'.")
  end
  -- Encontrar coincidencia
  return M.compare_with_files(captured_id)
end


-- Comprabar si el ID existe
function M.compare_with_ids(content, id)
  for _, item in ipairs(content) do
    for key, _ in pairs(item) do
      if key == id then
        return true
      end
    end
  end
  return false
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


-- Función para comparar el texto capturado con los nombres de archivos en el directorio nvim/LinkRef
function M.compare_with_files(captured_text)
  -- Directorio donde se encuentran los archivos
  local directory = vim.fn.stdpath('data') .. '/LinkRef/'
  -- Obtener la lista de archivos en el directorio
  local files = vim.fn.globpath(directory, "*", false, true)
  -- Recorrer la lista de archivos y comparar con el texto capturado
  for _, file in ipairs(files) do
    local filename = vim.fn.fnamemodify(file, ":t") -- Obtener solo el nombre del archivo
    if filename == captured_text .. ".json" then
      return file
    end
  end
  error("[LinkRef] El ID capturado no coincide con ningún archivo en el directorio LinkRef.")
  return nil
end

return M
