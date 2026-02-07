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
    
    -- Get highlighted cards
    local highlighted_cards = {}
    for k, v in ipairs(G.hand.cards) do
        if v.highlighted then
            table.insert(highlighted_cards, v)
        end
    end
    
    if #highlighted_cards == 0 then
        play_sound('button')
        card_eval_status_text(e.config.ref_table or G.play, 'extra', nil, nil, nil, {
            message = "Select cards first!",
            colour = G.C.RED
        })
        return
    end
    
    -- Use the actual game's scoring function (without side effects)
    local hand_chips, mult, final_score, text, disp_text = G.FUNCS.calculate_hand_score_only(highlighted_cards)
    
    calculated_score = final_score
    
    if final_score == 0 then
        play_sound('chips1')
        card_eval_status_text(e.config.ref_table or G.play, 'extra', nil, nil, nil, {
            message = "Debuffed! Score: 0",
            colour = G.C.RED
        })
    else
        play_sound('chips1')
        card_eval_status_text(e.config.ref_table or G.play, 'extra', nil, nil, nil, {
            message = disp_text .. ": " .. number_format(hand_chips) .. " X " .. number_format(mult) .. " = " .. number_format(final_score),
            colour = G.C.MULT
        })
    end
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
