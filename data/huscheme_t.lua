local utils_t = require 'alg.cards_utils'

local table_copy = luautils.table_copy
local print = function() end
local print_table = function() end -- luautils.print_table
local scheme = {}

function scheme.gen_all_combine()
    local t = {}
    for count = 1, 10 do
        t[count] = utils_t.gen_combine(count)
    end
    scheme.all_combines = t
end
scheme.gen_all_combine()

function scheme.new(obj)
    local t = {}
    setmetatable(t, {__index = scheme, __tostring = utils_t.format_scheme})
    t:init(obj)
    return t
end

function scheme:init(obj)

    if not obj then error('obj == nil') return end
    if not obj.card then error('obj.card == nil') return end

    self.card = obj.card
    self.color = obj.color
    self.value = self.color * 10 + self.card
    self.magic = obj.magic or 0
    self.index = obj.index or 0
    self.count = obj.count or 0
    self.mark_count = self.count
    self.mark_magic = self.magic

    self.result_list = {}   -- 结果列表 {magic - 使用万能牌个数, count - 实际个数, type - 类型, mark_seq - 序列值}    
    
    assert(self.count > 0, 'self.count == 0')

    local gen_num = function(num)
        local result = {}
        for i = num, 3 do
            local n = num + 10 * (i - num)
            if n == 11 then
                table.insert(result, 111)
            end
            table.insert(result, n)
        end
        return result
    end

    local result_combine = {}
    for _, combine in ipairs(self.all_combines[self.count]) do
        local tb = {}
        local size = #combine
        local check_hash = {}       -- 检测重复加入   
        local magic_tb = {}
        if size > 1 and combine[size - 1] == 2 and combine[size] == 1 then
            table.insert(magic_tb, gen_num(2))
            table.insert(magic_tb, gen_num(1))
        elseif size > 1 and combine[size - 1] == 1 and combine[size] == 1 then
            table.insert(magic_tb, gen_num(1))
            table.insert(magic_tb, gen_num(1))
        elseif combine[size] == 2 then
            table.insert(magic_tb, gen_num(2))
        elseif combine[size] == 1 then
            table.insert(magic_tb, gen_num(1))
        end

        if #magic_tb > 0 then
            for _, v1 in ipairs(magic_tb[1]) do
                if #magic_tb == 2 then
                    for _, v2 in ipairs(magic_tb[2]) do
                        local tb = {}
                        local need_magic = 0
                        for i = 1, size - #magic_tb do
                            table.insert(tb, combine[i])
                        end
                        table.insert(tb, v1)
                        table.insert(tb, v2)
                        local need_magic = math.floor((v1 % 100) / 10) + math.floor((v2 % 100) / 10)
                        if self.magic >= need_magic then
                            if not check_hash[v1 * 0x11223344 + v2] then    -- 0x11223344 is magic number
                                check_hash[v1 * 0x11223344 + v2] = true
                                check_hash[v2 * 0x11223344 + v1] = true
                                table.insert(result_combine, tb)
                            end
                        end
                    end
                else
                    local tb = {}
                    for i = 1, size - #magic_tb do
                        table.insert(tb, combine[i])
                    end          
                    table.insert(tb, v1)
                    local need_magic = math.floor((v1 % 100) / 10)
                    if self.magic >= need_magic then
                        table.insert(result_combine, tb)
                    end
                end
            end
        else
            local tb = {}
            for _, num in ipairs(combine) do
                table.insert(tb, num)
            end
            table.insert(result_combine, tb)
        end
    end

    print("------------------- self.magic = " .. self.magic .. "-------------------------", self.card)    
    print_table(result_combine)

    self.combine = result_combine
end

return scheme