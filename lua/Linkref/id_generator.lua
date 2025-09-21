local M = {}
local utils = require("Linkref.utils")

math.randomseed(os.time())

local bitand = bit32 and bit32.band or function(a, b)
  local result = 0
  local bitval = 1
  while a > 0 and b > 0 do
    if a % 2 == 1 and b % 2 == 1 then
      result = result + bitval
    end
    bitval = bitval * 2
    a = math.floor(a / 2)
    b = math.floor(b / 2)
  end
  return result
end

--- Generar un ID aleatorio
--- @param id_len (number) Longitud del ID
--- @param custom? (string) Alfabeto personalizado
--- @return (string)
M.nanoid = function(id_len, custom)
  id_len = id_len or 21
  local alphabet = custom or ("0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ" .. "$@:;~*=¿#&!><+-^¡")
  local alphabet_length = #alphabet
  local id = {}

  for i = 1, id_len do
    local byte = math.random(255)
    local index = bitand(byte, 63) % alphabet_length + 1
    id[i] = alphabet:sub(index, index)
  end

  return table.concat(id)
end


--- Generar un ID unico
--- @param data (table) Lista de IDs en JSON
--- @param alphabet (string|nil) Alfabeto personalizado
--- @param id_len (number) Longitud del ID
--- @param prefix (string) Añadir un prefijo al ID
--- @return (string|nil)
function M.generate_unique_id(data, alphabet, id_len, prefix)
  -- Build a fast-lookup set of already-used IDs
  local used = {}
  for _, record in ipairs(data) do
    local key = next(record)  -- Assume each record is a table with exactly one key
    if key then used[key] = true end
  end

  -- Try to create a new ID that is not in `used`
  for _ = 1, 20 do
    local new_id = (prefix or "") .. M.nanoid(id_len, alphabet)
    if not used[new_id] then
      used[new_id] = true  -- Mark as used for this session
      return new_id
    end
  end
  return utils.notify("warn", "Failed to generate a unique ID after 20 attempts")
end

return M
