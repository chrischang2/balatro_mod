--- STEAMODDED HEADER
--- MOD_NAME: Score Calculator Button
--- MOD_ID: ScoreCalcButton
--- MOD_AUTHOR: [chrischang2]
--- MOD_DESCRIPTION: Adds a button to calculate and display the current hand score

SMODS.current_mod.process_loc_text = function()
    G.localization.misc.dictionary.b_calculate_score = "Calculate Score"
end

local calculated_score = 0
local score_text = ""

-- Button callback function
G.FUNCS.calculate_score_button = function(e)
    if not G or not G.hand or not G.hand.cards then
        return
    end
    
    -- Get highlighted cards
    local scoring_hand = {}
    for k, v in ipairs(G.hand.cards) do
        if v.highlighted then
            table.insert(scoring_hand, v)
        end
    end
    
    if #scoring_hand == 0 then
        play_sound('button')
        card_eval_status_text(e.config.ref_table, 'extra', nil, nil, nil, {
            message = "Select cards first!",
            colour = G.C.RED,
            instant = true
        })
        return
    end
    
    -- Calculate score using game's scoring function
    local text, poker_hands, scoring_cards = G.FUNCS.get_poker_hand_info(scoring_hand)
    
    local chips = 0
    local mult = 0
    
    if poker_hands and #poker_hands > 0 then
        local hand_type = poker_hands[1]
        
        -- Get base chips and mult for this hand
        if G.GAME and G.GAME.hands and G.GAME.hands[hand_type] then
            chips = G.GAME.hands[hand_type].chips or 0
            mult = G.GAME.hands[hand_type].mult or 0
        end
        
        -- Add card chips
        for _, card in ipairs(scoring_cards) do
            if card.ability then
                chips = chips + (card.ability.bonus or 0)
            end
            if card.base and card.base.nominal then
                local card_chips = 0
                if card.base.nominal == 'Ace' then card_chips = 11
                elseif card.base.nominal == 'King' then card_chips = 10
                elseif card.base.nominal == 'Queen' then card_chips = 10
                elseif card.base.nominal == 'Jack' then card_chips = 10
                else card_chips = tonumber(card.base.nominal) or 0
                end
                chips = chips + card_chips
            end
        end
    end
    
    local final_score = chips * mult
    calculated_score = final_score
    
    play_sound('button')
    card_eval_status_text(e.config.ref_table, 'extra', nil, nil, nil, {
        message = "Score: " .. number_format(final_score),
        colour = G.C.CHIPS,
        instant = true
    })
end

-- Add button to the play buttons
local start_run_ref = Game.start_run
function Game:start_run(args)
    local result = start_run_ref(self, args)
    
    -- Add our button function to the UI buttons
    if G.FUNCS and not G.FUNCS.original_play_cards_from_highlighted then
        G.FUNCS.original_play_cards_from_highlighted = G.FUNCS.play_cards_from_highlighted
    end
    
    return result
end

-- Inject button into play UI
local create_UIBox_buttons_ref = create_UIBox_buttons
function create_UIBox_buttons()
    local result = create_UIBox_buttons_ref()
    
    -- Add our calculate button
    if G and G.STATE == G.STATES.SELECTING_HAND then
        table.insert(result.nodes[1].nodes, {
            n = G.UIT.C,
            config = {align = "cr", padding = 0.1, r = 0.15, emboss = 0.1, colour = G.C.BLUE, button = "calculate_score_button", hover = true, shadow = true},
            nodes = {
                {n = G.UIT.T, config = {text = "Calc Score", scale = 0.4, colour = G.C.UI.TEXT_LIGHT}}
            }
        })
    end
    
    return result
end
