local M = {}
local uv = vim.loop
local notify = require("LinkRef.notify")

--- Crea un directorio recursivamente si no existe
--- @return boolean
function M.ensure_directory_exists(path)
  if not M.is_directory(path) then
    local success = fn.mkdir(path, "p") == 1
    local msg = success and "Directorio creado: " or "Error creando directorio: "
    notify.info(msg .. path)
    return success
  end
  return true
end


--- Crear un archivo vacío si no existe
--- @return boolean
function M.ensure_file_exists(file_path, hidden_warning)
  if M.is_file(file_path) then
    notify.warn("El archivo ya existe: " .. file_path, hidden_warning)
    return true
  end

  local file = io.open(file_path, "w")
  if file then
    file:close()
    notify.info("Archivo creado: " .. file_path)
    return true
  end

  notify.error("Error al crear archivo: " .. file_path)
  return false
end


--- Normalizar y preparar una ruta de documento
--- @return string|nil
function M.prepare_document_path(base_dir, document_name)
  base_dir = base_dir or fn.getcwd()
  local normalized_dir = base_dir:gsub("[\\/]+$", "") .. "/"

  if not is_directory(normalized_dir) then
    return
  end

  local document_path = string.format("%s%s.json", normalized_dir, document_name)
  M.ensure_file_exists(document_path)
  return normalized_dir
end


--- Verificar si una ruta existe y es un directorio
--- @return boolean
function M.is_directory(path)
  local stat = uv.fs_stat(path)
  return stat and stat.type == "directory"
end


--- Verificar si una ruta existe y es un archivo
--- @return boolean
function M.is_file(path)
  local stat = uv.fs_stat(path)
  return stat and stat.type == "file"
end


--- Eliminar una subtabla por su índice
function M.remove_subtable(main_table, index)
  local size = #main_table
  if index > 0 and index <= size then
    table.remove(main_table, index)
  else
    notify.error("Índice fuera de rango: "..index.." (Tamaño: "..size..")", 2)
  end
end


--- Reorganizar los índices
function M.reorganize_indices(main_table)
  return table.move(main_table, 1, #main_table, 1, {})
end


--- Extraer el valor e índice de un registro
--- @return string|nil, integer|nil
function M.extract_value_and_index(records, matching_key)
  if not #records == 0 then
    for index = 1, #records do
      local record = records[index]
      local key = next(record)  -- Obtiene la primera y única clave
      if key == matching_key then
        return record[key], index
      end
    end
  end
end

return M
