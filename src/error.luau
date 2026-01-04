local font = love.graphics.newFont(20)

return function()
	love.graphics.setBackgroundColor(0, 0, 1, 0.4)
	love.graphics.setColor(1, 0, 0, 1)
	-- This will run every time a new frame will be drawn
	local x, y, w, h = love.window.getSafeArea()

	local center_x = w / 2
	local center_y = h / 2

	local text = "There was an error on your code. Check your console logs"

	local x_pos = center_x - (font:getWidth(text) /2)
	local y_pos = center_y - font:getHeight()

	love.graphics.setFont(font)
	love.graphics.print(text, x_pos, y_pos)
end
