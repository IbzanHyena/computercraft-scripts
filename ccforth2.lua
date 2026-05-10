local argv = { ... }

local reset = false
PSTACK = {}
local RSTACK = {}
local body, ip

local VOCAB = {}

local stdin = io.input()

VARIABLES = {
    [0] = 1, -- cp lives at address 0; its value is the next free address
}

local current_source = stdin
local word_buffer = nil

local compile_stack = {}
local current_def = nil
local current_word_idx = nil
local compilation_depth = 0
local last_created = nil
local last_defined = nil

local OP_LIT, OP_CALL, OP_TCALL, OP_EXEC, OP_TEXEC,
      OP_IF, OP_TIF, OP_DIP, OP_CALLQ, OP_TCALLQ
      = 1, 2, 3, 4, 5, 6, 7, 8, 9, 10

local function dump(o, depth)
    depth = depth or 0
    if type(o) == "table" then
        if o.repr then return o.repr end
        local s = "{ "
        for k, v in pairs(o) do
            s = s .. "\n"
            for _ = 1, depth do s = s .. "  " end
            local key = k
            if type(key) ~= "number" then key = '"' .. tostring(key) .. '"' end
            s = s .. "[" .. tostring(key) .. "] = " .. dump(v, depth + 1) .. ","
        end
        return s .. "} "
    else
        return tostring(o)
    end
end

local function ferror(msg)
    io.write("Error: " .. tostring(msg) .. "\n")
    io.write("Stack: " .. dump(PSTACK) .. "\n")
    io.write("Return stack depth: " .. tostring(#RSTACK) .. "\n")
    error()
end

local function fill_word_buffer(print_stack)
    if print_stack and #PSTACK > 0 then
        io.write("Program stack:\n" .. dump(PSTACK) .. "\n")
        io.flush()
    end
    if current_source == stdin then
        io.write("ccforth> ")
        io.flush()
    end
    word_buffer = current_source:read("*l")
    if word_buffer then word_buffer = word_buffer .. "\n" end
end

local function fetch_word(print_stack)
    while true do
        if not word_buffer then
            fill_word_buffer(print_stack)
            if not word_buffer then return nil end
        end
        local i, j = word_buffer:find("%S+")
        if i then
            local w = word_buffer:sub(i, j)
            word_buffer = word_buffer:sub(j + 1)
            if word_buffer == "" then word_buffer = nil end
            return w
        end
        word_buffer = nil
    end
end

local function fetch_char()
    if not word_buffer then
        fill_word_buffer()
        if not word_buffer then return nil end
    end
    local c = word_buffer:sub(1, 1)
    word_buffer = word_buffer:sub(2)
    if word_buffer == "" then word_buffer = nil end
    return c
end

local function find_word(name)
    for i = #VOCAB, 1, -1 do
        if VOCAB[i].name == name then return i, VOCAB[i] end
    end
    return nil, nil
end

local function emit(insn)
    current_def.body[#current_def.body + 1] = insn
end

local function detect_tail_calls(b)
    local n = #b
    if n == 0 then return end
    local last = b[n]
    if last.op == OP_CALL then last.op = OP_TCALL
    elseif last.op == OP_EXEC then last.op = OP_TEXEC
    elseif last.op == OP_IF then last.op = OP_TIF
    elseif last.op == OP_CALLQ then last.op = OP_TCALLQ
    end
end

local push, pop1, pop2, pop3

local function run()
    while true do
        local insn = body[ip]
        if insn == nil then
            local n = #RSTACK
            if n == 0 then
                body, ip = nil, nil
                return
            end
            local f = RSTACK[n]
            RSTACK[n] = nil
            body, ip = f[1], f[2]
        else
            ip = ip + 1
            local op = insn.op
            if op == OP_LIT then
                push(insn.value)
            elseif op == OP_CALL then
                local entry = VOCAB[insn.target]
                if entry.kind == "prim" then
                    entry.fn()
                elseif entry.kind == "create" then
                    push(entry.address)
                    if entry.does_body then
                        RSTACK[#RSTACK + 1] = { body, ip }
                        body, ip = entry.does_body, 1
                    end
                else
                    RSTACK[#RSTACK + 1] = { body, ip }
                    body, ip = entry.body, 1
                end
            elseif op == OP_TCALL then
                local entry = VOCAB[insn.target]
                if entry.kind == "prim" then
                    entry.fn()
                elseif entry.kind == "create" then
                    push(entry.address)
                    if entry.does_body then
                        body, ip = entry.does_body, 1
                    end
                else
                    body, ip = entry.body, 1
                end
            elseif op == OP_EXEC then
                local q = table.remove(PSTACK)
                if type(q) ~= "table" or not q.body then
                    ferror("execute: expected quotation, got " .. tostring(q))
                end
                RSTACK[#RSTACK + 1] = { body, ip }
                body, ip = q.body, 1
            elseif op == OP_TEXEC then
                local q = pop1()
                if type(q) ~= "table" or not q.body then
                    ferror("execute: expected quotation, got " .. tostring(q))
                end
                body, ip = q.body, 1
            elseif op == OP_IF then
                local cond, tq, fq = pop3()
                local q = cond and tq or fq
                if type(q) ~= "table" or not q.body then
                    ferror("if: expected quotation, got " .. tostring(q))
                end
                RSTACK[#RSTACK + 1] = { body, ip }
                body, ip = q.body, 1
            elseif op == OP_TIF then
                local cond, tq, fq = pop3()
                local q = cond and tq or fq
                if type(q) ~= "table" or not q.body then
                    ferror("if: expected quotation, got " .. tostring(q))
                end
                body, ip = q.body, 1
            elseif op == OP_DIP then
                local v, q = pop2()
                if type(q) ~= "table" or not q.body then
                    ferror("dip: expected quotation, got " .. tostring(q))
                end
                RSTACK[#RSTACK + 1] = { body, ip }
                RSTACK[#RSTACK + 1] = { { { op = OP_LIT, value = v } }, 1 }
                body, ip = q.body, 1
            elseif op == OP_CALLQ then
                RSTACK[#RSTACK + 1] = { body, ip }
                body, ip = insn.value.body, 1
            elseif op == OP_TCALLQ then
                body, ip = insn.value.body, 1
            else
                ferror("Unknown opcode: " .. tostring(op))
            end
        end
    end
end

local function run_body(b)
    body, ip = b, 1
    run()
end

local function add_prim(name, fn, immediate)
    VOCAB[#VOCAB + 1] = {
        name = name,
        kind = "prim",
        fn = fn,
        immediate = immediate or false,
    }
end

pop1 = function()
    if #PSTACK < 1 then ferror("stack underflow") end
    return table.remove(PSTACK)
end

pop2 = function()
    if #PSTACK < 2 then ferror("stack underflow") end
    local b = table.remove(PSTACK)
    local a = table.remove(PSTACK)
    return a, b
end

pop3 = function()
    if #PSTACK < 3 then ferror("stack underflow") end
    local c = table.remove(PSTACK)
    local b = table.remove(PSTACK)
    local a = table.remove(PSTACK)
    return a, b, c
end

push = function(v)
    PSTACK[#PSTACK + 1] = v
end

local process_token

local LOADED_FILES = {}

local function load_file(fname)
    if LOADED_FILES[fname] then return end
    LOADED_FILES[fname] = true
    local file, err = io.open(fname, "r")
    if not file then
        ferror("Could not open file: " .. tostring(fname) .. " - " .. tostring(err))
    end
    local saved_source = current_source
    local saved_buffer = word_buffer
    current_source = file
    word_buffer = nil
    while true do
        local w = fetch_word(false)
        if not w then break end
        process_token(w)
    end
    file:close()
    current_source = saved_source
    word_buffer = saved_buffer
end

-- compile-time / parser words

add_prim(
    ":",
    function()
        if compilation_depth > 0 then ferror("Cannot define a word in compile mode") end
        local name = fetch_word()
        if not name then ferror(": expects a word name") end
        local idx = #VOCAB + 1
        local entry = {
            name = nil,
            kind = "forth",
            body = {},
            immediate = false,
            repr = name,
        }
        VOCAB[idx] = entry
        compile_stack[#compile_stack + 1] = {
            entry = entry,
            pending_name = name,
            is_named = true,
        }
        current_def = entry
        current_word_idx = idx
        compilation_depth = compilation_depth + 1
    end,
    true
)

add_prim(
    ";",
    function()
        if compilation_depth == 0 then ferror("No definition to end") end
        compilation_depth = compilation_depth - 1
        local frame = compile_stack[#compile_stack]
        compile_stack[#compile_stack] = nil
        detect_tail_calls(frame.entry.body)
        if frame.is_named then
            frame.entry.name = frame.pending_name
            last_defined = frame.entry
        end
        if #compile_stack > 0 then
            current_def = compile_stack[#compile_stack].entry
        else
            current_def = nil
            current_word_idx = nil
        end
    end,
    true
)

add_prim(
    "[",
    function()
        local entry = {
            kind = "forth",
            body = {},
            immediate = false,
            repr = "[ ... ]",
        }
        compile_stack[#compile_stack + 1] = { entry = entry, is_named = false }
        current_def = entry
        compilation_depth = compilation_depth + 1
    end,
    true
)

add_prim(
    "]",
    function()
        if compilation_depth == 0 then ferror("] without matching [") end
        compilation_depth = compilation_depth - 1
        local frame = compile_stack[#compile_stack]
        compile_stack[#compile_stack] = nil
        detect_tail_calls(frame.entry.body)
        if #compile_stack > 0 then
            current_def = compile_stack[#compile_stack].entry
            emit({ op = OP_LIT, value = frame.entry })
        else
            current_def = nil
            push(frame.entry)
        end
    end,
    true
)

add_prim(
    "recurse",
    function()
        if compilation_depth == 0 then ferror("recurse outside compile mode") end
        if not current_word_idx then ferror("recurse without enclosing :") end
        emit({ op = OP_CALL, target = current_word_idx })
    end,
    true
)


local SPECIAL_OPCODE = {
    ["if"] = OP_IF,
    ["execute"] = OP_EXEC,
    ["dip"] = OP_DIP,
}

add_prim(
    "'",
    function()
        local name = fetch_word()
        if not name then ferror("' expects a word name") end
        local q
        if SPECIAL_OPCODE[name] then
            q = {
                kind = "forth",
                body = { { op = SPECIAL_OPCODE[name] } },
                repr = "' " .. name,
            }
        else
            local idx, entry = find_word(name)
            if entry then
                q = {
                    kind = "forth",
                    body = { { op = OP_TCALL, target = idx } },
                    repr = "' " .. name,
                }
            else
                local n = tonumber(name)
                if n then
                    q = {
                        kind = "forth",
                        body = { { op = OP_LIT, value = n } },
                        repr = "' " .. name,
                    }
                else
                    ferror("Unknown word: " .. name)
                end
            end
        end
        if compilation_depth > 0 then
            emit({ op = OP_LIT, value = q })
        else
            push(q)
        end
    end,
    true
)

add_prim(
    "\"",
    function()
        -- consume one delimiter character (the space separating `"` from the body)
        local delim = fetch_char()
        if not delim then ferror("Unterminated string literal") end
        local str = ""
        local escaped = false
        while true do
            local c = fetch_char()
            if not c then ferror("Unterminated string literal") end
            if c == "\"" and not escaped then
                break
            elseif c == "\\" and not escaped then
                escaped = true
            else
                if escaped then
                    if c == "n" then c = "\n"
                    elseif c == "t" then c = "\t"
                    elseif c == "\\" or c == "\"" then
                        -- char as-is
                    else
                        ferror("Unknown escape sequence: \\" .. c)
                    end
                    str = str .. c
                    escaped = false
                else
                    str = str .. c
                end
            end
        end
        if compilation_depth > 0 then
            emit({ op = OP_LIT, value = str })
        else
            push(str)
        end
    end,
    true
)

-- strictly this could be a colon word, but I want comments from the beginning
-- : NB. [ key 10 = ] [ ] until ;
add_prim(
    "NB.",
    function()
        local c
        repeat c = fetch_char() until c == "\n" or c == nil
    end
)

add_prim(
    "word",
    function()
        local w = fetch_word()
        if not w then ferror("word: end of input") end
        push(w)
    end
)

add_prim(
    "key",
    function()
        local c = fetch_char()
        if not c then ferror("No character input") end
        push(c)
    end
)

-- word creation and patching

add_prim(
    "create",
    function()
        local name = fetch_word()
        if not name then ferror("create: no name") end
        local addr = VARIABLES[0]
        local entry = {
            name = name,
            kind = "create",
            address = addr,
            does_body = nil,
            immediate = false
        }
        VOCAB[#VOCAB + 1] = entry
        last_created = entry
    end
)

add_prim(
    "does>",
    function()
        if not last_created then ferror("does>: nothing last_created") end
        local remainder = {}
        for i = ip, #body do remainder[#remainder + 1] = body[i] end
        detect_tail_calls(remainder)
        last_created.does_body = remainder
        ip = #body + 1
    end
)

add_prim(
    "immediate",
    function()
        if not last_defined then ferror("immediate: no last_defined") end
        last_defined.immediate = true
    end
)

-- fundamental combinators (immediate; emit inline opcodes when compiling)

add_prim(
    "if",
    function()
        if compilation_depth > 0 then
            emit({ op = OP_IF })
        else
            local cond, tq, fq = pop3()
            local q = cond and tq or fq
            if type(q) ~= "table" or not q.body then
                ferror("if: expected quotation, got " .. tostring(q))
            end
            run_body(q.body)
        end
    end,
    true
)

add_prim(
    "execute",
    function()
        if compilation_depth > 0 then
            emit({ op = OP_EXEC })
        else
            local q = pop1()
            if type(q) ~= "table" or not q.body then
                ferror("execute: expected quotation, got " .. tostring(q))
            end
            run_body(q.body)
        end
    end,
    true
)

add_prim(
    "dip",
    function()
        if compilation_depth > 0 then
            emit({ op = OP_DIP })
        else
            local v, q = pop2()
            if type(q) ~= "table" or not q.body then
                ferror("dip: expected quotation, got " .. tostring(q))
            end
            RSTACK[#RSTACK + 1] = { { { op = OP_LIT, value = v } }, 1 }
            run_body(q.body)
        end
    end,
    true
)

-- pure runtime primitives

add_prim("nil", function() push(nil) end)

add_prim("+", function() local a, b = pop2(); push(a + b) end)
add_prim("-", function() local a, b = pop2(); push(a - b) end)
add_prim("*", function() local a, b = pop2(); push(a * b) end)
add_prim(
    "/",
    function()
        local a, b = pop2()
        if b == 0 then ferror("Division by zero") end
        push(a / b)
    end
)
add_prim("^", function() local a, b = pop2(); push(a ^ b) end)

add_prim("not", function() push(not pop1()) end)
add_prim("and", function() local a, b = pop2(); push(a and b) end)
add_prim("or", function() local a, b = pop2(); push(a or b) end)

add_prim("=", function() local a, b = pop2(); push(a == b) end)
add_prim("~=", function() local a, b = pop2(); push(a ~= b) end)
add_prim("<", function() local a, b = pop2(); push(a < b) end)
add_prim(">", function() local a, b = pop2(); push(a > b) end)
add_prim("<=", function() local a, b = pop2(); push(a <= b) end)
add_prim(">=", function() local a, b = pop2(); push(a >= b) end)

add_prim("#", function() push(#pop1()) end)
add_prim("true", function() push(true) end)
add_prim("false", function() push(false) end)
add_prim("{}", function() push({}) end)

add_prim("..", function() local a, b = pop2(); push(a .. b) end)

add_prim(
    "dup",
    function()
        if #PSTACK < 1 then ferror("dup: stack underflow") end
        push(PSTACK[#PSTACK])
    end
)
add_prim(
    "2dup",
    function()
        if #PSTACK < 2 then ferror("2dup: stack underflow") end
        local n = #PSTACK
        local a, b = PSTACK[n - 1], PSTACK[n]
        push(a)
        push(b)
    end
)
add_prim(
    "3dup",
    function()
        if #PSTACK < 3 then ferror("3dup: stack underflow") end
        local n = #PSTACK
        local a, b, c = PSTACK[n - 2], PSTACK[n - 1], PSTACK[n]
        push(a)
        push(b)
        push(c)
    end
)
add_prim(
    "swap",
    function()
        if #PSTACK < 2 then ferror("swap: stack underflow") end
        local n = #PSTACK
    PSTACK[n], PSTACK[n - 1] = PSTACK[n - 1], PSTACK[n]
    end
)
add_prim(
    "drop",
    function()
        if #PSTACK < 1 then ferror("drop: stack underflow") end
        pop1()
    end
)
add_prim(
    "over",
    function()
        if #PSTACK < 2 then ferror("over: stack underflow") end
        push(PSTACK[#PSTACK - 1])
    end
)
add_prim(
    "rot",
    function()
        if #PSTACK < 3 then ferror("rot: stack underflow") end
        local n = #PSTACK
        local a = PSTACK[n - 2]
        PSTACK[n - 2] = PSTACK[n - 1]
        PSTACK[n - 1] = PSTACK[n]
        PSTACK[n] = a
    end
)

add_prim(".", function() print(pop1()) end)

add_prim(
    "@",
    function()
        local v = pop1()
        if type(v) ~= "number" then
            ferror("@: expected address (number), got " .. tostring(v))
        end
        push(VARIABLES[v])
    end
)

add_prim(
    "!",
    function()
        local val, v = pop2()
        if type(v) ~= "number" then
            ferror("!: expected address (number), got " .. tostring(v))
        end
        VARIABLES[v] = val
    end
)

add_prim(
    "compose",
    function()
        local f, g = pop2()
        if type(f) ~= "table" or not f.body then ferror("compose: expected quotation") end
        if type(g) ~= "table" or not g.body then ferror("compose: expected quotation") end
        push(
            {
                kind = "forth",
                body = {
                    { op = OP_CALLQ, value = f },
                    { op = OP_TCALLQ, value = g },
                },
                repr = "[ " .. (f.repr or "?") .. " " .. (g.repr or "?") .. " ]",
            }
        )
    end
)

add_prim(
    "curry",
    function()
        local arg, q = pop2()
        if type(q) ~= "table" or not q.body then ferror("curry: expected quotation") end
        push(
            {
                kind = "forth",
                body = {
                    { op = OP_LIT, value = arg },
                    { op = OP_TCALLQ, value = q },
                },
                repr = "[ <arg> " .. (q.repr or "?") .. " ]",
            }
        )
    end
)

add_prim(
    "luacall",
    function()
        local func_name = table.remove(PSTACK)
        local namespace_name = table.remove(PSTACK)
        if type(func_name) ~= "string" then
            ferror("luacall: function name must be a string")
        end
        local namespace
        if namespace_name then
            namespace = _G[namespace_name]
        else
            namespace = _G
        end
        if type(namespace) ~= "table" then
            ferror("luacall: unknown namespace " .. tostring(namespace_name))
        end
        local func = namespace[func_name]
        if type(func) ~= "function" then
            ferror("Function not found: " .. tostring(func_name))
        end
        local n_args = table.remove(PSTACK)
        if type(n_args) ~= "number" or n_args < 0 then
            ferror("luacall: invalid n_args: " .. tostring(n_args))
        end
        local args = {}
        for _ = 1, n_args do
            local a = table.remove(PSTACK)
            if a == nil then ferror("luacall: not enough arguments") end
            table.insert(args, 1, a)
        end
        local result = { pcall(func, table.unpack(args)) }
        if not result[1] then ferror("luacall error: " .. tostring(result[2])) end
        for i = 2, #result do push(result[i]) end
    end
)

add_prim(
    ">lua-fn",
    function()
        local q = pop1()
        if type(q) ~= "table" or not q.body then
            ferror(">lua-fn: expected quotation, got " .. tostring(q))
        end
        push(function(...)
            local n_args = select("#", ...)
            local args = { ... }
            local before = #PSTACK
            for i = 1, n_args do push(args[i]) end
            local saved_body, saved_ip = body, ip
            local saved_rstack = RSTACK
            RSTACK = {}
            body, ip = q.body, 1
            local ok, err = pcall(run)
            RSTACK = saved_rstack
            body, ip = saved_body, saved_ip
            if not ok then error(err) end
            local n_results = #PSTACK - before
            if n_results < 0 then
                ferror("lua-fn: quotation underflowed the stack")
            end
            local results = {}
            for i = 1, n_results do results[i] = PSTACK[before + i] end
            for _ = 1, n_results do table.remove(PSTACK) end
            return table.unpack(results, 1, n_results)
        end)
    end
)

add_prim(
    "get",
    function()
        local t, key = pop2()
        if type(t) ~= "table" then ferror("get: expected a table") end
        if key == nil then ferror("get: key is nil") end
        push(t[key])
    end
)

add_prim(
    "assoc",
    function()
        local k, v, t = pop3()
        if tpye(t) ~= "table" then ferror("assoc: expected a table") end
        t[k] = v
        push(t)
    end
)

add_prim(
    "require",
    function()
        local fname = pop1()
        if type(fname) ~= "string" then
            ferror("require: expected filename string, got " .. tostring(fname))
        end
        load_file(fname)
    end
)

-- expose `cp` as a variable word
VOCAB[#VOCAB + 1] = {
    name = "cp",
    kind = "prim",
    fn = function() push(0) end,
    immediate = false,
}

-- token dispatch

process_token = function(token)
    local idx, entry = find_word(token)

    if entry and entry.immediate then
        if entry.kind == "prim" then
            entry.fn()
        elseif entry.kind == "create" then
            push(entry.address)
            if entry.does_body then
                run_body(entry.does_body)
            end
        else
            run_body(entry.body)
        end
        return
    end

    if compilation_depth > 0 then
        if entry then
            emit({ op = OP_CALL, target = idx })
        else
            local n = tonumber(token)
            if n then
                emit({ op = OP_LIT, value = n })
            else
                ferror("Unknown word: " .. token)
            end
        end
    else
        if entry then
            if entry.kind == "prim" then
                entry.fn()
            elseif entry.kind == "create" then
                push(entry.address)
                if entry.does_body then
                    run_body(entry.does_body)
                end
            else
                run_body(entry.body)
            end
        else
            local n = tonumber(token)
            if n then
                push(n)
            else
                ferror("Unknown word: " .. token)
            end
        end
    end
end

-- file loading

for _, fname in ipairs(argv) do
    load_file(fname)
end

current_source = stdin

-- REPL

local function reset_after_error()
    body, ip = nil, nil
    RSTACK = {}
    -- abort any half-built definitions; remove their pre-allocated VOCAB slots
    while #compile_stack > 0 do
        local frame = compile_stack[#compile_stack]
        compile_stack[#compile_stack] = nil
        if frame.is_named then
            for i = #VOCAB, 1, -1 do
                if VOCAB[i] == frame.entry then
                    VOCAB[i] = nil
                    break
                end
            end
        end
    end
    current_def = nil
    current_word_idx = nil
    compilation_depth = 0
    word_buffer = nil
    last_created = nil
end

while true do
    local w = fetch_word(true)
    if not w then break end
    local ok = pcall(process_token, w)
    if not ok and reset then reset_after_error()
    elseif not ok then
        io.write("Error: " .. tostring(w) .. "\n")
        os.exit(1)
     end
end
