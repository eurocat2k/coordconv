package Matrix;
use strict;
use warnings;
use Data::Dumper;
use POSIX qw(ceil sqrt);
use Carp;
use Scalar::Util qw(looks_like_number);
require Exporter;
our @ISA = qw(Exporter);
our $VERSION = qw(1.0.0);
our @EXPORT = qw(new);
our @EXPORT_OK = qw(dim size);
# 
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
    if (@args) {
        $size = $private_nearest_square->(@args);          # get the size of the matrix: default 2x2=4 square maxtrix
        $dim = sqrt($private_nearest_square->(@args));     # get the dimension of the square matrix: default 2
    } else {
        $dim = 2;
        $size = 4;   
    }
    my $alen = scalar @args;
    @args = splice(@args, 0, $alen);
    my $aref = \@$self;                             # make an array reference of the class instance
    @$aref = (0) x $size;
    my @a = [ @args[0..$alen-1] ];
    for (my $i = 0; $i < $alen-1; $i += 1) {
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
END {
    print "Matrix destroyed\n";
}
#   
1;