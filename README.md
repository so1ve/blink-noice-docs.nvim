# blink-noice-docs.nvim

Render [blink.cmp](https://github.com/Saghen/blink.cmp) completion documentation with [noice.nvim](https://github.com/folke/noice.nvim)'s markdown renderer.

This gives blink documentation popups the same markdown treatment as Noice LSP hover: fenced code blocks get syntax highlighting, markdown links get Noice keymaps, and LSP `detail` can be shown as a language-aware code block above the documentation.

## Why

Noice ships an override for `nvim-cmp` documentation, but blink.cmp uses its own documentation window and draw hook. This plugin bridges that gap by replacing blink's documentation draw function with a Noice-backed renderer.

It also patches blink's documentation `show_item()` flow to avoid opening empty documentation windows after rendering.

## Requirements

- Neovim 0.10+
- `Saghen/blink.cmp`
- `folke/noice.nvim`
- `MunifTanjim/nui.nvim` through Noice

## Installation

### `lazy.nvim`

```lua
{
  "so1ve/blink-noice-docs.nvim",
  dependencies = {
    "Saghen/blink.cmp",
    "folke/noice.nvim",
  },
}
```

## Usage

Call `setup()` after `blink.cmp` has been set up:

```lua
require("blink.cmp").setup({
  completion = {
    documentation = {
      auto_show = true,
    },
  },
})

require("blink-noice-docs").setup()
```

By default, `setup()`:

- sets blink's `completion.documentation.draw` to `require("blink-noice-docs").draw`
- patches blink's internal `show_item()` so async-resolved items pass source context to the renderer
- closes the documentation window when the rendered buffer is empty

If you prefer to wire the draw hook yourself:

```lua
local docs = require("blink-noice-docs")

require("blink.cmp").setup({
  completion = {
    documentation = {
      draw = docs.draw,
    },
  },
})

docs.setup({ override_draw = false })
```

## Configuration

```lua
require("blink-noice-docs").setup({
  -- Replace blink's configured documentation draw function with Noice rendering.
  override_draw = true,

  -- Patch blink's show_item() to pass source context and suppress empty popups.
  patch_show_item = true,

  -- Close the documentation window when Noice rendering produced no content.
  close_empty = true,
})
```

## API

### `draw(opts)`

Blink-compatible documentation draw function. It accepts `blink.cmp.CompletionDocumentationDrawOpts` plus an optional `context` field injected by this plugin's `show_item()` patch.

```lua
require("blink-noice-docs").draw(opts)
```

### `setup(opts?)`

Configures and patches blink documentation integration.

```lua
require("blink-noice-docs").setup({})
```

### `patch_show_item()`

Applies only the blink `show_item()` patch. Normally you should call `setup()` instead.

## Notes

This plugin intentionally uses Noice internal renderer modules:

- `noice.lsp.format.format_markdown()`
- `noice.text.markdown.format()`
- `noice.message("lsp"):render()`
- `noice.text.markdown.keys()`

Those APIs are stable in practice but are not formally public Noice API. Pin Noice if you need maximum stability.

## 📝 License

[MIT](./LICENSE). Made with ❤️ by [Ray](https://github.com/so1ve)
