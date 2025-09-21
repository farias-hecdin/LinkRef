--[[
  ^bTareas-pendientes:
  ^b1: Usar (*) para incrustar directorios
  ^b2: Contador total de enlace guardados/total de combinaciones
]]
local M = {}
local config = require('Linkref.config')
local utils = require('Linkref.utils')
local id = require('Linkref.id_generator')
local url = require("Linkref.url_manager")
local json = require("Linkref.json_manager")
local checker = require('Linkref.id_checker')
local tops = require("Linkref.select_text")
local clog = require("vendor.log").info

local PATTERN = "[%w%d%+%*%$%^@:;~=¿#&!><¡-]"
local PATTERN_FILE = "linkref:%s(".. PATTERN .."+)%s%("

--- Setup del plugin
M.setup = function(opts)
  -- Merge the user-provided options with the default options
  config.options = vim.tbl_deep_extend("keep", opts or {}, config.options)
  -- Enable keymap if they are not disableds
  if config.options.disable_keymaps then return end
  local kdesc = function(text) return {buffer = 0, silent = true, desc = text} end
  local kmap = vim.keymap.set
  vim.api.nvim_create_autocmd('FileType', {
    pattern = "*",
    callback = function()
      kmap('n', '<leader>xi', M.initial_config, kdesc("Initialize Linkref"))
      kmap('n', '<leader>xa', M.analyze_buffer, kdesc("Analyze identifiers"))
      kmap('n', '<leader>xg', M.match_under_cursor, kdesc("Go to identifier"))
      kmap('v', '<leader>xg', ":lua require('Linkref').go_match_selected()<CR>", kdesc("Go to identifier"))
      kmap('v', '<leader>xa', ":lua require('Linkref').add_identifier()<CR>", kdesc("Add identifier"))
      kmap('v', '<leader>xs', ":lua require('Linkref').show_content()<CR>", kdesc("Show identifier"))
    end
  })
end


--- Contar los enlaces acortados
function M.counter_ids()
  local fpath = checker.verify_file(PATTERN_FILE)
  if not fpath then return end

  local records = json.read_json(fpath) or {}
  return utils.notify("info", "%d IDs have been saved", #records)
end



--- Analizar buffer para buscar IDs obsoletos
function M.analyze_buffer()
  local fpath = checker.verify_file(PATTERN_FILE)
  if not fpath then return end

  local pattern = "%((?".. PATTERN .."+)%)"
  local ids_captured = checker.capture_id(pattern)
  local records = json.read_json(fpath) or {}
  if #records == 0 then
    return utils.notify("info", "There are no obsolete IDs to delete")
  end

  local id_set, new_records = {}, {}
  -- Crear conjunto para búsquedas O(1)
  for _, Id in ipairs(ids_captured) do
    id_set[Id] = true
  end
  -- Filtrar registros válidos en una nueva tabla
  for _, record in ipairs(records) do
    local key = next(record)
    if id_set[key] then
      table.insert(new_records, record)
    end
  end

  -- Procesar cambios si hay eliminaciones
  local deleted_count = #records - #new_records
  if deleted_count > 0 then
    json.write_json(fpath, new_records)
    return utils.notify("info", "%d obsolete IDs have been deleted", deleted_count)
  end
  return utils.notify("info", "There are no obsolete IDs to delete")
end


--- Mostrar el enlace oculto
function M.show_content()
  local fpath = checker.verify_file(PATTERN_FILE)
  if not fpath then return end

  -- Capturar texto y validar su longitud
  local range, select_text = tops.capture_visual_selection()
  local max_len = config.options.id_length + 1
  if #select_text[1] > max_len then
    return utils.notify("warn", "ID too long (max. %d)", max_len)
  end

  -- Leer el JSON y Sutituir el ID por el URL
  local data = json.read_json(fpath) or {}
  select_text[1], _ = utils.extract_value_and_index(data, select_text[1])
  tops.change_text(range, select_text)
end


--- Generar un ID único, guardalo en el JSON e insertarlo en el buffer
function M.add_identifier()
  local fpath = checker.verify_file(PATTERN_FILE)
  if not fpath then return end

  -- Cargar datos existentes y generar un ID unico
  local data = json.read_json(fpath) or {}
  local alphabet, id_len = config.options.custom_alphabet, math.max(config.options.id_length, 2) -- Mínimo 2 caracteres
  local unique_id = id.generate_unique_id(data, alphabet, id_len, "?")
  if not unique_id then return end

  local range, select_text = tops.capture_visual_selection()
  table.insert(data, {[unique_id] = select_text[1]})
  json.write_json(fpath, data)

  -- Actualizar el texto
  select_text[1] = unique_id
  tops.change_text(range, select_text)
end


--- Abrir el link con el navegador en el modo NORMAL
function M.match_under_cursor()
  local cursor_col, matches = checker.find_in_line("%((%?".. PATTERN .."+)%)")
  if #matches == 0 then
    return utils.notify("warn", "Cursor is not within any match")
  end

  for _, m in ipairs(matches) do
    -- Verificar si el cursor está dentro de esta coincidencia
    if cursor_col >= m.start_pos and cursor_col <= m.end_pos then
      M.go_match_selected(m.text)
      break
    end
  end
end


--- Abrir el link con el navegador en el modo VISUAL
--- @param captured (string) Texto capturado
function M.go_match_selected(captured)
  local fpath = checker.verify_file(PATTERN_FILE)
  if not fpath then return end

  -- Obten el link y abrelo en el navegador
  if not captured then
    local _, select_text = tops.capture_visual_selection()
    captured = select_text[1]
  end

  local data = json.read_json(fpath) or {}
  local value, _ = utils.extract_value_and_index(data, captured)
  if value:match("^https*://") then
    url.open_in_browser(value)
  elseif value:match("^content:") then
    url.open_in_browser(value)
  else
    vim.cmd((":e %s"):format(value))
  end
end


--- Generar un ID único y añadirlo al inicio del buffer si no existe
function M.initial_config()
  local has_id = checker.capture_id("linkref:%s(".. PATTERN .."+)%s%(([%w%d%*/.]+)%)", 1)[1]
  if has_id then
    return utils.notify("warn", "The reference '%s' already exists in the document", has_id)
  end

  -- Generar un nuevo ID
  local new_id = id.nanoid(5)
  local link_line = ("linkref: %s (*)"):format(new_id)

  -- Preparar ruta y crear la estructura
  --[[
  ^wProcedimiento:
  1. Si no encuentra un Tag, es "Inicializacion", sino "Update".
  2. Los pasos "x.1, x.2" se envuelve en una sola funcion
  ^bInicializacion:
  1. Usas por 1ra vez el comando :Linkref, ya que no hay Tag, se crea con un nuevo ID y un Dir.
  1.1. Si tiene un Dir. capturalo y revisa que no exista.
  1.2. Si no existe, crea el Dir. y un archivo que reciba como nombre el ID del archivo.
  ^bUpdate:
  2. Si usas el comando :Linkref, se revisa el Tag si es correcto y tiene un Dir.
  1.1. Si tiene un Dir. capturalo y revisa que no exista.
  1.2. Si no existe, crea el Dir. y un archivo que reciba como nombre el ID del archivo.
  ^bOtras_funciones:
  1. Revisar el tag si tiene un Dir.
  2. Si tiene un Dir. capturalo y revisa que no exista.
  3. Si no existe, crea una alerta acerca del Dir o el archivo.
  ]]
  local dir_path  = vim.fs.joinpath(vim.fn.stdpath("data"), "Linkref")
  local file_path = vim.fs.joinpath(dir_path, new_id .. ".json")
  utils.create_dir(dir_path)
  utils.create_file(file_path)

  -- Insertar ID en el buffer
  utils.add_text_to_buffer(link_line)
  utils.notify("info", "Reference token created successfully")
end


--- Crear commandos para Checkly
vim.api.nvim_create_user_command('LinkrefInit', M.initial_config,
  {nargs = '?', complete = 'dir', desc = 'Initialize Linkref'}
)
vim.api.nvim_create_user_command('LinkrefAnalyze', M.analyze_buffer,
  {desc = 'Analyze identifiers'}
)
vim.api.nvim_create_user_command('LinkrefGo', M.match_under_cursor,
  {desc = 'Go to identifier'}
)
vim.api.nvim_create_user_command('LinkrefCounter', M.counter_ids,
  {desc = 'Count the shortened links'}
)

return M
