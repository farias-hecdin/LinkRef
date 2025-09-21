local M = {}
local json_ = require("vendor.json_lua.json")
local utils = require("Linkref.utils")

--- Leer un archivo JSON
--- @param fpath (string) ruta del archivo json
--- @return (table|nil)
function M.read_json(fpath)
  local f = io.open(fpath, "r")
  if not f then
    return utils.notify("error", "Could not open the file '%s'", fpath)
  end
  local content = f:read("*all")
  f:close()
  if not content or content:match("^%s*$") then
    return nil
  end
  return json_.decode(content)
end


--- Escribir en un archivo JSON
--- @param fpath (string) ruta del archivo json
--- @return (table|nil)
function M.write_json(fpath, data)
  local f = io.open(fpath, "w")
  if not f then
    return utils.notify("error", "Could not open the file '%s'", fpath)
  end
  f:write(json_.encode(data))
  f:close()
end

return M
