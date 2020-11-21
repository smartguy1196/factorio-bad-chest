-- Combinator will look similar to the decider,
-- but behaves like an arithmetic-comb like the moon logic controller in moon logistic
-- the arithmetic combinator supports more symbols than the decider

-- the output of the arithmetic combinator is tied to an invisible constant combinator
-- this allows for more output control than what is available to the arithmetic combinator

local blueprintCOMBINATOR = table.deepcopy(data.raw['arithmetic-combinator']['arithmetic-combinator'])
local baseDECIDER = data.raw['decider-combinator']['decider-combinator']

blueprintCOMBINATOR.name = 'blueprint-combinator'
blueprintCOMBINATOR.icon = png('blueprint-combinator-icon')
blueprintCOMBINATOR.icon_size = 32
blueprintCOMBINATOR.icons = nill
blueprintCOMBINATOR.minable.result = 'blueprint-combinator'

-- DUPE and REPLACE decider sprite sheet
blueprintCOMBINATOR.sprites = table.deepcopy(baseDECIDER.sprites)
for k, spec in pairs(blueprintCOMBINATOR.sprites) do
  for n, layer in pairs(spec.layers) do
    layer, layer.hr_version = layer.hr_version
    spec.layers[n] = layer
		if not layer.filename:match('^__base__/graphics/entity/combinator/hr%-decider%-combinator')
			then error('hr-decider-combinator sprite sheet incompatibility detected') end
		if not layer.filename:match('%-shadow%.png$')
			then layer.filename = png('hr-blueprint-combinator') end
			-- else layer.filename = png('hr-blueprint-combinator-shadow') end
end end

-- REPLACE display sprites
for prop, sprites in pairs(blueprintCOMBINATOR) do
	if not prop:match('_symbol_sprites$') then goto skip end
	for dir, spec in pairs(sprites) do
		spec, spec.hr_version = spec.hr_version -- only use hr version, for easier editing
		sprites[dir] = spec
		if spec.filename ~= '__base__/graphics/entity/combinator/hr-combinator-displays.png'
			then error('hr-decider-combinator display symbols sprite sheet incompatibility detected') end
		spec.filename = png('blueprint-displays')
		spec.shift = table.deepcopy(baseDECIDER.greater_symbol_sprites[dir].hr_version.shift)
end ::skip:: end

-- Copy values from decider that are different in it from arithmetic
for _, k in ipairs{
	'corpse', 'dying_explosion', 'activity_led_sprites',
	'input_connection_points', 'output_connection_points',
	'activity_led_light_offsets', 'screen_light', 'screen_light_offsets',
	'input_connection_points', 'output_connection_points'
} do
	local v = baseDECIDER[k]
	if type(v) == 'table' then v = table.deepcopy(baseDECIDER[k]) end
	blueprintCOMBINATOR[k] = v
end

do
	local invisible_sprite = {filename=png('invisible'), width=1, height=1}
	local wire_conn = {wire={red={0, 0}, green={0, 0}}, shadow={red={0, 0}, green={0, 0}}}
  local invisible_chest = table.deepcopy(data.raw["container"]["steel-chest"])
  invisible_chest.name = 'blueprint-core-chest'
  invisible_chest.collision_mask = {}
  invisible_chest.inventory_size = 1
  invisible_chest.sprites = invisible_sprite
  invisible_chest.circuit_wire_max_distance = 3
  invisible_chest.circuit_wire_connection_points = {wire_conn, wire_conn, wire_conn, wire_conn}
  invisible_chest.draw_circuit_wires = false

  data:extend{ blueprintCOMBINATOR, invisible_chest,
		{ type = 'constant-combinator',
			name = 'blueprint-core-const',
			flags = {'placeable-off-grid'},
			collision_mask = {},
			item_slot_count = 500,
			circuit_wire_max_distance = 3,
			sprites = invisible_sprite,
			activity_led_sprites = invisible_sprite,
			activity_led_light_offsets = {{0, 0}, {0, 0}, {0, 0}, {0, 0}},
			circuit_wire_connection_points = {wire_conn, wire_conn, wire_conn, wire_conn},
			draw_circuit_wires = false }, }
end
