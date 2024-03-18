package Vector;
use strict;
use POSIX;
use Scalar::Util qw(looks_like_number);
use Math::Trig;
use Math::Trig ':pi';
use FindBin;
use lib "$FindBin::Bin";
use Point;
our @ISA = qw(Point);
our @terse_exp = qw(
    unit
    scale
    add
    direction
    cross
    lerp
    dist
    dot
    isEqualTo
    isLinearlyDependent
);
our %EXPORT_TAGS = ( terse => [@terse_exp] );
Exporter::export_ok_tags( keys(%EXPORT_TAGS) );

our $NaN = POSIX::nan();
#
sub _lerp {
    my Vector $self = shift;
    my ($a, $b, $t) = @_;
    if (@_ eq 3 and looks_like_number($a) and looks_like_number($b) and looks_like_number($t)) {
        return $a + ($b - $a) * $t;
    }
    return $NaN;
}
#
sub cross {
    my Vector $self = shift;
    my Vector ( $b ) = @_;
    return Vector->new(
        # x
        (($self->[1] * $b->[2]) - ($b->[1] * $self->[2])),
        # y
        -(($self->[0] * $b->[2]) - ($b->[0] * $self->[2])),
        # z
        (($self->[0] * $b->[1]) - ($b->[0] * $self->[1]))
    );
    die "Wrong type of the argument";
}
#
sub dot {
    my Vector $self = shift;
    my Vector($b) = @_;
    return (( $self->[0] * $b->[0] ) + ( $self->[1] * $b->[1] ) + ( $self->[2] * $b->[2] ) );
    die "Wrong type of the argument";
}
#
sub isEqualTo {
    my Vector $self = shift;
    my Vector($b) = @_;
    return ( $self->[0] eq $b->[0] && $self->[1] eq $b->[1] && $self->[2] eq
          $b->[2] );
    die "Wrong type of the argument";
}
#
sub isLinearlyDependent {
    my Vector $self = shift;
    my Vector($b) = @_;
    # Same
    if ($self->isEqualTo($b)) {
        return 1;
    }

    # Factors of each, if one of those can const dx = this [0] / p1[0]
    my $dx = $self->[0] / $b->[0];
    my $dy = $self->[1] / $b->[1];
    my $dz = $self->[2] / $b->[2];

    # All factors are the same
    if ( $dx eq $dy && $dy eq $dz && $dx eq $dz ) {
        return 1;
    }

    # One factor can produce this vector
    if ( $b->timesScalar($dx)->isEqualTo($self)
        or $b->timesScalar($dy)->isEqualTo($self)
        or $b->timesScalar($dz)->isEqualTo($self) ) {
            return 1;
    }
    return 0;
}
#
sub lerp {
    my Vector $self = shift;
    my Vector $v = shift;
    my ($t) = @_;
    if (looks_like_number($t)) {
        return Vector->new(
            _lerp( $self->[0], $v->[0], $t ),
            _lerp( $self->[1], $v->[1], $t ),
            _lerp( $self->[2], $v->[2], $t )
        );
    }
    die "Expected a scalar."
}
#
sub dist {
    my Vector $self = shift;
    my Vector($b) = @_;
    return sqrt( ( $b->[0] - $self->[0] ) * ( $b->[0] - $self->[0] ) +
          ( $b->[1] - $self->[1] ) * ( $b->[1] - $self->[1] ) +
          ( $b->[2] - $self->[2] ) * ( $b->[2] - $self->[2] ) );
    die "Wrong type of argument";
}
#
sub unit {
    my Vector $self = shift;
    return Vector->new(
        $self->[0] / $self->mag,
        $self->[1] / $self->mag,
        $self->[2] / $self->mag
    );
}
#
sub scale {
    my Vector $self = shift;
    my $k = shift;
    $k = looks_like_number($k) ? $k : 1;
    return Vector->new(
        $self->[0] * $k,
        $self->[1] * $k,
        $self->[2] * $k
    );
}
#
sub add {
    my Vector $self = shift;
    my ($b) = @_;
    if (looks_like_number($b) ? $b : 0) {
        return Vector->new(
            $self->[0] + $b,
            $self->[1] + $b,
            $self->[2] + $b
        );
    } elsif (ref($b) eq 'Vector') {
        return Vector->new(
            $self->[0] + $b->[0],
            $self->[1] + $b->[1],
            $self->[2] + $b->[2]
        );
    } else {
        return $self;
    }
}
#
sub sub {
    my Vector $self = shift;
    my ($b) = @_;
    if (looks_like_number($b)) {
        return Vector->new($self->[0] - $b,
        $self->[1] - $b,
        $self->[2] - $b);
    } elsif (ref($b) eq 'Vector') {
        return Vector->new($self->[0] - $b->[0],
        $self->[1] - $b->[1],
        $self->[2] - $b->[2]);
    } else {
        return $self;
    }
}
#
sub norm {
    my Vector $self = shift;
    my $m = $self->mag;
    return Vector->new(
        $self->[0] / $m,
        $self->[1] / $m,
        $self->[2] / $m
    );
}
#
sub direction() {
    my Vector $self = shift;
    if ($self->[0] eq 0 && $self->[1] eq 0 && $self->[2] eq 0) {
        return $NaN;
    }
    my $r = $self->mag;
    if (not $r eq 0) {
        # get sigma first
        my $sigma = $NaN;
        if ($self->[2] > 0) {
            $sigma = atan(
                sqrt(
                    ($self->[0] * $self->[0]) +
                    ($self->[1] * $self->[1])
                ) / $self->[2]
            );
        } elsif ($self->[2] < 0) {
            $sigma = (
                atan(
                    sqrt(
                        ($self->[0] * $self->[0]) +
                        ($self->[1] * $self->[1])
                    ) / $self->[2]
                ) + pi
            );
        } elsif ($self->[2] eq 0 && not $self->[0] eq 0 && not $self->[1] eq 0) {
            $sigma = pip2;
        } else {
            $sigma = $NaN;
        }
        # get phi next
        my $phi = $NaN;
        if ($self->[0] > 0) {
            $phi = atan(($self->[1] / $self->[0]));
        } elsif ($self->[0] < 0 && $self->[1] >= 0) {
            $phi = atan(($self->[1] / $self->[0])) + pi;
        } elsif ($self->[0] < 0 && $self->[1] < 0) {
            $phi = atan(($self->[1] / $self->[0])) - pi;
        } elsif ($self->[0] == 0 && $self->[1] > 0) {
            $phi = pip2;
        } elsif ($self->[0] == 0 && $self->[1] < 0) {
            $phi = -pip2;
        }
        return { r => $r, sigma => $sigma, phi => $phi };
    }
    return $NaN;
}
#
1;
