local M = {}
local uv = vim.uv or vim.loop

--- Mapeo del nivel del log
local LEVEL_MAP = {
  ERROR = vim.log.levels.ERROR,
  WARN = vim.log.levels.WARN,
  INFO = vim.log.levels.INFO,
  DEBUG = vim.log.levels.DEBUG
}

--- Muestra un mensaje en la consola
--- @param input (string) Mensaje de entrada
--- @param level (string) Nivel del log (error, warn, ...)
--- @vararg (string|number)
--- @return (nil)
M.notify = function(level, input, ...)
  local log = LEVEL_MAP[level:upper()] or vim.log.levels.INFO
  local message = select("#", ...) > 0 and input:format(...) or input
  vim.notify(("[Linkref] %s. <%s>"):format(message, os.date("%H:%M:%S")), log)
  return nil
end


--- Eliminar una subtabla por su índice
--- @param main_table (table)
--- @param index (number)
--- @return (table)
function M.remove_subtable(main_table, index)
  local size = #main_table
  if index > 0 and index <= size then
    table.remove(main_table, index)
  else
    M.notify(("Index out of range: %d (size: %d)"):format(index, size), "error")
  end
  return main_table
end


--- Reorganizar los índices de una tabla
--- @param main_table (table)
--- @return (table)
function M.reorganize_indices(main_table)
  return table.move(main_table, 1, #main_table, 1, {})
end


--- Extraer el valor e índice de un registro
function M.extract_value_and_index(records, matching_key)
  for index = 1, #records do
    local record = records[index]
    local key = next(record)  -- Obtiene la primera y única clave
    if key == matching_key then
      return record[key], index
    end
  end
end


--- Mapear la extension del archivo → prefijo/sufijo
local COMMENT_PATTERNS = {
  lua  = { "-- ", "" },
  nim  = { "# ",  "" },
  md   = { "<!-- ", " -->" },
  html = { "<!-- ", " -->" },
  js   = { "/* ", " */" },
  jsx  = { "/* ", " */" },
  ts   = { "/* ", " */" },
  tsx  = { "/* ", " */" },
  css  = { "/* ", " */" },
  go   = { "/* ", " */" },
}

--- Añadir un comentario al inicio del buffer
--- @param token (string) ID para el archivo
function M.add_text_to_buffer(token)
  local extension = vim.fn.expand("%:e") -- Capturar la extension del archivo
  local pattern = COMMENT_PATTERNS[extension]
  if not pattern then return end

  -- Insertar texto y actualizar cursor
  local line = pattern[1] .. token .. pattern[2]
  local buf = vim.api.nvim_get_current_buf()
  vim.api.nvim_buf_set_lines(buf, 0, 0, false, {line})
  vim.api.nvim_win_set_cursor(0, {1, 0})
end


--- Verificar si un archivo/directorio existe
--- @param p (string) Ruta
local function exists(p)
  return uv.fs_stat(p) ~= nil
end


--- Crear un directorio (755) si no existe.
--- @param path (string)
function M.create_dir(path)
  if exists(path) then
    return M.notify("warn", "The directory already exists '%s'", path)
  end

  local dir, err = uv.fs_mkdir(path, 0x1ED) -- 0755
  if dir then
    return M.notify("info", "Directory created '%s'", path)
  end
  M.notify("error", "Could not create the directory '%s': %s", path, err)
end


--- Crea un archivo vacío si no existe.
--- @param path (string)
function M.create_file(path)
  if exists(path) then
    return M.notify("warn", "The file already exists '%s'", path)
  end

  local file, err = io.open(path, "w")
  if file then
    file:close()
    return M.notify("info", "File created '%s'", path)
  end
  M.notify("error", "Could not create the file '%s': %s", path, err)
end

return M
