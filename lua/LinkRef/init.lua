local M = {}
local config = require('LinkRef.config')
local utils = require('LinkRef.utils')
local id = require('LinkRef.id_generator')
local url = require("LinkRef.url_manager")
local json = require("LinkRef.json_manager")
local checker = require('LinkRef.id_checker')
local tops = require("LinkRef.select_text")
local notify = require("LinkRef.notify")

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
        vim.keymap.set('v', '<leader>xl', ":lua require('LinkRef').add_link_reference()<CR>", opts)
        vim.keymap.set('v', '<leader>xg', ":lua require('LinkRef').go_link_reference()<CR>", opts)
        vim.keymap.set('v', '<leader>xs', ":lua require('LinkRef').show_hidden_link()<CR>", opts)
      end,
    })
  end
end


-- Mostrar el enlace oculto
function M.show_hidden_link()
  local filePath = checker.verify_file_match()
  if not filePath then
    return
  end

  -- Capturar el ID y extraer su valor
  local posText, selectText = tops.capture_visual_selection()
  local existingData = json.read_json_file(filePath) or {}
  selectText[1], index = utils.extract_value_and_index(existingData, selectText[1])

  -- Actualizar el registro Json
  utils.remove_subtable(existingData, index)
  existingData = utils.reorganize_indices(existingData)
  json.write_json_file(filePath, existingData)

  -- Sutituir el ID por el valor
  tops.change_text(posText, selectText)
end


-- Añadir un ID
function M.add_link_reference()
  local filePath = checker.verify_file_match()
  if not filePath then
    return
  end

  -- Cargar datos existentes y preparar estructura de IDs
  local existingData = json.read_json_file(filePath) or {}
  local idLength = math.max(config.options.id_length, 2)  -- Mínimo 2 caracteres
  local alphabet = config.options.custom_alphabet
  local maxAttempts = 100

  -- Preprocesar IDs existentes para búsquedas rápidas
  local existingIDs = {}
  for _, record in ipairs(existingData) do
    local idx = next(record) -- Cada registro solo tiene una clave
    existingIDs[idx] = true
  end

  -- Generador de ID
  local function generate_unique_id()
    local attempts = 0
    local idRef
    repeat
      attempts = attempts + 1
      if attempts > maxAttempts then
        notify.error("No se pudo generar un ID único después de " .. maxAttempts .. " intentos.")
      end
      idRef = "L-" .. id.nanoid(idLength, alphabet)
    until not existingIDs[idRef]

    -- Prevenir colisiones en esta sesión
    existingIDs[idRef] = true
    return idRef
  end

  -- Operaciones de escritura
  local take_id = generate_unique_id()
  local posText, selectText = tops.capture_visual_selection()
  table.insert(existingData, { [take_id] = selectText[1] })
  json.write_json_file(filePath, existingData)

  -- Actualización de texto
  selectText[1] = take_id
  tops.change_text(posText, selectText)
end


-- Abrir el link con el navegador
function M.go_link_reference()
  local filePath = checker.verify_file_match()
  if not filePath then
    return
  end

  -- Capturar el ID
  local _, selectText = tops.capture_visual_selection()
  local existingData = json.read_json_file(filePath) or {}
  local link, _ = utils.extract_value_and_index(existingData, selectText[1])
  url.open_in_browser(link)
end


-- Inicializar un registro de IDs
function M.initial_config()
  local captured_id = checker.capture_id()

  -- Si el doc. no tiene un ID token
  if not captured_id then
    local id_token = id.nanoid(21)
    local id_generated = "R-" .. id_token
    local dir_path = string.format("%s/LinkRef/", vim.fn.stdpath('data'))
    local file_path = string.format("%s%s.json", dir_path, id_token)

    -- Crea los elementos correspondientes y añade el token al inicio del doc.
    utils.create_dir_if_missing(dir_path)
    utils.create_file_if_missing(file_path)
    utils.add_text_to_buffer(id_generated)
    notify.info("[LinkRef] Token de referencia creado con éxito.")
  else
    notify.warn("[LinkRef] La referencia R-" .. captured_id .. " ya existe.")
  end
end

return M
