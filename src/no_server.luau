local font = love.graphics.newFont(24)

return function(ip: string)
	love.graphics.setColor(1, 1, 1, 1)
	love.graphics.setBackgroundColor(0, 0, 0, 1)
	-- This will run every time a new frame will be drawn
	local x, y, w, h = love.window.getSafeArea()

	local center_x = w
	local center_y = h

	local text = "Put this ip in kaledis: " .. ip

	local x_pos = x + center_x - font:getWidth(text)
	local y_pos = y + center_y - font:getHeight()

	love.graphics.setFont(font)
	love.graphics.print(text, x_pos, y_pos)
end
