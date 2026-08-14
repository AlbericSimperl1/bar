-- Input configuration

hl.config({
    input = {
        sensitivity = 0.45,
        accel_profile = "flat",
        kb_layout = "be, kr",
        kb_options = "",
        -- Change speed of keyboard repeat
        repeat_rate = 40,
        repeat_delay = 250,
        -- Start with numlock on by default
        numlock_by_default = true,

    },
    -- Uncomment the section below to enable software cursors; this can help with cursor display or behavior issues
    -- cursor = {
    --     no_hardware_cursors = 1,
    -- },
})

hl.gesture({ fingers = 4, direction = "horizontal", action = "workspace" })
hl.gesture({ fingers = 3, direction = "down", action = "close" })
hl.gesture({ fingers = 3, direction = "up", action = "fullscreen" })
hl.gesture({ fingers = 3, direction = "left", action = "float" })
