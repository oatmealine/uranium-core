return function()
  function uranium.update()
    if b > 1 then
      GAMESTATE:SetSongBeat(b % 1)
    end
  end
end