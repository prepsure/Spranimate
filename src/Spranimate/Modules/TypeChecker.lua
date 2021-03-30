local TypeChecker = {}

function TypeChecker.AssertType(value, t, canBeNil)
    assert( (type(value) == t) or (canBeNil and (value == nil)) )
end

return TypeChecker