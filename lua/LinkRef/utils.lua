local M = {}

-- Función para verificar si un archivo o directorio existe
local function exists(path)
    local stat = vim.loop.fs_stat(path)
    return stat ~= nil
end

-- Función para crear un directorio si no existe
function M.create_dir_if_missing(path)
    if not exists(path) then
        vim.loop.fs_mkdir(path, 493) -- 493 es el permiso 0755 en octal
        print("Directorio creado: " .. path)
    else
        print("El directorio ya existe: " .. path)
    end
end

-- Función para crear un archivo si no existe
function M.create_file_if_missing(path)
    if not exists(path) then
        local file = io.open(path, "w")
        if file then
            file:close()
            print("Archivo creado: " .. path)
        else
            print("Error al crear el archivo: " .. path)
        end
    else
        print("El archivo ya existe: " .. path)
    end
end

return M
