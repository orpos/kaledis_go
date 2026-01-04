local pool = {
	messages = {},
	size = 100,
	callbacks = {},
}

function pool:new(size: number)
	local process = setmetatable({}, { __index = self })
	process.messages = {}
	process.size = size
	process.callbacks = {}
	return process
end

function pool:on(type: string, callback: (message: string) -> ())
    if not pool.callbacks[type] then
        self.callbacks[type] = {}
    end
    local pool = self.callbacks[type]
    table.insert(pool, callback)
end

function pool:add_message(message: string)
	local type_, data = message:match("([^\n]*)\n(.+)")
	local callbacks: { (data: string) -> () } | nil = self.callbacks[type_]
	if callbacks ~= nil then
		local function decompress()
			return love.data.decompress("string", "gzip", data)
		end
		local ok, decompressed = pcall(decompress)
		if ok then
			for i,callback in callbacks do
				callback(decompressed)
			end
		end
	end
end

return pool