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
use Math::Trig qw(deg2rad rad2deg);
use Carp;
use Scalar::Util qw(looks_like_number);
use constant MAXSIZE => 2;    # 1X2 vector X,Y
use constant DEBUG => 0; # 1 uses DEBUG constants
use FindBin;
use lib "$FindBin::Bin";
BEGIN {
    require Exporter;
}
our @ISA = qw(Exporter);
our $VERSION = qw(1.0.0);
our @EXPORT = qw(new);
our @EXPORT_OK = qw(dim size debug);
my $dim;
my $size;
# operator overloads
use overload
    '+' => sub {
        my ( $v0, $v1, $opt ) = @_;
        return $v0->add($v1);
    },
    '-' => sub {
        my ( $v0, $v1, $opt ) = @_;
        return $v0->subtract($v1);
    },
    '*' => sub {
        return $_[0]->mul($_[1]);
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

=item - set( $v0, $v1, $opt, $opt1 )

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

=item - add( $v0, $v1, $opt )

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

=item - subtract($v0, $v1, $opt)

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

=item - print($v0, $v1, $opt)

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

=item - zero($v0, $v1)

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
sub debug {
    my ($line, $file, $msg) = @_;
    printf "DEBUG::\"%s\" @ line %d in \"%s\".\n", length $msg ? $msg : "info", $line, $file;
};

=head2 B<Misc methods>

These methods extends the capabilities of the Vector2D package.

=over

=item - debug(__LINE__,__FILE__[,message])

prints out debug information.

=back

=head1 FILES

F<Vector2D.pm>

=head1 SEE ALSO

L<Vector3D(3)>, L<Matrix2D(3)>, L<Matrix3D(3)>, L<Matrix4D(3)>

=head1 AUTHOR

G.Zelenak

1;
