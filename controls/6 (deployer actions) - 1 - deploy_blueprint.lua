function deploy_blueprint( uid )

  local deployer = global.recursive.deployers[ uid ]
  local blueprint = global.recursive.blueprints[ uid ]

  if not blueprint then return end
  if not blueprint.valid_for_read then return end
  if not blueprint.is_blueprint_setup() then return end

  -- Rotate
  local rotation = get_signal( deployer, ROTATE_SIGNAL )
  local direction = defines.direction.north
  if (rotation == 1) then
    direction = defines.direction.east
  elseif (rotation == 2) then
    direction = defines.direction.south
  elseif (rotation == 3) then
    direction = defines.direction.west
  end

  -- Shift x,y coordinates
  local position = {
    x = deployer.position.x + get_signal( deployer, X_SIGNAL ),
    y = deployer.position.y + get_signal( deployer, Y_SIGNAL ),
  }

  -- Check for building out of bounds
  if position.x > 1000000
  or position.x < -1000000
  or position.y > 1000000
  or position.y < -1000000 then
    return
  end

  local result = blueprint.build_blueprint{
    surface = deployer.surface,
    force = deployer.force,
    position = position,
    direction = direction,
    force_build = true,
  }

  for _, entity in pairs(result) do
    script.raise_event(defines.events.script_raised_built, {
      entity = entity,
      stack = blueprint,
    })
  end
end
