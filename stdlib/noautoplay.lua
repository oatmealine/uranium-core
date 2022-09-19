local oldAutoplay

return function()
  function uranium.ready()
    oldAutoplay = PREFSMAN:GetPreference('AutoPlay')
    PREFSMAN:SetPreference('AutoPlay', 0)
    print('hi?? da hell??')
  end

  function uranium.exit()
    if oldAutoplay and oldAutoplay ~= 0 then
      PREFSMAN:SetPreference('AutoPlay', oldAutoplay)
    end
  end
end