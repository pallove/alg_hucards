local utils_t = require 'alg.cards_utils'

local handcards = {}

function handcards.new(obj)
    local t = {}
    setmetatable(t, {__index = handcards, __tostring = utils_t.format_handcards})
    t:init(obj)

    return t
end

function handcards:init(obj)
    if self.has_init then error('handcards has init!!!!') end
    self.has_init = true

    self:clear()
end

function handcards:clear()
    self.weaves = {}
    self.cards = {}
    self.colors = {}
    self.magics = {}
    self.magic_values = {}
    self.magic_count = 0
end

function handcards:is_magic(card)
    for _, v in ipairs(self.magics) do
        if card == v then
            return true
        end
    end

    return false
end

function handcards:set_magics(magics)
    self.magics = magics
end

function handcards:insert_card(color, value, only_normal)

    if not only_normal and self:is_magic(value) then
        self.magic_count = self.magic_count + 1
        table.insert(self.magic_values, value)        
    else
        local color_tb = self.colors[color] or {}
        self.colors[color] = color_tb
        table.insert(color_tb, value)
    end

    table.insert(self.cards, value)    
end


function handcards:remove_card(value, only_normal)

    if value > 0 then
        local is_magic = self:is_magic(value)
        if is_magic and not only_normal then
            self.magic_count = self.magic_count - 1
            luautils.array_remove(self.magic_values, value)
        else
            local color = math.floor(value / 10)
            local color_tb = self.colors[color]
            assert(color_tb)

            luautils.array_remove(color_tb, value)
        end
    else
        local color_tb = self.colors[card_color.WAN]
        assert(color_tb)
        luautils.array_remove(color_tb, value)
    end

    luautils.array_remove(self.cards, value)        
    table.sort(self.cards)
end

function handcards:set_cards(cards)
    for _, card in ipairs(cards) do
        self:insert_card(math.floor(card / 10), card)
    end
end

function handcards:set_weaves(weaves)
    self.weaves = weaves
end

function handcards:has_color(color)
    local t = self.colors[color]
    if t and #t > 0 then
         return true
    end

    return false
end

function handcards:has_weave()
    return next(self.weaves, nil) ~= nil
end

function handcards:count()
    return #self.cards
end

function handcards:is_outcard()
    return self:count() % 3 == 2
end

function handcards:has_feng_zi_seq()
    return true
end

return handcards