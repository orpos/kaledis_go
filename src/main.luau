function get_local_ip()
	local s = Socket.udp()
	-- This doesn't actually send any packets, but forces the OS to get the ip of the interface
	s:setpeername("8.8.8.8", 80)
	local ip, _ = s:getsockname()
	s:close()
	return ip
end

local ip = get_local_ip()

local thread = love.thread.newThread([[
function split_once(str, sep)
    local i, j = string.find(str, sep, 1, true)
    if not i then
        return str, nil
    end

    return string.sub(str, 1, i - 1),
        string.sub(str, j + 1)
end

local socket = require("socket")
function get_local_ip()
    local s = socket.udp()
    -- This doesn't actually send any packets, but forces the OS to get the ip of the interface
    s:setpeername("8.8.8.8", 80)
    local ip, _ = s:getsockname()
    s:close()
    return ip
end

local local_channel, channel = ...

local ip = get_local_ip()

local tcp = socket.tcp()
tcp:bind(ip, 9532)
tcp:listen(32)
tcp:settimeout(0)
local connection = nil
local buffer = ""
while true do
    if connection == nil then
        connection = tcp:accept()
        socket.sleep(0.001)
        if connection ~= nil then
            connection:settimeout(0.001)
            channel:push("has_server\n"..love.data.compress("string", "gzip", "1", 4))
        end
    else
		local msg = local_channel:pop()
		if msg ~= nil then
			connection:send(msg)
		end
        local data, err, partial = connection:receive(4028)
        if err == "closed" then
            connection = nil;
            channel:push("has_server\n"..love.data.compress("string", "gzip", "0", 4))
        else
            if data then
                buffer = buffer..data
            end
            if partial then
                buffer = buffer..partial
            end
            
            local previous_message, rest = split_once(buffer, "-_-EOF-_-")
            if rest ~= nil then
                buffer = rest
                channel:push(previous_message)
            end
        end
    end

    socket.sleep(0.001)
end
]])

local __llk = {
	local_channel = nil,
	channel = nil,
}
function report_error(error: string)
	if __llk.local_channel ~= nil and error ~= nil and type(error) == "string" then
		__llk.local_channel:push("error\n")
		__llk.local_channel:push(love.data.compress("string", "gzip", error))
		__llk.local_channel:push("-_-EOF-_-")
	end
end
local pool = require("./pool"):new(100)
local loading_draw = require("./loading_animation")
local no_server = require("./no_server")
local error_draw = require("./error")

local h_cn = false
local is_loading_new_version = false

local function ensureDirectories(path)
	local parts = {}
	for part in path:gmatch("[^/]+") do
		table.insert(parts, part)
	end

	local current = ""
	for i = 1, #parts - 1 do
		current = current == "" and parts[i] or (current .. "/" .. parts[i])
		love.filesystem.createDirectory(current)
	end
end

local function cleanDirectory(path)
	for _, item in ipairs(love.filesystem.getDirectoryItems(path)) do
		local fullPath = path .. "/" .. item
		local info = love.filesystem.getInfo(fullPath)

		if info then
			if info.type == "directory" then
				cleanDirectory(fullPath)
			end
			love.filesystem.remove(fullPath)
		end
	end
end

pool:on("clean_assets", function(message: string)
	cleanDirectory(love.filesystem.getSaveDirectory())
end)

pool:on("receiving", function(message)
	is_loading_new_version = true
end)

pool:on("has_server", function(has: string)
	h_cn = has == "1"
	if not h_cn then
		is_loading_new_version = false
	end
end)

local should_render_error = false

pool:on("asset_upload", function(message)
	local path, data = message:match("([^\n]*)\n(.+)")

	ensureDirectories(path)

	local file, err = love.filesystem.newFile(path, "w")
	if err then
		report_error(err)
		should_render_error = true
		return
	end

	local ok, w_err = file:write(data)
	if not ok then
		report_error(w_err)
		should_render_error = true
		return
	end
end)

pool:on("load", function(code: string)
	is_loading_new_version = false
	should_render_error = false
	local chunk = loadstring(code)
	local ok, err = pcall(chunk)
	if not ok then
		print("Failed to load chunk")
		report_error(err)
		should_render_error = true
	end
end)

function love.run()
	__llk.local_channel = love.thread.newChannel()
	__llk.channel = love.thread.newChannel()

	thread:start(__llk.local_channel, __llk.channel)

	if love.load then
		love.load(love.arg.parseGameArguments(arg), arg)
	end

	-- Workaround for macOS random number generator issue
	-- On macOS, the random number generator can produce the same sequence of numbers
	-- if not properly seeded. This workaround ensures that the random number generator
	-- is seeded correctly to avoid this issue.
	if jit and jit.os == "OSX" then
		math.randomseed(os.time())
		math.random()
		math.random()
	end

	-- We don't want the first frame's dt to include time taken by love.load.
	if love.timer then
		love.timer.step()
	end

	local dt = 0

	return function()
		if love.event then
			love.event.pump()
			for name, a, b, c, d, e, f in love.event.poll() do
				if name == "quit" then
					if not love.quit or not love.quit() then
						return a or 0
					end
				end
				love.handlers[name](a, b, c, d, e, f)
			end
		end

		-- Update dt, as we'll be passing it to update
		if love.timer then
			dt = love.timer.step()
		end

		while true do
			local message = __llk.channel:pop()
			if not message then
				break
			end
			pool:add_message(message)
		end

		-- Call update and draw
		if love.update then
			local ok, error = pcall(function()
				love.update(dt)
			end)
			if not ok then
				report_error(error)
				should_render_error = true
			end
		end -- will pass 0 if love.timer is disabled
		if love.graphics and love.graphics.isActive() then
			love.graphics.origin()
			love.graphics.clear(love.graphics.getBackgroundColor())
			if not h_cn then
				no_server(ip)
			else
				if should_render_error then
					error_draw()
				else
					if love.draw then
						-- TODO: handle errors
						local ok, error = pcall(love.draw)
						if not ok then
							should_render_error = true
							report_error(error)
						end
					end
				end
				if is_loading_new_version then
					loading_draw(dt, 100)
				end
			end

			love.graphics.present()
		end

		if love.timer then
			love.timer.sleep(0.001)
		end
	end
end
