luautils = {}

function luautils.array_is_unique(array)
    local t = {}
    for _, v in ipairs(array) do
        if t[v] then return false end
        t[v] = true
    end
    return true
end

-- table.xxx extention
-- unrecursive version
function luautils.table_merge(dest, src)
    for k, v in pairs(src) do
        dest[k] = v
    end
    return dest
end

function luautils.table_merge_kv(src)
    local t = luautils.table_copy(src)
    for k, v in pairs(src) do
        if type(v) ~= "table" and type(v) ~= "userdata" then
            t[v] = k
        end
    end
    
    return t
end

function luautils.array_equal(t, t2)
    for i, v in ipairs(t) do
        if v ~= t2[i] then return false end
    end
    return true
end

function luautils.array_unique(array)
    local r = {}
    local s = {}
    for _, v in ipairs(array) do
        if not s[v] then
            s[v] = true
            table.insert(r, v)
        end
    end
    return r
end

function luautils.array_new(len, val)
    local r = {}
    for i = 1, len do 
        table.insert(r, val)
    end
    return r
end

function luautils.array_find(t, val)
    for i, v in ipairs(t) do
        if val == v then return i end
    end
    return -1
end

function luautils.array_remove(t, val)
    local idx = luautils.array_find(t, val)
    if idx ~= -1 then
        table.remove(t, idx)
        return true
    end

    return false
end

function luautils.array_unique_insert(t, val, in_head)
    local idx = luautils.array_find(t, val)
    
    if idx ~= -1 then
        table.remove(t, idx)
    end
    table.insert(t, in_head and 1 or #t, val)    
end

function luautils.array_find_key(t, val, key)
    for i, v in ipairs(t) do
        local p = v[key]
        if p and p == val then return i end
    end
    return -1
end

function luautils.array_random(t, num)
    if num >= #t then return luautils.array_copy(t) end
    local ret = {}
    local ixs = {}
    for i = 1, num do
        local r = math.random(#t)
        while array_find(ixs, r) > -1 do
            r = math.random(#t)
        end
        table.insert(ixs, r)
        table.insert(ret, t[r])
    end
    return ret
end

function luautils.table_size(t)
    local r = 0
    for _, _ in pairs(t) do r = r + 1 end
    return r
end

function luautils.table_empty(t)
    return not next(t)
end

function luautils.table_equal(t, t2)
    local n = 0
    for k, v in pairs(t) do
        if v ~= t2[k] then return false end
        n = n + 1
    end
    return n == luautils.table_size(t2)
end

function luautils.table_copy(t)
    return luautils.table_merge({}, t)
end

function luautils.table_keys(t)
    local r = {}
    for k, _ in pairs(t) do
        table.insert(r, k)
    end
    return r
end

function luautils.table_values(t)
    local r = {}
    for _, v in pairs(t) do
        table.insert(r, v)
    end
    return r
end

function luautils.table_filter(t, func)
    local r = {}
    for k, v in pairs(t) do
        if func(k, v) then r[k] = v end
    end
    return r
end

function luautils.table_map(t, func)
    local r = {}
    for k, v in pairs(t) do
        local nk, nv = func(k, v)
        r[nk] = nv
    end
    return r
end

function luautils.table_requal(t, t2)
    local n = 0
    for k, v in pairs(t) do
        if type(v) == 'table' then
            local v2 = t2[k]
            if type(v2) ~= 'table' then return false end
            if not luautils.table_requal(v, v2) then return false end
        else
            if v ~= t2[k] then return false end
        end
        n = n + 1
    end
    return n == luautils.table_size(t2)
end

function luautils.table_rcopy(t)
    local r = {}
    for k, v in pairs(t) do
        if type(v) == 'table' then
            r[k] = luautils.table_rcopy(v)
        else
            r[k] = v
        end
    end
    return r
end

function luautils.table_next(tb, sort_func)
    local array_keys = luautils.table_keys(tb)
    table.sort(array_keys, sort_func)

    return function(key)
        local next_key = nil
        if not key then 
            next_key = key or array_keys[1]
        else
            for i, v in ipairs(array_keys) do
                if key == v then
                    next_key = array_keys[i + 1]
                    break
                end
            end
        end

        if next_key then
            return next_key, tb[next_key]
        end
    end    
end

function luautils.table_key_pairs(tb, sort_func)
    local array_keys = luautils.table_keys(tb)
    table.sort(array_keys, sort_func or function(a, b) return a < b end)

    local i = 0
    return function()
        i = i + 1
        if array_keys[i] then
            return array_keys[i], tb[array_keys[i]]
        end
    end        
end

function luautils.table_value_pairs(tb, key, sort_func)
    -- fit argument size
    if key and not sort_func then
        sort_func = key
        key = nil
    end
    local array_keys = luautils.table_keys(tb)
    sort_func = sort_func or function(a, b) return a < b end
    table.sort(array_keys, function(a, b)
        if key then
            return sort_func(tb[a][key], tb[b][key])
        else
            return sort_func(tb[a], tb[b])
        end        
    end)

    local i = 0
    return function()
        i = i + 1
        if array_keys[i] then
            return array_keys[i], tb[array_keys[i]]
        end
    end     
end

function luautils.table_shuffle(tb, is_copy)
    if is_copy then tb = luautils.table_copy(tb) end
    for i = 1, #tb * 2 do
        local idx1 = luautils.random(1, #tb)
        local idx2 = luautils.random(1, #tb)
        tb[idx1], tb[idx2] = tb[idx2], tb[idx1]
    end
    return tb
end

function luautils.random( ... )
    local randomseed = luautils.randomseed or os.time()

	local len = #arg
	if len > 2 then
		LTRACE("[luautils] random arg num is error!, num:%d", len)
		return
	end

    local m = 65536
	local u = 2053
	local v = 13849
	randomseed = (u * randomseed + v) % m
    luautils.randomseed = randomseed

	local result = randomseed / m
	if len ~= 0 then
		local min, max = 0, 1
		if len == 1 then
			max = arg[1]
		elseif len == 2 then
			min = arg[1]
			max = arg[2]
		end

		result = math.floor(min + (max-min)*result + 0.5)
	end

	return result
end

function luautils.print_table(node)
    -- to make output beautiful
    local function tab(amt)
        local str = ""
        for i=1,amt do
            str = str .. "\t"
        end
        return str
    end

    local cache, stack, output = {},{},{}
    local depth = 1
    local output_str = "{\n"

    while true do
        local size = 0
        for k,v in pairs(node) do
            size = size + 1
        end

        local cur_index = 1
        for k,v in pairs(node) do
            if (cache[node] == nil) or (cur_index >= cache[node]) then

                if (string.find(output_str,"}",output_str:len())) then
                    output_str = output_str .. ",\n"
                elseif not (string.find(output_str,"\n",output_str:len())) then
                    output_str = output_str .. "\n"
                end

                -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
                table.insert(output,output_str)
                output_str = ""

                local key
                if (type(k) == "number" or type(k) == "boolean") then
                    key = "["..tostring(k).."]"
                else
                    key = "['"..tostring(k).."']"
                end

                if (type(v) == "number" or type(v) == "boolean") then
                    output_str = output_str .. tab(depth) .. key .. " = "..tostring(v)
                elseif (type(v) == "table") then
                    output_str = output_str .. tab(depth) .. key .. " = {\n"
                    table.insert(stack,node)
                    table.insert(stack,v)
                    cache[node] = cur_index+1
                    break
                else
                    output_str = output_str .. tab(depth) .. key .. " = '"..tostring(v).."'"
                end

                if (cur_index == size) then
                    output_str = output_str .. "\n" .. tab(depth-1) .. "}"
                else
                    output_str = output_str .. ","
                end
            else
                -- close the table
                if (cur_index == size) then
                    output_str = output_str .. "\n" .. tab(depth-1) .. "}"
                end
            end

            cur_index = cur_index + 1
        end

        if (size == 0) then
            output_str = output_str .. "\n" .. tab(depth-1) .. "}"
        end

        if (#stack > 0) then
            node = stack[#stack]
            stack[#stack] = nil
            depth = cache[node] == nil and depth + 1 or depth - 1
        else
            break
        end
    end

    -- This is necessary for working with HUGE tables otherwise we run out of memory using concat on huge strings
    table.insert(output,output_str)
    output_str = table.concat(output)

    print(output_str)
end

