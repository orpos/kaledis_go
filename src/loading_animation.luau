function lerp(a: number, b: number, t: number)
	return a + (b - a) * t
end

function mapRange(val, minInput, maxInput, minOutput, maxOutput)
	return minOutput + (val - minInput) * (maxOutput - minOutput) / (maxInput - minInput)
end

local t = 0;
return function (dt: number, size: number)
	-- love.graphics.clear()
    t += dt;
    t %= 1

	local a, b, c, d = love.graphics.getColor()
    
    local x, y, w, h = love.window.getSafeArea()
	local center_x = (x + w / 2)
	local center_y = (y + h / 2)

	local thickness = size / 5
	local lat = (size - thickness) / 2
	local offset = lat - thickness
	local radius = size / 10
	love.graphics.push()
	love.graphics.translate(center_x, center_y)
	love.graphics.rotate(math.rad(165))

	love.graphics.setColor(0.86, 0.62, 0.86, 1)

	local w_h, x1_h, x2_h

	if t < 0.35 then
		local localT = mapRange(t, 0, 0.35, 0, 1)
		w_h = lerp(thickness, size, localT)
		x1_h = lerp(lat, 0, localT)
		x2_h = lerp(-lat, 0, localT)
	elseif t < 0.70 then
		local localT = mapRange(t, 0.35, 0.70, 0, 1)
		w_h = lerp(size, thickness, localT)
		x1_h = lerp(0, -lat, localT)
		x2_h = lerp(0, lat, localT)
	else
		local localT = mapRange(t, 0.70, 1.0, 0, 1)
		w_h = thickness
		x1_h = lerp(-lat, lat, localT)
		x2_h = lerp(lat, -lat, localT)
	end

	love.graphics.rectangle("fill", x1_h - w_h / 2, -offset - thickness / 2, w_h, thickness, radius, radius)
	love.graphics.rectangle("fill", x2_h - w_h / 2, offset - thickness / 2, w_h, thickness, radius, radius)

	love.graphics.setColor(0.2, 0.6, 1, 1)

	local h_v, y1_v, y2_v

	if t < 0.35 then
		local localT = mapRange(t, 0, 0.35, 0, 1)
		h_v = lerp(thickness, size, localT)
		y1_v = lerp(lat, 0, localT)
		y2_v = lerp(-lat, 0, localT)
	elseif t < 0.70 then
		local localT = mapRange(t, 0.35, 0.70, 0, 1)
		h_v = lerp(size, thickness, localT)
		y1_v = lerp(0, -lat, localT)
		y2_v = lerp(0, lat, localT)
	else
		local localT = mapRange(t, 0.70, 1.0, 0, 1)
		h_v = thickness
		y1_v = lerp(-lat, lat, localT)
		y2_v = lerp(lat, -lat, localT)
	end

	love.graphics.rectangle("fill", offset - thickness / 2, y1_v - h_v / 2, thickness, h_v, radius, radius)
	love.graphics.rectangle("fill", -offset - thickness / 2, y2_v - h_v / 2, thickness, h_v, radius, radius)

	love.graphics.pop()
	love.graphics.setColor(a, b, c, d)
	-- love.graphics.present()
end
