type callback = (...any) -> (...any)
local bridge = script:WaitForChild("Bridge")
local http = game:GetService("HttpService")
local is_server = game:GetService("RunService"):IsServer()

local set_attr = function(action: string, key: string, scope: any, value: any?)
	local key = `_{key}_{scope}_`
	if is_server then
		if action == "set" then
			script:SetAttribute(key, value)
		elseif action == "inc" then
			script:SetAttribute(key, (script:GetAttribute(key) or 1) + 1)
		end
	else
		bridge:FireServer(action, key, value)
	end
end

if is_server then
	bridge.OnServerEvent:Connect(function(_, action: string, key: string, data: any)
		if action == "set" then
			script:SetAttribute(key, data)
		elseif action == "inc" then
			script:SetAttribute(key, (script:GetAttribute(key) or 1) + 1)
		elseif action == "send" then
			task.wait() -- will only send last message in single frame without this
			script:SetAttribute(key, http:JSONEncode(data))
		end
	end)
end

local conn = {}

function conn:send(data: any?): nil
	if is_server then
		task.wait() -- will only send last message in single frame without this
		script:SetAttribute(self.OUT, http:JSONEncode(data))
	else
		bridge:FireServer("send", self.OUT, data)
	end
	return nil
end

function conn:close(): nil
	self.conn:Disconnect()
	return nil
end

export type Connection = typeof(conn)

local router = {}

function router.create(key: string, size: number, code: callback): Connection
	local self = table.clone(conn)
	self.OUT = `_{key}_2_`
	self.IN = `_{key}_3_`
	local count = script:GetAttribute(`_{key}_1_`)
	if not count then
		set_attr("set", key, 0, size)
		set_attr("set", key, 1, 1)
	elseif count <= size then
		set_attr("inc", key, 1)
	end
	self.conn = script:GetAttributeChangedSignal(self.IN):Connect(function()
		code(http:JSONDecode(script:GetAttribute(self.IN)))
	end)
	return self
end

function router.connect(key: string, code: callback): Connection
	local hosts = script:GetAttribute(`_{key}_0_`)
	if not hosts or script:GetAttribute(`_{key}_1_`) < hosts then
		local signal = script:GetAttributeChangedSignal(`_{key}_1_`)
		repeat
			signal:Wait()
		until
			(script:GetAttribute(`_{key}_1_`) or 0) >= script:GetAttribute(`_{key}_0_`)
	end
	local self = table.clone(conn)
	self.OUT = `_{key}_3_`
	self.IN = `_{key}_2_`
	self.conn = script:GetAttributeChangedSignal(self.IN):Connect(function()
		code(http:JSONDecode(script:GetAttribute(self.IN)))
	end)
	return self
end

return router
