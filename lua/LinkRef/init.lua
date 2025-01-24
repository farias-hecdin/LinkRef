local M = {}
local config = require('LinkRef.config')
local utils = require('LinkRef.utils')
local id = require('LinkRef.id_generator')
local url = require("LinkRef.url_manager")
local json = require("LinkRef.json_manager")
local checker = require('LinkRef.id_checker')
local tops = require("LinkRef.select_text")

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


function M.show_hidden_link()
  local filePath = checker.verify_file_match()
  if not filePath then
    return
  end

  local posText, selectText = tops.capture_visual_selection()
  local existingData = json.read_json_file(filePath) or {}
  selectText[1], index = utils.search_data(existingData, selectText[1])

  utils.remove_subtable(existingData, index)
  existingData = utils.reorganize_indices(existingData)
  json.write_json_file(filePath, existingData)

  tops.change_text(posText, selectText)
end


function M.add_link_reference(content, length)
  local filePath = checker.verify_file_match() or path
  if not filePath then
    return
  end

  local existingData = json.read_json_file(filePath) or content or {}
  local idLength = math.max(config.options.id_size, 2) or length -- Garantiza un tamaño mínimo de 2 caracteres para el ID
  local idRef = "L-" .. id.nanoid(idLength)

  if checker.compare_with_ids(existingData, idRef) then
    print("[LinkRef] ID " .. idRef .. " encontrado, generando uno nuevo.")
    M.add_link_reference(existingData, idLength)
  end

  local posText, selectText = tops.capture_visual_selection()
  -- Actualiza el archivo JSON con los nuevos datos
  table.insert(existingData, { [idRef] = selectText[1] })
  json.write_json_file(filePath, existingData)
  -- Reemplaza el texto del cursor con el nuevo ID
  selectText[1] = idRef
  tops.change_text(posText, selectText)
end


function M.go_link_reference()
  local filePath = verify_file_match()
  if not filePath then
    return
  end

  local _, selectText = tops.capture_visual_selection() -- ref
  local existingData = json.read_json_file(filePath) or {}
  local link = utils.search_data(existingData, selectText[1])
  url.open_in_browser(link)
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
    utils.add_text_to_buffer(id_generated)
    print("[LinkRef] Token de referencia creado con éxito.")
  else
    print("[LinkRef] La referencia R-" .. captured_id .. " ya existe.")
  end
end

return M
