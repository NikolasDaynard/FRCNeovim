-- ~/.config/nvim/lua/execute_commands/init.lua

local M = {}

local utils = require'utils'

function M.setup(options)
  -- Variable for the size of the opened terminal
  -- 60 works pretty good for the debug logs
  M.terminal_size = options.terminal_size or M.terminal_size or 60
  -- Directory where the robot code is located
  M.robot_directory = options.robot_directory or M.robot_directory
  -- Whether to quit the terminal on success
  M.autoQuitOnSuccess = options.autoQuitOnSuccess
  if M.autoQuitOnSuccess == nil then
    M.autoQuitOnSuccess = true
  end
  -- Whether to quit the terminal on failure NOTE: This is only used if autoQuitOnSuccess is true
  -- An error message will still be printed
  M.autoQuitOnFailure = options.autoQuitOnFailure
  if M.autoQuitOnFailure == nil then
    M.autoQuitOnFailure = false
  end
  M.printOnSuccess = options.printOnSuccess
  if M.printOnSuccess == nil then
    M.printOnSuccess = true
  end
  M.printOnFailure = options.printOnFailure
  if M.printOnFailure == nil then
    M.printOnFailure = true
  end
  M.teamNumber = options.teamNumber or M.teamNumber
  -- Java home for the robot code optional if you have the environment variable set
  M.javaHome = options.javaHome or M.javaHome
end

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


function M.deployRobotCode()
  if checkConfigs() == false then
    return
  end
  local predefined_commands = {
    'cd ' .. M.robot_directory .. ' && ./gradlew deploy -PteamNumber=' .. M.teamNumber .. ' --offline',
  }
  if M.javaHome ~= nil then
    predefined_commands[1] = predefined_commands[1] .. ' -Dorg.gradle.java.home="' .. M.javaHome .. '"'
  end
  M.runCommands(predefined_commands, vim.fn.getcwd(), vim.fn.expand('%:p')) -- expand('%:p') returns the full path of the current file
end

function M.buildRobotCode()
  if checkConfigs() == false then
    return
  end
  local predefined_commands = {
    'cd ' .. M.robot_directory .. ' && ./gradlew build',
  }
  if M.javaHome ~= nil then
    predefined_commands[1] = predefined_commands[1] .. ' -Dorg.gradle.java.home="' .. M.javaHome .. '"'
  end

  M.runCommands(predefined_commands, vim.fn.getcwd(), vim.fn.expand('%:p')) -- expand('%:p') returns the full path of the current file
end

function M.runCommands(predefined_commands, current_directory, current_file)
  for _, command in ipairs(predefined_commands) do
    print('Executing command:', command)
    -- Check if terminal_size is 0
    if M.terminal_size == 0 then
      vim.cmd('terminal ' .. command) -- open terminal and run the command and override current

      local job_id = vim.fn.jobstart(command, {
        on_exit = function(job_id, exit_code, _) -- callback function for the exit code
          if exit_code == 0 then
            -- Success and can go back to file
            if current_file ~= '' then
              vim.cmd('edit ' .. current_file) -- open the file in a new buffer
            else
              vim.cmd('Explore ' .. current_directory) -- open the directory in a new buffer
            end

          else
            if current_file ~= '' then
              vim.cmd('vsplit | edit ' .. current_file) -- open the file in a new buffer
            else
              vim.cmd('vsplit | Explore ' .. current_directory) -- open the directory in a new buffer
            end
          end
        end
      })
      vim.fn.jobwait({job_id}, 0)
    else -- terminal_size is greater than half of the window width so open at half
      openTerminal(command)
      closeTerminal(command)
    end
  end
end
function openTerminal(command)
  local width = vim.fn.winwidth(0)  -- Get current window width
  
  if M.terminal_size < width / 2 then -- normal case
    
  else -- terminal_size is greater than half of the window width so open at half
    vim.cmd('vsplit | terminal ' .. command)
  end
end
function closeTerminal(command)
  -- close the terminal
  if M.autoQuitOnSuccess == true then
    local job_id = vim.fn.jobstart("terminal " .. command, {
      on_exit = function(job_id, exit_code, _) -- callback function for the exit code
        if exit_code == 0 then -- success!
          -- check if window is terminal to avoid closing other windows
          if vim.api.nvim_buf_get_option(0, 'buftype') == 'terminal' and utils.hasOtherOpenBuffers() then
            vim.cmd(':q') -- close the terminal window
          end
          if M.printOnSuccess then
            vim.cmd('echohl Normal') -- set the color to normal
            vim.cmd('echomsg "Success"')
            vim.cmd('echohl None') -- reset the color
          end
        else
          if M.autoQuitOnFailure and vim.api.nvim_buf_get_option(0, 'buftype') == 'terminal' and utils.hasOtherOpenBuffers() then
            vim.cmd(':q') -- close the terminal window
          end
          if M.printOnFailure then
            vim.cmd('echohl Error') -- set the color to red
            vim.cmd('echomsg "Failed"')
            vim.cmd('echohl None') -- reset the color
          end
        end
      end
    })
    vim.fn.jobwait({job_id}, 0)
  end
end
function checkConfigs()
  if M.robot_directory == nil then
    print('robot_directory is not set')
    return false
  end
  if M.teamNumber == nil then
    print('teamNumber is not set')
    return false
  end
  return true
end
-- Define the commands with the predefined set of commands
vim.cmd([[command! DeployRobotCode lua require'FRCNeovim'.deployRobotCode()]])
vim.cmd([[command! BuildRobotCode lua require'FRCNeovim'.buildRobotCode()]])

vim.cmd("command! -nargs=1 AddVendorDep lua require'FRCNeovim'.addVendorDep(<f-args>)")

-- help command
vim.cmd([[command! -nargs=0 FRCNeovimHelp :help FRCNeovim]])

return M
