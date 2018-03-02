local utils_t = require 'alg.cards_utils'
local result = {}
local result_item = {}
local print_r = print
local print = function() end

function result.new(handcards)
    local t = {}
    setmetatable(t, {__index = result})
    t:init(handcards)
    return t
end

function result:init(handcards)
    self.magic = handcards.magic_count
    self.weave = handcards.weaves or {}
    self.save_list = {}
    local less_count_t, rest_magic = utils_t.gen_magic_count(handcards.colors, handcards.magic_count)
    self.colors, self.color_size = self:gen_color(utils_t.gen_color_numcard(handcards.colors), handcards:has_feng_zi_seq())
end

function result:gen_color(colors, feng_zi_seq)
    local t = {}
    local size = 0
    for color, color_t in pairs(colors) do
        if next(color_t) then
            size = size + 1
            t[color] = result_item.new{cards = color_t, color = color, feng_zi_seq = feng_zi_seq}
        end
    end
    return t, size
end

function result:push_scheme(scheme)
    t[scheme.color]:push_scheme(scheme)
end

function result:pop_scheme()
    return t[scheme.color]:pop_scheme() 
end

function result:has_weave()
    return next(self.weaves, nil) ~= nil
end

function result:get_color(color)
    return self.colors[color]
end

function result:save(list, leftmagic)
    print('-------------- result:save-----------')
    local tb = {index = #self.save_list + 1, hash_value = hash_value, magic = leftmagic, seq_count = 0, three_count = 0, pair_count = 0, result = {}}
    for _, v in ipairs(list) do
        tb.seq_count = tb.seq_count + v.seq_count
        tb.three_count = tb.three_count + v.three_count
        tb.pair_count = tb.pair_count + v.pair_count

        local get_cardvalue = function(value)
            return v.color * 10 + value
        end

        for _, scheme in ipairs(v.scheme_list) do
            print(string.format('color=%d, scheme=%s', v.color, utils_t.format_scheme(scheme)))
            for _, result_ in ipairs(scheme.result_list) do
                local t = {}
                if result_.type == scheme_type.SEQUENCE then
                     for _, v_ in ipairs(result_.mark_seq) do
                        table.insert(t, get_cardvalue(v_))
                     end
                else
                    for i = 1, result_.count do
                        table.insert(t, get_cardvalue(scheme.card))
                    end
                end
                for i = 1, result_.magic do
                    table.insert(t, card_value.MAGIC)
                end
                table.insert(tb.result, t)
            end
        end
    end

    print(utils_t.format_result(tb))

    -- 保存到结果
    table.insert(self.save_list, tb)
end

function result:save_fullmagic(leftmagic)
    print('-------------- result:save_fullmagic-----------')
    leftmagic = leftmagic - 2
    local three_count = math.floor(leftmagic / 3)

    local tb = {index = #self.save_list + 1, magic = 0, seq_count = 0, three_count = three_count, pair_count = 1, result = {}}
    table.insert(tb.result, {card_value.MAGIC, card_value.MAGIC})
    for i = 1, three_count do
        local t = {}
        for i = 1, 3 do
            table.insert(t, card_value.MAGIC)
        end
        table.insert(tb.result, t)
    end

    table.insert(self.save_list, tb)
end

function result:save_fullpair(pair_tb, leftmagic)
    print('-------------- result:save_fullpair-----------')
    local tb = {index = #self.save_list + 1, magic = leftmagic, seq_count = 0, three_count = 0, pair_count = 0, result = {}}

    for color, color_t in pairs(pair_tb) do
        for num, count in pairs(color_t) do
            local value = color * 10 + num
            for i = 1, count do
                if i % 2 == 0 then
                    table.insert(tb.result, {value, value})
                end
            end
            if count % 2 == 1 then
                table.insert(tb.result, {value, card_value.MAGIC})
            end
            tb.pair_count = tb.pair_count + math.ceil(count / 2)
        end
    end 
    tb.pair_count = tb.pair_count + math.floor(leftmagic / 2)

    print(utils_t.format_result(tb))

    -- 保存到结果
    table.insert(self.save_list, tb)
end

function result:save_13yao(leftmagic)
    print('-------------- result:save_13yao-----------')
    local tb = {index = #self.save_list + 1, magic = leftmagic, is_13_yao = true, seq_count = 0, three_count = 0, pair_count = 0, result = {}}
    for color, color_item in pairs(self.colors) do
        local color_tb = {}
        for card in luautils.table_key_pairs(color_item.cards) do
            table.insert(color_tb, color * 10 + card)
        end
        table.insert(tb.result, color_tb)
    end
    table.insert(self.save_list, tb)
end

function result:get_result()
    return self.save_list
end

function result:print()
    for index, tb in ipairs(self.save_list) do
        print_r(utils_t.format_result(tb))
    end
end

----------------------------------------------------------
function result_item.new(obj)
    local t = {}
    setmetatable(t, {__index = result_item})
    t:init(obj)
    return t    
end

function result_item:init(obj)
    self.copy_cards = obj.cards
    self.color = obj.color
    self.feng_zi_seq = obj.feng_zi_seq

    self:reset()
end

function result_item:reset()

    self.cards = luautils.table_rcopy(self.copy_cards)
    self.has_pair = false
    self.pair_count = 0
    self.seq_count = 0
    self.three_count = 0
    self.leftmagic = 0
    self.use_less_magic = 99

    self.scheme_list = {}
    self.result_list = {}
end

function result_item:is_empty()
    assert(self.leftmagic >= 0, "leftmagic < 0, self.color = " .. self.color)

    local total = 0
    for _, num in pairs(self.cards) do
        total = total + num
    end
    return total == 0 and self.leftmagic >= 0
end

function result_item:push_scheme(scheme)
    table.insert(self.scheme_list, scheme)
    print(string.format("push_scheme: ====> scheme=%s, summary.seq=%d, summary.pair=%d, summary.three=%d, leftmagic=%d", tostring(scheme), self.seq_count, self.pair_count, self.three_count, self.leftmagic))    
end

function result_item:print()
    index = index or 0
    local tb = {}
    for k, v in luautils.table_key_pairs(self.cards) do
        table.insert(tb, string.format('[%d] = %d', k, v))
    end
    print('self.cards = {' .. table.concat(tb, ',') .. '}')
end

function result_item:pop_scheme()
    local scheme = table.remove(self.scheme_list, #self.scheme_list)
    if scheme then

        local card = scheme.card
        for i, v in ipairs(scheme.result_list) do
            --- 如果是顺子        
            if v.type == scheme_type.SEQUENCE then
                local mark_seq = v.mark_seq
                if not mark_seq then error('not found mark_seq in pop_scheme:' .. tostring(scheme)) end
                for _, seq_card in ipairs(mark_seq) do
                    self.cards[seq_card] = self.cards[seq_card] + 1
                end
            else
                local combine = scheme.combine[scheme.index]
                self.cards[card] = self.cards[card] + v.count
            end

            if v.type == scheme_type.SEQUENCE then
                self.seq_count = self.seq_count - 1
            elseif v.type == scheme_type.PAIR then
                self.pair_count = self.pair_count - 1
            elseif v.type == scheme_type.THREE then
                self.three_count = self.three_count - 1
            end
        end

        -- 还原magic
        self.leftmagic = self.leftmagic + scheme.magic
        scheme.magic = 0

        print(string.format("pop_scheme: <==== scheme=%s, summary.seq=%d, summary.pair=%d, summary.three=%d, leftmagic=%d", tostring(scheme), self.seq_count, self.pair_count, self.three_count, self.leftmagic))
    end

    return scheme
end

function result_item:save_list()

    local save_tb = {}
    save_tb.color = self.color
    save_tb.pair_count = self.pair_count
    save_tb.seq_count = self.seq_count
    save_tb.three_count = self.three_count
    save_tb.leftmagic = self.leftmagic
    save_tb.scheme_list = luautils.table_rcopy(self.scheme_list)
    save_tb.has_pair = self:has_two()

    print(string.format('---------------- save_list:%d, leftmagic:%d, pair:%s ---------------', self.color, self.leftmagic, tostring(self:has_two())))
    for _, scheme in pairs(save_tb.scheme_list) do
        print(utils_t.format_scheme(scheme))
    end
    print(string.format('---------------- save_list:%d --------------------', self.color))

    table.insert(self.result_list, save_tb)
    
end

function result_item:has_save_list()
    return #self.result_list > 0
end

function result_item:has_two()
    return self.has_pair or self.pair_count > 0
end

return result