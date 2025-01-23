local M = {}

-- Función para abrir el enlace en el navegador
function M.open_in_browser(url)
    -- Comando para abrir el enlace en el navegador
    local command
    if vim.fn.has("unix") == 1 then
        command = "xdg-open " .. url
    elseif vim.fn.has("mac") == 1 then
        command = "open " .. url
    elseif vim.fn.has("win32") == 1 then
        command = "start " .. url
    else
        error("Sistema operativo no soportado")
    end

    -- Ejecutar el comando
    vim.cmd("!" .. command)
end

return M
