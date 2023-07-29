-- at which intervals should the screen switch to the
-- next image?
local INTERVAL = 10

-- enough time to load next image
local SWITCH_DELAY = 1

-- transition time in seconds.
-- set it to 0 switching instantaneously
local SWITCH_TIME = 2.0


-- Media directory. Set to '' to have your
-- images in the current directory.
local MEDIA_DIRECTORY = ''
-- local MEDIA_DIRECTORY = 'media'

local font = resource.load_font("Lato-Heavy.ttf")

----------------------------------------------------------------
local ALL_CONTENTS, ALL_CHILDS = node.make_nested()

assert(SWITCH_TIME + SWITCH_DELAY < INTERVAL,
    "INTERVAL must be longer than SWITCH_DELAY + SWITCHTIME")

gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)

local function alphanumsort(o)
    local function padnum(d) return ("%03d%s"):format(#d, d) end
    table.sort(o, function(a,b)
        return tostring(a):gsub("%d+",padnum) < tostring(b):gsub("%d+",padnum)
    end)
    return o
end

local function randsort(o)
    local o2 = {}
    for i=1,#o do
        local index = math.random(#o)
        o2[#o2 + 1] = o[index]
        table.remove(o, index)
    end
    o = o2
    return o
end

local pictures = util.generator(function()
    local files = {}
    for name, _ in pairs(ALL_CONTENTS[MEDIA_DIRECTORY]) do
        if name:match(".*jpg$") or name:match(".*png$") then
            files[#files+1] = name
        end
    end
    return alphanumsort(files) -- sort files by filename
end)
node.event("content_remove", function(filename)
    pictures:remove(filename)
end)

local current_image = resource.create_colored_texture(0,0,0,0)
local fade_start = 0
local info_text = nil

local function next_image()
    local next_image_name = pictures.next()
    print("now loading " .. next_image_name)
    last_image = current_image
    current_image = resource.load_image(next_image_name)
    fade_start = sys.now()
        
    info_text = nil
    info_text = resource.load_file(next_image_name .. ".txt")
end

function node.render()
    local delta = sys.now() - fade_start - SWITCH_DELAY
    if last_image and delta < 0 then
        util.draw_correct(last_image, 0, 0, WIDTH, HEIGHT)
    elseif last_image and delta < SWITCH_TIME then
        local progress = delta / SWITCH_TIME
        util.draw_correct(last_image, 0, 0, WIDTH, HEIGHT, 1 - progress)
        util.draw_correct(current_image, 0, 0, WIDTH, HEIGHT, progress)
    else
        if last_image then
            last_image:dispose()
            last_image = nil
        end
        util.draw_correct(current_image, 0, 0, WIDTH, HEIGHT)
        
        if info_text then
            text_y = 56
            for line in info_text:gmatch("([^\n]*)\n?") do
                font:write(NATIVE_WIDTH /2 - font:width(line, 64) /2, text_y, line, 64, 1,1,1,1)
                text_y = text_y + 100
            end
        end
    end
end

util.set_interval(INTERVAL, next_image)


