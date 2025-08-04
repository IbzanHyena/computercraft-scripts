local argv = { ... }

PROGRAM_STACK = {}

VARIABLES = {
    _compilation_depth = 0,
    _current_word = nil,
    _current_definition = nil,
    _current_definitions = {},
    _current_dictionary = nil,
    _current_source = io.stdin,
    _execution_stack = {},
    _word_buffer = nil,
    _dictionaries = {},
    cp = 1,
}

local function dump(o, depth)
    if not depth then
        depth = 0
    end
   if type(o) == 'table' then
      if o.repr then
        return o.repr
      end
      local s = '{ '
      for k,v in pairs(o) do
        s = s .. "\n"
        for i = 1, depth do
            s = s .. '  '
         end
         if type(k) ~= 'number' then k = '"'..k..'"' end
         s = s .. '['..k..'] = ' .. dump(v, depth + 1) .. ','
      end
      return s .. '} '
   else
      return tostring(o)
   end
end

local function ferror(msg)
    io.write("Error: " .. msg .. "\n")
    io.write("Currently executing: " .. dump(VARIABLES["_execution_stack"]) .. "\n")
    io.write("Stack: " .. dump(PROGRAM_STACK) .. "\n")
    error()
end

local function fill_word_buffer(print_stack)
    if print_stack and #PROGRAM_STACK > 0 then
        io.write("Program stack:\n" .. dump(PROGRAM_STACK) .. "\n")
        io.flush()
    end
    if VARIABLES["_current_source"] == io.stdin then
        io.write("ccforth> ")
        io.flush()
    end

    VARIABLES["_word_buffer"] = VARIABLES["_current_source"]:read("l")
    if VARIABLES["_word_buffer"] then
        VARIABLES["_word_buffer"] = VARIABLES["_word_buffer"] .. "\n"
    end
end

local function fetch_word(print_stack)
    if not VARIABLES["_word_buffer"] then
        repeat
            fill_word_buffer(print_stack)
        until VARIABLES["_word_buffer"] == nil or VARIABLES["_word_buffer"]:find("%S")
    end
    if not VARIABLES["_word_buffer"] then
        return nil
    end

    local i, j = VARIABLES["_word_buffer"]:find("%S+")
    local word = VARIABLES["_word_buffer"]:sub(i, j)
    VARIABLES["_word_buffer"] = VARIABLES["_word_buffer"]:sub(j + 1)
    -- trim leading whitespace
    VARIABLES["_word_buffer"] = VARIABLES["_word_buffer"]:gsub("^%s+", "")
    -- if the buffer is empty after trimming, set it to nil
    if VARIABLES["_word_buffer"] == "" then
        VARIABLES["_word_buffer"] = nil
    end
    return word
end

local function fetch_char()
    if not VARIABLES["_word_buffer"] then
        fill_word_buffer()
        if not VARIABLES["_word_buffer"] then
            return nil
        end
    end

    local char = VARIABLES["_word_buffer"]:sub(1, 1)
    VARIABLES["_word_buffer"] = VARIABLES["_word_buffer"]:sub(2)
    if VARIABLES["_word_buffer"] == "" then
        VARIABLES["_word_buffer"] = nil
    end
    return char
end

local function decode_word(name)
    if type(name) ~= "string" then
        return name
    end

    for _, value in pairs(VARIABLES["_dictionaries"]) do
        for key, word in pairs(value) do
            if key == name then
                return word
            end
        end
    end

    return tonumber(name)
end

local interpret
local execute_definition

VARIABLES["_dictionaries"]["USER"] = {}
VARIABLES["_dictionaries"]["SYSTEM"] = {}
VARIABLES["_current_dictionary"] = VARIABLES["_dictionaries"]["SYSTEM"]
VARIABLES["_dictionaries"]["CODE"] = {
    [ "nil" ] = {
        immediate=false,
        definition=function()
            table.insert(PROGRAM_STACK, nil)
        end,
        repr="nil",
    },
    [ "word" ] = {
        immediate=true,
        definition=function()
            local word = fetch_word()
            table.insert(PROGRAM_STACK, word)
        end,
        repr="word",
    },
    [ "key" ] = {
        immediate=false,
        definition=function()
            local char = fetch_char()
            if not char then
                ferror("No character input")
            end
            table.insert(PROGRAM_STACK, char)
        end,
        repr="key",
    },
    [ "NB." ] = {
        immediate=true,
        definition=function()
            local char
            repeat
                char = fetch_char()
            until char == "\n"
        end,
        repr="NB.",
    },
    [ "\"" ] = {
        immediate=true,
        definition=function()
            local str = ""
            local escaped = false
            while true do
                local char = fetch_char()
                if not char then
                    ferror("Unterminated string literal")
                end

                if char == "\"" and not escaped then
                    break
                elseif char == "\\" and not escaped then
                    escaped = true
                else
                    if escaped then
                        if char == "n" then
                            char = "\n"
                        elseif char == "t" then
                            char = "\t"
                        elseif char == "\\" or char == "\"" then
                            str = str .. char
                        else
                            ferror("Unknown escape sequence: \\" .. char)
                        end
                        escaped = false
                    else
                        str = str .. char
                    end
                end
            end

            if VARIABLES["_compilation_depth"] == 0 then
                table.insert(PROGRAM_STACK, str)
            else
                table.insert(
                    VARIABLES["_current_definition"]["definition"],
                    {
                        immediate=true,
                        definition=function()
                            table.insert(PROGRAM_STACK, str)
                        end,
                        repr="\" " .. str .. "\""
                    }
                )
            end
        end,
        repr="\"",
    },
    [ "luacall" ] = {
        immediate=false,
        definition=function()
            local func_name = table.remove(PROGRAM_STACK)
            local namespace = table.remove(PROGRAM_STACK)
            if type(func_name) ~= "string" then
                ferror("Function name must be a string")
            end

            if namespace then
                namespace = _G[namespace]
            else
                namespace = _G
            end

            local func = namespace[func_name]
            if not func or type(func) ~= "function" then
                ferror("Function not found: " .. func_name)
            end

            local n_args = table.remove(PROGRAM_STACK)
            if type(n_args) ~= "number" or n_args < 0 then
                ferror("Invalid number of arguments: " .. tostring(n_args))
            end

            local args = {}
            for i = 1, n_args do
                local arg = table.remove(PROGRAM_STACK)
                if arg == nil then
                    ferror("Not enough arguments for function: " .. func_name)
                end
                table.insert(args, 1, arg)
            end
            if #args ~= n_args then
                ferror("Expected " .. n_args .. " arguments, got " .. #args)
            end

            local result = { pcall(func, table.unpack(args)) }
            if not result[1] then
                ferror("Error calling function: " .. result[2])
            end
            for i = 2, #result do
                table.insert(PROGRAM_STACK, result[i])
            end
        end,
        repr="luacall",
    },
    [ "get" ] = {
        immediate=false,
        definition=function()
            local key = table.remove(PROGRAM_STACK)
            local t = table.remove(PROGRAM_STACK)
            if type(t) ~= "table" then
                ferror("Expected a table, got: " .. type(t))
            end
            if key == nil then
                ferror("Key cannot be nil")
            end
            table.insert(PROGRAM_STACK, t[key])
        end,
        repr="get",
    },
    [ ":" ] = {
        immediate=false,
        definition=function()
            if VARIABLES["_compilation_depth"] ~= 0 then
                ferror("Cannot define a word in compile mode")
            end
            VARIABLES["_compilation_depth"] = VARIABLES["_compilation_depth"] + 1
            VARIABLES["_current_word"] = fetch_word()
            VARIABLES["_current_definition"] = {
                immediate=false,
                definition={},
                repr=VARIABLES["_current_word"] or "<unnamed>",
            }
            table.insert(VARIABLES["_current_definitions"], VARIABLES["_current_definition"])
        end,
        repr=":",
    },
    [ ";" ] = {
        immediate=true,
        definition=function()
            if VARIABLES["_compilation_depth"] == 0 then
                ferror("No current definition to end")
            end
            VARIABLES["_compilation_depth"] = VARIABLES["_compilation_depth"] - 1
            VARIABLES["_current_dictionary"][VARIABLES["_current_word"]] = VARIABLES["_current_definition"]
            VARIABLES["_current_word"] = nil
            table.remove(VARIABLES["_current_definitions"])
            VARIABLES["_current_definition"] = VARIABLES["_current_definitions"][#VARIABLES["_current_definitions"]]
        end,
        repr=";",
    },
    [ "[" ] = {
        immediate=true,
        definition=function()
            -- local old_mode = VARIABLES["_interpreter_mode"]
            -- VARIABLES["_interpreter_mode"] = "compile"
            -- local old_current_definition = VARIABLES["_current_definition"]
            -- local definition = {}
            VARIABLES["_compilation_depth"] = VARIABLES["_compilation_depth"] + 1
            VARIABLES["_current_definition"] = {
                immediate=false,
                definition={},
            }
            table.insert(VARIABLES["_current_definitions"], VARIABLES["_current_definition"])
        end,
        repr="[",
    },
    [ "]" ] = {
        immediate=true,
        definition=function()
            if VARIABLES["_compilation_depth"] == 0 then
                ferror("Cannot end a definition outside of compile mode")
            end
            if not VARIABLES["_current_definition"] then
                ferror("No current definition to end")
            end
            VARIABLES["_compilation_depth"] = VARIABLES["_compilation_depth"] - 1
            local word = table.remove(VARIABLES["_current_definitions"])
            word["repr"] = "[ "
            for _, w in ipairs(word.definition) do
                word["repr"] = word["repr"] .. (w.repr or tostring(w)) .. " "
            end
            word["repr"] = word["repr"] .. "]"
            VARIABLES["_current_definition"] = VARIABLES["_current_definitions"][#VARIABLES["_current_definitions"]]

            if VARIABLES["_compilation_depth"] == 0 then
                table.insert(PROGRAM_STACK, word)
            else
                table.insert(VARIABLES["_current_definition"]["definition"], {
                    immediate=false,
                        definition=function ()
                        table.insert(PROGRAM_STACK, word)
                    end,
                    repr=word.repr,
                })
            end
        end,
        repr="]",
    },
    [ "+" ] = {
        immediate=false,
        definition=function()
            local b = table.remove(PROGRAM_STACK)
            local a = table.remove(PROGRAM_STACK)
            table.insert(PROGRAM_STACK, a + b)
        end,
        repr="+",
    },
    [ "-" ] = {
        immediate=false,
        definition=function()
            local b = table.remove(PROGRAM_STACK)
            local a = table.remove(PROGRAM_STACK)
            table.insert(PROGRAM_STACK, a - b)
        end,
        repr="-",
    },
    [ "*" ] = {
        immediate=false,
        definition=function()
            local b = table.remove(PROGRAM_STACK)
            local a = table.remove(PROGRAM_STACK)
            table.insert(PROGRAM_STACK, a * b)
        end,
        repr="*",
    },
    [ "/" ] = {
        immediate=false,
        definition=function()
            local b = table.remove(PROGRAM_STACK)
            local a = table.remove(PROGRAM_STACK)
            if b == 0 then
                ferror("Division by zero")
            end
            table.insert(PROGRAM_STACK, a / b)
        end,
        repr="/",
    },
    [ "^" ] = {
        immediate=false,
        definition=function()
            local b = table.remove(PROGRAM_STACK)
            local a = table.remove(PROGRAM_STACK)
            table.insert(PROGRAM_STACK, a ^ b)
        end,
        repr="^",
    },
    [ "not" ] = {
        immedate=false,
        definition=function()
            local value = table.remove(PROGRAM_STACK)
            table.insert(PROGRAM_STACK, not value)
        end,
        repr="not",
    },
    [ "and" ] = {
        immediate=false,
        definition=function()
            local b = table.remove(PROGRAM_STACK)
            local a = table.remove(PROGRAM_STACK)
            table.insert(PROGRAM_STACK, a and b)
        end,
        repr="and",
    },
    [ "or" ] = {
        immediate=false,
        definition=function()
            local b = table.remove(PROGRAM_STACK)
            local a = table.remove(PROGRAM_STACK)
            table.insert(PROGRAM_STACK, a or b)
        end,
        repr="or",
    },
    [ "=" ] = {
        immediate=false,
        definition=function()
            local b = table.remove(PROGRAM_STACK)
            local a = table.remove(PROGRAM_STACK)
            table.insert(PROGRAM_STACK, a == b)
        end,
        repr="=",
    },
    [ "~=" ] = {
        immediate=false,
        definition=function()
            local b = table.remove(PROGRAM_STACK)
            local a = table.remove(PROGRAM_STACK)
            table.insert(PROGRAM_STACK, a ~= b)
        end,
        repr="~=",
    },
    [ "<" ] = {
        immediate=false,
        definition=function()
            local b = table.remove(PROGRAM_STACK)
            local a = table.remove(PROGRAM_STACK)
            table.insert(PROGRAM_STACK, a < b)
        end,
        repr="<",
    },
    [ ">" ] = {
        immediate=false,
        definition=function()
            local b = table.remove(PROGRAM_STACK)
            local a = table.remove(PROGRAM_STACK)
            table.insert(PROGRAM_STACK, a > b)
        end,
        repr=">",
    },
    [ "<=" ] = {
        immediate=false,
        definition=function()
            local b = table.remove(PROGRAM_STACK)
            local a = table.remove(PROGRAM_STACK)
            table.insert(PROGRAM_STACK, a <= b)
        end,
        repr="<=",
    },
    [ ">=" ] = {
        immediate=false,
        definition=function()
            local b = table.remove(PROGRAM_STACK)
            local a = table.remove(PROGRAM_STACK)
            table.insert(PROGRAM_STACK, a >= b)
        end,
        repr=">=",
    },
    [ "t" ] = {
        immediate=false,
        definition=function()
            table.insert(PROGRAM_STACK, true)
        end,
        repr="t",
    },
    [ "f" ] = {
        immediate=false,
        definition=function()
            table.insert(PROGRAM_STACK, false)
        end,
        repr="f",
    },
    [ "dup" ] = {
        immediate=false,
        definition=function()
            local top = table.remove(PROGRAM_STACK)
            table.insert(PROGRAM_STACK, top)
            table.insert(PROGRAM_STACK, top)
        end,
        repr="dup",
    },
    [ "2dup" ] = {
        immediate=false,
        definition=function()
            local top = table.remove(PROGRAM_STACK)
            local second = table.remove(PROGRAM_STACK)
            table.insert(PROGRAM_STACK, second)
            table.insert(PROGRAM_STACK, top)
            table.insert(PROGRAM_STACK, second)
            table.insert(PROGRAM_STACK, top)
        end,
        repr="2dup",
    },
    [ "3dup" ] = {
        immediate=false,
        definition=function()
            local top = table.remove(PROGRAM_STACK)
            local second = table.remove(PROGRAM_STACK)
            local third = table.remove(PROGRAM_STACK)
            table.insert(PROGRAM_STACK, third)
            table.insert(PROGRAM_STACK, second)
            table.insert(PROGRAM_STACK, top)
            table.insert(PROGRAM_STACK, third)
            table.insert(PROGRAM_STACK, second)
            table.insert(PROGRAM_STACK, top)
        end,
        repr="3dup",
    },
    [ "swap" ] = {
        immediate=false,
        definition=function()
            local a = table.remove(PROGRAM_STACK)
            local b = table.remove(PROGRAM_STACK)
            table.insert(PROGRAM_STACK, a)
            table.insert(PROGRAM_STACK, b)
        end,
        repr="swap",
    },
    [ "drop" ] = {
        immediate=false,
        definition=function()
            table.remove(PROGRAM_STACK)
        end,
        repr="drop",
    },
    [ "." ] = {
        immediate=false,
        definition=function()
            local value = table.remove(PROGRAM_STACK)
            print(value)
        end,
        repr=".",
    },
    [ "immediate" ] = {
        immediate=true,
        definition=function()
            if VARIABLES["_compilation_depth"] == 0 then
                ferror("Cannot set immediate mode outside of compile mode")
            end
            VARIABLES["_current_definition"]["immediate"] = true
        end,
        repr="immediate",
    },
    [ "variable:" ] = {
        immediate=true,
        definition=function()
            local name = fetch_word()
            if not name then
                ferror("No variable name provided")
            end

            VARIABLES["_current_dictionary"][name] = {
                immediate=false,
                definition=function()
                    table.insert(PROGRAM_STACK, {address=name})
                end,
            }
        end,
        repr="variable:",
    },
    [ "@" ] = {
        immediate=false,
        definition=function()
            local v = table.remove(PROGRAM_STACK)
            table.insert(PROGRAM_STACK, VARIABLES[v.address])
        end,
        repr="@",
    },
    [ "!" ] = {
        immedate=false,
        definition=function()
            local v = table.remove(PROGRAM_STACK)
            local val = table.remove(PROGRAM_STACK)
            if not v.address then
                ferror("Cannot store value to non-variable: " .. tostring(v))
            end
            VARIABLES[v.address] = val
        end,
        repr="!",
    },
    [ "'" ] = {
        immediate=true,
        definition=function()
            local name = fetch_word()
            if not name then
                ferror("No word name provided")
            end

            local decoded_word = decode_word(name)
            if not decoded_word then
                ferror("Unknown word: " .. name)
            end

            table.insert(PROGRAM_STACK, decoded_word)
        end,
        repr="'",
    },
    [ "execute" ] = {
        immediate=false,
        definition=function()
            local word = table.remove(PROGRAM_STACK)
            execute_definition(word.definition)
        end,
        repr="execute",
    },
    [ "if" ] = {
        immediate=false,
        definition=function()
            local false_branch = table.remove(PROGRAM_STACK)
            local true_branch = table.remove(PROGRAM_STACK)
            local condition = table.remove(PROGRAM_STACK)
            if condition then
                execute_definition(true_branch.definition)
            else
                execute_definition(false_branch.definition)
            end
        end,
        repr="if",
    },
    [ "dip" ] = {
        immediate=false,
        definition=function()
            local word = table.remove(PROGRAM_STACK)
            local top = table.remove(PROGRAM_STACK)
            if not word or type(word) ~= "table" or not word.definition then
                ferror("Expected a word for dip (word: " .. tostring(word) .. ", top: " .. tostring(top) .. ")")
            end
            execute_definition(word.definition)
            table.insert(PROGRAM_STACK, top)
        end,
        repr="dip",
    },
    [ "over" ] = {
        immediate=false,
        definition=function()
            local top = table.remove(PROGRAM_STACK)
            local second = table.remove(PROGRAM_STACK)
            table.insert(PROGRAM_STACK, second)
            table.insert(PROGRAM_STACK, top)
            table.insert(PROGRAM_STACK, second)
        end,
        repr="over",
    },
    [ "rot" ] = {
        immediate=false,
        definition=function()
            local c = table.remove(PROGRAM_STACK)
            local b = table.remove(PROGRAM_STACK)
            local a = table.remove(PROGRAM_STACK)
            table.insert(PROGRAM_STACK, b)
            table.insert(PROGRAM_STACK, c)
            table.insert(PROGRAM_STACK, a)
        end,
        repr="rot",
    },
    [ "compose" ] = {
        immediate=false,
        definition=function()
            local g = table.remove(PROGRAM_STACK)
            local f = table.remove(PROGRAM_STACK)
            if type(f) ~= "table" or not f.definition then
                ferror("Expected a word for compose")
            end
            if type(g) ~= "table" or not g.definition then
                ferror("Expected a word for compose")
            end
            local composed = {
                immediate=false,
                definition=function()
                    execute_definition(f.definition)
                    execute_definition(g.definition)
                end,
                repr=f.repr:sub(1, -3) .. " " .. g.repr:sub(3),
            }
            table.insert(PROGRAM_STACK, composed)
        end,
        repr="compose",
    },
    [ "curry" ] = {
        immediate=false,
        definition=function()
            local word = table.remove(PROGRAM_STACK)
            local arg = table.remove(PROGRAM_STACK)
            if type(word) ~= "table" or not word.definition then
                ferror("Expected a word for curry")
            end
            if not arg then
                ferror("No argument provided for curried word")
            end
            local curried = {
                immediate=false,
                definition=function()
                    table.insert(PROGRAM_STACK, arg)
                    execute_definition(word.definition)
                end,
                repr="[ " .. dump(arg) .. " " .. dump(word):sub(3, -3) .. " ]",
            }
            table.insert(PROGRAM_STACK, curried)
        end,
    },
    [ "recurse" ] = {
        immediate=true,
        definition=function()
            if VARIABLES["_compilation_depth"] == 0 then
                ferror("Cannot define a recursive word outside of compile mode")
            end
            if not VARIABLES["_current_definition"] then
                ferror("No current definition to recurse into")
            end

            local current_word = VARIABLES["_current_word"]
            if not current_word then
                ferror("No current word defined for recursion")
            end

            table.insert(VARIABLES["_current_definition"]["definition"], current_word)
        end,
        repr="recurse",
    }
}

execute_definition = function(definition)
    table.insert(VARIABLES["_execution_stack"], definition)
    if type(definition) == "function" then
        definition()
    elseif type(definition) == "table" then
        for _, word in ipairs(definition) do
            interpret(word, decode_word(word))
        end
    end
    table.remove(VARIABLES["_execution_stack"])
end

for name, _ in pairs(VARIABLES) do
    VARIABLES["_current_dictionary"][name] = {
        immediate=false,
        definition=function()
            table.insert(PROGRAM_STACK, {address=name})
        end,
    }
end

interpret = function(raw_word, decoded_word)
    -- print()
    -- print("Interpreting: " .. tostring(raw_word))
    -- print("Decoded: " .. tostring(decoded_word))
    -- print("Compilation depth: " .. VARIABLES["_compilation_depth"])

    if decoded_word and type(decoded_word) == "table" and decoded_word.immediate then
        execute_definition(decoded_word.definition)
        return
    end

    if VARIABLES["_compilation_depth"] > 0 then
        if not VARIABLES["_current_definition"] then
            ferror("No current definition to compile into")
        end
        table.insert(VARIABLES["_current_definition"]["definition"], raw_word)
    else
        if not decoded_word then
            ferror("Unknown word: " .. raw_word)
        end

        if type(decoded_word) == "function" then
            decoded_word()
        elseif type(decoded_word) == "table" and decoded_word.definition then
            execute_definition(decoded_word.definition)
        else
            table.insert(PROGRAM_STACK, decoded_word)
        end
    end
end

for _, fname in ipairs(argv) do
    VARIABLES["_current_dictionary"] = VARIABLES["_dictionaries"]["USER"]
    local file, err = io.open(fname, "r")
    if not file then
        ferror("Could not open file: " .. fname .. " - " .. err)
    end
    VARIABLES["_current_source"] = file

    while true do
        local w = fetch_word()
        if not w then break end
        interpret(w, decode_word(w))
    end

    file:close()
    VARIABLES["_word_buffer"] = nil
end

VARIABLES["_current_dictionary"] = VARIABLES["_dictionaries"]["USER"]
VARIABLES["_current_source"] = io.stdin

local function repl()
   while true do
        local w = fetch_word(true)
        if w then
            interpret(w, decode_word(w))
        end
    end
end

local _, err = pcall(repl)
if err then
    ferror("REPL error: " .. tostring(err))
end
