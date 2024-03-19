package Matrix3;
use strict;
use warnings;
use Data::Dumper;
use POSIX qw(ceil sqrt sin cos);
use Math::Trig qw(deg2rad rad2deg);
use Carp;
use Scalar::Util qw(looks_like_number);
require Exporter;
our @ISA = qw(Exporter);
our $VERSION = qw(1.0.0);
our @EXPORT = qw(new);
our @EXPORT_OK = qw(dim size);
#
use constant MAXSIZE => 9;    # 3X3 matrix
my $dim;
my $size;
#
my $private_nearest_square = sub {
    my $n = @_;
    my $sq = ceil(sqrt($n))**2;
    if ($sq < 4) {
        return 4;
    }
    if ($sq < $n) {
        return Matrix::private_nearest_square->($n+1);
    }
    return $sq;
};
my $private_nearest_square_root = sub {
    my $n = shift;
    my $sq = $private_nearest_square->($n);
    return sqrt($sq);
};
#
sub new {
    my $class = shift;                              # Store the package name
    my $self = [];                                  # it's an ARRAY object
    bless($self, $class);                           # Bless the reference into that package
    my @args = @_;                                  # save arguments
    @args = splice(@_, 0, &MAXSIZE);
    if (@args) {
        $size = $private_nearest_square->(@args);          # get the size of the matrix: default 2x2=4 square maxtrix
        $dim = sqrt($private_nearest_square->(@args));     # get the dimension of the square matrix: default 2
    } else {
        $dim = sqrt(&MAXSIZE);
        $size = &MAXSIZE;
    }
    my $aref = \@$self;                             # make an array reference of the class instance
    @$aref = (0) x $size;
    my @a = [ @args[0..&MAXSIZE-1] ];
    for (my $i = 0; $i < &MAXSIZE; $i += 1) {
        if (defined $args[$i]) {
            @$aref[$i] = $args[$i];
        }
    }
    return $self;
}
#
sub dim {
    my $self = shift;
    my $aref = \@$self;
    return sqrt(scalar @$aref);
}
#
sub size {
    my $self = shift;
    my $aref = \@$self;
    return $self->dim**2;
}
#
sub print {
    my $self = shift;
    my $aref = \@$self;
    my $_dim = $self->dim;
    my $id = 0;
    print "[\n";
    for my $rowId (0..$_dim-1) {
        print "  [\n";
        for my $colId (0..$_dim-1) {
            print "    ".@$self[$id++]."\n";
        }
        print "  ]\n";
    }
    print "]\n";
    return $self;
}
#
sub set {
    my $self = shift;
    my $aref = \@$self;
    my @idxs = ( 0 .. &MAXSIZE -1);
    my @args = @_;
    @args = splice(@args, 0, &MAXSIZE);
    foreach (@idxs) {
        @$self[ $idxs[$_] ] = $args[$_] unless not defined $args[$_];
    }
    return $self;
}
#
sub identity {
    my $self = shift;
    $self->set( 1, 0, 0, 0, 1, 0, 0, 0, 1 );
    return $self;
}
#
sub copy {
    my $self = shift;
    my Matrix3 ($m) = @_;
    my $aref = \@$m;
    die "Invlid type of argument: expected 'Matrix3'! -" if not ref($m) eq 'Matrix3';
    my @idxs = ( 0 .. &MAXSIZE - 1 );
    for (@idxs) {
        $self->[$_] = $m->[$_];
    }
    return $self;
}
#
sub mul {
    my $self = shift;
    my Matrix3 ($a, $b) = @_;
    my $te;
    my ($a11, $a12, $a13, $a21, $a22, $a23, $a31, $a32, $a33, $ae);
    my ($b11, $b12, $b13, $b21, $b22, $b23, $b31, $b32, $b33, $be );
    if (@_ eq 2) {
        die "Invlid type of arguments: expected one or two 'Matrix3'! -"
          if not ref($a) eq 'Matrix3'
          or not ref($b) eq 'Matrix3';
        # static method - return a new matrix
        $ae  = $a;
        $be  = $b;
        $te  = Matrix3->new();
    } elsif (@_ eq 1) {
        # multiply self with argument
        die "Invlid type of arguments: expected one or two 'Matrix3'! -"
          if not ref($a) eq 'Matrix3';
        $ae  = Matrix3->new();
        $ae->copy($self);
        $be  = $a;
        $te = $self;
    } else {
        die "Invlid type of arguments: expected one or two 'Matrix3'! -";
    }
    $a11 = $ae->[0];
    $a12 = $ae->[3];
    $a13 = $ae->[6];

    $a21 = $ae->[1];
    $a22 = $ae->[4];
    $a23 = $ae->[7];

    $a31 = $ae->[2];
    $a32 = $ae->[5];
    $a33 = $ae->[8];

    $b11 = $be->[0];
    $b12 = $be->[3];
    $b13 = $be->[6];

    $b21 = $be->[1];
    $b22 = $be->[4];
    $b23 = $be->[7];

    $b31 = $be->[2];
    $b32 = $be->[5];
    $b33 = $be->[8];

    $te->[0] = $a11 * $b11 + $a12 * $b21 + $a13 * $b31;
    $te->[3] = $a11 * $b12 + $a12 * $b22 + $a13 * $b32;
    $te->[6] = $a11 * $b13 + $a12 * $b23 + $a13 * $b33;

    $te->[1] = $a21 * $b11 + $a22 * $b21 + $a23 * $b31;
    $te->[4] = $a21 * $b12 + $a22 * $b22 + $a23 * $b32;
    $te->[7] = $a21 * $b13 + $a22 * $b23 + $a23 * $b33;

    $te->[2] = $a31 * $b11 + $a32 * $b21 + $a33 * $b31;
    $te->[5] = $a31 * $b12 + $a32 * $b22 + $a33 * $b32;
    $te->[8] = $a31 * $b13 + $a32 * $b23 + $a33 * $b33;
	return $te;
}
#
sub mulscale {
    my $self = shift;
    my ($scalar) = @_;
    die "Expected one scalar argument" unless not @_ eq 0;
    $self->[ 0 ] *= $scalar; $self->[ 3 ] *= $scalar; $self->[ 6 ] *= $scalar;
    $self->[ 1 ] *= $scalar; $self->[ 4 ] *= $scalar; $self->[ 7 ] *= $scalar;
    $self->[ 2 ] *= $scalar; $self->[ 5 ] *= $scalar; $self->[ 8 ] *= $scalar;
    return $self;
}
#
sub det {
    my $self = shift;
    my $a = $self->[0];
    my $b = $self->[1];
    my $c = $self->[2];
    my $d = $self->[3];
    my $e = $self->[4];
    my $f = $self->[5];
    my $g = $self->[6];
    my $h = $self->[7];
    my $i = $self->[8];
    return $a * $e * $i - $a * $f * $h - $b * $d * $i + $b * $f * $g + $c * $d * $h - $c * $e * $g;
}
#
sub invert {
    my $self = shift;
    my ($a) = @_;
    my $te = $self;
    if (@_ eq 1) {
        $te = Matrix3->new();
        $te->copy($self);
    }
    my $n11 = $te->[0];
    my $n21 = $te->[1];
    my $n31 = $te->[2];

    my $n12 = $te->[3];
    my $n22 = $te->[4];
    my $n32 = $te->[5];

    my $n13 = $te->[6];
    my $n23 = $te->[7];
    my $n33 = $te->[8];

    my $t11 = $n33 * $n22 - $n32 * $n23;    my $t12 = $n32 * $n13 - $n33 * $n12;
    my $t13 = $n23 * $n12 - $n22 * $n13;

    my $det = $n11 * $t11 + $n21 * $t12 + $n31 * $t13;

    if ( $det eq 0 ) {
        $self->set( 0, 0, 0, 0, 0, 0, 0, 0, 0 );
        return $self;
    }
    my $detInv = 1 / $det;
    $te->[0] = $t11 * $detInv;
    $te->[1] = ( $n31 * $n23 - $n33 * $n21 ) * $detInv;
    $te->[2] = ( $n32 * $n21 - $n31 * $n22 ) * $detInv;

    $te->[3] = $t12 * $detInv;
    $te->[4] = ( $n33 * $n11 - $n31 * $n13 ) * $detInv;
    $te->[5]= ( $n31 * $n12 - $n32 * $n11 ) * $detInv;

    $te->[6] = $t13 * $detInv;
    $te->[7] = ( $n21 * $n13 - $n23 * $n11 ) * $detInv;
    $te->[8] = ( $n22 * $n11 - $n21 * $n12 ) * $detInv;

    return $te;
}
#
sub transpose() {
    my $m = shift;
    my $tmp;
    $tmp = $m->[ 1 ]; $m->[ 1 ] = $m->[ 3 ]; $m->[ 3 ] = $tmp;
    $tmp = $m->[ 2 ]; $m->[ 2 ] = $m->[ 6 ]; $m->[ 6 ] = $tmp;
    $tmp = $m->[ 5 ]; $m->[ 5 ] = $m->[ 7 ]; $m->[ 7 ] = $tmp;
    return $m;
}
#
sub setUvTransform {
    my $this = shift;
    my ( $tx, $ty, $sx, $sy, $rotation, $cx, $cy ) = @_;
    die "Error: setUvTransform( tx, ty, sx, sy, rotation, cx, cy ) expects 7 arguments!" if ( not @_ eq 7 );
    my $c = cos(deg2rad($rotation));
    my $s = sin(deg2rad($rotation));

    $this->set(
        $sx * $c, $sx * $s, -$sx * ( $c * $cx + $s * $cy ) + $cx + $tx,
        -$sy * $s, $sy * $c, -$sy * ( -$s * $cx + $c * $cy ) + $cy + $ty,
        0, 0, 1
    );
    return $this;
}
#
END {
    print "Matrix destroyed\n";
}
#
1;
