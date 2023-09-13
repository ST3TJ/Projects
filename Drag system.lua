---@diagnostic disable
math.clamp = function(v, m, M) return math.min(math.max(v, m), M) end

local drag = {
    cache = {},
    busy = nil,
    resizing = {},
    M1_TIME = 0,
}

---Checks if the cursor is in a certain area
---@param x number
---@param y number
---@param w number
---@param h number
---@return boolean
drag.in_bounds = function(x, y, w, h)
    local c = utils.get_cursor_position()
    return c.x >= x and c.x <= w+x and c.y >= y and c.y <= h+y
end

---Checks if the left mouse button is clicked in a certain area
---@param x number
---@param y number
---@param w number
---@param h number
---@return boolean
drag.is_clicked = function(x, y, w, h)
    return drag.in_bounds(x, y, w, h) and drag.M1_TIME == 1
end

drag.update = function()
    drag.M1_TIME = utils.get_active_key(0x01) and drag.M1_TIME + 1 or 0
end

---Returns resizable data. Write "lock" to lock changes of value
---@param animation boolean
---@param w number
---@param h number
---@return table
drag.resize = function(animation, w, h)
    return {
        w = w,
        h = h,
        animation = animation,
    }
end

---Caches and returns the position of the dragged item
---@param name string
---@param x number
---@param y number
---@param w number
---@param h number
---@param resizable boolean
---@param overwrite boolean
---@return userdata
drag.new = function(name, x, y, w, h, resizable, overwrite)

    name = type(name) ~= "string" and "item0" or name
    x = type(x) ~= "number" and 0 or x
    y = type(y) ~= "number" and 0 or x
    w = type(w) ~= "number" and 100 or w
    h = type(h) ~= "number" and 100 or h
    resizable = resizable or true

    if not drag.cache[name] or overwrite then
        drag.cache[name] = {
            x = x, tx = 0, 
            y = y, ty = 0,
            w = w, h = h,
        }
    end

    local item = drag.cache[name]

    local function data()
        return {
            x = item.x, y = item.y,
            w = item.w, h = item.h,
        }
    end

    local cursour = utils.get_cursor_position()
    local screen = engine.get_screen_size()

    local busy = (drag.busy and drag.busy ~= name)
    local is_dragged = (drag.busy == name)

    if resizable == true then
        drag.cache[name].w = w
        drag.cache[name].h = h
    end

    if not gvars.is_open_menu() or busy then
        return data()
    end

    if type(resizable) == "table" and not busy then
        local point = vector_2d(item.x + item.w, item.y + item.h)
        local distance = math.sqrt((cursour.x-point.x)^2 + (cursour.y-point.y)^2)

        local is_clicked = (distance <= 10 and drag.M1_TIME == 1)
        local resizing = (drag.resizing[name])

        if is_clicked or resizing then

            local wlock = (type(resizable.w) == "string" and resizable.w:find("lock"))
            local hlock = (type(resizable.h) == "string" and resizable.h:find("lock"))

            if resizable.animation then
                item.w = wlock and item.w or animate.lerp(item.w, cursour.x - item.x, 0.065)
                item.h = hlock and item.h or animate.lerp(item.h, cursour.y - item.y, 0.065)
            else
                item.w = wlock and item.w or cursour.x - item.x
                item.h = hlock and item.h or cursour.y - item.y
            end

            if type(resizable.w) == "number" and item.w < resizable.w then
                item.w = resizable.w
            end
            if type(resizable.h) == "number" and item.h < resizable.h then
                item.h = resizable.h
            end

            if drag.M1_TIME > 0 then
                drag.resizing[name] = true
            else
                drag.resizing = {}
            end
            return data()
        end
    end

    if drag.is_clicked(item.x, item.y, item.w, item.h) or is_dragged then
        if not is_dragged then
            item.tx = cursour.x - item.x
            item.ty = cursour.y - item.y
        end
        item.x = math.clamp(cursour.x - item.tx, 0, screen.x - item.w)
        item.y = math.clamp(cursour.y - item.ty, 0, screen.y - item.h)
        drag.busy = drag.M1_TIME > 0 and name or nil
    end

    return data()
end