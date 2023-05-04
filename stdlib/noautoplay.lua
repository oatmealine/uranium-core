local oldAutoplay

return function()
  uranium.on('ready', function()
    oldAutoplay = PREFSMAN:GetPreference('AutoPlay')
    PREFSMAN:SetPreference('AutoPlay', 0)
  end)

  uranium.on('exit', function()
    if oldAutoplay and oldAutoplay ~= 0 then
      PREFSMAN:SetPreference('AutoPlay', oldAutoplay)
    end
  end)
end