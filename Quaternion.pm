package Quaternion;

=head1 NAME

Quaternion

=head1 SYNOPSYS

use Quaternion;

my $vector = Quaternion->new();

my $vector = Quaternion->new(1, 2, 3);

=cut

use utf8;
use strict;
use warnings;
use Data::Dumper;
use POSIX      qw(ceil sqrt sin cos round floor);
use Math::Trig qw (:pi);
use Math::Trig qw(deg2rad rad2deg acos);
use List::Util qw(min max);
use Carp;
use Scalar::Util qw(looks_like_number);
use constant MAXSIZE => 4;                   # 1X2 vector X,Y
use constant DEBUG   => 0;                   # 1 uses DEBUG constants
use constant PI      => atan2( 1, 1 ) * 4;

# use constant PI => pi;
# use constant PI => POSIX::M_PI;
use constant HALF_PI => PI * .5;
use constant TWO_PI  => PI * 2;
use FindBin;
use lib "$FindBin::Bin";

BEGIN {
    # use Vector4D;
    use MathUtils;
    require Exporter;

    # printf "PI: %.12e\n", PI;
    # printf "PI: %.12e\n", pi;
    # printf "PI: %.12e\n", (atan2(1,1) * 4);
}
our @ISA       = qw(Exporter);
our $VERSION   = qw(1.0.0);
our @EXPORT    = qw(new);
our @EXPORT_OK = qw(
    dim
    size
);
my $dim = 1;
my $size = MAXSIZE;
#
use overload
    '==' => sub {
        if (ref $_[0] eq __PACKAGE__ and ref $_[1] eq __PACKAGE__) {
            # warn "Quaternion set another quaternion (copy or clone) is not implemented yet.";
            return Quaternion->equals($_[0], $_[1]);
        }
    };
#

# private methods
sub _onChange {
    # it is instance call only
    if (ref $_[0] eq __PACKAGE__) {
        if (defined $_[1] and ref \$_[1] eq 'CODE') {
            $_[0]->{_onChangeCB} = $_[1];
            return $_[0];
        }
    }
}
#
=over

=head2 Constructor

=back
=cut

sub new($$$$) {
    my $self   = $_[0];
    my @params = @_;
    my $elems  = [];
    for ( 0 .. MAXSIZE - 1 ) {
        if ( defined $_[ $_ + 1 ] ) {
            @$elems[$_] = $_[ $_ + 1 ];
        }
        else {
            @$elems[$_] = 0;
        }
    }
    return bless { elems => $elems, dim => 1, size => MAXSIZE, id => generateUUID(), _onChangeCB => \&_onChange }, ref($self) || $self;
}
#
=over

=item clone([$arg])

Make an exact copy of the quaternion

=back
=cut
sub clone {
    my $ret;
    unless (ref $_[0]) {
        croak "Error: invalid type detected at pos 1", unless (ref $_[1] eq __PACKAGE__);
        $ret = Quaternion->new;
        $ret = Quaternion->new->set( $ret, $_[1]->get );

    } else {
        $ret = Quaternion->new->set($ret, $_[0]->get);
    }
    return $ret;
}
#
=over

=item clone([$arg])

See clone above

=back
=cut
sub copy {
    my $ret;
    unless (ref $_[0]) {
        croak "Error: invalid type detected at pos 1", unless (ref $_[1] eq __PACKAGE__);
        $ret = Quaternion->new;
        $ret = Quaternion->new->set( $ret, $_[1]->get );

    } else {
        $ret = Quaternion->new->set($ret, $_[0]->get);
    }
    return $ret;
}
#
=over

=item set(@args)

Sets the quaternion elements from list of scalars - in case of instance call -
otherwise expects a quaternion as a first argument - in case of Class call - and the remaining
list of new element values - in order - as scalars.

Note: if the argument list - respecting the quaternion's elements - contains
'undefined' values, they will be omitted by default.


=back
=cut
sub set {
    unless (ref $_[0]) {
        my @params = @_;
        shift @params;  # pulls of invocant
        my $q = shift @params;
        croak "Error: invalid type detected at pos 1", unless (ref $q eq __PACKAGE__);
        # print Dumper @_;
        for (0..MAXSIZE-1) {
            print "static: ".$_."=".$params[$_]."\n";
            if ( defined $params[$_] and ref \$params[$_] eq 'SCALAR' ) {
                $_[1]->{elems}[$_] = $params[$_];
            }
        }
        return $_[1];
    } else {
        my @params = @_;
        # print Dumper @params;
        my $self = shift @params;  # pulls off self
        shift @params unless defined $params[0];
        for (0..MAXSIZE-1) {
            # print "instance: ".$_."=".$params[$_]."\n";
            if (defined $params[$_] and ref \$params[$_] eq 'SCALAR') {
                $self->{elems}[$_] = $params[$_];
            }
        }
        return $_[0];
    }
}
#
=over

=item get([$arg])

Returns the elements list of the quertnion.

=back
=cut
sub get {
    # returns elemets list
    unless (ref $_[0]) {
        croak "Error: invalid type detected at pos 1",
          unless ( ref $_[1] eq __PACKAGE__ );
        return @{$_[1]->{elems}};
    } else {
        return @{$_[0]->{elems}};
    }
}
#
=over

=item ID([$arg])

Returns the ID of the quternion.

=back
=cut
sub ID {
    unless (ref $_[0]) {
        croak "Error: invalid type detected at pos 1",
          unless ( ref $_[1] eq __PACKAGE__ );
        return $_[1]->{id};
    } else {
        return $_[0]->{id};
    }
}
#

=over

=item X([@args])

Getter/setter of the quternion's [0] element.

=back
=cut
sub X($) {
    unless (ref $_[0]) {
        croak "Error: invalid type detected at pos 1", unless (ref $_[1] eq __PACKAGE__);
        if (defined $_[2] and ref \$_[2] eq 'SCALAR') {
            $_[1]->{elems}[0] = 0+$_[2];
            return $_[1];
        }
        return $_[0]->{elems}[0];
    } else {
        if (defined $_[1] and ref \$_[1] eq 'SCALAR') {
            $_[0]->{elems}[0] = 0+$_[1];
            return $_[0];
        }
        return $_[0]->{elems}[0];
    }
}
#
=over

=item Y([@args])

Getter/setter of the quaternion's [1] element.

=back
=cut
sub Y($) {
    unless (ref $_[0]) {
        croak "Error: invalid type detected at pos 1", unless (ref $_[1] eq __PACKAGE__);
        if (defined $_[2] and ref \$_[2] eq 'SCALAR') {
            $_[1]->{elems}[1] = 0+$_[2];
            return $_[1];
        }
        return $_[0]->{elems}[1];
    } else {
        if (defined $_[1] and ref \$_[1] eq 'SCALAR') {
            $_[0]->{elems}[1] = 0+$_[1];
            return $_[0];
        }
        return $_[0]->{elems}[1];
    }
}
#
=over

=item Z([@args])

Getter/setter of the quternion's [2] element.

=back
=cut
sub Z($) {
    unless (ref $_[0]) {
        croak "Error: invalid type detected at pos 1", unless (ref $_[1] eq __PACKAGE__);
        if (defined $_[2] and ref \$_[2] eq 'SCALAR') {
            $_[1]->{elems}[2] = 0+$_[2];
            return $_[1];
        }
        return $_[0]->{elems}[2];
    } else {
        if (defined $_[1] and ref \$_[1] eq 'SCALAR') {
            $_[0]->{elems}[2] = 0+$_[1];
            return $_[0];
        }
        return $_[0]->{elems}[2];
    }
}
#
=over

=item W([@args])

Getter/setter of the quaternion's [3] element.

=back
=cut
sub W($) {
    unless (ref $_[0]) {
        croak "Error: invalid type detected at pos 1", unless (ref $_[1] eq __PACKAGE__);
        if (defined $_[2] and ref \$_[2] eq 'SCALAR') {
            $_[1]->{elems}[3] = 0+$_[2];
            return $_[1];
        }
        return $_[0]->{elems}[3];
    } else {
        if (defined $_[1] and ref \$_[1] eq 'SCALAR') {
            $_[0]->{elems}[3] = 0+$_[1];
            return $_[0];
        }
        return $_[0]->{elems}[3];
    }
}
#
=over

=item print([@args])

Prints the quertnion elemets to the STDOUT with or without custom label.

If the second argument - the label text - is defined, the method will
put the message before the list of the elements. Otherwise the
quternion's ID string will be put before the list.

=back
=cut
sub print {
    unless (ref $_[0]) {
        croak "Error: invalid type detected at pos 1", unless (ref $_[1] eq __PACKAGE__);
        if (defined $_[2] and ref \$_[2] eq 'SCALAR') {
            printf "%s [\n", $_[2];
        } else {
            printf "quaternion_%s [\n", $_[1]->{id};
        }
        for (0..MAXSIZE-1) {
            printf "  %.12e,\n", $_[1]->{elems}[$_] if ( $_ < MAXSIZE - 1 );
            printf "  %.12e\n",  $_[1]->{elems}[$_] if ( $_ eq MAXSIZE - 1 );
        }
        printf "]\n";
        return $_[1];
    } else {
        if ( defined $_[1] and ref \$_[1] eq 'SCALAR' ) {
            printf "%s [\n", $_[1];
        } else {
            printf "quaternion_%s[\n", $_[0]->{id};
        }
        for ( 0 .. MAXSIZE- 1 ) {
            printf "  %.12e,\n", $_[0]->{elems}[$_] if ($_ < MAXSIZE - 1);
            printf "  %.12e\n", $_[0]->{elems}[$_] if ( $_ eq MAXSIZE - 1 );
        }
        printf "]\n";
        return $_[0];
    }
}
#
sub setFromEuler {
    unless (ref $_[0]) {
    } else {
    }
}
#
sub setFromAxisAngle {
    unless (ref $_[0]) {
    } else {
    }
}
#
sub setFromRotationMatrix {
    unless ( ref $_[0] ) {
    }
    else {
    }
}
#
sub setFromUnitVectors {
    unless (ref $_[0]) {
    } else {
    }
}
#
sub angleTo {
    unless (ref $_[0]) {
    } else {
    }
}
#
sub rotateTowards {
    unless (ref $_[0]) {
    } else {
    }
}
#
sub identity {
    unless (ref $_[0]) {
    } else {
    }
}
#
sub invert {
    unless (ref $_[0]) {
    } else {
    }
}
#
sub conjugate {
    unless ( ref $_[0] ) {
    }
    else {
    }
}
#
sub dot {
    unless (ref $_[0]) {
    } else {
    }
}
#
sub lengthSq {
    unless (ref $_[0]) {
    } else {
    }
}
#
sub length {
    unless ( ref $_[0] ) {
    }
    else {
    }
}
#
sub normalize {
    unless ( ref $_[0] ) {
    }
    else {
    }
}
#
sub mul {
    unless ( ref $_[0] ) {
    }
    else {
    }
}
sub premul {
    unless (ref $_[0]) {
    } else {
    }
}
#
sub multiplyQuaternions {
    # maybe it's not necessary because of 'mul'
    # 'premul' and 'mul' differs only the order of
    # arguments during the calculation - static method going to be
    # used the latter case with opposit order as default.
    unless (ref $_[0]) {
    } else {
    }
}
#
sub slerp {
    unless (ref $_[0]) {
    } else {
    }
}
#
sub random {
    unless (ref $_[0]) {
    } else {
    }
}
#
sub equals {
    # should be applied to overloaded '==' operator as well
    unless (ref $_[0]) {
        croak 'Error: invalid type of argument detected at pos 1' unless (ref $_[1] eq __PACKAGE__);
        croak 'Error: invalid type of argument detected at pos 2' unless (ref $_[2] eq __PACKAGE__);
        return (($_[2]->{elems}[0] eq $_[1]->{elems}[0]) and
            ($_[2]->{elems}[1] eq $_[1]->{elems}[1]) and
            ($_[2]->{elems}[2] eq $_[1]->{elems}[2]) and
            ($_[2]->{elems}[3] eq $_[1]->{elems}[3]));
    } else {
        croak 'Error: invalid type of argument detected at pos 1' unless (ref $_[1] eq __PACKAGE__);
        return (($_[0]->{elems}[0] eq $_[1]->{elems}[0]) and
            ($_[0]->{elems}[1] eq $_[1]->{elems}[1]) and
            ($_[0]->{elems}[2] eq $_[1]->{elems}[2]) and
            ($_[0]->{elems}[3] eq $_[1]->{elems}[3]));
    }
}
#
sub fromArray {
    unless (ref $_[0]) {
    } else {
    }
}
#
sub toArray {
    unless (ref $_[0]) {
    } else {
    }
}
#
sub fromBufferAttribute {
    unless (ref $_[0]) {
    } else {
    }
}
#
sub toJSON {
    unless (ref $_[0]) {
    } else {
    }
}
#
sub DESTROY {
    my $self = shift;
    warn $self->{id}." destroyed";
}
#
END {
    warn "Quaternion destroyed successfully\n";
}
1;
