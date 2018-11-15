local MEDIA_DIRECTORY = 'media'

local ALL_CONTENTS, ALL_CHILDS = node.make_nested()

gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)

local video
local current_updated = {}
local last_updated = {}
local playlist

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

function split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={} ; i=1
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        t[i] = str
        i = i + 1
    end
    return t
end

function split_name(file)
    local split_info = {}
    local split_ext = split(file, ".")
    local split_name = split(split_ext[1], "_")
    local split_path = split(split_name[1], "/")
    split_info["path"] = split_path[1]
    split_info["name"] = split_path[2]
    split_info["number"] = split_name[2]
    split_info["ext"] = split_ext[2]
    return split_info
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

function get_playlist()
    local playlist = util.generator(function()
        local files = {}
        for name, _ in pairs(ALL_CONTENTS[MEDIA_DIRECTORY]) do
            if name:match(".*mkv") then
                local split_info = split_name(name)
                if last_updated[split_info["name"]] ~= nil and last_updated[split_info["name"]] == split_info["number"] then
                    print("adding file to playlist: "..name)
                    files[#files+1] = name
                end
            end
        end
        return randsort(files) -- sort files by filename
    end)
    return playlist
end

node.event("content_remove", function(filename)
    playlist:remove(filename)
end)

node.event("content_update", function(file, content)
    local split_info = split_name(file)
    if current_updated[split_info["name"]] ~= nil then
        if not (current_updated[split_info["name"]] == split_info["number"]) then
            last_updated[split_info["name"]] = current_updated[split_info["name"]]
            print("selecting for playback: "..split_info["name"].."#"..last_updated[split_info["name"]])
        end
    end
    current_updated[split_info["name"]] = split_info["number"]
end)

function next_video()
    if not playlist then
        playlist = get_playlist()
    end
    if video then
        video:dispose()
    end
    video = util.videoplayer(playlist.next(), {loop=false})
end

function node.render()
    local length = tablelength(last_updated)
    if not (length == 0) then
        if not video or not video:next() then
            next_video()
        end
        util.draw_correct(video, 0, 0, WIDTH, HEIGHT)
    end
end

