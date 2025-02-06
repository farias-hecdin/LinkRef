local M = {}

function M.warn(msg, hidden, name)
  if not hidden then
    vim.notify("[LinkRef] " .. msg, vim.log.levels.WARN, {title = name})
  end
end


function M.error(msg, hidden, name)
  if not hidden then
    vim.notify("[LinkRef] " .. msg, vim.log.levels.ERROR, {title = name})
  end
end


function M.info(msg, hidden, name)
  if not hidden then
    vim.notify("[LinkRef] " .. msg, vim.log.levels.INFO, {title = name})
  end
end

return M
