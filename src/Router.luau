type callback = (...any) -> (...any)
local http = game:GetService("HttpService")
local json_encode = function(data: any): string
	return http:JSONEncode(data)
end
local json_decode = function(data: string): any
	return http:JSONDecode(data)
end
local link = {}

function link:send(data: string): nil
	script:SetAttribute(self.OUT, json_encode(data))
	return nil
end

function link:listen(code: callback): callback
	local conn = self.signal:Connect(function()
		local attr = json_decode(script:GetAttribute(self.IN))
		if attr ~= "" then code(attr) end
	end)
	return function() conn:Disconnect() end
end

export type Link = typeof(link)

local module = {}

function module.host(key: string): Link
	local self = table.clone(link)
	self.OUT = `_{key}_0_`
	self.IN = `_{key}_1_`
	self.signal = script:GetAttributeChangedSignal(self.IN)
	task.defer(script.SetAttribute, script, self.OUT, '""')
	task.defer(script.SetAttribute, script, self.IN, '""')
	return self
end

function module.connect(key: string): Link
	local data = script:GetAttribute(`_{key}_1_`)
			  or script:GetAttributeChangedSignal(`_{key}_1_`):Wait()
	local self = table.clone(link)
	self.OUT = `_{key}_1_`
	self.IN = `_{key}_0_`
	self.signal = script:GetAttributeChangedSignal(self.IN)
	return self
end

return module
