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
