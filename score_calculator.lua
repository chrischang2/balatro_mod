--- STEAMODDED HEADER
--- MOD_NAME: Score Calculator Button
--- MOD_ID: ScoreCalcButton
--- MOD_AUTHOR: [chrischang2]
--- MOD_DESCRIPTION: Adds a separate button to calculate and display the current hand score

local calculated_score = 0

-- Button callback function
G.FUNCS.calculate_score_button = function(e)
    if not G or not G.hand or not G.hand.cards then
        return
    end
    
    -- Get highlighted cards (simulate them being in G.play)
    local scoring_hand = {}
    local simulated_play = {}
    for k, v in ipairs(G.hand.cards) do
        if v.highlighted then
            table.insert(simulated_play, v)
        end
    end
    
    if #simulated_play == 0 then
        play_sound('button')
        card_eval_status_text(e.config.ref_table or G.play, 'extra', nil, nil, nil, {
            message = "Select cards first!",
            colour = G.C.RED
        })
        return
    end
    
    -- Use the game's actual poker hand detection
    local text, disp_text, poker_hands, scoring_hand, non_loc_disp_text = G.FUNCS.get_poker_hand_info(simulated_play)
    
    -- Start with base hand values
    local mult = mod_mult(G.GAME.hands[text].mult)
    local hand_chips = mod_chips(G.GAME.hands[text].chips)
    
    -- Check if hand is debuffed
    if G.GAME.blind:debuff_hand(simulated_play, poker_hands, text) then
        play_sound('chips1')
        card_eval_status_text(e.config.ref_table or G.play, 'extra', nil, nil, nil, {
            message = "Debuffed! Score: 0",
            colour = G.C.RED
        })
        return
    end
    
    -- Add stone cards to scoring hand (like the real function does)
    local pures = {}
    for i=1, #simulated_play do
        if next(find_joker('Splash')) then
            scoring_hand[i] = simulated_play[i]
        else
            if simulated_play[i].ability.effect == 'Stone Card' then
                local inside = false
                for j=1, #scoring_hand do
                    if scoring_hand[j] == simulated_play[i] then
                        inside = true
                    end
                end
                if not inside then table.insert(pures, simulated_play[i]) end
            end
        end
    end
    for i=1, #pures do
        table.insert(scoring_hand, pures[i])
    end
    
    -- Calculate card chips and mults (simplified version of game logic)
    for i=1, #scoring_hand do
        if not scoring_hand[i].debuff then
            -- Get base card effects
            local effects = {eval_card(scoring_hand[i], {cardarea = G.play, full_hand = simulated_play, scoring_hand = scoring_hand, poker_hand = text})}
            
            -- Add joker individual card effects
            for k=1, #G.jokers.cards do
                local eval = G.jokers.cards[k]:calculate_joker({cardarea = G.play, full_hand = simulated_play, scoring_hand = scoring_hand, scoring_name = text, poker_hands = poker_hands, other_card = scoring_hand[i], individual = true})
                if eval then 
                    table.insert(effects, eval)
                end
            end
            
            -- Apply effects
            for ii = 1, #effects do
                if effects[ii].chips then 
                    hand_chips = mod_chips(hand_chips + effects[ii].chips)
                end
                if effects[ii].mult then 
                    mult = mod_mult(mult + effects[ii].mult)
                end
                if effects[ii].x_mult then 
                    mult = mod_mult(mult*effects[ii].x_mult)
                end
            end
        end
    end
    
    -- Calculate joker main effects
    for i=1, #G.jokers.cards do
        local effects = eval_card(G.jokers.cards[i], {cardarea = G.jokers, full_hand = simulated_play, scoring_hand = scoring_hand, scoring_name = text, poker_hands = poker_hands, joker_main = true})
        if effects.jokers then 
            if effects.jokers.mult_mod then mult = mod_mult(mult + effects.jokers.mult_mod) end
            if effects.jokers.chip_mod then hand_chips = mod_chips(hand_chips + effects.jokers.chip_mod) end
            if effects.jokers.Xmult_mod then mult = mod_mult(mult*effects.jokers.Xmult_mod) end
        end
    end
    
    -- Final score
    local final_score = hand_chips * mult
    calculated_score = final_score
    
    play_sound('chips1')
    card_eval_status_text(e.config.ref_table or G.play, 'extra', nil, nil, nil, {
        message = number_format(hand_chips) .. " X " .. number_format(mult) .. " = " .. number_format(final_score),
        colour = G.C.MULT
    })
end

-- Hook into update_selecting_hand to create our button
local update_selecting_hand_ref = Game.update_selecting_hand
function Game:update_selecting_hand(dt)
    -- Create our button if it doesn't exist
    if not self.calc_score_button then
        self.calc_score_button = UIBox{
            definition = {
                n = G.UIT.ROOT,
                config = {align = "cm", padding = 0.1},
                nodes = {
                    {
                        n = G.UIT.R,
                        config = {align = "cm", padding = 0.1},
                        nodes = {
                            UIBox_button{
                                label = {"Calculate Score"},
                                button = "calculate_score_button",
                                colour = G.C.GREEN,
                                minw = 3,
                                minh = 1,
                                scale = 0.5
                            }
                        }
                    }
                }
            },
            config = {align = "tm", offset = {x = 0, y = -0.5}, major = self.hand, bond = 'Weak'}
        }
    end
    
    -- Make sure button is visible
    if self.calc_score_button and not self.calc_score_button.states.visible then
        self.calc_score_button.states.visible = true
    end
    
    -- Call original function
    update_selecting_hand_ref(self, dt)
end

-- Hide button when leaving the selecting hand state
local set_current_state_ref = Game.set_current_state
function Game:set_current_state(state)
    if state ~= G.STATES.SELECTING_HAND and self.calc_score_button then
        if self.calc_score_button.states then
            self.calc_score_button.states.visible = false
        end
    end
    return set_current_state_ref(self, state)
end
