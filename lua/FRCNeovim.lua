-- ~/.config/nvim/lua/execute_commands/init.lua

local M = {}

function M.setup(options)
  -- Variable for the size of the opened terminal
  -- 60 works pretty good for the debug logs
  M.terminal_size = options.terminal_size or M.terminal_size or 60
  -- Directory where the robot code is located
  M.robot_directory = options.robot_directory or M.robot_directory or '~/swerve2024/'
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
  M.teamNumber = options.teamNumber or M.teamNumber or 1740
  -- Java home for the robot code optional if you have the environment variable set
  M.javaHome = options.javaHome or M.javaHome
end

function M.deployRobotCode()
  local predefined_commands = {
    'cd ' .. M.robot_directory .. ' && ./gradlew deploy -PteamNumber=' .. M.teamNumber .. ' --offline',
  }
  if M.javaHome ~= '' then
    table.insert(predefined_commands, ' -Dorg.gradle.java.home="' .. M.javaHome .. '"')
  end
  M.runCommands(predefined_commands, vim.fn.getcwd(), vim.fn.expand('%:p')) -- expand('%:p') returns the full path of the current file
end

function M.buildRobotCode()
  local predefined_commands = {
    'cd ' .. M.robot_directory .. ' && ./gradlew build',
  }
  if M.javaHome ~= '' then
    table.insert(predefined_commands, ' -Dorg.gradle.java.home="' .. M.javaHome .. '"')
  end
  M.runCommands(predefined_commands, vim.fn.getcwd(), vim.fn.expand('%:p')) -- expand('%:p') returns the full path of the current file
end

function M.runCommands(predefined_commands, current_directory, current_file)
  local width = vim.fn.winwidth(0)  -- Get current window width

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

    elseif M.terminal_size < width / 2 then -- normal case
      vim.cmd('vsplit | vertical resize ' .. M.terminal_size .. ' | terminal ' .. command)

    else -- terminal_size is greater than half of the window width so open at half
      vim.cmd('vsplit | terminal ' .. command)
    end

    -- close the terminal
    if M.autoQuitOnSuccess == true and M.terminal_size ~= 0 then -- 0 has special case
      local job_id = vim.fn.jobstart(command, {
        on_exit = function(job_id, exit_code, _) -- callback function for the exit code
          if exit_code == 0 then -- success!
            -- check if window is terminal to avoid closing other windows
            if vim.api.nvim_buf_get_option(0, 'buftype') == 'terminal' then
              vim.cmd(':q') -- close the terminal window
            end
            if M.printOnSuccess then
              vim.cmd('echohl Normal') -- set the color to red
              vim.cmd('echomsg "Success"')
              vim.cmd('echohl None') -- reset the color
            end
          else
            if M.autoQuitOnFailure and vim.api.nvim_buf_get_option(0, 'buftype') == 'terminal' then
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

end

-- Define the commands with the predefined set of commands
vim.cmd([[command! DeployRobotCode lua require'FRCNeovim'.deployRobotCode()]])
vim.cmd([[command! BuildRobotCode lua require'FRCNeovim'.buildRobotCode()]])
-- help command
vim.cmd([[command! -nargs=0 FRCNeovimHelp :help FRCNeovim]])

return M
