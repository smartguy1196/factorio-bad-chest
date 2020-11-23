local function map_signals( map )
    local signals = {}
    local i = 1
    for k, v in pairs(map) do
        signals[i] = {
            count = v,
            index = i,
            signal = { name = k, type = "item" }
        }
        i = i + 1
    end
    return signals
end

function update_output( uid )
  if not global.recursive.deployers[ uid ].name == "blueprint-combinator" then return end

  local blueprint = global.recursive.blueprints[ uid ]
  if not blueprint.is_blueprint_setup() then return end

  local output = global.recursive.outputs[ uid ]
  local control = {
    output = output.get_or_create_control_behavior()
  }

  local entities = blueprint.get_blueprint_entities()
  local tiles = blueprint.get_blueprint_tiles()

  local map = {}

  local count = {
    entities = 0,
    tiles = 0,
    map = 0
  }

  if entities then
    for _, entity in pairs( entities ) do
      count.entities = count.entities + 1
      local item = game.entity_prototypes[ entity.name ].items_to_place_this[ 1 ]
      if type( item ) == "string" then
        item = {
          name = item,
          count = game.item_prototypes[ item ].stack_size
        }
      end

      map[ item.name ] = ( map[ item.name ] or 0 ) + item.count
    end
  end

  if tiles then
    for _, tile in pairs( tiles ) do
      count.tiles = count.tiles + 1
      local item = game.entity_prototypes[ tiles.name ].items_to_place_this[ 1 ]
      if type( item ) == "string" then
        item = {
          name = item,
          count = game.item_prototypes[ item ].stack_size
        }
      end

      map[ item.name ] = ( map[ item.name ] or 0 ) + item.count
    end
  end

  for _ in pairs( map ) do count.map = count.map + 1 end

  signals = map_signals( map )
  control.output.enabled, control.output.parameters = true, { parameters = signals }

end
