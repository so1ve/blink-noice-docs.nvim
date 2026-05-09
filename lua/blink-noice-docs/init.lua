local renderer = require("blink-noice-docs.renderer")

local M = {}

local defaults = {
  close_empty = true,
  override_draw = true,
  patch_show_item = true,
}

M.config = vim.deepcopy(defaults)

local function context_filetype(context)
  local bufnr = context and context.bufnr

  if type(bufnr) == "number" and vim.api.nvim_buf_is_valid(bufnr) then
    return vim.bo[bufnr].filetype
  end

  return vim.bo.filetype
end

local function notify_error(message)
  vim.notify(message, vim.log.levels.ERROR, { title = "blink-noice-docs.nvim" })
end

function M.draw(opts)
  local item = opts.item
  local filetype = context_filetype(opts.context)
  local lines = renderer.build_lines({
    documentation = item.documentation,
    detail = item.detail,
    filetype = filetype,
  })

  if not renderer.has_lines(lines) then
    if M.config.close_empty and opts.window and opts.window.close then
      opts.window:close()
    end

    return
  end

  local bufnr = opts.window:get_buf()

  vim.api.nvim_set_option_value("modifiable", true, { buf = bufnr })
  vim.api.nvim_buf_set_lines(bufnr, 0, -1, false, {})
  renderer.render(bufnr, lines, { filetype = filetype })
  vim.api.nvim_set_option_value("modifiable", false, { buf = bufnr })
  vim.api.nvim_set_option_value("modified", false, { buf = bufnr })
end

function M.patch_show_item()
  local ok_docs, docs = pcall(require, "blink.cmp.completion.windows.documentation")

  if not ok_docs then
    notify_error("blink.cmp documentation window module is not available")

    return false
  end

  if docs._blink_noice_docs_patched then
    return true
  end

  local ok_config, blink_config = pcall(require, "blink.cmp.config")
  local ok_sources, sources = pcall(require, "blink.cmp.sources.lib")
  local ok_menu, menu = pcall(require, "blink.cmp.completion.windows.menu")

  if not (ok_config and ok_sources and ok_menu) then
    notify_error("blink.cmp internals are not available; call setup() after blink.cmp is loaded")

    return false
  end

  docs._blink_noice_docs_patched = true

  local config = blink_config.completion.documentation

  if M.config.override_draw then
    config.draw = M.draw
  end

  function docs.show_item(context, item)
    docs.auto_show_timer:stop()
    if item == nil or not menu.win:is_open() then
      return docs.win:close()
    end

    sources
      .resolve(context, item)
      :map(function(resolved)
        local valid_documentation = type(resolved.documentation) == "table" or type(resolved.documentation) == "string"
        local valid_detail = type(resolved.detail) == "string"

        if not valid_documentation and not valid_detail then
          docs.close()

          return
        end

        if docs.shown_item ~= resolved then
          local docs_buf = docs.win:get_buf()
          local default_impl = function(draw_opts)
            M.draw(vim.tbl_extend("force", {
              context = context,
              item = resolved,
              window = docs.win,
              config = config,
            }, draw_opts or {}))
          end
          local draw = type(resolved.documentation) == "table" and resolved.documentation.draw or config.draw

          vim.api.nvim_set_option_value("modifiable", true, { buf = docs_buf })
          draw({
            item = resolved,
            context = context,
            window = docs.win,
            config = config,
            default_implementation = default_impl,
          })
          vim.api.nvim_set_option_value("modifiable", false, { buf = docs_buf })

          if M.config.close_empty and not renderer.buffer_has_content(docs_buf) then
            docs.close()

            return
          end
        end

        docs.shown_item = resolved

        if menu.win:get_win() then
          docs.win:open()
          docs.win:set_cursor({ 1, 0 })
          docs.update_position()
        end
      end)
      :catch(function(err)
        notify_error(err)
      end)
  end

  return true
end

function M.setup(opts)
  M.config = vim.tbl_deep_extend("force", vim.deepcopy(defaults), opts or {})

  if M.config.patch_show_item then
    M.patch_show_item()
  end

  return M
end

return M
