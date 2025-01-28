> Translate this file into your native language using `Google Translate` or a [similar service](https://immersivetranslate.com).

# LinkRef

LinkRef es una pequeña utilidad para Neovim que te permite reemplazar enlaces largos en tus archivos Markdown por ID cortos, mientras que los enlaces originales se almacenan localmente de forma organizada en archivos separados. Esto hace que tus archivos Markdown sean más fáciles de leer y editar.

## 🗒️ Requerimientos

* [`Neovim`](https://github.com/neovim/neovim): Versión 0.7 o superior.

### Instalación

Usando [`folke/lazy.nvim`](https://github.com/folke/lazy.nvim):

```lua
{
    "farias-hecdin/LinkRef",
    ft = "markdown",
    config = true
    -- If you want to configure some options, replace the previous line with:
    -- config = function()
    -- end
},
```

## 🗒️ Configuración

Estas son las opciones de configuración predeterminadas:

```lua
{
  id_length = 3, -- <int> Longitud del ID.
  custom_alphabet = nil, -- <string> Caracteres validos para el ID (ej: 0123abc...).
  disable_keymaps = false, -- <boolean> Indicates whether keymaps are disabled.
}
```

### Atajos de teclado

Estos son los atajos de teclado predeterminados:

```lua
local opts = {buffer = 0, silent = true}

vim.keymap.set('n', '<leader>xn', ":lua require('LinkRef').initial_config()<CR>", opts)
vim.keymap.set('n', '<leader>xa', ":lua require('LinkRef').analyze_buffer()<CR>", opts)
vim.keymap.set('v', '<leader>xl', ":lua require('LinkRef').add_link_reference()<CR>", opts)
vim.keymap.set('v', '<leader>xg', ":lua require('LinkRef').go_link_reference()<CR>", opts)
vim.keymap.set('v', '<leader>xs', ":lua require('LinkRef').show_hidden_link()<CR>", opts)
```

Para más información, visite [FAQ](FAQ.md)

## 🗒️ Agradecimientos a

* [`rxi/json.lua`](https://github.com/rxi/json.lua): Una biblioteca JSON para Lua.

## 🛡️ Licencia

LinkRef está bajo la licencia MIT. Consulta el archivo `LICENSE` para obtener más información.
