# alg_hucards

lua版的麻将牌的胡牌算法，适用于当下所有麻将的胡牌与听牌，给出可胡牌的牌型。以下特别说明：
    1. 能做什么：手牌中万能牌张数不限，针对七对，13幺，平胡基本胡牌牌型，输出胡牌结果
    2. 不能做什么：对于胡牌类型，算法不做涉及，只会给出是否胡的结果。如：给出胡七对子，但是龙七对，暗七对需要拿到七对结果进一步处理。
    3. 万能牌：不同地方叫法不一样，算法里统一叫万能牌，对手牌中万能牌数量不限，算法也不会因为万能牌多少性能有太大的波动
    4. 听牌（报叫）：由于可以随意将某张手牌换成万能牌，亦是支持的
    5. 风字牌：东南西北中发白，有地方会让东南西北任意三张牌做为一铺牌，算法里有开关：has_feng_zi_seq(), 具体自行打开关闭

# 具体使用
    参考：test_game.lua
    local handcards = handcards_t.new()     
    handcards:set_magics{31, 32}        -- 将手牌内的所有一条，二条设为万能牌
    handcards:set_weaves{}              -- 设定是否有碰杠吃牌堆, 用于七对判断
    handcards:set_cards{31, xx, ...}    -- 设定手牌内容 
    local result = alg_hucards.check_handcards(handcards) -- 得到胡牌结果     

    输出说明：
    result[1] = {magic=2, seq_count=2, three_count=1, pair_count=0, card=([W]4-[W]4-[W]4,[W]4-[W]5-[W]6,[W]5-[W]6-[M]M)}
    result[2] = {magic=0, seq_count=1, three_count=2, pair_count=1, card=([W]4-[W]4-[W]4,[W]4-[W]5-[W]6,[W]5-[M]M,[W]6-[M]M-[M]M)}
    magic=2, 是在胡牌牌配完之后，还剩下的万能牌数量，为n*3+2或0，示例说明可做将
    seq_count=2, 指顺子个数
    three_count=1, 三张相同的个数
    pair_count=0, 将牌数量，如果大于1，则为七对。
    card=(...)， 这是牌型结果, [WOTFZM][1-9M], 一张牌可分为两部分理解，花色-牌值。[WOTFZM]分别是：万筒条风字万能，[1-9M]为1-9[万筒条],M为万能，东南西北[1-4], 中发白[1-3], [W]4意思为四万

# 补充
    算法已在公司多个产品（重庆，四川）上运行数月，可放心使用。
    如有进一步想法，可提出宝贵意见。


