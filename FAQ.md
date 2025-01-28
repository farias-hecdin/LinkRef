<!-- toc omit heading -->
# FAQ

- [¿Cómo funciona?](#cmo-funciona)
- [¿Qué hace cada atajo de teclado?](#qu-hace-cada-atajo-de-teclado)

## ¿Cómo funciona?

Aquí te explicamos paso a paso cómo LinkRef organiza y almacena tus enlaces localmente:

**1. Configuración inicial:**

* Primero utiliza el atajo de teclado `<leader>xn` y LinkRef revisara si ya tienes una carpeta llamada `LinkRef/` en la ruta `~/.local/share/nvim/`. Si no existe, la creara. Esta carpeta será la que contendra todos los archivos relacionados con los enlaces.
* Dentro de la carpeta `LinkRef/`, se crea un nuevo archivo que será el contenedor de los enlaces de tu archivo Markdown. Este archivo se asocia a tu archivo Markdown mediante un ID que se creara al usar el atajo de teclado anterior por primera vez. Este ID tiene un aspecto similar a `<!-- R-iKeKKmCAwAoIW6yoa4U6I -->`.

**2. Acortando un enlace:**

* Coloca el cursor sobre el enlace que quieres acortar en tu archivo Markdown.
* Ejecuta el atajo de teclado `<leader>xl`.
* LinkRef hará lo siguiente:
    * Reemplazará el enlace en tu Markdown por un ID corto y único (ej: `L-W3u`).
    * Abrirá el archivo contenedor de enlaces correspondiente a tu Markdown.
    * Guardará el enlace original junto con el ID corto en ese archivo. El archivo contenedor tendrá la siguiente forma:

    ```json
    [
      {"ID_1": "ENLACE_ORIGINAL_1"},
      {"ID_2": "ENLACE_ORIGINAL_2"}
    ]
    ```
    * Finalmente, te mostrará un mensaje para confirmar que el enlace se ha acortado correctamente.

## ¿Qué hace cada atajo de teclado?

1. **Modo NORMAL**
    * `<leader>xn`: Crea una instancia para LinkRef.
    * `<leader>xa`: Analiza el buffer actual para buscar todos los IDs obsoletos.
2. **Modo VISUAL**
    * `<leader>xl`: Añade un nuevo ID al enlace seleccionado.
    * `<leader>xg`: Abre el enlace previamente oculto en un ID y lo abre en el navegador.
    * `<leader>xs`: Remueve el ID y retorna el enlace original.

