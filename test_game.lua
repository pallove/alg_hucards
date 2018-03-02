require 'utils.luautils'
require 'data.gameplay_define'

function gen_allcards()
    -- luautils.randomseed = 9876543210
    local t = {}
    for count = 1, 4 do
        for color = card_color.WAN,  card_color.TIAO do
            for num = 1, 9 do
                table.insert(t, color * 10 + num)
            end
        end
    end

    for count = 1, 4 do
        for color = card_color.FENG,  card_color.ZI do
            for num = 1, 4 do
                table.insert(t, color * 10 + num)
            end
        end
    end    

    return luautils.table_shuffle(t)
end

function test_handcard(times)

    local alg_hucards = require 'alg.alg_hucards'
    local utils_t = require 'alg.cards_utils'
    local handcards_t = require 'data.handcards_t'

    local record = {}
    local test_counts = {14, 11, 8, 5, 2}
    while times > 0 do
        for i, v in ipairs(test_counts) do
            local all_cards = gen_allcards()
            while #all_cards >= v do
                local handcards = handcards_t.new()
                handcards:clear()
                local cards = {}
                while #cards < v do
                    local card = table.remove(all_cards, 1)
                    table.insert(cards, card)
                end
                handcards:set_magics{31}
                handcards:set_cards(cards)

                local result = alg_hucards.check_handcards(handcards)
            end
        end
        times = times - 1
    end
end

function test_handcard1()

    local alg_hucards = require 'alg.alg_hucards'
    local utils_t = require 'alg.cards_utils'
    local handcards_t = require 'data.handcards_t'

    local handcards = handcards_t.new()
    handcards:set_magics{31}
    handcards:set_weaves({})
    handcards:set_cards{14, 14, 14, 14, 15, 15, 16, 16, 31, 31, 31}
    local result = alg_hucards.check_handcards(handcards)
    result:print()
end

function test_handcard2()
    
    local alg_hucards = require 'alg.alg_hucards'
    local utils_t = require 'alg.cards_utils'
    local handcards_t = require 'data.handcards_t'

    local handcards = handcards_t.new()
    -- handcards:set_magics{31}
    -- handcards:set_weaves({})
    -- handcards:set_cards{31, 31, 31, 31, 32, 32, 33, 33, 33, 37, 38, 39, 39, 39}
    -- handcards:set_cards{11, 11, 11, 11, 13, 14, 15, 16, 24, 24, 31, 31, 36, 37}
    -- handcards:set_cards{11, 11, 15, 15, 17, 18, 18, 26, 26, 31, 31, 31, 35, 39}
    handcards:set_cards{11, 12, 13, 31, 32, 33, 34, 35, 36, 41, 41}
    local result = alg_hucards.check_handcards(handcards)
    result:print()
end

function test_13yao()
    local alg_hucards = require 'alg.alg_hucards'
    local utils_t = require 'alg.cards_utils'
    local handcards_t = require 'data.handcards_t'

    local handcards = handcards_t.new()
    handcards:set_magics{41}
    handcards:set_cards{41, 42, 43, 44, 41, 51, 53, 52, 11, 14, 18, 21, 29, 24}
    -- handcards:set_cards{41, 41, 41, 41, 43, 43, 44, 44}
    local result = alg_hucards.check_handcards(handcards)
    result:print()    
end

-- test_handcard(10000)
-- test_13yao()
test_handcard1()
-- test_handcard1()
-- test_handcard2()