function raster_csv(csv, height, stroke_width, height_margin, width_margin)
  local margin = margin or 10
  local Cairo = require "oocairo"

  min_x, max_x, min_y, max_y = bounding_box(csv)

  local real_width  = max_x - min_x
  local real_height = max_y - min_y

  local ratio = height / real_height

  local norm_height = height
  local norm_width = real_width * ratio

  local surface = Cairo.image_surface_create("rgb24", norm_width + width_margin * 2, norm_height + height_margin * 2)
  local cr = Cairo.context_create(surface)

  cr:set_source_rgb(1, 1, 1)
  cr:paint()

  local old_id = nil

  for i=1, #csv, 1 do  
    local current_id = tonumber(csv[i]['id'])
    local x = (tonumber(csv[i]['x']) - min_x) * ratio + width_margin
    local y = (tonumber(csv[i]['y']) - min_y) * ratio + height_margin
    local w = tonumber(csv[i]['is_writing'])

    if w == 1 then -- draw only the pen-downs
      if old_id == nil then
        --print('Initial.',xoff,yoff)
        cr:move_to( x , y )
      elseif current_id ~= old_id then -- changing stroke
        --print('End.')
        cr:set_source_rgb(0, 0, 0)
        cr:set_line_join("round")
        cr:set_line_cap("round")
        cr:set_line_width(stroke_width)
        cr:stroke()
        --print('First.',xoff,yoff)
        cr:move_to( x , y )
      else -- paint this point
        --print('Moving.',xoff,yoff)
        cr:line_to( x , y )
      end
      if i == #csv then -- close last remaining stroke
        --print('Ending.',xoff,yoff)
        cr:set_source_rgb(0, 0, 0)
        cr:set_line_join("round")
        cr:set_line_cap("round")
        cr:set_line_width(stroke_width)
        cr:stroke()
      end
    end
    old_id = current_id
  end
  -- The returned image is a ByteTensor with values in the range [0, 255], so
  -- convert in order to use with the image package.
  return Cairo.rgb2tensor(surface, false):float():div(255)
end

function read_csv(filename)
  local content = {}
  local cont_lines = 0
  if file then
    for line in io.lines(filename) do
      if cont_lines ~=0 then 
        -- ignore csv header
        local i, x, y, t, w = line: match '(%S+)%s+(%S+)%s+(%S+)%s+(%S+)%s+(%S+)'
        table.insert( content, {id = i, x = x, y = y, t = t, is_writing = w})
      end
      cont_lines = cont_lines + 1
    end
  end
  return content
end

function bounding_box(csv)
  local min_x = 100000
  local min_y = 100000
  local max_x = -100000
  local max_y = -100000
  for i=1, #csv, 1 do
    x = tonumber(csv[i]['x'])
    y = tonumber(csv[i]['y'])
    
    if x < min_x then
      min_x = x
    end
    if x > max_x then
      max_x = x
    end
    if y < min_y then
      min_y = y
    end
    if y > max_y then
      max_y = y
    end    
  end
  return min_x, max_x, min_y, max_y
end

local input=arg[1]
local output=arg[2]

csv_file = read_csv(input)
t_img = raster_csv(csv_file, 62, 2, 1, 5)

image.savePNG(output, t_img)


