-- Global events
script.on_init(on_init)
script.on_configuration_changed(on_mods_changed)
script.on_event(defines.events.on_tick, on_tick)

-- Deployer events
local filter = {{filter = "name", name = "blueprint-deployer"},{filter = "name", name = "blueprint-combinator"}}
script.on_event(defines.events.on_built_entity, on_built, filter)
script.on_event(defines.events.on_robot_built_entity, on_built, filter)
script.on_event(defines.events.on_entity_cloned, on_built, filter)
script.on_event(defines.events.script_raised_built, on_built, filter)
script.on_event(defines.events.script_raised_revive, on_built, filter)

script.on_event(defines.events.on_pre_player_mined_item, on_mined, filter)
script.on_event(defines.events.on_robot_pre_mined, on_mined, filter)
script.on_event(defines.events.on_entity_died, on_destroyed, filter)
script.on_event(defines.events.script_raised_destroy, on_destroyed, filter)

script.on_event(defines.events.on_entity_settings_pasted, on_entity_settings_pasted)

--todo: control combinator LEDs
