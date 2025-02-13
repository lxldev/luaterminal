-- Simple terminal mod for Minetest with real-time Lua execution and error handling

local terminal_history = {}  -- Stores terminal command history

minetest.register_privilege("luaterminaladmin", {
    description = "Allows access to the Lua terminal for real-time command execution",
    give_to_singleplayer = false,  -- Don't give to singleplayer by default
})

-- Function to execute Lua commands safely and capture output
local function execute_command(player_name, command)
    local result = ""
    local success, err = pcall(function()
        -- Capture print output
        local original_print = print
        print = function(...)  -- Override print function to capture output
            result = result .. table.concat({...}, " ") .. "\n"  -- Append output to result
        end

        -- Compile and execute the command
        local func, loadErr = loadstring(command)  -- Compile the command

        if not func then
            result = "Error: " .. loadErr  -- Error compiling command
            return
        end

        -- Execute the command (only runs once)
        func()

        -- Restore the original print function
        print = original_print
    end)

    if not success then
        result = "Error: " .. err
    end

    return result
end

-- Function to show the terminal GUI
local function open_terminal(player_name)
    if not minetest.check_player_privs(player_name, {luaterminaladmin = true}) then
        return
    end

    local formspec = "size[10,8]" ..
                     "textarea[0.5,1;9,6;terminal_output;Terminal Output;]" ..
                     "field[0.5,7;9,1;terminal_input;Input Command;]" ..
                     "button_exit[3.5,7.5;3,1;run;Run]"

    minetest.show_formspec(player_name, "luaterminal:terminal", formspec)
end

-- Handle form submission (command execution)
minetest.register_on_player_receive_fields(function(player, formname, fields)
    if formname == "luaterminal:terminal" then
        local player_name = player:get_player_name()

        if fields.terminal_input and fields.terminal_input ~= "" then
            local command = fields.terminal_input
            local output = execute_command(player_name, command)

            -- Show the result in the terminal (clear previous output)
            local formspec = "size[10,8]" ..
                             "textarea[0.5,1;9,6;terminal_output;Terminal Output;" .. minetest.formspec_escape(output) .. "]" ..
                             "field[0.5,7;9,1;terminal_input;Input Command;]" ..
                             "button_exit[3.5,7.5;3,1;run;Run]"

            minetest.show_formspec(player_name, "luaterminal:terminal", formspec)
        end
    end
end)

-- Register chat command to open the terminal
minetest.register_chatcommand("terminal", {
    description = "Open the terminal interface for real-time Lua execution (requires luaterminaladmin priv)",
    func = function(name)
        open_terminal(name)
    end,
})
