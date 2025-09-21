local M = {}
local utils = require("Linkref.utils")

--- Encontrar todas las coincidencias con sus posiciones
--- @param pattern (string) Patron a buscar
--- @return (number)
--- @return (table)
function M.find_in_line(pattern)
  local row, col = unpack(vim.api.nvim_win_get_cursor(0))
  local line = vim.api.nvim_buf_get_lines(0, row - 1, row, false)[1] or ""
  local matches = {}
  local start_idx = 1

  while true do
    local start_pos, end_pos, captured = line:find(pattern, start_idx)
    if not start_pos then
      break
    end
    table.insert(matches, {start_pos = start_pos, end_pos = end_pos, text = captured})
    -- Continuar después de esta coincidencia
    start_idx = end_pos + 1
  end
  return col + 1, matches
end


--- Capturar el texto que contiene el ID
--- @param pattern (string) Patron regex a buscar
--- @param limit? (number) Buscar N coincidencias
--- @return (table)
function M.capture_id(pattern, limit)
  local ids, count = {}, 0
  -- Obtener el buffer actual y todas sus lineas
  for _, line in ipairs(vim.api.nvim_buf_get_lines(0, 0, -1, false)) do
    for id in line:gmatch(pattern) do
      ids[#ids + 1] = id
      if only and limit == count then
        return { id }
      end
      count = count + 1
    end
  end
  return ids
end


--- Comparar el texto capturado con los archivos en `nvim/Linkref`
--- @return (string|nil)
function M.verify_file(pattern)
  local id = M.capture_id(pattern, 1)[1]
  if not id then
    return utils.notify("error", "'linkref: TOKEN' does not exist in the file")
  end

  -- Existe el archivo
  local dir = vim.fs.joinpath(vim.fn.stdpath('data'), 'Linkref')
  local file = vim.fs.joinpath(dir, id .. ".json")
  return vim.uv.fs_stat(file) and file or utils.notify("error", "ID '%s' does not exist in '%s'", id, dir)
end

return M
