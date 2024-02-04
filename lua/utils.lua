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

function M.yesNoPrompt(question)
  local answer = vim.fn.input(question .. ' (y/n): ')
  return answer:lower() == 'y'
end

return M
