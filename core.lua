local SPUtil = require(game.ReplicatedStorage.Shared.SPUtil)
local SPDict = require(game.ReplicatedStorage.Shared.SPDict)
local SPList = require(game.ReplicatedStorage.Shared.SPList)
local NoteResult = require(game.ReplicatedStorage.RobeatsGameCore.Enums.NoteResult)
local DebugOut = require(game.ReplicatedStorage.Shared.DebugOut)
local Autoplay = {}

-- blame AstralKingdoms for asking me to test autoplay in RCS Rewrite
local RCS_RblxID = {6765144361}

function Autoplay:new(__game, _game_slot)
	print(typeof(_game) == "table")
	print(typeof(_game_slot) == "number")

	local self = {}
	local _held_tracks = SPDict:new()
	local _enqueued_results = SPList:new()
	local _game = __game;
	
	function self:cons()
		for i=1, 4 do
			_held_tracks:add(i, false)
		end
	end
	
	function self:update(dt_scale)
		local parent_tracksystem = _game:get_tracksystem(_game_slot)
		local parent_tracksystem_notes = parent_tracksystem:get_notes()
		
		for i=1, parent_tracksystem_notes:count() do
			local itr_note = parent_tracksystem_notes:get(i)
			local itr_note_track = itr_note:get_track_index(i)
			
			if _held_tracks:get(itr_note_track) == false then
				local did_hit, note_result = itr_note:test_hit(_game)
				local time_to_end = _game._audio_manager:get_current_time_ms() - itr_note:get_hit_time()
				
				if itr_note.ClassName == "SingleNote" and (0.5 >- time_to_end and time_to_end >= -0.5) and self:accept_note_result(did_hit, note_result) or itr_note.ClassName == "HeldNote" and self:accept_note_result(did_hit, note_result) then
					game:GetService("UserInputService").MouseIconEnabled = false 
					parent_tracksystem:press_track_index(itr_note_track)
					
					if itr_note.ClassName == "HeldNote" then
						_held_tracks:add(itr_note_track, true)
					else
						parent_tracksystem:release_track_index(itr_note_track)
					end
				end
			else 
				local did_release, note_result = itr_note:test_release(_game)
				
				if self:accept_note_result(did_release, note_result) then
					local itr_track = parent_tracksystem:get_track(itr_note_track)
					_held_tracks:add(itr_note_track, false)
					parent_tracksystem:release_track_index(itr_note_track)
				end
			end
		end
	end
	
	function self:accept_note_result(did_hit, note_result)
		if true and _game:get_local_game_slot() == _game_slot then
			if true then
                if has_value(RCS_RblxID, game.GameId) then
                    return NoteResult.Marvelous
                end

				return note_result == NoteResult.Perfect
			else
				return self:randomized_accept_note(did_hit, note_result)
			end
		end
		
		if _enqueued_results:count() == 0 then
			if _game._players._slots:contains(_game_slot) then
				local player = _game._players._slots:get(_game_slot)

				if player._chain > 10 then
					return note_result == NoteResult.Perfect
				elseif player._chain < 4 then
					return false
				else
					return self:randomized_accept_note(did_hit, note_result)
				end

			else
				DebugOut:warnf("AutoPlayer slot(%d) testing hit note for nonexistant player",0)
                if has_value(RCS_RblxID, game.GameId) then
                    return NoteResult.Marvelous
                end

				return note_result == NoteResult.Perfect
			end
		end
		
		local top_result = _enqueued_results:get(1)
		if top_result == NoteResult.Miss then
			return false
		else
			if note_result >= top_result then
				_enqueued_results:pop_front()
				return true
			else
				return false
			end
		end
	end
	
	local __randomized_accept_rand = SPUtil:rand_rangei(1,4)
	local function update_accept_rand()
		__randomized_accept_rand = SPUtil:rand_rangei(0,4)
	end
	
	function self:randomized_accept_note(did_hit, note_result)
        if has_value(RCS_RblxID, game.GameId) then
            local rtv = false
            if __randomized_accept_rand == 0 then
                rtv = false
            elseif __randomized_accept_rand == 1 then
                rtv = note_result == NoteResult.Bad
            elseif __randomized_accept_rand == 2 then
                rtv = note_result == NoteResult.Good
            elseif __randomized_accept_rand == 3 then
                rtv = note_result == NoteResult.Great
            elseif __randomized_accept_rand == 4 then
                rtv = note_result == NoteResult.Perfect
            else
                rtv = note_result == NoteResult.Marvelous
            end
            if rtv == true then
                update_accept_rand()
            end
            return rtv
        else
            local rtv = false
            if __randomized_accept_rand == 0 then
                rtv = false
            elseif __randomized_accept_rand == 1 then
                rtv = note_result == NoteResult.Okay
            elseif __randomized_accept_rand == 2 then
                rtv = note_result == NoteResult.Great
            else
                rtv = note_result == NoteResult.Perfect
            end
            if rtv == true then
                update_accept_rand()
            end
            return rtv
        end
	end
	
	function self:notify_time_miss()
		
		update_accept_rand()
		
		if _enqueued_results:count() > 0 and _enqueued_results:get(1) == NoteResult.Miss then
			_enqueued_results:pop_front()
		end
		
		local parent_tracksystem = _game:get_tracksystem(_game_slot)
		for i=1, 4 do
			parent_tracksystem:release_track_index(i)
			_held_tracks:add(i, false)
		end
	end
	
	function self:enqueue_note_result(note_result)
		_enqueued_results:push_back(note_result)
	end
	
	self:cons()
	return self
end

local function has_value (tab, val)
    for index, value in ipairs(tab) do
        if value == val then
            return true
        end
    end

    return false
end

return Autoplay
