local M = {}

--- Tabla de opciones por defecto
M.options = {
  id_length = 3, -- <int> Longitud del ID
  custom_alphabet = nil, -- <string> Caracteres validos para el ID (ej: 0123abc...)
  disable_keymaps = false, -- <boolean> Desativar las keymaps por defecto.
}

return M
