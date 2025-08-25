-- This is the weak chessbot, the built-in chessbot for
-- this mod. It is really bad at playing Chess but at
-- least it can play at all!

local NS = function(s) return s end

local realchess = xdecor.chess

-- How valuable the chessbot thinks each piece is
-- (higher = more valuable)
local piece_values = {
	pawn   = 10,
	knight = 30,
	bishop = 30,
	rook   = 50,
	queen  = 90,
	king   = 900
}

-- Pick a move from the list of all possible moves
-- on this chessboard
local function best_move(moves, board_t)
	--[[ This is a VERY simple algorithm that will greedily
	capture pieces as soon the opprtunity arises
	and otherwise takes random moves.
	This makes the bot very weak, as it lacks any kind of
	foresight, but the algorithm is blazingly fast. ]]

	--[[ The algorithm:
	Look at all moves and rate each of them with a number
	(higher = better). Pick the move with the highest rating.
	If it's a tie, pick randomly from the tied moves.
	Non-capturing moves are rated 0.
	Capturing moves are rated by which piece is captured
	(in piece_values) ]]

	local max_value, choices = 0, {}

	for from, tos in pairs(moves) do
		for to, _ in pairs(tos) do
			-- Move rating. rating 0 is for non-capturing moves.
			-- higher ratings are for capturing moves.
			local val = 0
			local to_piece_name = board_t[to]

			-- If destination is a piece that we capture, rate this move
			-- according to a table.
			if to_piece_name ~= "" then
				for piece_type, piece_value in pairs(piece_values) do
					if realchess.get_piece_type(to_piece_name) == piece_type then
						val = piece_value
					end
				end
			end

			-- Update the list of best moves (choices).
			if val > max_value then
				max_value = val
				choices = {{
					from = from,
					to = to
				}}
			elseif val == max_value then
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

local function choose_move(board_t, meta_t)
	local lastMove = meta_t["lastMove"]
	local gameResult = meta_t["gameResult"]
	local botColor = meta_t["botColor"]
	local prevDoublePawnStepTo = meta_t["prevDoublePawnStepTo"]
	local castlingRights = {
		castlingWhiteR = meta_t["castlingWhiteR"],
		castlingWhiteL = meta_t["castlingWhiteL"],
		castlingBlackR = meta_t["castlingBlackR"],
		castlingBlackL = meta_t["castlingBlackL"],
	}

	if botColor == "" then
		return
	end
	local currentBotColor, opponentColor
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
	if (lastMove == opponentColor or ((botColor == "white" or botColor == "both") and lastMove == "")) and gameResult == "" then

		local moves = realchess.get_theoretical_moves_for(board_t, currentBotColor, prevDoublePawnStepTo, castlingRights)
		local safe_moves, safe_moves_count = realchess.get_king_safe_moves(moves, board_t, currentBotColor)
		if safe_moves_count == 0 then
			-- No safe move: stalemate or checkmate
			return
		end
		local choice_from, choice_to = best_move(safe_moves, board_t)
		if choice_from == nil then
			-- No best move: stalemate or checkmate
			return
		end

		return choice_from, choice_to
	else
		minetest.log("error", "[xdecor] Chess: Weak chessbot: choose_move was apparently called in an invalid game state!")
		return
	end
end

local function choose_promote(board_t, pawnIndex)
	-- Bot always promotes to queen
	return "queen"
end

-- Set the weak chessbot
realchess.set_chessbot({
	id = "xdecor:weak",
	name = NS("Weak Computer"),
	choose_move = choose_move,
	choose_promote = choose_promote,
})
