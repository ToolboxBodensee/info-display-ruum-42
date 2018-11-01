gl.setup(NATIVE_WIDTH, NATIVE_HEIGHT)

node.alias("departures")

json = require "json"

util.auto_loader(_G)

local base_time = N.base_time or 0
local departures = N.departures or {}

local drawer

util.data_mapper{
    ["clock/set"] = function(time)
        base_time = tonumber(time) - sys.now()
        N.base_time = base_time
    end;
    ["update"] = function()
        schedule.update()
    end;
}

node.event("input", function(line, client)
    departures = json.decode(line)
    N.departures = departures
    print("departures update")
    schedule.update()
end)

function unixnow()
    return base_time + sys.now()
end

shader = resource.create_shader[[
    uniform sampler2D Texture;
    uniform sampler2D frame2;
    varying vec2 TexCoord;
    uniform float which;

    void main() {
        vec4 col1 = texture2D(Texture, TexCoord.st);
        vec4 col2 = texture2D(frame2, TexCoord.st);
        // gl_FragColor = vec4(mix(col1.rgb, col2.rgb, which), max(col1.a, col2.a));
        gl_FragColor = mix(col1, col2, which);
    }
]]

function draw_departures(now, frame)
    local y = 23
    local now = unixnow()
    for idx, dep in ipairs(departures) do
        if dep.date > now then
            local time = dep.nice_date

            local remaining = math.floor((dep.date - now) / 60)
            local append = ""

            if remaining < 0 then
                time = "WEG"
                if dep.next_date then
                    append = string.format("wieder in %d min", math.floor((dep.next_date - now)/60))
                end
            elseif remaining < 4 then
                if frame == 1 then
                    time = "jetzt"
                else
                    time = "jetzt"
                end
                if dep.next_date then
                    append = string.format("wieder in %d min", math.floor((dep.next_date - now)/60))
                end
            elseif remaining < 2 then
                time = string.format("%d min", ((dep.date - now)/60))
                if dep.next_nice_date then
                    -- time = time .. " und erneut um " .. dep.next_nice_date
                    append = "wieder um " .. math.floor((dep.next_date - dep.date)/60) .. " min spaeter"
                end
            else
                time = time -- .. " +" .. remaining
                if dep.next_nice_date then
                    append = "wieder um " .. dep.next_nice_date
                end
            end

            if #dep.platform > 0 then
                if #append > 0 then
                    append = append .. " / " .. dep.platform
                else
                    append = dep.platform
                end
            end

            if remaining < 8 then
                util.draw_correct(_G[dep.icon], 10, y, 140, y+50, 0.9)
                if frame == 1 then
                    if #dep.more > 0 then
                        font:write(150, y, dep.more, 40, 1,0,0,1)
                    else
                        font:write(150, y, dep.stop, 40, 1,0,0,1)
                    end
                else
                    font:write(150, y, "->" .. dep.direction, 40, 1,0,0,1)
                end
                y = y + 50
                font:write(150, y, time .. " / " .. append , 25, 0,1,1,1)
                y = y + 40
            else
                util.draw_correct(_G[dep.icon], 10, y, 140, y+45, 0.9)
                font:write(150, y, time, 35, 1,1,1,1)
                if frame == 1 and #dep.more > 0 then
                    font:write(300, y, dep.more, 40, 1,1,1,1)
                else
                    font:write(300, y, dep.stop .. " → " .. dep.direction, 40, 1,1,1,1)
                end
                y = y + 35
                font:write(300, y, append , 25, 0,1,1,1)
                y = y + 30 
            end
            if y > HEIGHT - 60 then
                break
            end
        end
    end
end

function make_schedule()
    local frame1, frame2
    local updater

    local function update_func()
        coroutine.yield()
        print("updating!")
        local now = unixnow()
        print('time is now', now)
        gl.clear(0, 0, 0, 0)
        draw_departures(now, 1)
        frame1 = resource.create_snapshot()
        coroutine.yield()
        gl.clear(0, 0, 0, 0)
        draw_departures(now, 2)
        frame2 = resource.create_snapshot()
    end

    local function update()
        updater = coroutine.wrap(update_func)
    end

    local function draw()
        if updater then
            local success = pcall(updater)
            if not success then
                updater = nil
            end
        end
        gl.clear(0, 0, 0, 0)
        if frame1 and frame2 then
            shader:use{
                frame2 = frame2;
                which = math.max(-1, math.min(1, 3 + math.sin(sys.now()) * 5.5)) * 0.5 + 0.5 
            }
            frame1:draw(0, 0, WIDTH, HEIGHT, 1)
            shader:deactivate()
        end
    end
    return {
        draw = draw;
        update = update;
    }
end

schedule = make_schedule()
util.set_interval(30, schedule.update)

function node.render()
    schedule.draw()
end
