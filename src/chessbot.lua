local chessbot = {}

local realchess = xdecor.chess

-- Delay in seconds for a bot moving a piece (excluding choosing a promotion)
local BOT_DELAY_MOVE = 1.0
-- Delay in seconds for a bot promoting a piece
local BOT_DELAY_PROMOTE = 1.0

local function best_move(moves)
	local value, choices = 0, {}

	for from, _ in pairs(moves) do
	for to, val in pairs(_) do
		if val > value then
			value = val
			choices = {{
				from = from,
				to = to
			}}
		elseif val == value then
			choices[#choices + 1] = {
				from = from,
				to = to
			}
		end
	end
	end

	if #choices == 0 then
		return nil
	end
	local random = math.random(1, #choices)
	local choice_from, choice_to = choices[random].from, choices[random].to

	return tonumber(choice_from), choice_to
end

function chessbot.move(inv, meta)
	local board_t = realchess.board_to_table(inv)
	local lastMove = meta:get_string("lastMove")
	local gameResult = meta:get_string("gameResult")
	local botColor = meta:get_string("botColor")
	if botColor == "" then
		return
	end
	local currentBotColor, opponentColor
	local botName
	if botColor == "black" then
		currentBotColor = "black"
		opponentColor = "white"
	elseif botColor == "white" then
		currentBotColor = "white"
		opponentColor = "black"
	elseif botColor == "both" then
		opponentColor = lastMove
		if lastMove == "black" or lastMove == "" then
			currentBotColor = "white"
		else
			currentBotColor = "black"
		end
	end
	if currentBotColor == "white" then
		botName = meta:get_string("playerWhite")
	else
		botName = meta:get_string("playerBlack")
	end
	if (lastMove == opponentColor or ((botColor == "white" or botColor == "both") and lastMove == "")) and gameResult == "" then
		local moves = realchess.get_theoretical_moves_for(meta, board_t, currentBotColor)

		local choice_from, choice_to = best_move(moves)
		if choice_from == nil then
			-- No best move: stalemate or checkmate
			return
		end

		local pieceFrom = inv:get_stack("board", choice_from):get_name()
		local pieceTo   = inv:get_stack("board", choice_to):get_name()

		local black_king_idx, white_king_idx = realchess.locate_kings(board_t)
		local bot_king_idx
		if currentBotColor == "black" then
			bot_king_idx = black_king_idx
		else
			bot_king_idx = white_king_idx
		end
		local botAttacked = realchess.attacked(currentBotColor, bot_king_idx, board_t)
		local kingSafe    = true
		local bestMoveSaveFrom, bestMoveSaveTo

		if botAttacked then
			kingSafe = false
			meta:set_string(currentBotColor.."Attacked", "true")
			local safe_moves, save_moves_count = realchess.get_king_safe_move(moves, board_t, currentBotColor)
			if save_moves_count >= 1 then
				bestMoveSaveFrom, bestMoveSaveTo = best_move(safe_moves)
			end
		end

		minetest.after(BOT_DELAY_MOVE, function()
			local gameResult = meta:get_string("gameResult")
			if gameResult ~= "" then
				return
			end
			local botColor = meta:get_string("botColor")
			if botColor == "" then
				return
			end
			local lastMove = meta:get_string("lastMove")
			local lastMoveTime = meta:get_int("lastMoveTime")
			if lastMoveTime > 0 or lastMove == "" then
				if currentBotColor == "black" and meta:get_string("playerBlack") == "" then
					meta:set_string("playerBlack", botName)
				elseif currentBotColor == "white" and meta:get_string("playerWhite") == "" then
					meta:set_string("playerWhite", botName)
				end
				local moveOK = false
				if not kingSafe then
					-- Make a move to put the king out of check
					if bestMoveSaveTo ~= nil then
						moveOK = realchess.move(meta, "board", bestMoveSaveFrom, "board", bestMoveSaveTo, botName)
						if not moveOK then
							minetest.log("error", "[xdecor] Chess: Bot tried to make an invalid move (to protect the king) from "..
								realchess.index_to_notation(bestMoveSaveFrom).." to "..realchess.index_to_notation(bestMoveSaveTo))
						end
					else
					-- No safe move left: checkmate or stalemate
						return
					end
				else
					-- Make a regular move
					moveOK = realchess.move(meta, "board", choice_from, "board", choice_to, botName)
					if not moveOK then
						minetest.log("error", "[xdecor] Chess: Bot tried to make an invalid move from "..
							realchess.index_to_notation(choice_from).." to "..realchess.index_to_notation(choice_to))
					end
				end
				-- Bot resigns if it made an incorrect move
				if not moveOK then
					realchess.resign(meta, currentBotColor)
				end
			end
		end)
	end
end

function chessbot.promote(inv, meta, pawnIndex)
	minetest.after(BOT_DELAY_PROMOTE, function()
		local lastMove = meta:get_string("lastMove")
		local color
		if lastMove == "black" or lastMove == "" then
			color = "white"
		else
			color = "black"
		end
		-- Always promote to queen
		realchess.promote_pawn(meta, color, "queen")
	end)
end

return chessbot
