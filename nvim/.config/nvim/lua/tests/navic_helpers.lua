local function sym(name, kind, sl, sc, el, ec, children)
  return {
    name = name,
    kind = kind,
    range = {
      start = { line = sl, character = sc },
      ['end'] = { line = el, character = ec },
    },
    children = children or {},
  }
end

return { sym = sym }
