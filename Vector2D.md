# Vector and matrix manipulations

These codes were designed and implemented in Perl programming language.

## NAME

Vector2D

## SYNOPSYS

This is a 2D vector class - or 2D point class with numerous useful methods.

```perl
use Vector2D;

my $vector = Vector2D->new();

my $vector = Vector2D->new(1, 1);
```

### Constructor

```perl
Vector2D->new();
```

The constructor expects zero, one or max two scalar values.

### Methods

- **set( @args )**

    This method sets the vector elements. Depending on the type of
    caller - Class or instance - the method will parse first three, or
    all arguments.

    If caller is a Class, the $v1 refers to the instance which will be
    altered with the remaining arguments - if they defined.

    If caller is an instance, $1 and $opt will be used to set vector
    elements.

- **add( @args )**

    See "subtract" above.

- **sadd(@args)**

    This method adds a scalar value to the vector's each elements.

- **ssub(@args)**

    This method decrements the vector's each elements by a scalar value.

- **subtract(@args)**

    Expects maximum 3 arguments. If all arguments set - the argument
    count equals 3, the first two will contain the references to the
    Vector2D instances.

    If only two arguments defined - the static method called - the
    Vector2D class calls the subtract method with two references: first
    vector will be subtracted by second vector.

    The result going to be stored into a new vector in both cases;

- **print(@args)**

    If the caller is not an instance but Vector2D class, the last two
    arguments processed - $opt refers to the label text argument, this
    is optional. The $v1 argument refers to an instance of Vector2D
    class.

    If the caller is an instance, only the first two arguments will be
    used.

    The first one is the instance itself, the second - optional -
    argument is the label text.

    Returns the printed instance in both cases.

- **zero([$arg])**
    This method initializes the vector with 0s.

    If caller is a Class, then the second argument will be zeroed,
    otherwise the first one which is the instance itself.

- **clone(@args)**
    This method creates an exact copy of the argument ( *which must be
    an instance of Vector2D class* ) - in that case, when the caller is
    the Class -, or itself.

    Returns a new instance vector.

- **copy(@args)**
    This method is an alias of clone. See details clone method above.

- **dot(@args)**
    This method calculates the dot product of the two vectors.

- **cross(@args)**
    This method returns the cross product of two Vector2D

- **mul(@args)**
    This method multiplies two vectors - common elements miltiplied -
    quite the same as dot product, but the result is not summed.

- **div(@args)**
    This method multiplies two vectors - common elements miltiplied -
    quite the same as dot product, but the result is not summed.

- **length([$arg])**
    This method gives back the length of the vector - the distance of
    the vector end from the origo.

- **lengthSq([$arg])**
    This method gives back the length squared of the vector.

- **manhattanLength([$arg])**
    This method calculates the vector's Manhattan length.

- **negate([$arg])**
    This method negates the vector.

- **sdiv(@args)**
    THis method returns the vector which elements were divided by scalar

- **smul(@args)**
    THis method returns the vector which elements were multiplied by
    scalar

- **normalize([$arg])**
    This method calculates the normalized vector - unit vector - from
    the original one.

- **angle([$arg])**
    This method calculates direction of the vector. X - heading right -
    represents North.

- **angleNU([$arg])**
    This method calculates direction of the vector. Y - heading up -
    represents North.

- **angleTo(@args)**
    This method calculates the direction between two vectors in 2D.

- **angleToNU(@args)** *deprecated*
    This method calculates the direction between two vectors in 2D - Y
    axis North up.

- **vmin(@args)**
    This method compares two vectors - at each element index - and
    returns with a new vector containing the minimum values from the
    original vectors.

- **vmax(@args)**
    This method compares two vectors - at each element index - and
    returns with a new vector containing the maximum values from the
    original vectors.

- **vclamp(@args)**
    This method 'clamps-down' - or restrict in terms of its element
    values of the left most vector (the instance itself, or in case the
    static call, the very first vector) between the limits set by the
    next two vectors. Simplified: keeps vector in range between the
    other two as limits.

- **clampScalar(@args)**
    This method returns a vector which elements value restricted to be
    in the range defined by the next two scalar values.

- **clampLength(@args)**
    This method calculates the clamped length of the vector between the
    range minimum and maximum values.

- **vfloor([$arg])**
    This method rounds down the vector's elements to the nearest integer

- **vceil([$arg])**
    This method rounds up the vector's elements to the nearest integer

- **vround([$arg])**
    This method rounds the vector's elements to the nearest integer

- **vtruncate([$arg])**
    This method modifies the vetor elements setting each of its integer
    part value. This method does not apply any kind of mathematical
    rounding, simply cuts off the decimal part - if any - from vector
    element at index.

- **distanceToSquared(@args)**
    This method calculates the squared distance between two vectors

- **distanceTo(@args)**
    This method calculates the distance between two vectors

- **manhattanDistanceTo(@args)**
    Calculates Manhattan distance between two vectors.

- **setLength(arg)**
    This method returns a modified length of the original vector

- **vlerp(@args)**
    This method calculates the linear extrapolated vector based on a
    given scalar value.

- **vlerpVectors(@args)**
    This method calculates the lerp vector of three vectors and a scalar

- **equals(@args)**
    Checks wether two vectors equal or not.

- **rotateAround(@args)**
    This method rotates the original vector around another vector by
    angle.

- **random()**
    This method generates random valued vector.

### Misc methods

These methods extends the capabilities of the Vector2D package.

- **debug(\_\_LINE\_\_,\_\_FILE\_\_[,message])**

    prints out debug information.

- **normalize_angle_degrees($angle_in_degrees)**

    returns the angle in range 0 .. 360 degrees

- **normalize_angle_radians($angle_in_radians)**

    returns the angle in range 0 .. 2 * PI radians

- **clamp(min, max, value)**

    This method returns clamp value - in range 'min' .. 'max' -, or in
    case when the value is out of the range, then returns 'min' if value
    is below the minimum, or returns 'max' if the value is beyond the
    maximum.

## FILES

Vector2D.pm

## SEE ALSO

*Vector3D(3)*, *Matrix2D(3)*, *Matrix3D(3)*, *Matrix4D(3)*

## AUTHOR

G.Zelenak
