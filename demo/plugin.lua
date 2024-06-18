--- SPDX-License-Identifier: MPL-2.0
--- Copyright (C) 2024, Emik.
---
--- --- Type definitions ---
---
--- @alias MCA 'SelectChannel' | 'ToggleChannel' | 'ToggleChildren' | nil
---
--- @class (exact) MultiPlotLines_Params<T>
--- @field get_channel_name (fun(data: T, channel_idx: number): string)
--- @field get_channel_color (fun(data: T, channel_idx: number): number)
--- @field get_channel_parent (fun(data: T, channel_idx: number): number | nil)
--- @field RW_HideChannel boolean[]
--- @field SelectedColor number
--- @field RW_SelectedChannelIdx number | nil
--- @field RW_HoveredChannelIdx number | nil
--- @field PlotDrawThickness number
--- @field SelectedDrawThickness number
--- @field HoveredDrawThickness number
--- @field HoveredDrawTooltip boolean
--- @field HoveredDrawValue boolean
--- @field bFilterUI boolean
--- @field RW_FilterAlpha number
--- @field RW_ShowLegend boolean
--- @field bLegendUI boolean
--- @field LegendMaxColumns number
--- @field PlotMCA MCA[]
--- @field LegendMCA MCA[]
--- @field AutoScale boolean
--- @field FramePadding number
--- @field SnapMouseX boolean
--- @field TextColor number | nil
---
--- @class Optional_MultiPlotLines_Params<T>
--- @field get_channel_name (fun(data: T, channel_idx: number): string) | nil
--- @field get_channel_color (fun(data: T, channel_idx: number): number) | nil
--- @field get_channel_parent (fun(data: T, channel_idx: number): number | nil) | nil
--- @field RW_HideChannel boolean[] | nil
--- @field SelectedColor number | nil
--- @field RW_SelectedChannelIdx number | nil
--- @field RW_HoveredChannelIdx number | nil
--- @field PlotDrawThickness number | nil
--- @field SelectedDrawThickness number | nil
--- @field HoveredDrawThickness number | nil
--- @field HoveredDrawTooltip boolean | nil
--- @field HoveredDrawValue boolean | nil
--- @field bFilterUI boolean | nil
--- @field RW_FilterAlpha number | nil
--- @field RW_ShowLegend boolean | nil
--- @field bLegendUI boolean | nil
--- @field LegendMaxColumns number | nil
--- @field PlotMCA MCA[] | nil
--- @field LegendMCA MCA[] | nil
--- @field AutoScale boolean | nil
--- @field FramePadding number | nil
--- @field SnapMouseX boolean | nil
--- @field TextColor number | nil

--- Creates a plot with multiple channels.
--- @generic T
--- @param label string | number | boolean | nil
--- @param get_value (fun(data: T, value_idx: number, channel_idx: number): number) | number[][] | number[]
--- @param data T
--- @param num_values number
--- @param num_channels number
--- @param params Optional_MultiPlotLines_Params<T>
--- @param scale_min number | nil
--- @param scale_max number | nil
--- @param frame_size number[] | {x: number, y: number} | {X: number, Y: number} | nil
--- @return MultiPlotLines_Params<T>
local function MultiPlotLines(
    label,
    get_value,
    data,
    num_values,
    num_channels,
    params,
    scale_min,
    scale_max,
    frame_size
)
    --- @generic T
    --- @return (fun(T, number): number)
    local function get_channel_color()
        -- https://personal.sron.nl/~pault/
        local s_Palette = {
            0xffddaa77, 0xffffdd99, 0xff998844, 0xff33ccbb,
            0xff00aaaa, 0xff88ddee, 0xff6688ee, 0xffbbaaff,
            0xff3377ee, 0xff1133cc, 0xff7733ee, 0xff7766cc,
            0xff552288, 0xff9944aa, 0xff0000ee, 0xff00ee00,
            0xffeecc99, 0xffffeebb, 0xffbbaa66, 0xff55dddd,
            0xff22cccc, 0xffaaeeff, 0xff88aaff, 0xffddccff,
            0xff5599ff, 0xff3355dd, 0xff9955ff, 0xff9988dd,
            0xff7744aa, 0xffbb66cc, 0xff2222ff, 0xff22ff22
        }

        return function(_, channel_idx)
            return s_Palette[((channel_idx - 1) % #s_Palette) + 1]
        end
    end

    --- @param _ any
    --- @param channel_idx number
    --- @return string
    local function get_channel_name(_, channel_idx)
        return "C_" .. (channel_idx - 1)
    end

    --- @param _ any
    --- @return number | nil
    local function get_channel_parent(_, _)
        return nil
    end

    --- @generic T
    --- @return MultiPlotLines_Params<T>
    local function defaults()
        return {
            get_channel_name = get_channel_name,
            get_channel_color = get_channel_color(),
            get_channel_parent = get_channel_parent,
            RW_HideChannel = {},
            SelectedColor = 0xffffffff,
            RW_SelectedChannelIdx = nil,
            RW_HoveredChannelIdx = nil,
            PlotDrawThickness = 1,
            SelectedDrawThickness = 1,
            HoveredDrawThickness = 1,
            HoveredDrawTooltip = true,
            HoveredDrawValue = true,
            bFilterUI = true,
            RW_FilterAlpha = 1,
            RW_ShowLegend = false,
            bLegendUI = true,
            LegendMaxColumns = 4,
            PlotMCA = {"SelectChannel", nil, nil},
            LegendMCA = {"SelectChannel", "ToggleChannel", nil},
            AutoScale = true,
            FramePadding = 4,
            SnapMouseX = true,
            TextColor = 0xffffffff
        }
    end

    --- @generic T
    --- @param hide_channels boolean[]
    --- @param g (fun(data: T, value_idx: number, channel_idx: number): number) | number[][] | number[]
    --- @param d T
    --- @return number, number
    local function find_min_and_max(hide_channels, g, d)
        local min = 1 / 0
        local max = -1 / 0

        if type(g) == "function" then
            for it_channel = 1, num_channels do
                if not hide_channels[it_channel] then
                    for i = 1, num_values do
                        local v = g(d, i, it_channel)

                        if v == v then
                            if min > v then
                                min = v
                            end

                            if max < v then
                                max = v
                            end
                        end
                    end
                end
            end
        elseif type(g[1]) == "table" then
            for it_channel = 1, num_channels do
                if not hide_channels[it_channel] then
                    for i = 1, num_values do
                        local v = g[it_channel][i]

                        if v == v then
                            if min > v then
                                min = v
                            end

                            if max < v then
                                max = v
                            end
                        end
                    end
                end
            end
        else --- @cast g number[]
            for it_channel = 1, num_channels do
                if not hide_channels[it_channel] then
                    for i = 1, num_values do
                        local v = g[(it_channel - 1) * num_channels + i]

                        if v == v then
                            if min > v then
                                min = v
                            end

                            if max < v then
                                max = v
                            end
                        end
                    end
                end
            end
        end

        return min, max
    end

    --- @generic T
    --- @param p table
    --- @param g (fun(data: T, value_idx: number, channel_idx: number): number) | number[][] | number[]
    --- @param d T
    --- @param num_lines number
    --- @param inv_scale number
    --- @param inner_bb_min_x number
    --- @param inner_bb_min_y number
    --- @param inner_bb_width number
    --- @param inner_bb_height number
    --- @param draw_list table
    local function draw_lines(
        p,
        g,
        d,
        draw_list,
        gcc_fn,
        inv_scale,
        num_lines,
        inner_bb_min_x,
        inner_bb_min_y,
        inner_bb_width,
        inner_bb_height
    )
        local t_step = 1 / num_lines
        local hide_channel = p.RW_HideChannel

        if type(g) == "function" then
            for it_channel = 1, num_channels do
                if not hide_channel[it_channel] then
                    local channel_thickness = p.PlotDrawThickness
                    local channel_color

                    if it_channel == p.RW_HoveredChannelIdx then
                        channel_thickness = channel_thickness + p.HoveredDrawThickness
                    end

                    if it_channel == p.RW_SelectedChannelIdx then
                        channel_thickness = channel_thickness + p.SelectedDrawThickness
                        channel_color = p.SelectedColor
                    else
                        channel_color = gcc_fn(d, it_channel)
                    end

                    local t1 = 0
                    local v1 = g(d, 1, it_channel)
                    local ftp1_x = 0
                    local ftp1_y = 1 - (v1 - scale_min) * inv_scale

                    if ftp1_y < 0 then
                        ftp1_y = 0
                    elseif ftp1_y > 1 then
                        ftp1_y = 1
                    end

                    for n = 2, num_values do
                        local t2 = t1 + t_step
                        local v2 = g(d, n, it_channel)
                        local tp2_y = 1 - (v2 - scale_min) * inv_scale

                        if tp2_y < 0 then
                            tp2_y = 0
                        elseif tp2_y > 1 then
                            tp2_y = 1
                        end

                        local ftp2_x = ftp1_x + (t2 - ftp1_x)
                        local ftp2_y = ftp1_y + p.RW_FilterAlpha * (tp2_y - ftp1_y)

                        draw_list.AddLine(
                            {
                                inner_bb_min_x + inner_bb_width * ftp1_x,
                                inner_bb_min_y + inner_bb_height * ftp1_y,
                            },
                            {
                                inner_bb_min_x + inner_bb_width * ftp2_x,
                                inner_bb_min_y + inner_bb_height * ftp2_y,
                            },
                            channel_color,
                            channel_thickness
                        )

                        t1 = t2
                        ftp1_x = ftp2_x
                        ftp1_y = ftp2_y
                    end
                end
            end
        elseif type(g[1]) == "table" then
            for it_channel = 1, num_channels do
                if not hide_channel[it_channel] then
                    local channel_thickness = p.PlotDrawThickness
                    local channel_color

                    if it_channel == p.RW_HoveredChannelIdx then
                        channel_thickness = channel_thickness + p.HoveredDrawThickness
                    end

                    if it_channel == p.RW_SelectedChannelIdx then
                        channel_thickness = channel_thickness + p.SelectedDrawThickness
                        channel_color = p.SelectedColor
                    else
                        channel_color = gcc_fn(d, it_channel)
                    end

                    local g_channel = g[it_channel]
                    local t1 = 0
                    local v1 = g_channel[1]
                    local ftp1_x = 0
                    local ftp1_y = 1 - (v1 - scale_min) * inv_scale

                    if ftp1_y < 0 then
                        ftp1_y = 0
                    elseif ftp1_y > 1 then
                        ftp1_y = 1
                    end

                    for n = 2, num_values do
                        local t2 = t1 + t_step
                        local v2 = g_channel[n]
                        local tp2_y = 1 - (v2 - scale_min) * inv_scale

                        if tp2_y < 0 then
                            tp2_y = 0
                        elseif tp2_y > 1 then
                            tp2_y = 1
                        end

                        local ftp2_x = ftp1_x + (t2 - ftp1_x)
                        local ftp2_y = ftp1_y + p.RW_FilterAlpha * (tp2_y - ftp1_y)

                        draw_list.AddLine(
                            {
                                inner_bb_min_x + inner_bb_width * ftp1_x,
                                inner_bb_min_y + inner_bb_height * ftp1_y,
                            },
                            {
                                inner_bb_min_x + inner_bb_width * ftp2_x,
                                inner_bb_min_y + inner_bb_height * ftp2_y,
                            },
                            channel_color,
                            channel_thickness
                        )

                        t1 = t2
                        ftp1_x = ftp2_x
                        ftp1_y = ftp2_y
                    end
                end
            end
        else
            for it_channel = 1, num_channels do
                if not hide_channel[it_channel] then
                    local channel_thickness = p.PlotDrawThickness
                    local channel_color

                    if it_channel == p.RW_HoveredChannelIdx then
                        channel_thickness = channel_thickness + p.HoveredDrawThickness
                    end

                    if it_channel == p.RW_SelectedChannelIdx then
                        channel_thickness = channel_thickness + p.SelectedDrawThickness
                        channel_color = p.SelectedColor
                    else
                        channel_color = gcc_fn(d, it_channel)
                    end

                    local t1 = 0
                    local v1 = g[(it_channel - 1) * num_channels + 1]
                    local ftp1_x = 0
                    local ftp1_y = 1 - (v1 - scale_min) * inv_scale

                    if ftp1_y < 0 then
                        ftp1_y = 0
                    elseif ftp1_y > 1 then
                        ftp1_y = 1
                    end

                    for n = 2, num_values do
                        local t2 = t1 + t_step
                        local v2 = g[(it_channel - 1) * num_channels + n]
                        local tp2_y = 1 - (v2 - scale_min) * inv_scale

                        if tp2_y < 0 then
                            tp2_y = 0
                        elseif tp2_y > 1 then
                            tp2_y = 1
                        end

                        local ftp2_x = ftp1_x + (t2 - ftp1_x)
                        local ftp2_y = ftp1_y + p.RW_FilterAlpha * (tp2_y - ftp1_y)

                        draw_list.AddLine(
                            {
                                inner_bb_min_x + inner_bb_width * ftp1_x,
                                inner_bb_min_y + inner_bb_height * ftp1_y,
                            },
                            {
                                inner_bb_min_x + inner_bb_width * ftp2_x,
                                inner_bb_min_y + inner_bb_height * ftp2_y,
                            },
                            channel_color,
                            channel_thickness
                        )

                        t1 = t2
                        ftp1_x = ftp2_x
                        ftp1_y = ftp2_y
                    end
                end
            end
        end
    end

    --- @generic T
    --- @param hide_channel boolean[]
    --- @param g (fun(data: T, value_idx: number, channel_idx: number): number) | number[][] | number[]
    --- @param hovered_c_idx number | nil
    --- @param hovered_v_idx number
    --- @param mouse_v number
    --- @return number, number | nil, number
    local function closest(hide_channel, g, hovered_c_idx, hovered_v_idx, mouse_v)
        local cHoveredMaxDistanceSq = (0.1 * (scale_max - scale_min)) *
            (0.1 * (scale_max - scale_min))

        local closest_dist_sq = 2 * cHoveredMaxDistanceSq
        local closest_v = 0
        local idx_x = 0

        if type(g) == "function" then
            for it_channel = 1, num_channels do
                if not hide_channel[it_channel] then
                    local v1 = get_value(data, hovered_v_idx, it_channel)
                    local v2, v3

                    if hovered_v_idx == 1 then
                        v2 = v1
                    else
                        v2 = get_value(data, hovered_v_idx - 1, it_channel)
                    end

                    if hovered_v_idx == num_values then
                        v3 = v1
                    else
                        v3 = get_value(data, hovered_v_idx + 1, it_channel)
                    end

                    local mid_v = 0.3333 * (v1 + v2 + v3)
                    local d_sq1 = (v1 - mouse_v) * (v1 - mouse_v)
                    local d_sq2 = (v2 - mouse_v) * (v2 - mouse_v)
                    local d_sq3 = (v3 - mouse_v) * (v3 - mouse_v)
                    local mid_d_sq = (mouse_v - mid_v) * (mouse_v - mid_v)

                    if mid_d_sq < closest_dist_sq then
                        hovered_c_idx = it_channel

                        if d_sq1 <= d_sq2 then
                            if d_sq1 <= d_sq3 then
                                closest_v = v1
                                idx_x = hovered_v_idx
                            else
                                closest_v = v3
                                idx_x = hovered_v_idx + 1
                            end
                        else
                            if d_sq2 <= d_sq3 then
                                closest_v = v2
                                idx_x = hovered_v_idx - 1
                            else
                                closest_v = v3
                                idx_x = hovered_v_idx + 1
                            end
                        end

                        closest_dist_sq = mid_d_sq
                    end
                end
            end
        elseif type(g[1]) == "table" then
            for it_channel = 1, num_channels do
                if not hide_channel[it_channel] then
                    local g_channel = g[it_channel]
                    local v1 = g_channel[hovered_v_idx]
                    local v2 = g_channel[hovered_v_idx - 1] or v1
                    local v3 = g_channel[hovered_v_idx + 1] or v1
                    local mid_v = 0.3333 * (v1 + v2 + v3)
                    local mid_d_sq = (mouse_v - mid_v) * (mouse_v - mid_v)
                    local d_sq1 = (v1 - mouse_v) * (v1 - mouse_v)
                    local d_sq2 = (v2 - mouse_v) * (v2 - mouse_v)
                    local d_sq3 = (v3 - mouse_v) * (v3 - mouse_v)

                    if mid_d_sq < closest_dist_sq then
                        hovered_c_idx = it_channel

                        if d_sq1 <= d_sq2 then
                            if d_sq1 <= d_sq3 then
                                closest_v = v1
                                idx_x = hovered_v_idx
                            else
                                closest_v = v3
                                idx_x = hovered_v_idx + 1
                            end
                        else
                            if d_sq2 <= d_sq3 then
                                closest_v = v2
                                idx_x = hovered_v_idx - 1
                            else
                                closest_v = v3
                                idx_x = hovered_v_idx + 1
                            end
                        end

                        closest_dist_sq = mid_d_sq
                    end
                end
            end
        else --- @cast g number[]
            for it_channel = 1, num_channels do
                if not hide_channel[it_channel] then
                    local v1 = g[(it_channel - 1) * num_channels + hovered_v_idx]
                    local v2 = g[(it_channel - 1) * num_channels + hovered_v_idx - 1] or v1
                    local v3 = g[(it_channel - 1) * num_channels + hovered_v_idx + 1] or v1
                    local mid_v = 0.3333 * (v1 + v2 + v3)
                    local mid_d_sq = (mouse_v - mid_v) * (mouse_v - mid_v)
                    local d_sq1 = (v1 - mouse_v) * (v1 - mouse_v)
                    local d_sq2 = (v2 - mouse_v) * (v2 - mouse_v)
                    local d_sq3 = (v3 - mouse_v) * (v3 - mouse_v)

                    if mid_d_sq < closest_dist_sq then
                        hovered_c_idx = it_channel

                        if d_sq1 <= d_sq2 then
                            if d_sq1 <= d_sq3 then
                                closest_v = v1
                                idx_x = hovered_v_idx
                            else
                                closest_v = v3
                                idx_x = hovered_v_idx + 1
                            end
                        else
                            if d_sq2 <= d_sq3 then
                                closest_v = v2
                                idx_x = hovered_v_idx - 1
                            else
                                closest_v = v3
                                idx_x = hovered_v_idx + 1
                            end
                        end

                        closest_dist_sq = mid_d_sq
                    end
                end
            end
        end

        return idx_x, hovered_c_idx, closest_v
    end

    if type(params) == "table" then
        for k, v in pairs(defaults()) do
            if type(params[k]) ~= type(v) then
                params[k] = v
            end
        end
    else
        params = defaults()
    end --- @cast params MultiPlotLines_Params<T>

    if num_values < 2 or num_channels < 1 or imgui.GetWindowWidth() < 41 then
        return params
    end

    if type(frame_size) ~= "table" then
        frame_size = {}
    end

    local width = frame_size[1] or frame_size["x"] or frame_size["X"]
    local height = frame_size[2] or frame_size["y"] or frame_size["Y"]

    if not width then
        if params.AutoScale then
            width = imgui.GetContentRegionAvailWidth()
        else
            width = 400
        end
    end

    if not height then
        height = 225
    end

    local do_min = type(scale_min) ~= "number"
    local do_max = type(scale_max) ~= "number"

    if do_min or do_max then
        local min, max = find_min_and_max(params, get_value, data)

        if do_min then
            scale_min = min
        end

        if do_max then
            scale_max = max
        end
    end

    local gcc_fn = params.get_channel_color
    local gcn_fn = params.get_channel_name
    local gcp_fn = params.get_channel_parent

    local execute_mca_fn = function(vec_mca, button_idx, channel_idx)
        local sw = vec_mca[button_idx]

        if sw == "SelectChannel" then
            if params.RW_SelectedChannelIdx == channel_idx then
                params.RW_SelectedChannelIdx = nil
            else
                params.RW_SelectedChannelIdx = channel_idx
            end
        elseif not channel_idx then
            return
        elseif sw == "ToggleChannel" then
            params.RW_HideChannel[channel_idx] = not params.RW_HideChannel[channel_idx]
        elseif sw == "ToggleChildren" then
            for it_c = 1, num_channels do
                local parent = gcp_fn(data, it_c)

                while type(parent) == "number" and parent >= 0 and parent < num_channels do
                    if parent == channel_idx then
                        params.RW_HideChannel[it_c] = not params.RW_HideChannel[it_c]
                    end

                    parent = gcp_fn(data, parent)
                end
            end
        end
    end

    local inv_scale

    if scale_max == scale_min then
        inv_scale = 0
    else
        inv_scale = 1 / (scale_max - scale_min)
    end

    local num_lines = num_values - 1
    local cursor_pos = imgui.GetCursorScreenPos()
    local padding = params.FramePadding
    local frame_bb_min_x = cursor_pos[1]
    local frame_bb_min_y = cursor_pos[2]
    local frame_bb_max_x = frame_bb_min_x + width
    local frame_bb_max_y = frame_bb_min_y + height

    if params.AutoScale then
        local max = imgui.GetContentRegionAvail()
        local max_x = max[1] + frame_bb_min_x
        local max_y = max[2] + frame_bb_min_y

        if frame_bb_max_x > max_x then
            frame_bb_max_x = max_x
            width = max_x - frame_bb_min_x
        end

        if frame_bb_max_y > max_y then
            frame_bb_max_y = max_y
            height = max_y - frame_bb_min_y
        end

        if max[1] <= padding or max[2] <= padding then
            return params
        end
    end

    local inner_bb_min_x = frame_bb_min_x + padding
    local inner_bb_min_y = frame_bb_min_y + padding
    local inner_bb_max_x = frame_bb_max_x - padding
    local inner_bb_max_y = frame_bb_max_y - padding
    local inner_bb_width = inner_bb_max_x - inner_bb_min_x
    local inner_bb_height = inner_bb_max_y - inner_bb_min_y
    local frame_bg = imgui.GetColorU32(imgui_col.FrameBg)
    local draw_list = imgui.GetWindowDrawList()
    local ty = type(label)
    draw_list.AddRectFilled(cursor_pos, {frame_bb_max_x, frame_bb_max_y}, frame_bg)
    imgui.Dummy({width, height})

    draw_lines(
        params,
        get_value,
        data,
        draw_list,
        gcc_fn,
        inv_scale,
        num_lines,
        inner_bb_min_x,
        inner_bb_min_y,
        inner_bb_width,
        inner_bb_height
    )

    local mouse = imgui.GetMousePos()
    local mouse_x = mouse[1]
    local mouse_y = mouse[2]
    local hovered_c_idx

    if params.RW_HoveredChannelIdx and params.RW_HoveredChannelIdx < num_channels then
        hovered_c_idx = params.RW_HoveredChannelIdx
    else
        hovered_c_idx = nil
    end

    if num_values > 1 then
        if frame_bb_min_x < mouse_x and mouse_x < frame_bb_max_x and
            frame_bb_min_y < mouse_y and mouse_y < frame_bb_max_y then
            hovered_c_idx = nil
            local mouse_t = (mouse_x - inner_bb_min_x) / inner_bb_width
            local mouse_y01 = 1 - (mouse_y - inner_bb_min_y) / inner_bb_height

            if mouse_t < 0 then
                mouse_t = 0
            elseif mouse_t > 1 then
                mouse_t = 1
            end

            if mouse_y01 < 0 then
                mouse_y01 = 0
            elseif mouse_y01 > 1 then
                mouse_y01 = 1
            end

            local mouse_v = scale_min + mouse_y01 * (scale_max - scale_min)
            local hovered_v_idx = math.floor(mouse_t * num_lines)
            local closest_v, idx_x

            if hovered_v_idx ~= num_values then
                hovered_v_idx = hovered_v_idx + 1
            end

            idx_x, hovered_c_idx, closest_v = closest(
                params.RW_HideChannel,
                get_value,
                hovered_c_idx,
                hovered_v_idx,
                mouse_v
            )

            if hovered_c_idx then
                if params.HoveredDrawTooltip then
                    imgui.BeginTooltip()
                    imgui.PushTextWrapPos(imgui.GetFontSize() * 20)
                    imgui.Text(string.format("%s %4.4g", gcn_fn(data, hovered_c_idx), closest_v))
                    imgui.PopTextWrapPos()
                    imgui.EndTooltip()
                end

                if params.HoveredDrawValue then
                    if params.SnapMouseX then
                        mouse_t = (idx_x - 1) / num_lines
                    end

                    local closest_y01 = (closest_v - scale_min) * inv_scale

                    draw_list.AddCircleFilled(
                        {
                            inner_bb_min_x + inner_bb_width * mouse_t,
                            inner_bb_min_y + inner_bb_height * (1 - closest_y01)
                        },
                        5,
                        gcc_fn(data, hovered_c_idx),
                        10
                    )
                end
            end

            if imgui.IsItemClicked(0) then
                execute_mca_fn(params.PlotMCA, 1, hovered_c_idx)
            end

            if imgui.IsItemClicked(1) then
                execute_mca_fn(params.PlotMCA, 2, hovered_c_idx)
            end

            if imgui.IsItemClicked(2) then
                execute_mca_fn(params.PlotMCA, 3, hovered_c_idx)
            end
        end

        params.RW_HoveredChannelIdx = hovered_c_idx
    end

    if ty == "string" or ty == "number" or ty == "boolean" then
        draw_list.AddText(
            {(frame_bb_min_x + width / 2 - imgui.CalcTextSize(label)[1] / 2), frame_bb_min_y},
            params.TextColor,
            label
        )
    end

    if params.bFilterUI then
        imgui.Text("Filter")
        imgui.SameLine()
        imgui.PushItemWidth(-1)

        _, params.RW_FilterAlpha =
            imgui.SliderFloat("##FilterAlpha", params.RW_FilterAlpha or 0, 0.1, 1)

        imgui.PopItemWidth()
    end

    if params.bLegendUI then
        _, params.RW_ShowLegend = imgui.Checkbox("Legend?", not not params.RW_ShowLegend)
        imgui.SameLine()

        if imgui.Button("All") then
            for it_channel = 1, num_channels do
                params.RW_HideChannel[it_channel] = false
            end
        end

        imgui.SameLine()

        if imgui.Button("None") then
            for it_channel = 1, num_channels do
                params.RW_HideChannel[it_channel] = true
            end
        end
    end

    if params.RW_ShowLegend then
        local num_columns

        if params.LegendMaxColumns and params.LegendMaxColumns <= 0 or
            num_channels > params.LegendMaxColumns then
            num_columns = params.LegendMaxColumns
        else
            num_columns = num_channels
        end

        if (num_channels % num_columns) ~= 0 and (num_channels % (num_columns - 1)) == 0 and
            (num_channels / (num_columns - 1)) <= (num_channels / num_columns + 1) then
            num_columns = num_columns - 1
        end

        imgui.Columns(num_columns)
        local bor = bit32.bor
        local band = bit32.band

        for it_channel = 1, num_channels do
            local channel_color

            if it_channel == params.RW_SelectedChannelIdx then
                channel_color = params.SelectedColor
            else
                channel_color = gcc_fn(data, it_channel)
            end

            imgui.PushStyleColor(imgui_col.CheckMark, 0)

            if params.RW_HideChannel[it_channel] then
                imgui.PushStyleColor(imgui_col.FrameBg, 0)
                imgui.PushStyleColor(imgui_col.FrameBgHovered, 0)
            else
                imgui.PushStyleColor(imgui_col.FrameBg, channel_color)
                imgui.PushStyleColor(imgui_col.FrameBgHovered, channel_color)
            end

            imgui.PushStyleColor(
                imgui_col.FrameBgActive,
                bor(band(channel_color, 0x00ffffff), 0x77000000)
            )

            imgui.PushStyleColor(imgui_col.Text, channel_color)
            imgui.PushStyleColor(imgui_col.Border, channel_color)
            imgui.Checkbox(gcn_fn(data, it_channel), not not params.RW_HideChannel[it_channel])

            if imgui.IsItemHovered() then
                params.RW_HoveredChannelIdx = it_channel
            end

            if it_channel == params.RW_HoveredChannelIdx then
                draw_list.AddRect(imgui.GetItemRectMin(), imgui.GetItemRectMax(), channel_color)
            end

            if imgui.IsItemClicked(0) then
                execute_mca_fn(params.LegendMCA, 1, it_channel)
            end

            if imgui.IsItemClicked(1) then
                execute_mca_fn(params.LegendMCA, 2, it_channel)
            end

            if imgui.IsItemClicked(2) then
                execute_mca_fn(params.LegendMCA, 3, it_channel)
            end

            imgui.PopStyleColor(6)
            imgui.NextColumn()
        end

        imgui.Columns(1)
    end

    return params
end
--- @type MultiPlotLines_Params<string>
local args = {RW_ShowLegend = true}

--- Gets the y-value of the corresponding x-valued slice and channel indices.
--- @param _ any
--- @param slice_idx number
--- @param channel_idx number
--- @return number
local function amounts_sine(_, slice_idx, channel_idx)
    return math.sin(0.5 * 3.159265 * channel_idx * (slice_idx - 1) / 100)
end

--- Performs the ternary operator, eagerly.
--- @generic T
--- @param condition boolean
--- @param consequent T
--- @param alternative T
--- @return T
local function ternary(condition, consequent, alternative)
    if condition then
        return consequent
    end

    return alternative
end

--- Gets the value from the current state.
--- @generic T
--- @param label string
--- @param fallback T
--- @return T
local function get(label, fallback)
    local value = state.GetValue(label)

    if value == nil then
        return fallback
    end

    return value
end

--- Draws the plot and its parameters.
function draw()
    if not args.PlotMCA then
        imgui.PushStyleVar(imgui_style_var.WindowMinSize, {425, 835})
        imgui.Begin("MPL Demo")
        imgui.PopStyleVar()
    else
        imgui.Begin("MPL Demo")
    end

    local label = get("label", "MPL Demo")
    local values = get("values", 100)
    local channels = get("channels", 8)
    local useMin = get("useMin", false)
    local min = get("min", -1)
    local useMax = get("useMax", false)
    local max = get("max", 1)
    local useFrame = get("useFrame", false)
    local frame = get("frame", {400, 225})
    local selectedColor = get("selectedColor", {1, 1, 1, 1})
    local textColor = get("textColor", {1, 1, 1, 1})

    args = MultiPlotLines(
        label,
        amounts_sine,
        nil,
        values,
        channels,
        args,
        ternary(useMin, min),
        ternary(useMax, max),
        ternary(useFrame, frame)
    )

    imgui.Separator()
    imgui.PushItemWidth(math.max(imgui.GetWindowWidth() - 180, 1))

    imgui.Text("Function parameters:")
    _, label = imgui.InputText("label", label, 2000)
    _, values = imgui.SliderInt("num_values", values, 2, 800 / channels)
    _, channels = imgui.SliderInt("num_channels", channels, 1, 32)

    if values > 800 / channels then
        values = 800 / channels
    end

    _, useMin = imgui.Checkbox("scale_min", useMin)

    if useMin then
        imgui.SameLine()
        _, min = imgui.SliderFloat("##scale_min", min, -2, 0)
    end

    _, useMax = imgui.Checkbox("scale_max", useMax)

    if useMax then
        imgui.SameLine()
        _, max = imgui.SliderFloat("##scale_max", max, 0, 2)
    end

    _, useFrame = imgui.Checkbox("frame_size", useFrame)

    if useFrame then
        imgui.SameLine()
        _, frame = imgui.InputInt2("##frame_size", frame)
    end

    imgui.Separator()
    imgui.Text("params.")

    _, args.PlotDrawThickness = imgui.SliderInt("PlotDrawThickness", args.PlotDrawThickness, 1, 4)

    _, args.SelectedDrawThickness =
        imgui.SliderInt("SelectedDrawThickness", args.SelectedDrawThickness, 0, 3)

    _, args.HoveredDrawThickness =
        imgui.SliderInt("HoveredDrawThickness", args.HoveredDrawThickness, 0, 3)

    _, args.LegendMaxColumns = imgui.SliderInt("LegendMaxColumns", args.LegendMaxColumns, 1, 32)
    _, args.FramePadding = imgui.SliderInt("FramePadding", args.FramePadding, 0, 15)
    _, args.HoveredDrawTooltip = imgui.Checkbox("HoveredDrawTooltip", args.HoveredDrawTooltip)

    if imgui.GetContentRegionAvailWidth() >= 308 then
        imgui.SameLine()
    end

    _, args.HoveredDrawValue = imgui.Checkbox("HoveredDrawValue", args.HoveredDrawValue)
    _, args.bFilterUI = imgui.Checkbox("bFilterUI", args.bFilterUI)

    if imgui.GetContentRegionAvailWidth() >= 178 then
        imgui.SameLine()
    end

    _, args.bLegendUI = imgui.Checkbox("bLegendUI", args.bLegendUI)
    _, args.AutoScale = imgui.Checkbox("AutoScale", args.AutoScale)

    if imgui.GetContentRegionAvailWidth() >= 200 then
        imgui.SameLine()
    end

    _, args.SnapMouseX = imgui.Checkbox("SnapMouseX", args.SnapMouseX)
    imgui.PopItemWidth()
    _, selectedColor = imgui.ColorEdit4("SelectedColor", selectedColor)
    _, textColor = imgui.ColorEdit4("TextColor", textColor)

    args.SelectedColor = imgui.GetColorU32(selectedColor)
    args.TextColor = imgui.GetColorU32(textColor)

    state.SetValue("label", label)
    state.SetValue("values", values)
    state.SetValue("channels", channels)
    state.SetValue("useMin", useMin)
    state.SetValue("min", min)
    state.SetValue("useMax", useMax)
    state.SetValue("max", max)
    state.SetValue("useFrame", useFrame)
    state.SetValue("frame", frame)
    state.SetValue("selectedColor", selectedColor)
    state.SetValue("textColor", textColor)

    imgui.End()
end
