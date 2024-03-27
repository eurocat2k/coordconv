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
# use overload
#     '=' => sub {
#         if (ref $_[0] eq __PACKAGE__ and ref $_[1] eq __PACKAGE__) {
#             warn "Quaternion set another quaternion (copy or clone) is not implemented yet.";
#             return;
#         } elsif (ref $_[0] eq __PACKAGE__ and ref \$_[1] eq 'SCALAR') {
#             warn "Quaternion set scalar\n";
#             return;
#         }
#     };
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
    return bless { elems => $elems, dim => 1, size => MAXSIZE, id => generateUUID() }, ref($self) || $self;
}
#
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
sub set {
    unless (ref $_[0]) {
        my @params = @_;
        croak "Error: invalid type detected at pos 1", unless (ref $_[1] eq __PACKAGE__);
        # print Dumper @_;
        for (3..MAXSIZE+2) {
            # print $_."=".$params[$_]."\n";
            if ( defined $params[$_] and ref \$params[$_] eq 'SCALAR' ) {
                $_[1]->{elems}[$_ - 3] = $params[$_];
            }
        }
        return $_[1];
    } else {
        my @params = @_;
        for (1..MAXSIZE) {
            if (defined $params[$_] and ref \$params[$_] eq 'SCALAR') {
                $_[0]->{elems}[$_ - 1] = $params[$_];
            }
        }
        return $_[0];
    }
}
#
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
sub DESTROY {
    my $self = shift;
    warn $self->{id}." destroyed";
}
#
END {
    warn "Quaternion destroyed successfully\n";
}
1;
