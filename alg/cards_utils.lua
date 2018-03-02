local utils = {}
local print = function() end

function utils.gen_color_numcard(colors)
    local t = {}
    for color, cards in pairs(colors) do
        local color_t = t[color] or {}
        for _, card in ipairs(cards) do
            local card_num = card % 10
            local num = color_t[card_num] or 0
            num = num + 1
            color_t[card_num] = num
        end
        t[color] = color_t
    end
    return t
end

function utils.check_pair_magicard(colors)
    local color_t = utils.gen_color_numcard(colors)
    local need_magic = 0
    for color, cards in pairs(color_t) do
        for num, count in pairs(cards) do
            need_magic = need_magic + (count % 2)
        end
    end

    return need_magic, color_t
end

function utils.format_card_value(value)
    if type(value) == 'table' then
        value = value.value
    end

    if value == card_value.MAGIC then
        return '[M]M'
    end

    local color = math.floor(value / 10)
    local num = value % 10
    return string.format('[%s]%d', string.sub('XWOTFZ', color + 1, color + 1), num)
end

function utils.format_handcards(v)
    v.player = v.player or 0
    local str = v.player .. " = ["
    if #v.hucards > 0 then
        str = str .. 'hu = {' .. table.concat(v.hucards, '-') .. '},'
    end
    
    if next(v.weaves, nil) then 
        str = str .. 'weave = {'
        local flag = true
        for _, weave in pairs(v.weaves) do
            str = (not flag and ',' or '') .. table.concat(weave, '-')
            flag = false
        end
        str = str + '},'
    end

    if #v.cards > 0 then
        local t = {}
        for _, card in luautils.table_value_pairs(v.cards, "id", function(a, b) return a  < b end) do
            table.insert(t, tostring(card))
        end
        str = str .. 'card = {' .. table.concat(t, '-') .. '},'
    end

    if #v.magics > 0 then
        local t = {}
        for _, card in ipairs(v.magics) do
            table.insert(t, utils.format_card_value(card))
        end    
        str = str .. 'magic = {' .. table.concat(t, ',') .. '}'
    end

    str = str .. ']'  

    return str  
end


function utils.gen_magic_count(colors, magic)
    magic = magic or 0

    local rest_cards = {}
    for color, cards in pairs(colors) do
        rest_cards[color] = {color = color, count = #cards, need_magic = 0}
    end

    local has_two = false
    for color, v in luautils.table_value_pairs(rest_cards, "count", function(a, b) return a % 3 > b % 3 end) do
        local count = v.count % 3
        local need_magic = 0
        if count == 0 then
            if not has_two then
                has_two = true
                need_magic = 2
            end
        elseif count == 1 then
            if not has_two then
                has_two = true
                need_magic = 1
            else
                need_magic = 2
            end
        else 
            if not has_two then
                has_two = true
            else
                need_magic = 1
            end
        end
        magic = magic - need_magic
        v.need_magic = need_magic
    end

    if magic < 0 then return false, magic end

    local result = has_two and 2 or 0
    if result + magic % 3 ~= 2 then return false, magic end

    return true, magic
end

function utils.gen_combine(count)
    local three_num = math.floor(count / 3)
    local rest_count = count % 3

    local combine = {}
    local tb = {}
    if three_num > 0 then
        for i = 1, three_num do
            table.insert(tb, 3)
        end
        if rest_count == 0 then
            table.insert(combine, tb)
        end
    end

    local rest_tb = luautils.table_copy(tb)
    if rest_count > 0 then
        table.insert(rest_tb, rest_count)
        table.insert(combine, rest_tb)
    else
        rest_tb[#rest_tb] = 2
        table.insert(rest_tb, 1)
        table.insert(combine, rest_tb)

        --- 3 ---> 1-1-1
        local rest_tb_3x1 = luautils.table_copy(tb)
        rest_tb_3x1[#rest_tb_3x1] = 1
        table.insert(rest_tb_3x1, 1)
        table.insert(rest_tb_3x1, 1)
        table.insert(combine, rest_tb_3x1)
    end

    if rest_count == 2 then
        local rest_two_tb = luautils.table_copy(tb)
        table.insert(rest_two_tb, 1)
        table.insert(rest_two_tb, 1)

        table.insert(combine, rest_two_tb)
    end

    if count >= 4 and count % 2 == 0 then
        local two_tb = {}
        for i = 1, count / 2 - 1 do
            table.insert(two_tb, 2)
        end
        table.insert(two_tb, 1)
        table.insert(two_tb, 1)
        table.insert(combine, two_tb)
    end

    return combine
end

function utils.format_scheme(v)
    return '{' .. utils.format_card_value(v.value) .. ", magic = " .. v.magic .. ', count = ' .. v.count .. ', index = ' .. v.index .. '}'
end

function utils.format_result(v)
    -- local tb = {magic = leftmagic, seq_count = 0, three_count = 0, pair_count = 0, result = {}}
    local str = string.format('result[%d] = {magic=%d, seq_count=%d, three_count=%d, pair_count=%d, card='
        , v.index
        , v.magic
        , v.seq_count
        , v.three_count
        , v.pair_count)

    local all_t = {}
    for _, value in ipairs(v.result) do
        local t = {}
        for _, value_ in ipairs(value) do
            table.insert(t, utils.format_card_value(value_))
        end
        table.insert(all_t, table.concat(t, '-'))
    end
    str = str .. '(' .. table.concat(all_t, ',') .. ')}'

    return str
end

return utils