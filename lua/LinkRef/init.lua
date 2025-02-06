local M = {}
local config = require('LinkRef.config')
local utils = require('LinkRef.utils')
local id = require('LinkRef.id_generator')
local url = require("LinkRef.url_manager")
local json = require("LinkRef.json_manager")
local checker = require('LinkRef.id_checker')
local tops = require("LinkRef.select_text")
local notify = require("LinkRef.notify")
local Log = require("vendor.log").info
local fn = vim.fn

M.setup = function(options)
  -- Merge the user-provided options with the default options
  config.options = vim.tbl_deep_extend("keep", options or {}, config.options)

  -- Enable keymap if they are not disableds
  if not config.options.disable_keymaps then
    local opts = {buffer = 0, silent = true}
    vim.api.nvim_create_autocmd('FileType', {
      desc = 'LinkRef keymaps',
      callback = function()
        vim.keymap.set('n', '<leader>xn', ":lua require('LinkRef').initial_config()<CR>", opts)
        vim.keymap.set('n', '<leader>xa', ":lua require('LinkRef').analyze_buffer()<CR>", opts)
        vim.keymap.set('v', '<leader>xl', ":lua require('LinkRef').add_link()<CR>", opts)
        vim.keymap.set('v', '<leader>xg', ":lua require('LinkRef').go_link()<CR>", opts)
        vim.keymap.set('v', '<leader>xs', ":lua require('LinkRef').show_link()<CR>", opts)
      end,
    })
  end
end


--- User commands
vim.api.nvim_create_user_command("LinkRefInit", function(args)
  if #args.fargs == 1 then
    M.initial_config(args.fargs[1])
    return
  end
  M.initial_config()
end, {desc = "Inicializar configuración", nargs = "*"})


--- Analizar buffer
function M.analyze_buffer()
  local file_path = checker.verify_file_match()
  if not file_path then
    return
  end

  local id_length = config.options.id_length
  local captured_ids = checker.capture_pattern("L", id_length, true, true) or {}
  local records = json.read_json_file(file_path) or {}

  if #records == 0 then
    return
  end

  -- Crear conjunto para búsquedas O(1)
  local id_set = {}
  for _, id in ipairs(captured_ids) do
    id_set[id] = true
  end

  -- Colectar índices y claves a eliminar
  local indices_delete = {}
  local keys_delete = {}

  for index = 1, #records do
    local record = records[index]
    local key = next(record)
    if not id_set[key] then
      table.insert(indices_delete, index)
      table.insert(keys_delete, key)
    end
  end

  if #indices_delete > 0 then
    -- Eliminar en orden inverso para mantener índices válidos
    table.sort(indices_delete, function(a, b) return a > b end)
    for _, index in ipairs(indices_delete) do
      utils.remove_subtable(records, index)
    end

    -- Reorganizar y guardar una sola vez
    records = utils.reorganize_indices(records)
    json.write_json_file(file_path, records)
    notify.info("Se eliminó " .. #indices_delete .. " IDs obsoletos.")
  else
    notify.info("No hay IDs obsoletos para eliminar.")
  end
end


--- Mostrar el enlace oculto
function M.show_link()
  local file_path = checker.verify_file_match()
  if not file_path then
    return
  end

  -- Capturar el ID y extraer su valor
  local pos_text, select_text = tops.capture_visual_selection()
  local id_length = config.options.id_length + 2
  if #select_text[1] > id_length then
    notify.warn("ID inválido. La longitud proporcionada es mayor a la permitida: " .. id_text_length)
    return
  end

  -- Actualizar el registro Json
  local existing_data = json.read_json_file(file_path) or {}
  select_text[1], _ = utils.extract_value_and_index(existing_data, select_text[1])

  -- Sustituir el ID por el valor
  tops.change_text(pos_text, select_text)
end


--- Añadir un ID
function M.add_link()
  local file_path = checker.verify_file_match()
  if not file_path then
    return
  end

  -- Cargar datos existentes y preparar estructura de IDs
  local existing_data = json.read_json_file(file_path) or {}
  local id_length = math.max(config.options.id_length, 2)  -- Mínimo 2 caracteres
  local alphabet = config.options.custom_alphabet
  local max_attempts = 50

  -- Preprocesar IDs existentes para búsquedas rápidas
  local existing_ids = {}
  for _, record in ipairs(existing_data) do
    local idx = next(record) -- Si cada registro solo tiene una clave
    existing_ids[idx] = true
  end


  -- Generador de IDs
  local function generate_unique_id()
    local attempts = 0
    local id_ref

    repeat
      attempts = attempts + 1
      if attempts > max_attempts then
        notify.error("No se pudo generar un ID único después de " .. max_attempts .. " intentos.")
        return nil
      end
      id_ref = "L-" .. id.nanoid(id_length, alphabet)
    until not existing_ids[id_ref]

    -- Prevenir colisiones en esta sesión
    existing_ids[id_ref] = true
    return id_ref
  end


  -- Operaciones de escritura
  local new_id = generate_unique_id()
  if new_id == nil then
    return
  end

  local pos_text, select_text = tops.capture_visual_selection()
  table.insert(existing_data, {[new_id] = select_text[1]})
  json.write_json_file(file_path, existing_data)

  -- Actualizar el texto
  select_text[1] = new_id
  tops.change_text(pos_text, select_text)
end


--- Abrir el link con el navegador
function M.go_link()
  local file_path = checker.verify_file_match()
  if not file_path then
    return
  end

  -- Obtener el link y abrirlo en el navegador
  local _, select_text = tops.capture_visual_selection()
  local existing_data = json.read_json_file(file_path) or {}
  local link, _ = utils.extract_value_and_index(existing_data, select_text[1])
  url.open_in_browser(link)
end


--- Configura el sistema de referencias de documentos
function M.initial_config(path)
  local document_path = path or false
  local document_id = checker.capture_id()
  local links_dir = vim.fs.joinpath(fn.stdpath("data"), "LinkRef")

  -- Crear directorio principal y archivo enrutador
  utils.ensure_directory_exists(links_dir)
  local router_file = vim.fs.joinpath(links_dir, "g-router.json")
  utils.ensure_file_exists(router_file, true)

  -- Generar nuevo ID si no existe
  local token = nil
  if not document_id then
    token = "R-" .. id.nanoid(21)
    document_path = vim.fs.joinpath(links_dir, token .. ".json")
    local comment = "<!-- ".. token .." -->"
    vim.api.nvim_buf_set_lines(vim.api.nvim_get_current_buf(), 0, 0, false, {comment})
    vim.api.nvim_win_set_cursor(0, {1, 0})
    notify.info("Nuevo token de referencia creado: " .. token)
  else
    notify.warn("Referencia existente detectada: " .. document_id)
  end
  token = token or document_id

  -- Crear estructura si se provee ruta específica
  local router_data = json.read_json_file(router_file) or {}
  local entry = nil
  Log(links_dir)
  if not path then
    utils.ensure_file_exists(vim.fs.joinpath(links_dir, token .. ".json"))
    entry = {[token] = vim.fs.joinpath(links_dir, token)}
  else
    document_path = utils.prepare_document_path(document_path, token)
    entry = {[token] = vim.fs.joinpath(vim.fn.expand('$HOME'), document_path)}
  end

  -- Actualizar enrutador con nueva entrada
  local _, index = utils.extract_value_and_index(router_data, token)
  if index then
    router_data[index][token] = vim.fs.joinpath(vim.fn.expand('$HOME'), document_path)
  else
    table.insert(router_data, entry)
  end
  json.write_json_file(router_file, router_data)
end

return M
