# coordconv

Geographic coordinates conversion module - stereographic conversion implemented using WGS84 ellipse parameters.

**NAME**

    Vector2D

**SYNOPSYS**

    use Vector2D;

    my $vector = Vector2D->new();

    my $vector = Vector2D->new(1, 1);

  **Constructor**

    new(X: 0, y: 0)
        The constructor expects zero, one or max two scalar values.

  **Methods**

    - set( $v0, $v1, $opt, $opt1 )
        This method sets the vector elements. Depending on the type of
        caller - Class or instance - the method will parse first three, or
        all arguments.

        If caller is a Class, the $v1 refers to the instance which will be
        altered with the remaining arguments - if they defined.

        If caller is an instance, $1 and $opt will be used to set vector
        elements.

    - add( $v0, $v1, $opt )
        See "subtract" above.

    - subtract($v0, $v1, $opt)
        Expects maximum 3 arguments. If all arguments set - the argument
        count equals 3, the first two will contain the references to the
        Vector2D instances.

        If only two arguments defined - the static method called - the
        Vector2D class calls the subtract method with two references: first
        vector will be subtracted by second vector.

        The result going to be stored into a new vector in both cases;

    - print($v0, $v1, $opt)
        If the caller is not an instance but Vector2D class, the last two
        arguments processed - $opt refers to the label text argument, this
        is optional. The $v1 argument refers to an instance of Vector2D
        class.

        If the caller is an instance, only the first two arguments will be
        used.

        The first one is the instance itself, the second - optional -
        argument is the label text.

        Returns the printed instance in both cases.

    - zero($v0, $v1)
        This method initializes the vector with 0s.

        If caller is a Class, then the second argument will be zeroed,
        otherwise the first one which is the instance itself.

    - clone(@args)
        This method creates an exact copy of the argument ( *which must be
        an instance of Vector2D class* ) - in that case, when the caller is
        the Class -, or itself.

        Returns a new instance vector.

    - copy(@args)
        This method is an alias of clone. See details clone method above.

    - dot(@args)
        This method calculates the dot product of the two vectors.

    - mul(@args)
        This method multiplies two vectors - common elements miltiplied -
        quite the same as dot product, but the result is not summed.

    - div(@args)
        This method multiplies two vectors - common elements miltiplied -
        quite the same as dot product, but the result is not summed.

  **Misc methods**
    These methods extends the capabilities of the Vector2D package.

    - debug(__LINE__,__FILE__[,message])
        prints out debug information.

**FILES**

    Vector2D.pm

**SEE ALSO**

    Vector3D(3), Matrix2D(3), Matrix3D(3), Matrix4D(3)

**AUTHOR**

    G.Zelenak
