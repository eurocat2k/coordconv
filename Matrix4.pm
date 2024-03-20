package Matrix4;
use strict;
use warnings;
use Data::Dumper;
use POSIX qw(ceil sqrt sin cos);
use Math::Trig qw(deg2rad rad2deg);
use Carp;
use Scalar::Util qw(looks_like_number);
use FindBin;
use lib "$FindBin::Bin";
BEGIN {
    require Exporter;
    require Matrix3;
    require Vector;
}
our @ISA = qw(Exporter);
our $VERSION = qw(1.0.0);
our @EXPORT = qw(new);
our @EXPORT_OK = qw(dim size);
#
use constant MAXSIZE => 16;    # 4X4 matrix
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
        } else {
            @$aref[$i] = 0;
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
            # print "    ".@$self[$id++]."\n";
            printf "    %.12e\n", @$self[$id++];
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
    $self->set( 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1, 0, 0, 0, 0, 1 );
    return $self;
}
#
sub copy {
    my $self = shift;
    my Matrix4 ($m) = @_;
    die "Invlid type of argument: expected 'Matrix4'! -" if not ref($m) eq 'Matrix4';
    my @idxs = ( 0 .. &MAXSIZE - 1 );
    for (@idxs) {
        $self->[$_] = $m->[$_];
    }
    return $self;
}
# 
sub clone {
    my $self = shift;
    my Matrix4 ($m) = @_;
    my $te;
    my @idxs = ( 0 .. &MAXSIZE - 1 );
    if (@_ eq 1) {
        die "Invlid type of argument: expected 'Matrix4'! -" if not ref($m) eq 'Matrix4';
        $te = Matrix4->new();
    } elsif (@_ eq 0) {
        $te = $self;
    }
    for (@idxs) {
        $te->[$_] = $m->[$_];
    }
    return $te;
}
#
sub copyPosition {
    my $this = shift;
    my Matrix4 ($m) = @_;
    die "Error: expected one 'Matrix4' argument" unless @_ eq 1 and ref($m) eq 'Matrix4';
    my $te = $this;
    my $me = $m;
    $te->[ 12 ] = $me->[ 12 ];
    $te->[ 13 ] = $me->[ 13 ];
    $te->[ 14 ] = $me->[ 14 ];
    return $this;
}
# 
sub setFromMatrix3 {
    my $this = shift;
    my Matrix3 ($me) = @_;
    die "Error: expected one 'Matrix3' argument" unless @_ eq 1 and ref($me) eq 'Matrix3';
    $this->set(
        $me->[ 0 ], $me->[ 3 ], $me->[ 6 ], 0,
        $me->[ 1 ], $me->[ 4 ], $me->[ 7 ], 0,
        $me->[ 2 ], $me->[ 5 ], $me->[ 8 ], 0,
        0, 0, 0, 1
    );
    return $this;
}
#  
1;