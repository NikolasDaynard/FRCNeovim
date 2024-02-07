-- ~/.config/nvim/lua/execute_commands/init.lua

local M = {}

local utils = require'utils'
local utils = require'vendorDep'

function M.setup(options)
  -- Variable for the size of the opened terminal
  -- 60 works pretty good for the debug logs
  M.terminal_size = options.terminal_size or M.terminal_size or 60
  -- Variable for the size of the terminal when the build fails
  -- It can be useful to see more
  M.terminal_sizeOnFailure = options.terminal_size or 80

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
    openTerminal()
    closeTerminal(command)
  end
end
function openTerminal()
  local width = vim.fn.winwidth(0)  -- Get current window width
  if M.terminal_size < width / 2 then -- normal case
    vim.cmd('vsplit | vertical resize ' .. M.terminal_size .. ' | e term')
  else -- terminal_size is greater than half of the window width so open at half
    vim.cmd('vsplit | e term')
  end
end
function closeTerminal(command)
  -- close the terminal
  if M.autoQuitOnSuccess == true then
    local job_id = vim.fn.termopen(command, {
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
