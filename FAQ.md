# FAQ

## ¿Cómo funciona?

Aquí te explicamos paso a paso cómo LinkRef organiza y almacena tus enlaces localmente:

**1. Configuración inicial:**

* Primero utiliza el comando `LinkRefInit` o el atajo `<leader>xn` y LinkRef revisara si ya tienes una carpeta llamada `LinkRef/` en la ruta `~/.local/share/nvim/`. Si no existe, la creara. Esta carpeta será la que contendra todos los archivos relacionados con los enlaces.
* Dentro de la carpeta `LinkRef/`, se crea un nuevo archivo que será el contenedor de los enlaces de tu archivo Markdown. Este archivo se asocia a tu archivo Markdown mediante un ID que se creara al usar `LinkRefInit` por primera vez. Este ID tiene un aspecto similar a `<!-- R-iKeKKmCAwAoIW6yoa4U6I -->`.

**2. Acortando un enlace:**

* Coloca el cursor sobre el enlace que quieres acortar en tu archivo Markdown.
* Ejecuta el comando de LinkRef (el comando específico dependerá de cómo lo hayas configurado).
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

