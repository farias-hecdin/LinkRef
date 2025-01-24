local M = {}

-- Eliminar una subtabla por su índice
function M.remove_subtable(mainTable, index)
  -- Verificar si el índice es válido
  if index <= #mainTable then
    table.remove(mainTable, index)
  else
    error("[LinkRef] Índice fuera de rango")
  end
end


-- Reorganizar los índices
function M.reorganize_indices(mainTable)
  local newTable = {}
  for i, subtable in ipairs(mainTable) do
    newTable[i] = subtable
  end
  return newTable
end


-- Buscar valor e índice en el registro
function M.search_data(records, matching_key)
  for index, record in ipairs(records) do
    for key, value in pairs(record) do
      if key == matching_key then
        return value, index
      end
    end
  end
end


-- Definir la función en Lua
function M.add_text_to_buffer(token)
  local text = "<!- " .. token .. " -->"
  local buf = vim.api.nvim_get_current_buf()
  -- Insertar el texto en la primera línea y mover el cursor
  vim.api.nvim_buf_set_lines(buf, 0, 0, false, {text})
  vim.api.nvim_win_set_cursor(0, {1, 0})
end


-- Verificar si un archivo o directorio existe
local function exists(path)
  local stat = vim.loop.fs_stat(path)
  return stat ~= nil
end


-- Crear un directorio si no existe
function M.create_dir_if_missing(path)
  if not exists(path) then
    vim.loop.fs_mkdir(path, 493) -- 493 es el permiso 0755 en octal
    print("[LinkRef] Directorio creado: " .. path)
  end
end


-- Crear un archivo si no existe
function M.create_file_if_missing(path)
  if not exists(path) then
    local file = io.open(path, "w")
    if file then
      file:close()
      print("[LinkRef] Archivo creado: " .. path)
    else
      print("[LinkRef] Error al crear el archivo: " .. path)
    end
  else
    print("[LinkRef] El archivo ya existe: " .. path)
  end
end

return M
