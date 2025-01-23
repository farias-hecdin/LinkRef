local M = {}
local config = require('LinkRef.config')
local utils = require('LinkRef.utils')
local id = require('LinkRef.id_generator')
local url = require("LinkRef.url_manager")
local json = require("LinkRef.json_manager")
local checker = require('LinkRef.id_checker')
local tops = require("LinkRef.select_text")
local Log = require('vendor.log').info


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
      end,
    })
  end
end


local function verify_file_match()
  -- Capturar el texto precedido por "R-XXX"
  local captured_id = checker.capture_id()
  if not captured_id then
    error("No se encontró texto precedido por 'R-'.")
  end
  -- Encontrar coincidencia
  return checker.compare_with_files(captured_id)
end

function M.add_link_reference()
  local filePath = verify_file_match()
  if not filePath then
    return
  end

  local idLength = math.max(config.options.id_size, 2) -- Garantiza un tamaño mínimo de 2 caracteres para el ID
  local idRef = "L-" .. id.nanoid(idLength)

  local posText, selectText = tops.capture_visual_selection()
  local existingData = json.read_json_file(filePath) or {}

  -- Actualiza el archivo JSON con los nuevos datos
  table.insert(existingData, { [idRef] = selectText[1] })
  json.write_json_file(filePath, existingData)
  -- Reemplaza el texto del cursor con el nuevo ID
  selectText[1] = idRef
  tops.change_text(posText, selectText)
end


-- Definir la función en Lua
local function add_text_to_buffer(token)
  local text = "<!- " .. token .. " -->"
  -- Obtener el buffer actual
  local buf = vim.api.nvim_get_current_buf()
  -- Insertar el texto en la primera línea
  vim.api.nvim_buf_set_lines(buf, 0, 0, false, {text})
  -- Mover el cursor a la primera línea
  vim.api.nvim_win_set_cursor(0, {1, 0})
end


function M.go_link_reference()
  local filePath = verify_file_match()
  if not filePath then
    return
  end

  local _, selectIdRef = tops.capture_visual_selection()
  local existingData = json.read_json_file(filePath) or {}

  local found = false
  for _, dataRef in ipairs(existingData) do
    for key, link in pairs(dataRef) do
      if key == selectIdRef[1] then
        found = true
        url.open_in_browser(link)
        break
      end
    end

    if found then
      break
    end
  end
end


function M.initial_config()
  local captured_id = checker.capture_id()

  if not captured_id then
    local id_token = id.nanoid(21)
    local id_generated = "R-" .. id_token
    local dir_path = vim.fn.stdpath('data') .. "/LinkRef/"
    local file_path = dir_path .. id_token .. ".json"

    utils.create_dir_if_missing(dir_path)
    utils.create_file_if_missing(file_path)
    add_text_to_buffer(id_generated)
    print("[LinkRef] Token de referencia creado con éxito.")
  else
    print("[LinkRef] La referencia R-" .. captured_id .. " ya existe.")
  end
end


return M
