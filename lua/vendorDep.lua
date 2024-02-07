local M = {}

local utils = require'utils'

function M.addVendorDep(link)
  if checkConfigs() == false then
    return
  end
  -- check last 5 characters of the link for .json
  if string.sub(link, -5) ~= ".json" then
    if not utils.yesNoPrompt("The link does not end in .json, are you sure you want to continue?") then
      return
    end
  end

  if isCurlAvailable() == false then
    vim.cmd('echohl Error') -- set the color to normal
    vim.cmd('echomsg ". Curl is not avalible"')
    vim.cmd('echohl None') -- reset the color
    return
  end

  local command = "curl -s " .. link
  local handle = io.popen(command)
  local result = handle:read("*a")
  handle:close()

  local startPos, endPos = string.find(result, 'fileName')

  if startPos == nil then
    vim.cmd('echohl Error') -- set the color to normal
    vim.cmd('echomsg ". Filename not found in the json file, it is very likely the link is bad"')
    vim.cmd('echohl None') -- reset the color
    return
  end
  local name = ''
  -- Iterate forward through the link from endPos to the end of the string
  -- 12 is the length of fileName": "
  for i = startPos + 12, #result do
    -- If it sees a quote, then break
    if string.sub(result, i, i) == '"' then
        break
    end
    -- Add character to the name
    name = name .. string.sub(result, i, i)
  end

  print(name)

  -- open the file in a new buffer
  vim.cmd('vsplit | :e ' .. M.robot_directory .. 'vendordeps/' .. name)
  -- split the result by new line and set the lines
  vim.fn.setline(1, vim.fn.split(result, "\n"))
  -- save the file and quit
  vim.cmd(':wq')
end

return M
