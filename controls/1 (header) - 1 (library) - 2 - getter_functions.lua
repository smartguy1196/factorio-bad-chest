function get_area( deployer )
  local X = get_signal( deployer, X_SIGNAL )
  local Y = get_signal( deployer, Y_SIGNAL )
  local W = get_signal( deployer, WIDTH_SIGNAL )
  local H = get_signal( deployer, HEIGHT_SIGNAL )

  if W < 1 then W = 1 end
  if H < 1 then H = 1 end

  if settings.global["recursive-blueprints-area"].value == "corner" then
    -- Convert from top left corner to center
    X = X + math.floor((W - 1) / 2)
    Y = Y + math.floor((H - 1) / 2)
  end

  -- Align to grid
  if W % 2 == 0 then X = X + 0.5 end
  if H % 2 == 0 then Y = Y + 0.5 end

  -- Subtract 1 pixel from edges to avoid tile overlap
  W = W - 1/128
  H = H - 1/128

  return {
    {deployer.position.x+X-(W/2), deployer.position.y+Y-(H/2)},
    {deployer.position.x+X+(W/2), deployer.position.y+Y+(H/2)},
  }
end

-- Return integer value for given Signal: {type=, name=}
function get_signal( entity, signal )
  -- Cache the circuit networks to speed up performance
  local cache = global.net_cache[entity.unit_number]
  if not cache then
    cache = {last_update = -1}
    global.net_cache[entity.unit_number] = cache
  end
  -- Try to reload empty networks once per tick
  -- Never reload valid networks
  if cache.last_update < game.tick then
    if not cache.red_network or not cache.red_network.valid then
      cache.red_network = entity.get_circuit_network(defines.wire_type.red)
    end
    if not cache.green_network or not cache.green_network.valid then
      cache.green_network = entity.get_circuit_network(defines.wire_type.green)
    end
    cache.last_update = game.tick
  end

  -- Get the signal
  local value = 0
  if cache.red_network then
    value = value + cache.red_network.get_signal(signal)
  end
  if cache.green_network then
    value = value + cache.green_network.get_signal(signal)
  end

  -- Mimic circuit network integer overflow
  if value > 2147483647 then value = value - 4294967296 end
  if value < -2147483648 then value = value + 4294967296 end
  return value
end
