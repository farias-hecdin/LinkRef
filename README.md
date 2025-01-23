> Translate this file into your native language using `Google Translate` or a [similar service](https://immersivetranslate.com).

# LinkRef
LinkRef es una pequeña utilidad que te ayuda a acortar los enlaces en tus archivos Markdown dentro de Neovim, haciéndolos más limpios y manejables.

> [!IMPORTANT]
> Work in progress

Usando [`folke/lazy.nvim`](https://github.com/folke/lazy.nvim):

```lua
{
    url = "https://github.com/farias-hecdin/LinkRef.git",
    ft = "markdown",
    config = true
},

```

## Atajos de teclado

Estos son los atajos de teclado predeterminados:

```lua
vim.keymap.set('n', '<leader>xn', ":lua require('LinkRef').initial_config()<CR>", opts)
vim.keymap.set('v', '<leader>xl', ":lua require('LinkRef').add_link_reference()<CR>", opts)
vim.keymap.set('v', '<leader>xg', ":lua require('LinkRef').go_link_reference()<CR>", opts)
```
