local M = {}

local function has_text(value)
  return type(value) == "string" and value:find("%S") ~= nil
end

local function has_lines(lines)
  for _, line in ipairs(lines or {}) do
    if has_text(line) then
      return true
    end
  end

  return false
end

local function base_filetype(filetype)
  if not has_text(filetype) then
    return ""
  end

  return filetype:match("^[^%.]+") or filetype
end

local function default_format_markdown(documentation)
  if type(documentation) ~= "string" and type(documentation) ~= "table" then
    return {}
  end

  return require("noice.lsp.format").format_markdown(documentation)
end

local function append_detail(lines, detail, filetype)
  if not has_text(detail) then
    return lines
  end

  local text = table.concat(lines, "\n")

  if text:find(detail, 1, true) then
    return lines
  end

  local detail_lines = vim.split(
    ("```%s\n%s\n```"):format(base_filetype(filetype), vim.trim(detail)),
    "\n",
    { plain = true }
  )

  if #lines > 0 then
    table.insert(detail_lines, "")
    vim.list_extend(detail_lines, lines)
  end

  return detail_lines
end

function M.has_text(value)
  return has_text(value)
end

function M.has_lines(lines)
  return has_lines(lines)
end

function M.build_lines(opts)
  opts = opts or {}

  local format_markdown = opts.format_markdown or default_format_markdown
  local documentation = opts.documentation
  local lines = {}

  if type(documentation) == "string" or type(documentation) == "table" then
    lines = format_markdown(documentation)
  end

  return append_detail(lines, opts.detail, opts.filetype)
end

function M.buffer_has_content(bufnr)
  if not vim.api.nvim_buf_is_valid(bufnr) then
    return false
  end

  return has_lines(vim.api.nvim_buf_get_lines(bufnr, 0, -1, false))
end

function M.render(bufnr, lines, opts)
  opts = opts or {}

  local noice_config = require("noice.config")
  local namespace = opts.namespace or noice_config.ns
  local text = table.concat(lines, "\n")
  local message = require("noice.message")("lsp")
  local markdown = require("noice.text.markdown")

  vim.api.nvim_buf_clear_namespace(bufnr, namespace, 0, -1)
  markdown.format(message, text, { ft = opts.filetype })
  message:render(bufnr, namespace)
  markdown.keys(bufnr)
end

return M
