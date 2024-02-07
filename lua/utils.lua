-- ~/.config/nvim/lua/execute_commands/init.lua

local M = {}

-- checks if other buffers are open
function M.hasOtherOpenBuffers()
  local bufinfo = vim.fn.getbufinfo()
  local currentBufNr = vim.fn.bufnr('%')

  for _, buf in ipairs(bufinfo) do
      if buf.bufnr ~= currentBufNr and vim.fn.bufwinnr(buf.bufnr) ~= -1 then
          return true  -- Found at least one other open buffer
      end
  end

  return false  -- No other open buffers found
end

function M.isOpenBufferATerminal() -- broken
  local current_buffer = vim.api.nvim_get_current_buf()
  local buffer_name = vim.api.nvim_buf_get_name(current_buffer)
  return buffer_name == 'term://.'
end

function M.yesNoPrompt(question)
  local answer = vim.fn.input(question .. ' (y/n): ')
  return answer:lower() == 'y'
end

function isCurlAvailable()
  return vim.fn.executable('curl') == 1
end

-- WIP
function M.saveUnsavedFilesInDirectory(directory)
  -- check all buffers in the current directory
  for _, buf in ipairs(vim.api.nvim_list_bufs()) do
    if vim.api.nvim_buf_get_option(buf, 'modified') then
      -- check if the buffer contains the current directory
      if(string.find(getBufferDirectory(buf), vim.fn.expand(directory))) then
        -- save the buffer
        vim.api.nvim_buf_call(buf, function()
          vim.cmd(':w')
        end)
      end
    end
  end
end

function getBufferDirectory(buf)
  -- Get the full path of the buffer's file
  local buffer_path = vim.fn.expand(vim.api.nvim_buf_get_name(buf))
  print(buffer_path.lower() .. ' & ' .. vim.fn.expand('~/swerve2024/').lower())
  return buffer_path
end

return M
