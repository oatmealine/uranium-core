local self = {}

function self.sprite(self)
  self:basezoomx(sw / dw)
  self:basezoomy(-sh / dh)
  self:x(scx)
  self:y(scy)
end

function self.aft(self)
  self:SetWidth(dw)
  self:SetHeight(dh)
  self:EnableDepthBuffer(false)
  self:EnableAlphaBuffer(false)
  self:EnableFloat(false)
  self:EnablePreserveTexture(true)
  self:Create()
end

return self