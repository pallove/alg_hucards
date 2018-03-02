local scheme_t = require 'data.huscheme_t'
local result_t = require 'data.huresult_t'
local utils_t = require 'alg.cards_utils'

local table_next = luautils.table_next
local table_keys = luautils.table_keys
local print = function() end
local print_table = function() end --luautils.print_table
local alg_hucards = {}

--[[
    检查刻子
]]
function alg_hucards.check_three(scheme, cards_info)
    local cards = cards_info.cards
    local card = scheme.card
    print('check_three:' .. card)

    return true
end

--[[
    检查对子
]]
function alg_hucards.check_pair(scheme, cards_info)
    local cards = cards_info.cards
    local card = scheme.card
    result = not cards_info:has_two()
    print('check_pair:' .. card, 'result:' .. tostring(result))

    return result
end

--[[
    检查顺子
]]
function alg_hucards.check_sequence(scheme, use_magic, cards_info)
    --- 回避风字牌参与顺子
    local color = cards_info.color
    local is_fengzi = false
    local has_feng_zi_seq = cards_info.feng_zi_seq
    if color == card_color.FENG or color == card_color.ZI then
        is_fengzi = true
        if not has_feng_zi_seq then 
            return false
        end
    end

    local is_used_magic = false
    local cards = cards_info.cards
    local card = scheme.card
    print('check_sequence:' .. card)

    local result = true
    local mark_seq = {}
    local seq_card = card

    local end_num = 9
    local plus_to = 2
    local step_count = 1
    if is_fengzi and has_feng_zi_seq then
        end_num = 4
        plus_to = 3
        step_count = 2
    end

    local rest_num = end_num - card
    if rest_num < 2 then
        seq_card = card - rest_num
    end

    for v = seq_card, seq_card + plus_to do
        if cards[v] and cards[v] > 0 then      
            table.insert(mark_seq, v)
            if #mark_seq == 3 then
                break
            end                
        else
            if use_magic > 0 then
                is_used_magic = true
                use_magic = use_magic - 1
            else
                step_count = step_count - 1
                if step_count == 0 then
                    result = false
                    break
                end
            end
        end
    end

    return result, mark_seq, is_used_magic
end

--[[
    检查组合
]]
function alg_hucards.check_combine(scheme, combine, cards_info)

    local cards = cards_info.cards
    local leftmagic = cards_info.leftmagic

    local total_magic = 0
    local result = true
    local card = scheme.card
    local removelist_final = {}

    scheme.result_list = {}
    for i, v in ipairs(combine) do
        local result_ = {}
        local removelist = {[card] = 0}

        local force_seq = v > 100
        v = v % 100
        local use_magic = math.floor(v / 10)
        local count = v % 10 + (force_seq and 0 or use_magic)

        if count == 1 then
            local flag, mark_seq, is_used_magic = alg_hucards.check_sequence(scheme, use_magic, cards_info)
            if flag then
                -- 消耗值
                for _, v in ipairs(mark_seq) do
                    removelist[v] = removelist[v] and removelist[v] + 1 or 1
                end 

                result_.type = scheme_type.SEQUENCE
                result_.mark_seq = mark_seq 
                if use_magic > 0 and not is_used_magic then
                    use_magic = 0
                    flag = false
                end
            end
            result = flag
        elseif count == 2 then
            result = alg_hucards.check_pair(scheme, cards_info)
            if result then
                result_.type = scheme_type.PAIR
                result_.count = 2 - use_magic
                removelist[card] = removelist[card] + result_.count
            end

        elseif count == 3 then
            result = alg_hucards.check_three(scheme, cards_info)
            result_.count = 3 - use_magic
            removelist[card] = removelist[card] + result_.count

            result_.type = scheme_type.THREE
        end

        if result then 
            total_magic = total_magic + use_magic
            result_.magic = use_magic
            table.insert(scheme.result_list, result_)

            for card, count in pairs(removelist) do
                removelist_final[card] = removelist_final[card] and removelist_final[card] + count or count
                cards[card] = cards[card] - count
            end            
        else
            break
        end
    end

    if result then
        scheme.magic = total_magic
        cards_info.leftmagic = cards_info.leftmagic - total_magic

        for _, v in ipairs(scheme.result_list) do
            if v.type == scheme_type.SEQUENCE then
                cards_info.seq_count = cards_info.seq_count + 1
            elseif v.type == scheme_type.PAIR then
                cards_info.pair_count = cards_info.pair_count + 1
            elseif v.type == scheme_type.THREE then
                cards_info.three_count = cards_info.three_count + 1
            end
        end        
    else
        -- 如果检测失败，还原牌数量
        scheme.magic = 0
        scheme.result_list = {}
        -- 还原
        for card, count in pairs(removelist_final) do
            cards[card] = cards[card] + count
        end
    end

    return result
end

--[[
    检查夹张
]]
function alg_hucards.check_interval(cards)
    local prev_card = 0
    for _, card in luautils.table_value_pairs(cards) do
        if card - prev_card > 2 then
            prev_card = card
        else
            return false
        end
    end
    return true
end

--[[
    检查某张牌的方案
]]
function alg_hucards.check_scheme(scheme, cards_info)
    --- 检测组合
    local cards = cards_info.cards
    local result = false
    local now_index = scheme.index + 1
    -- 检测index
    for index = now_index, #scheme.combine do
        local combine = scheme.combine[index]
        result = alg_hucards.check_combine(scheme, combine, cards_info)
        if result then
            scheme.index = index
            break
        end
    end

    print(string.format("check_scheme: result=%s, card=%d, count=%d, now_index=%d, combine_size=%d"
            , result and 'true' or 'false', scheme.card, cards[scheme.card], scheme.index, #scheme.combine))

    return result
end

--[[
    生成某张牌的组合方案 
]]
function alg_hucards.gen_scheme(card, color_info)
    local num = color_info.cards[card]
    if num == 0 then return nil end

    print("card:", card, "num:", num)
    return scheme_t.new{card = card, count = num, color = color_info.color, magic = color_info.leftmagic}
end

function alg_hucards.check_color(result, color, magic, has_pair)

    -- 检测方案
    local color_info = result:get_color(color)
    color_info:reset()
    color_info.leftmagic = magic
    color_info.has_pair = has_pair

    print(string.format('-----------------------alg_hucards.check_color = %d, has_pair = %s, magic = %d-----------------------', color, tostring(has_pair), magic))

    -- 检测方案
    local check_result = true
    local scheme = color_info:pop_scheme()    -- 弹出一个方案

    local tb_next = table_next(color_info.cards)
    local card = scheme and scheme.card or tb_next()    

    while card do
        color_info:print()
        scheme = scheme or alg_hucards.gen_scheme(card, color_info)             
        if scheme then
            local result = alg_hucards.check_scheme(scheme, color_info)
            if result then
                color_info:push_scheme(scheme)
                if color_info:is_empty() then
                    color_info:save_list()
                    scheme = color_info:pop_scheme()    
                else
                    scheme = nil
                    card = tb_next(card)
                end            
            else
                scheme = color_info:pop_scheme()
                if scheme then 
                    card = scheme.card
                else
                    break                
                end                    
            end
        else
            card = tb_next(card)
        end
    end

    return color_info:has_save_list()
end

function alg_hucards.check_fullpair(handcards, result)
    if handcards:count() ~= handcards_define.CARD_SIZE then return end
    if handcards:has_weave() then return end

    local need_magic, color_t = utils_t.check_pair_magicard(handcards.colors)
    local leftmagic = handcards.magic_count - need_magic
    if leftmagic >= 0 and leftmagic % 2 == 0 then
        -- 保存牌形
        result:save_fullpair(color_t, leftmagic)
    end
end

function alg_hucards.check_fullmagic(handcards, result)
    local tb_next = table_next(result.colors)
    local next_color, color_item = tb_next()
    if not next_color then
        result:save_fullmagic(result.magic)
    end      
end

function alg_hucards.check_13yao(handcards, result)
    if handcards:count() ~= handcards_define.CARD_SIZE then return end
    if handcards:has_weave() then return end

    local colors = handcards.colors
    for _, v in pairs(colors) do
        if not luautils.array_is_unique(v) then return end
    end

    -- 如果万筒条有一色大于3张
    for color = card_color.WAN, card_color.TIAO do
        if colors[color] and #colors[color] > 3 then return end
    end

    local feng_count = colors[card_color.FENG] and #colors[card_color.FENG] or 0
    local zi_count = colors[card_color.ZI] and #colors[card_color.ZI] or 0
    --- 最少5张风字牌
    if handcards.magic_count + feng_count + zi_count < 5 then return end

    --- 只是检查万筒条
    for color = card_color.WAN, card_color.TIAO do
        if colors[color] and not alg_hucards.check_interval(colors[color]) then
            return
        end
    end
    --- 保存牌形
    result:save_13yao(handcards.magic_count)
end


function alg_hucards.check_normal(handcards, result)

    local tb_next = table_next(result.colors)
    print_table(handcards)
    function check_result(next_color, color_item, magic, has_pair, save_list)
        print(string.format('print_color - color=%d, leftmagic=%d, has_pair:%s', next_color, magic, tostring(has_pair)))
        if alg_hucards.check_color(result, next_color, magic, has_pair) then
            
            local result_list = color_item.result_list
            next_color, color_item = tb_next(next_color)

            for index, save_tb in ipairs(result_list) do
                table.insert(save_list, save_tb)
                
                magic = save_tb.leftmagic
                has_pair = save_tb.has_pair
                
                if #save_list == result.color_size then
                    local success = false
                    local magic_rest = magic % 3
                    if magic_rest == 2 and not has_pair then
                        success = true
                    elseif magic_rest == 0 and has_pair then
                        success = true
                    end
                    if success then
                        -- 保存牌形
                        result:save(save_list, magic)    
                    end
                else
                    if next_color then
                        check_result(next_color, color_item, magic, has_pair, save_list)
                    end
                end

                -- 弹出一个值
                save_list[#save_list] = nil
            end
        end
    end

    local next_color, color_item = tb_next()
    if next_color then
        local save_tb_list = {}
        check_result(next_color, color_item, result.magic, false, save_tb_list)
    end    
end

function alg_hucards.check_handcards(handcards, rules)
    assert(handcards:is_outcard(), 'must be out card player')
    
    local result = result_t.new(handcards)

    alg_hucards.check_fullpair(handcards, result)
    alg_hucards.check_fullmagic(handcards, result)
    alg_hucards.check_13yao(handcards, result)
    alg_hucards.check_normal(handcards, result)

    return result
end

return alg_hucards