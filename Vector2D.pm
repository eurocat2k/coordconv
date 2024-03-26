package Vector2D;

=head1 NAME

Vector2D

=head1 SYNOPSYS

use Vector2D;

my $vector = Vector2D->new();

my $vector = Vector2D->new(1, 1);

=cut

use utf8;
use strict;
use warnings;
use Data::Dumper;
use POSIX qw(ceil sqrt sin cos round floor);
use Math::Trig qw (:pi);
use Math::Trig qw(deg2rad rad2deg acos);
use List::Util qw(min max);
use Carp;
use Scalar::Util qw(looks_like_number);
use constant MAXSIZE => 2;    # 1X2 vector X,Y
use constant DEBUG => 0; # 1 uses DEBUG constants
use constant PI => atan2(1, 1) * 4;
# use constant PI => pi;
# use constant PI => POSIX::M_PI;
use constant HALF_PI => PI * .5;
use constant TWO_PI => PI * 2;
use FindBin;
use lib "$FindBin::Bin";
BEGIN {
    require Exporter;
    # printf "PI: %.12e\n", PI;
    # printf "PI: %.12e\n", pi;
    # printf "PI: %.12e\n", (atan2(1,1) * 4);
}
our @ISA = qw(Exporter);
our $VERSION = qw(1.0.0);
our @EXPORT = qw(new);
our @EXPORT_OK =
  qw(dim size debug normalize_angle_degrees normalize_angle_radians);
my $dim;
my $size;
# operator overloads
use overload
    '+' => sub {
        my ( $v0, $v1, $opt ) = @_;
        # return $v0->add($v1);
        my $ret = Vector2D->add($v0, $v1);
    },
    '-' => sub {
        my ( $v0, $v1, $opt ) = @_;
        return Vector2D->subtract($v0, $v1);;
    },
    '*' => sub {
        my ( $v0, $v1, $opt ) = @_;
        if (ref ($v0) eq ref($v1) and ref($v0) eq __PACKAGE__) {
            return Vector2D->mul( $v0, $v1 );
        } elsif (ref ($v0) eq __PACKAGE__ and defined $v1 and ref(\$v1) eq 'SCALAR') {
            return Vector2D->smul($v0, $v1);
        } elsif (ref (\$v0) eq 'SCALAR' and defined $v1 and ref($v1) eq __PACKAGE__) {
            return Vector2D->smul($v1, $v0);
        }
        croak "Error: missing or invalid type of arguments detected";
    },
    '/' => sub {
        my ( $v0, $v1, $opt ) = @_;
        return Vector2D->div( $v0, $v1 );
    },
    'x' => sub {
        my ( $v0, $v1, $opt ) = @_;
        return Vector2D->cross($v0, $v1);
    },
    '.' => sub {
        my ( $v0, $v1, $opt ) = @_;
        return Vector2D->dot($v0, $v1);
    },
    '==' => sub {
        return Vector2D->dot($_[0], $_[1]);
    },
    '!=' => sub {
        return not Vector2D->dot($_[0], $_[1]);
    };
#
my $private_nearest_square = sub {
    my $n = @_;
    my $sq = round(sqrt($n))**2;
    if ($sq < 2) {
        return 2;
    }
    if ($sq < $n) {
        return Vector2D::private_nearest_square->($n+1);
    }
    return $sq;
};
my $private_nearest_square_root = sub {
    my $n = shift;
    my $sq = $private_nearest_square->($n);
    return sqrt($sq);
};
#
=head2 Constructor

=over

=item new(X: 0, y: 0)

The constructor expects zero, one or max two scalar values.

=back

=cut

sub new {
    my $self   = $_[0];
    my @params = @_;

    # print Dumper {params => @params};
    # @params = splice(@params, 0, MAXSIZE);
    my $elems = [];
    for ( 0 .. MAXSIZE- 1 ) {
        if ( defined $params[ $_ + 1 ] ) {
            @$elems[$_] = $params[ $_ + 1 ];
        }
        else {
            @$elems[$_] = 0;
        }
    }
    return bless { elems => $elems, dim => 1, size => MAXSIZE },
      ref($self) || $self;
}
#
sub dim {
    my ($self, $v0) = @_;
    unless (ref $self) {
        # Static
        unless (ref($v0) ne __PACKAGE__ ) {
            return $v0->{dim};
        }
        die "Error: ".__PACKAGE__."->dim expects ".__PACKAGE__." type argument";
    } else {
        # Instance
        return $self->{dim};
    }
}
#
sub size {
    my ($self, $v0) = @_;
    unless (ref $self) {
        # Static
        unless (ref($v0) ne __PACKAGE__ ) {
            return $v0->{size};
        }
        die "Error: ".__PACKAGE__."->dim expects ".__PACKAGE__." type argument";
    } else {
        # Instance
        return $self->{size};
    }
}
#

=head2 Methods

=over

=item - set( @args )

This method sets the vector elements. Depending on the type of caller - Class or instance -
the method will parse first three, or all arguments.

If caller is a Class, the $v1 refers to the instance which will be
altered with the remaining arguments - if they defined.

If caller is an instance, $1 and $opt will be used to set vector elements.

=back

=cut

sub set {
    my ( $v0, $v1, $opt, $opt1 ) = @_;
    croak "Not enough arguments for ", ( caller(0) )[3] if @_ < 2;
    croak "Too many arguments for ",   ( caller(0) )[3] if @_ > 4;
    unless ( ref($v0) ) {

        # $v1, $opt, $opt1 used
        croak "Error: invalid type of argument detected: expected "
          . __PACKAGE__
          . " and optionally other two scalars - ", ( caller(0) )[3]
          if ( ref($v1) ne __PACKAGE__ );
        my @args = ( $opt, $opt1 );
        for ( 0 .. MAXSIZE - 1 ) {
            $v1->{elems}[$_] = $args[$_] if defined $args[$_];
        }
        return $v1;
    }
    else {
        # $v0, $v1, $opt used
        my @args = ( $v1, $opt );
        for ( 0 .. MAXSIZE - 1 ) {
            $v0->{elems}[$_] = $args[$_] if defined $args[$_];
        }
        return $v0;
    }
}
#

=over

=item - add( @args )

See C<subtract> above.

=back

=cut

sub add {
    my ( $v0, $v1, $opt ) = @_;

    # print "argcount:" . scalar @_ . "\n";
    croak "Not enough arguments for ", ( caller(0) )[3] if @_ < 2;
    croak "Too many arguments for ",   ( caller(0) )[3] if @_ > 3;
    unless ( ref($v0) ) {
        if ( ref($v1) eq ref($opt) and ref($v1) eq __PACKAGE__ ) {
            my $vr = $v1->new;
            for ( 0 .. MAXSIZE - 1 ) {
                $vr->{elems}[$_] = $v1->{elems}[$_] + $opt->{elems}[$_];
            }
            return $vr;
        }
    }
    else {
        # # returns new vector
        if ( ref($v0) eq ref($v1) and ref($v0) eq __PACKAGE__ ) {
            my $vr = $v0->new;
            for ( 0 .. MAXSIZE - 1 ) {
                $vr->{elems}[$_] = $v0->{elems}[$_] + $v1->{elems}[$_];
            }
            return $vr;
        }
    }
}
#

=over

=item sadd(@args)

This method adds a scalar value to the vector's each elements.

=back

=cut
sub sadd {
    my $ret;
    unless (ref $_[0]) {
        # static
        croak "Error: 1st argument type is not ".__PACKAGE__."\n", (caller(0))[3] if (ref($_[1]) ne __PACKAGE__);
        croak "Error: missing or invalid type of 2nd argument", ( caller(0) )[3]
          if (not defined $_[2] or ref( \$_[2] ) ne 'SCALAR' );
        $ret = Vector2D->new();
        for ( 0 .. MAXSIZE- 1 ) {
            $ret->{elems}[$_] = $_[1]->{elems}[$_] + $_[2];
        }
    } else {
        # instance
        croak "Error: missing or invalid type of 2nd argument", ( caller(0) )[3]
          if (not defined $_[1] or ref( \$_[1] ) ne 'SCALAR' );
        $ret = Vector2D->new();
        for ( 0 .. MAXSIZE- 1 ) {
            $ret->{elems}[$_] = $_[0]->{elems}[$_] + $_[1];
        }
    }
    return $ret;
}
#

=over

=item ssub(@args)

This method decrements the vector's each elements by a scalar value.

=back

=cut
sub ssub {
    my $ret;
    unless (ref $_[0]) {
        # static
        croak "Error: 1st argument type is not ".__PACKAGE__."\n", (caller(0))[3] if (ref($_[1]) ne __PACKAGE__);
        croak "Error: missing or invalid type of 2nd argument", ( caller(0) )[3]
          if (not defined $_[2] or ref( \$_[2] ) ne 'SCALAR' );
        $ret = Vector2D->new();
        for (0..MAXSIZE-1) {
            $ret->{elems}[$_] = $_[1]->{elems}[$_] - $_[2];
        }
    } else {
        # instance
        croak "Error: missing or invalid type of 2nd argument", ( caller(0) )[3]
          if (not defined $_[1] or ref( \$_[1] ) ne 'SCALAR' );
        $ret = Vector2D->new();
        for (0..MAXSIZE-1) {
            $ret->{elems}[$_] = $_[0]->{elems}[$_] - $_[1];
        }
    }
    return $ret;
}
#

=over

=item - subtract(@args)

Expects maximum 3 arguments. If all arguments set - the argument count equals 3, the first
two will contain the references to the Vector2D instances.

If only two arguments defined - the static method called - the Vector2D class calls
the subtract method with two references: first vector will be subtracted by second vector.

The result going to be stored into a new vector in both cases;

=back

=cut
sub subtract {
    my ( $v0, $v1, $opt ) = @_;
    # print "argcount:" . scalar @_ . "\n";
    croak "Not enough arguments for ", ( caller(0) )[3] if @_ < 2;
    croak "Too many arguments for ",   ( caller(0) )[3] if @_ > 3;
    unless ( ref($v0) ) {
        if ( ref($v1) eq ref($opt) and ref($v1) eq __PACKAGE__ ) {
            my $vr = $v1->new;
            for ( 0 .. MAXSIZE - 1 ) {
                $vr->{elems}[$_] = $v1->{elems}[$_] - $opt->{elems}[$_];
            }
            return $vr;
        }
    }
    else {
        # # returns new vector
        if ( ref($v0) eq ref($v1) and ref($v0) eq __PACKAGE__ ) {
            my $vr = $v0->new;
            for ( 0 .. MAXSIZE - 1 ) {
                $vr->{elems}[$_] = $v0->{elems}[$_] - $v1->{elems}[$_];
            }
            return $vr;
        }
    }
}
#

=over

=item - print(@args)

If the caller is not an instance but Vector2D class, the last two
arguments processed - $opt refers to the label text argument, this is
optional. The $v1 argument refers to an instance of Vector2D class.

If the caller is an instance, only the first two arguments will be used.

The first one is the instance itself, the second - optional - argument
is the label text.

Returns the printed instance in both cases.

=back

=cut

sub print {
    my ($v0, $v1, $opt) = @_;
    my $ret;
    unless (ref($v0)) {
        # the static method
        croak "Error: argument type is not ".__PACKAGE__."\n", (caller(0))[3] if (ref($v1) ne __PACKAGE__);
        if (defined $opt) {
            print qq("$opt").": [\n";
        } else {
            print "[\n";
        }
        for (0 .. MAXSIZE - 1) {
            # printf "    %.12e,\n", $v1->{elems}[$_] unless ($_ < MAXSIZE - 1);
            if ($_ < MAXSIZE - 1){
                printf "    %.12e, \n", $v1->{elems}[$_];
                carp "DEBUG: \$v1->{elements}[$_] = "
                  . $v1->{elems}[$_]
                  . "; # called ", ( caller(0) )[3]
                  unless !DEBUG;
            } else {
                printf "    %.12e \n", $v1->{elems}[$_];
                carp "DEBUG: \$v1->{elements}[$_] = "
                  . $v1->{elems}[$_]
                  . "; # called ", ( caller(0) )[3]
                  unless !DEBUG;
            }
        }
        $ret = $v1;
    } else {
        # the instance method
        if (defined $v1 and ref(\$v1) eq 'SCALAR') {
            print qq("$v1") . ": [\n"
        } else {
            print "[\n";
        }
        for (0 .. MAXSIZE - 1) {
            if ( $_ < MAXSIZE - 1 ) {
                printf "    %.12e, \n", $v0->{elems}[$_];
                carp "DEBUG: \$v1->{elements}[$_] = "
                  . $v0->{elems}[$_]
                  . "; # called ", ( caller(0) )[3]
                  unless !DEBUG;
            }
            else {
                printf "    %.12e \n", $v0->{elems}[$_];
                carp "DEBUG: \$v1->{elements}[$_] = "
                  . $v0->{elems}[$_]
                  . "; # called ", ( caller(0) )[3]
                  unless !DEBUG;
            }
        }
        $ret = $v0;
    }
    print "]\n";
    return $ret;
}
#
=over

=item - zero([$arg])

This method initializes the vector with 0s.

If caller is a Class, then the second argument will be zeroed, otherwise the first one
which is the instance itself.

=back

=cut
sub zero {
    my $ret = $_[0];
    unless (ref $_[0]) {
        # static method: $_[1] shall be zeroed if it's an instance of Vector2D
        croak "Error: invalid type detected - called ", ( caller(0) )[3] if (ref ($_[1]) ne __PACKAGE__);
        for (0 .. MAXSIZE - 1) {
            $_[1]->{elems}[$_] = 0;
        }
        # print Dumper {retstatic => $_[1]};
        $ret = $_[1];
        # return $_[1];
    } else {
        for (0 .. MAXSIZE - 1) {
            $_[0]->{elems}[$_] = 0;
        }
        # print Dumper { retinstance => $_[0] };
        $ret = $_[0];
    }
    return $ret;
}
#

=over

=item - clone(@args)

This method creates an exact copy of the argument ( I<which must be an instance of Vector2D class> ) - in that case, when
the caller is the Class -, or itself.

Returns a new instance vector.

=back

=cut
sub clone {
    my $ret;
    unless (ref $_[0]) {
        croak "Error: invalid type detected - called ", ( caller(0) )[3]
          if ( ref( $_[1] ) ne __PACKAGE__ );
        # The trick - dereference instance elements into a list
        $ret = Vector2D->set( $_[1] , @{ $_[1]->{elems} } );
    } else {
        $ret = Vector2D->set( $_[0] , @{ $_[0]->{elems} } );
    }
    return $ret;
}
#

=over

=item - copy(@args)

This method is an alias of clone. See details L<clone> method above.

=back

=cut
sub copy {
    my $ret;
    unless (ref $_[0]) {
        croak "Error: invalid type detected - called ", ( caller(0) )[3]
          if ( ref( $_[1] ) ne __PACKAGE__ );
        # The trick - dereference instance elements into a list
        $ret = Vector2D->set( $_[1] , @{ $_[1]->{elems} } );
    } else {
        $ret = Vector2D->set( $_[0] , @{ $_[0]->{elems} } );
    }
    return $ret;
}
#
=over

=item - dot(@args)

This method calculates the dot product of the two vectors.

=back

=cut
sub dot {
    unless (ref $_[0]) {
        croak "Error: invalid argument detected at pos 1 ", (caller(0))[3] unless (ref $_[1] eq __PACKAGE__);
        croak "Error: invalid argument detected at pos 2 ", (caller(0))[3] unless (ref $_[2] eq __PACKAGE__);
        return ( $_[1]->{elems}[0] * $_[2]->{elems}[0] +
              $_[1]->{elems}[1] * $_[2]->{elems}[1] );
    } else {
        croak "Error: invalid argument detected at pos 1 ", ( caller(0) )[3]
          unless ( ref $_[1] eq __PACKAGE__ );
        return ( $_[0]->{elems}[0] * $_[1]->{elems}[0] +
              $_[0]->{elems}[1] * $_[1]->{elems}[1] );
    }
    # return this[0] * v[0] + this[1] * v[1];
}
#
=over

=item - cross(@args)

This method returns the cross product of two Vector2D

=back

=cut
sub cross {
    unless (ref $_[0]) {
        croak "Error: invalid argument detected at pos 1 ", ( caller(0) )[3]
          unless ( ref $_[1] eq __PACKAGE__ );
        croak "Error: invalid argument detected at pos 2 ", ( caller(0) )[3]
          unless ( ref $_[2] eq __PACKAGE__ );
        return ($_[1]->{elems}[0] * $_[2]->{elems}[1] - $_[1]->{elems}[1] * $_[2]->{elems}[0]);
    } else {
        croak "Error: invalid argument detected at pos 1 ", ( caller(0) )[3]
          unless ( ref $_[1] eq __PACKAGE__ );
        return ( $_[0]->{elems}[0] * $_[1]->{elems}[1] -
              $_[0]->{elems}[1] * $_[1]->{elems}[0] );
    }
}
#
=over

=item - mul(@args)

This method multiplies two vectors - common elements miltiplied - quite the same as dot product, but the result is not summed.

=back

=cut
sub mul {
    unless (ref $_[0]) {
        croak "Error: invalid argument detected at pos 1 ", (caller(0))[3] unless (ref $_[1] eq __PACKAGE__);
        croak "Error: invalid argument detected at pos 2 ", (caller(0))[3] unless (ref $_[2] eq __PACKAGE__);
        $_[1]->{elems}[0] *= $_[2]->{elems}[0];
        $_[1]->{elems}[1] *= $_[2]->{elems}[1];
        return $_[1];
    } else {
        croak "Error: invalid argument detected at pos 1 ", ( caller(0) )[3]
          unless ( ref $_[1] eq __PACKAGE__ );
        $_[0]->{elems}[0] *= $_[1]->{elems}[0];
        $_[0]->{elems}[1] *= $_[1]->{elems}[1];
        return $_[0];
    }
    # return this[0] * v[0] + this[1] * v[1];
}
#
=over

=item - div(@args)

This method multiplies two vectors - common elements miltiplied - quite the same as dot product, but the result is not summed.

=back

=cut
sub div {
    unless (ref $_[0]) {
        croak "Error: invalid argument detected at pos 1 ", (caller(0))[3] unless (ref $_[1] eq __PACKAGE__);
        croak "Error: invalid argument detected at pos 2 ", (caller(0))[3] unless (ref $_[2] eq __PACKAGE__);
        croak "Divide by zero is not allowed" unless $_[2]->{elems}[0] ne 0;
        croak "Divide by zero is not allowed" unless $_[2]->{elems}[1] ne 0;
        $_[1]->{elems}[0] *= (1 / $_[2]->{elems}[0]);
        $_[1]->{elems}[1] *= (1 / $_[2]->{elems}[1]);
        return $_[1];
    } else {
        croak "Error: invalid argument detected at pos 1 ", ( caller(0) )[3]
          unless ( ref $_[1] eq __PACKAGE__ );
        croak "Divide by zero is not allowed" unless $_[1]->{elems}[0] ne 0;
        croak "Divide by zero is not allowed" unless $_[1]->{elems}[1] ne 0;
        $_[0]->{elems}[0] *= (1 / $_[1]->{elems}[0]);
        $_[0]->{elems}[1] *= (1 / $_[1]->{elems}[1]);
        return $_[0];
    }
    # return this[0] * v[0] + this[1] * v[1];
}
#
=over

=item - length([$arg])

This method gives back the length of the vector - the distance of the vector end from the origo.

=back

=cut
sub length {
    unless(ref $_[0]) {
        croak "Error: invalid argument detected at pos 1 ", ( caller(0) )[3]
          unless ( ref $_[1] eq __PACKAGE__ );
        return sqrt(($_[1]->{elems}[0]**2) + ($_[1]->{elems}[1]**2));
    } else {
        return sqrt( ( $_[0]->{elems}[0]**2 ) + ( $_[0]->{elems}[1]**2 ) );
    }
}
#

=over

=item - lengthSq([$arg])

This method gives back the length squared of the vector.

=back

=cut
sub lengthSq {
    unless(ref $_[0]) {
        croak "Error: invalid argument detected at pos 1 ", ( caller(0) )[3]
          unless ( ref $_[1] eq __PACKAGE__ );
        return (($_[1]->{elems}[0]**2) + ($_[1]->{elems}[1]**2));
    } else {
        return ( ( $_[0]->{elems}[0]**2 ) + ( $_[0]->{elems}[1]**2 ) );
    }
}
#
=over

=item - manhattanLength([$arg])

This method calculates the vector's Manhattan length.

=back
=cut
sub manhattanLength {
    unless (ref $_[0]) {
        croak "Error: invalid argument detected at pos 1 ", ( caller(0) )[3]
          unless ( ref $_[1] eq __PACKAGE__ );
        return abs($_[1]->{elems}[0]) + abs($_[1]->{elems}[1]);
    } else {
        return abs($_[0]->{elems}[0]) + abs($_[0]->{elems}[1]);
    }
}
#
=over

=item - negate([$arg])

This method negates the vector.

=back
=cut
sub negate {
    unless (ref $_[0]) {
        croak "Error: invalid argument detected at pos 1 ", ( caller(0) )[3]
          unless ( ref $_[1] eq __PACKAGE__ );
        $_[1]->{elems}[0] = -$_[1]->{elems}[0];
        $_[1]->{elems}[1] = -$_[1]->{elems}[1];
        return $_[1];
    } else {
        $_[0]->{elems}[0] = -$_[0]->{elems}[0];
        $_[0]->{elems}[1] = -$_[0]->{elems}[1];
        return $_[0];
    }
}
#
=over

=item - sdiv(@args)

THis method returns the vector which elements were divided by scalar

=back
=cut
sub sdiv {
    unless (ref $_[0]) {
        croak "Error: invalid argument detected at pos 1 ", ( caller(0) )[3]
          unless ( ref $_[1] eq __PACKAGE__ );
        my $rv = Vector2D->new;
        if (defined $_[1]) {
            croak "Error: invalid argument type at pos 2: expected scalar ",
              ( caller(0) )[3]
              unless ( ref \$_[2] eq 'SCALAR' );
            croak "Divide by zero is not allowed" unless $_[2] ne 0;
            $rv->set($_[1]->{elems}[0] /= $_[2], $_[1]->{elems}[1] /= $_[2]);
            return $rv;
        }
        $rv->set(@{$_[1]});
        return $rv;
    } else {
        croak "Error: invalid argument type at pos 1: expected scalar ",
          ( caller(0) )[3]
          unless ( ref \$_[1] eq 'SCALAR' );
        croak "Divide by zero is not allowed" unless $_[1] ne 0;
        $_[0]->{elems}[0] /= $_[1];
        $_[0]->{elems}[1] /= $_[1];
        return $_[0];
    }
}
#
=over

=item - smul(@args)

THis method returns the vector which elements were multiplied by scalar

=back
=cut
sub smul {
    unless ( ref $_[0] ) {
        croak "Error: invalid argument detected at pos 1 ", ( caller(0) )[3]
          unless ( ref $_[1] eq __PACKAGE__ );
        my $rv = Vector2D->new;
        if ( defined $_[1] ) {
            croak "Error: invalid argument type at pos 2: expected scalar ",
              ( caller(0) )[3]
              unless ( ref \$_[2] eq 'SCALAR' );
            $rv->set( $_[1]->{elems}[0] *= $_[2], $_[1]->{elems}[1] *= $_[2] );
            return $rv;
        }
        $rv->set( @{ $_[1] } );
        return $rv;
    }
    else {
        croak "Error: invalid argument type at pos 1: expected scalar ",
          ( caller(0) )[3]
          unless ( ref \$_[1] eq 'SCALAR' );
        $_[0]->{elems}[0] *= $_[1];
        $_[0]->{elems}[1] *= $_[1];
        return $_[0];
    }
}
#
=over

=item - normalize([$arg])

This method calculates the normalized vector - unit vector - from the original one.

=back
=cut
sub normalize {
    unless (ref $_[0]) {
        croak "Error: invalid argument detected at pos 1 ", ( caller(0) )[3]
          unless ( ref $_[1] eq __PACKAGE__ );
        my $vr = Vector2D->new;
        return $vr->set(@{$_[1]->sdiv($_[1]->length)});
    } else {
        return $_[0] = $_[0]->sdiv($_[0]->length);
    }
}
#
=over

=item - angle([$arg])

This method calculates direction of the vector. X - heading right - represents North.

=back
=cut
sub angle {
    unless (ref $_[0]) {
        croak "Error: invalid argument detected at pos 1 ", ( caller(0) )[3]
          unless ( ref $_[1] eq __PACKAGE__ );
        return atan2($_[1]->{elems}[1], $_[1]->{elems}[0]);
    } else {
        return atan2( $_[0]->{elems}[1], $_[0]->{elems}[0] );
    }
}
#
=over

=item - angleNU([$arg])

This method calculates direction of the vector. Y - heading up - represents North.

=back
=cut
sub angleNU {
    unless (ref $_[0]) {
        croak "Error: invalid argument detected at pos 1 ", ( caller(0) )[3]
          unless ( ref $_[1] eq __PACKAGE__ );
        return atan2( $_[1]->{elems}[1], - $_[1]->{elems}[0]) #- PI / 2;
    } else {
        return atan2( - $_[0]->{elems}[1], -$_[0]->{elems}[0] ) #- PI / 2;
    }
}
#
=over

=item - angleTo(@args)

This method calculates the direction between two vectors in 2D.

=back
=cut
sub angleTo {
    unless (ref $_[0]) {
        croak "Error: invalid or missing argument detected at pos 1 ", ( caller(0) )[3]
          unless (defined $_[1] and ref $_[1] eq __PACKAGE__ );
        croak "Error: invalid or missing argument detected at pos 2 ", ( caller(0) )[3]
          unless (defined $_[1] and  ref $_[2] eq __PACKAGE__ );
        my $denominator = sqrt( $_[1]->lengthSq * $_[2]->lengthSq );
        if ( $denominator eq 0 ) {
            return HALF_PI;
        }
        my $theta = $_[1]->dot( $_[2] ) / $denominator;

        # // clamp, to handle numerical problems
        return acos( clamp( $theta, -1, 1 ) );
    } else {
        croak "Error: invalid or missing argument detected at pos 1 ", ( caller(0) )[3]
        unless ( defined $_[1] and ref $_[1] eq __PACKAGE__ );

        my $denominator = sqrt( $_[0]->lengthSq * $_[1]->lengthSq );
        if ( $denominator eq 0 ) {
            return HALF_PI
        };
        my $theta = $_[0]->dot($_[1]) / $denominator;
        # // clamp, to handle numerical problems
        return acos( clamp( $theta, -1, 1 ) );
    }
}
#
=over

=item - angleToNU(@args) I<deprecated>

This method calculates the direction between two vectors in 2D - Y axis North up.

=back
=cut
sub angleToNU {
    unless (ref $_[0]) {
        croak "Error: invalid or missing argument detected at pos 1 ", ( caller(0) )[3]
          unless (defined $_[1] and ref $_[1] eq __PACKAGE__ );
        croak "Error: invalid or missing argument detected at pos 2 ", ( caller(0) )[3]
          unless (defined $_[1] and  ref $_[2] eq __PACKAGE__ );
        my $denominator = sqrt( $_[1]->lengthSq * $_[2]->lengthSq );
        if ( $denominator eq 0 ) {
            return HALF_PI;
        }
        my $theta = ($_[1]->dot( $_[2] ) / $denominator);

        # // clamp, to handle numerical problems
        return acos( clamp( $theta, -1, 1 ) );
    } else {
        croak "Error: invalid or missing argument detected at pos 1 ", ( caller(0) )[3]
        unless ( defined $_[1] and ref $_[1] eq __PACKAGE__ );

        my $denominator = sqrt( $_[0]->lengthSq * $_[1]->lengthSq );
        if ( $denominator eq 0 ) {
            return HALF_PI
        };
        my $theta = ($_[0]->dot($_[1]) / $denominator);
        # // clamp, to handle numerical problems
        return acos( clamp( $theta, -1, 1 ) );
    }
}
#
=over

=item vmin(@args)

This method compares two vectors - at each element index - and returns with a new vector containing the minimum values from the original vectors.

=back
=cut
sub vmin {
    my $ret;
    unless(ref $_[0]) {
        # static
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[1] and ref $_[1] eq __PACKAGE__ );
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[2] and ref $_[2] eq __PACKAGE__ );
        $ret = Vector2D->new;
        for (0..MAXSIZE-1) {
            $ret->{elems}[$_] = min( $_[1]->{elems}[$_], $_[2]->{elems}[$_] );
        }
    } else {
        # instance
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[1] and ref $_[1] eq __PACKAGE__ );
        $ret = $_[0];
        for ( 0 .. MAXSIZE- 1 ) {
            $ret->{elems}[$_] = min( $_[0]->{elems}[$_], $_[1]->{elems}[$_] );
        }
    }
    return $ret;
}
#
=over

=item vmax(@args)

This method compares two vectors - at each element index - and returns with a new vector containing the maximum values from the original vectors.

=back
=cut
sub vmax {
    my $ret;
    unless ( ref $_[0] ) {

        # static
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[1] and ref $_[1] eq __PACKAGE__ );
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[2] and ref $_[2] eq __PACKAGE__ );
        $ret = Vector2D->new;
        for ( 0 .. MAXSIZE- 1 ) {
            $ret->{elems}[$_] = max( $_[1]->{elems}[$_], $_[2]->{elems}[$_] );
        }
    }
    else {
        # instance
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[1] and ref $_[1] eq __PACKAGE__ );
        $ret = $_[0];
        for ( 0 .. MAXSIZE- 1 ) {
            $ret->{elems}[$_] = max( $_[0]->{elems}[$_], $_[1]->{elems}[$_] );
        }
    }
    return $ret;
}
#
=over

=item vclamp(@args)

This method 'clamps-down' - or restrict in terms of its element values of the left most vector
(the instance itself, or in case the static call, the very first vector) between the limits
set by the next two vectors. Simplified: keeps vector in range between the other two as limits.

=back
=cut
sub vclamp {
    my $ret;
    unless(ref $_[0]) {
        # static
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[1] and ref $_[1] eq __PACKAGE__ );
        croak "Error: invalid or missing argument detected at pos 2 ",
          ( caller(0) )[3]
          unless ( defined $_[2] and ref $_[2] eq __PACKAGE__ );
        croak "Error: invalid or missing argument detected at pos 3 ",
          ( caller(0) )[3]
          unless ( defined $_[3] and ref $_[3] eq __PACKAGE__ );
        $ret = $_[1];
        my @min = @{$_[2]->{elems}};
        my @max = @{$_[3]->{elems}};
        $ret->{elems}[0] = max( $min[0], min( $max[0], $ret->{elems}[0] ) );
        $ret->{elems}[1] = max( $min[1], min( $max[1], $ret->{elems}[1] ) );
    } else {
        # instance
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[1] and ref $_[1] eq __PACKAGE__ );
        croak "Error: invalid or missing argument detected at pos 2 ",
          ( caller(0) )[3]
          unless ( defined $_[2] and ref $_[2] eq __PACKAGE__ );
        # destructive
        $ret = $_[0];
        my @min = @{$_[1]->{elems}};
        my @max = @{$_[2]->{elems}};
        $ret->{elems}[0] = max( $min[0], min( $max[0], $ret->{elems}[0] ) );
        $ret->{elems}[1] = max( $min[1], min( $max[1], $ret->{elems}[1] ) );
    }
    return $ret;
}
#
=over

=item clampScalar(@args)

This method returns a vector which elements value restricted to be in the range defined by the next two scalar values.

=back
=cut
sub clampScalar {
    my $ret;
    unless (ref $_[0]) {
        # static
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[1] and ref $_[1] eq __PACKAGE__ );
        croak "Error: invalid or missing argument detected at pos 2 ",
          ( caller(0) )[3]
          unless ( defined $_[2] and ref \$_[2] eq 'SCALAR' );
        croak "Error: invalid or missing argument detected at pos 3 ",
          ( caller(0) )[3]
          unless ( defined $_[3] and ref \$_[3] eq 'SCALAR' );
        # print Dumper{
        #     ret => $_[1],
        #     min => $_[2],
        #     max => $_[3]
        # };
        $ret = $_[1];
        my $min = $_[2];
        my $max = $_[3];;
        $ret->{elems}[0] = max($min, min($max, $ret->{elems}[0]));
        $ret->{elems}[1] = max($min, min($max, $ret->{elems}[1]));
    } else {
        # instance
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[1] and ref \$_[1] eq 'SCALAR' );
        croak "Error: invalid or missing argument detected at pos 2 ",
          ( caller(0) )[3]
          unless ( defined $_[2] and ref \$_[2] eq 'SCALAR' );
        $ret = $_[0];
        my $min = $_[1];
        my $max = $_[2];
        $ret->{elems}[0] = max($min, min($max, $ret->{elems}[0]));
        $ret->{elems}[1] = max($min, min($max, $ret->{elems}[1]));
    }
    return $ret;
}
#
=over

=item clampLength(@args)

This method calculates the clamped length of the vector between the range minimum and maximum values.

=back
=cut
sub clampLength {
    unless (ref $_[0]) {
        # static call
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[1] and ref $_[1] eq __PACKAGE__ );
        croak "Error: invalid or missing argument detected at pos 2 ",
          ( caller(0) )[3]
          unless ( defined $_[2] and ref \$_[2] eq 'SCALAR' );
        croak "Error: invalid or missing argument detected at pos 3 ",
          ( caller(0) )[3]
          unless ( defined $_[3] and ref \$_[3] eq 'SCALAR' );
        my $length = $_[1]->length;
        my $min = $_[2];
        my $max = $_[3];
        return $_[1]->sdiv($length || 1)->smul(max($min, min($max, $length)));
    } else {
        # instance call
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[1] and ref \$_[1] eq 'SCALAR' );
        croak "Error: invalid or missing argument detected at pos 2 ",
          ( caller(0) )[3]
          unless ( defined $_[2] and ref \$_[2] eq 'SCALAR' );
        my $length = $_[0]->length;
        my $min = $_[1];
        my $max = $_[2];
        $length = 1 unless ($length ne 0);
        return $_[0]->sdiv( $length )->smul( max( $min, min( $max, $length ) ) );
    }
}
#
=over

=item vfloor([$arg])

This method rounds down the vector's elements to the nearest integer

=back
=cut
sub vfloor {
    unless (ref $_[0]) {
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[1] and ref $_[1] eq __PACKAGE__ );
        my $ret = $_[1];
        $ret->{elems}[0] = floor($_[1]->{elems}[0]);
        $ret->{elems}[1] = floor($_[1]->{elems}[1]);
        return $ret;
    } else {
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[0] and ref $_[0] eq __PACKAGE__ );
        my $ret = $_[0];
        $ret->{elems}[0] = floor($_[0]->{elems}[0]);
        $ret->{elems}[1] = floor($_[0]->{elems}[1]);
        return $ret;
    }
}
#
=over

=item vceil([$arg])

This method rounds up the vector's elements to the nearest integer

=back
=cut
sub vceil {
    unless (ref $_[0]) {
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[1] and ref $_[1] eq __PACKAGE__ );
        my $ret = $_[1];
        $ret->{elems}[0] = ceil($_[1]->{elems}[0]);
        $ret->{elems}[1] = ceil($_[1]->{elems}[1]);
        return $ret;
    } else {
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[0] and ref $_[0] eq __PACKAGE__ );
        my $ret = $_[0];
        $ret->{elems}[0] = ceil($_[0]->{elems}[0]);
        $ret->{elems}[1] = ceil($_[0]->{elems}[1]);
        return $ret;
    }
}
#
=over

=item vround([$arg])

This method rounds the vector's elements to the nearest integer

=back
=cut
sub vround {
    unless (ref $_[0]) {
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[1] and ref $_[1] eq __PACKAGE__ );
        my $ret = $_[1];
        $ret->{elems}[0] = round($_[1]->{elems}[0]);
        $ret->{elems}[1] = round($_[1]->{elems}[1]);
        return $ret;
    } else {
        my $ret = $_[0];
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[0] and ref $_[0] eq __PACKAGE__ );
        $ret->{elems}[0] = round($_[0]->{elems}[0]);
        $ret->{elems}[1] = round($_[0]->{elems}[1]);
        return $ret;
    }
}
#
=over

=item vtruncate([$arg])

This method modifies the vetor elements setting each of its integer part value. This method
does not apply any kind of mathematical rounding, simply cuts off the decimal part - if any -
from vector element at index.

=back
=cut
sub vtruncate {
    unless (ref $_[0]) {
        # static call
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[1] and ref $_[1] eq __PACKAGE__ );
        $_[1]->{elems}[0] = int( $_[1]->{elems}[0] );
        $_[1]->{elems}[1] = int( $_[1]->{elems}[1] );
        return $_[1];
    } static {
        # instance call
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[0] and ref $_[0] eq __PACKAGE__ );
        $_[0]->{elems}[0] = int( $_[0]->{elems}[0] );
        $_[0]->{elems}[1] = int( $_[0]->{elems}[1] );
        return $_[0];
    }
}
#
=over

=item distanceToSquared(@args)

This method calculates the squared distance between two vectors

=back
=cut
sub distanceToSquared {
    unless (ref $_{0}) {
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[1] and ref $_[1] eq __PACKAGE__ );
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[2] and ref $_[2] eq __PACKAGE__ );
        my ( $dx, $dy );
        $dx = $_[2]->{elems}[0] - $_[1]->{elems}[0];
        $dy = $_[2]->{elems}[1] - $_[1]->{elems}[1];
        return $dx ** 2 + $dy ** 2;
    } else {
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[1] and ref $_[1] eq __PACKAGE__ );
        my ( $dx, $dy );
        $dx = $_[1]->{elems}[0] - $_[0]->{elems}[0];
        $dy = $_[1]->{elems}[1] - $_[0]->{elems}[1];
        return $dx**2 + $dy**2;
	}
}
=over

=item distanceTo(@args)

This method calculates the distance between two vectors

=back
=cut
sub distanceTo {
    unless ( ref $_{0} ) {
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[1] and ref $_[1] eq __PACKAGE__ );
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[2] and ref $_[2] eq __PACKAGE__ );
        return sqrt(Vector2D->distanceToSquared($_[1], $_[2]));
    }
    else {
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[1] and ref $_[1] eq __PACKAGE__ );
        return sqrt( Vector2D->distanceToSquared( $_[0], $_[1] ) );
    }
}
#
=over

=item manhattanDistanceTo(@args)

Calculates Manhattan distance between two vectors.

=back
=cut
sub manhattanDistanceTo {
    unless ( ref $_{0} ) {
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[1] and ref $_[1] eq __PACKAGE__ );
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[2] and ref $_[2] eq __PACKAGE__ );
        return abs($_[1]->{elems}[0] - $_[2]->{elems}[0]) + abs($_[1]->{elems}[1] - $_[2]->{elems}[1]);
    }
    else {
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[1] and ref $_[1] eq __PACKAGE__ );
        return
          abs( $_[0]->{elems}[0] - $_[1]->{elems}[0] ) +
          abs( $_[0]->{elems}[1] - $_[1]->{elems}[1] );
    }
}
#
=over

=item setLength(arg)

This method returns a modified length of the original vector

=back
=cut
#
sub setLength {
    unless (ref $_[0]) {
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[1] and ref $_[1] eq __PACKAGE__ );
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[2] and ref \$_[2] eq 'SCALAR' );
        return $_[1]->normalize->smul($_[2]);
    } else {
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[1] and ref \$_[1] eq 'SCALAR' );
        return $_[0]->normalize->smul($_[1]);
    }
}
#
=over

=item vlerp(@args)

This method calculates the linear extrapolated vector based on a given scalar value.

=back
=cut
sub vlerp {
    unless ( ref $_[0] ) {
        croak "Error: invalid or missing argument detected at pos 1 ",
            ( caller(0) )[3]
            unless ( defined $_[1] and ref $_[1] eq __PACKAGE__ );
        croak "Error: invalid or missing argument detected at pos 1 ",
            ( caller(0) )[3]
            unless ( defined $_[2] and ref $_[2] eq __PACKAGE__ );
        croak "Error: invalid or missing argument detected at pos 1 ",
            ( caller(0) )[3]
            unless ( defined $_[3] and ref \$_[3] eq 'SCALAR' );
        $_[1]->{elems}[0] = ($_[2]->{elems}[0] - $_[1]->{elems}[0]) * $_[3];
        $_[1]->{elems}[1] = ($_[2]->{elems}[1] - $_[1]->{elems}[1]) * $_[3];
        return $_[1];
    }
    else {
        croak "Error: invalid or missing argument detected at pos 1 ",
            ( caller(0) )[3]
            unless ( defined $_[1] and ref $_[1] eq __PACKAGE__ );
        croak "Error: invalid or missing argument detected at pos 1 ",
            ( caller(0) )[3]
            unless ( defined $_[2] and ref \$_[2] eq 'SCALAR' );
        $_[0]->{elems}[0] = ($_[1]->{elems}[0] - $_[0]->{elems}[0]) * $_[2];
        $_[0]->{elems}[1] = ($_[1]->{elems}[1] - $_[0]->{elems}[1]) * $_[2];
        return $_[0];
    }
}
#
=over

=item vlerpVectors(@args)

This method calculates the lerp vector of three vectors and a scalar

=back
=cut
sub lerpVectors {
    unless (ref $_[0]) {
        # expects four arguments, three vectors and one scalar
        croak "Error: invalid or missing argument detected at pos 1 ",
            ( caller(0) )[3]
            unless ( defined $_[1] and ref $_[1] eq __PACKAGE__ );
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[2] and ref $_[2] eq __PACKAGE__ );
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[3] and ref $_[3] eq __PACKAGE__ );
        croak "Error: invalid or missing argument detected at pos 1 ",
            ( caller(0) )[3]
            unless ( defined $_[4] and ref \$_[4] eq 'SCALAR' );

        $_[1]->{elems}[0] = $_[2]->{elems}[0] +
          ( $_[3]->{elems}[0] - $_[2]->{elems}[0] ) * $_[4];
        $_[1]->{elems}[1] = $_[2]->{elems}[1] +
          ( $_[3]->{elems}[1] - $_[2]->{elems}[1] ) * $_[4];
        return $_[1];
    } else {
        # expects three arguments, two vectors and one scalar
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[1] and ref $_[1] eq __PACKAGE__ );
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[2] and ref $_[2] eq __PACKAGE__ );
        croak "Error: invalid or missing argument detected at pos 1 ",
            ( caller(0) )[3]
            unless ( defined $_[3] and ref \$_[3] eq 'SCALAR' );
        $_[0]->{elems}[0] = $_[1]->{elems}[0] +
          ( $_[2]->{elems}[0] - $_[1]->{elems}[0] ) * $_[3];
        $_[0]->{elems}[0] = $_[1]->{elems}[1] +
          ( $_[2]->{elems}[1] - $_[1]->{elems}[1] ) * $_[3];
        return $_[1];
    }
}
#
=over

=item equals(@args)

Checks wether two vectors equal or not.

=back
=cut
sub equals {
    unless (ref $_[0]) {
        croak "Error: invalid or missing argument detected at pos 1 ",
            ( caller(0) )[3]
            unless ( defined $_[1] and ref $_[1] eq __PACKAGE__ );
        croak "Error: invalid or missing argument detected at pos 2 ",
          ( caller(0) )[3]
          unless ( defined $_[2] and ref $_[2] eq __PACKAGE__ );
        return (($_[1]->{elems}[0] eq $_[2]->{elems}[0]) and ($_[1]->{elems}[1] eq $_[2]->{elems}[1]));
    } else {
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[1] and ref $_[1] eq __PACKAGE__ );
        return (($_[0]->{elems}[0] eq $_[1]->{elems}[0]) and ($_[0]->{elems}[1] eq $_[1]->{elems}[1]));
    }
}
#
=over

=item rotateAround(@args)

This method rotates the original vector around another vector by angle.

=back
=cut
sub rotateAround {
    my ( $c, $s, $x, $y );
    unless (ref $_[0]) {
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[1] and ref $_[1] eq __PACKAGE__ );
        croak "Error: invalid or missing argument detected at pos 2 ",
          ( caller(0) )[3]
          unless ( defined $_[2] and ref $_[2] eq __PACKAGE__ );
        croak "Error: invalid or missing argument detected at pos 3 ",
          ( caller(0) )[3]
          unless ( defined $_[3] and ref \$_[3] eq 'SCALAR' );
        $c = cos(deg2rad($_[3]));
        $s = sin(deg2rad($_[3]));
        $x = $_[2]->{elems}[0] - $_[1]->{elems}[0];
        $y = $_[2]->{elems}[1] - $_[1]->{elems}[1];
        $_[1]->{elems}[0] = $x * $c - $y * $s + $_[2]->{elems}[0];
        $_[1]->{elems}[1] = $x * $s + $y * $c + $_[2]->{elems}[1];
        return $_[1];
    } else {
        croak "Error: invalid or missing argument detected at pos 1 ",
          ( caller(0) )[3]
          unless ( defined $_[1] and ref $_[1] eq __PACKAGE__ );
        croak "Error: invalid or missing argument detected at pos 2 ",
          ( caller(0) )[3]
          unless ( defined $_[2] and ref \$_[2] eq 'SCALAR' );
        $c = cos(deg2rad($_[2]));
        $s = sin(deg2rad($_[2]));
        $x = $_[1]->{elems}[0] - $_[0]->{elems}[0];
        $y = $_[1]->{elems}[1] - $_[0]->{elems}[1];
        $_[0]->{elems}[0] = $x * $c - $y * $s + $_[1]->{elems}[0];
        $_[0]->{elems}[1] = $x * $s + $y * $c + $_[1]->{elems}[1];
        return $_[0];
    }
}
=over

=item random()

This method generates random valued vector.

=back
=cut
sub random {
    unless (ref $_[0]) {
        croak "Error: invalid or missing argument detected at pos 1 ",
            ( caller(0) )[3]
            unless ( defined $_[1] and ref $_[1] eq __PACKAGE__ );
        $_[1]->{elems}[0] = rand();
        $_[1]->{elems}[1] = rand();
        return $_[1];
    } else {
        $_[0]->{elems}[0] = rand();
        $_[0]->{elems}[1] = rand();
        return $_[0];
    }
}
#
# Utilities
sub debug {
    my ($line, $file, $msg) = @_;
    printf "DEBUG::\"%s\" @ line %d in \"%s\".\n", defined $msg ? $msg : "info", $line, $file;
};
sub normalize_angle_degrees {
    my ($angle) = @_;
    croak "Error: missing argument", (caller(0))[3] unless defined $angle;
    croak "Error: invalid argument detected at pos 1, expected SCALAR ", ( caller(0) )[3]
      unless ( ref \$angle eq 'SCALAR' );
    return  ($angle % 360 + 360) % 360;
}
sub normalize_angle_radians {
    my ($angle) = @_;
    croak "Error: missing argument", (caller(0))[3] unless defined $angle;
    croak "Error: invalid argument detected at pos 1, expected SCALAR ", ( caller(0) )[3]
      unless ( ref \$angle eq 'SCALAR' );
    return  ($angle % (2 * PI) + (2 * PI)) % (2 * PI);
}
sub clamp {
    my ( $value, $min, $max ) = @_;
	return max( $min, min( $max, $value ) );

}
=head2 B<Misc methods>

These methods extends the capabilities of the Vector2D package.

=over

=item - debug(__LINE__,__FILE__[,message])

prints out debug information.

=item - normalize_angle_degrees($angle_in_degrees)

returns the angle in range 0 .. 360 degrees

=item - normalize_angle_radians($angle_in_radians)

returns the angle in range 0 .. 2 * PI radians

=item clamp(min, max, value)

This method returns clamp value - in range 'min' .. 'max' -, or
in case when the value is out of the range, then returns 'min' if value is below
the minimum, or returns 'max' if the value is beyond the maximum.

=back

=head1 FILES

F<Vector2D.pm>

=head1 SEE ALSO

L<Vector3D(3)>, L<Matrix2D(3)>, L<Matrix3D(3)>, L<Matrix4D(3)>

=head1 AUTHOR

G.Zelenak

1;
