package Matrix3D;
use v5.28.0;
use strict;
require Exporter;
use FindBin;
use lib "$FindBin::Bin";
use POSIX;
use Data::Dumper;
use Math::Trig;
use Math::Trig ':pi';
use Math::BigFloat;
use Scalar::Util qw(looks_like_number);
our @ISA       = qw(Exporter);
our $VERSION   = qw(1.0.0);
our @EXPORT    = qw(new);
our @EXPORT_OK = qw();

use strict;
use warnings;

use Carp;
use Scalar::Util 'blessed';

our $eps = 1.0e-10;    # epsilon
our $true  = 1;
our $NaN   = POSIX::nan();


use overload
  '+'  => sub {
              my ($x, $y, $swap) = @_;
              $x -> add($y);
          },

  '-'  => sub {
              my ($x, $y, $swap) = @_;
              if ($swap) {
                  return $x -> neg() if !ref($y) && $y == 0;

                  my $class = ref $x;
                  return $class -> new($y) -> sub($x);
              }
              $x -> sub($y);
          },

  '*'  => sub {
              my ($x, $y, $swap) = @_;
              $x -> Mul($y);
          },

  '**' => sub {
              my ($x, $y, $swap) = @_;
              if ($swap) {
                  my $class = ref $x;
                  return $class -> new($y) -> Pow($x);
              }
              $x -> Pow($y);
          },

  '==' => sub {
              my ($x, $y, $swap) = @_;
              $x -> meq($y);
          },

  '!=' => sub {
              my ($x, $y, $swap) = @_;
              $x -> mne($y);
          },

  'int' => sub {
               my ($x, $y, $swap) = @_;
               $x -> int();
           },

  'abs' => sub {
               my ($x, $y, $swap) = @_;
               $x -> abs();
           },
  '~'  => 'transpose',
  '""' => 'as_string',
  '='  => 'clone';

sub new {
    my $that = shift;
    my $class = ref($that) || $that;
    my $self = [];

    # If called as an instance method and no arguments are given, return a
    # zero matrix of the same size as the invocand.

    if (ref($that) && (@_ == 0)) {
        @$self = map [ (0) x @$_ ], @$that;
    }

    # Otherwise return a new matrix based on the input arguments. The object
    # data is a blessed reference to an array containing the matrix data. This
    # array contains a list of arrays, one for each row, which in turn contains
    # a list of elements. An empty matrix has no rows.
    #
    #   [[ 1, 2, 3 ], [ 4, 5, 6 ]]  2-by-3 matrix
    #   [[ 1, 2, 3 ]]               1-by-3 matrix
    #   [[ 1 ], [ 2 ], [ 3 ]]       3-by-1 matrix
    #   [[ 1 ]]                     1-by-1 matrix
    #   []                          empty matrix

    else {

        my $data;

        # If there is a single argument, and that is not a reference,
        # assume new() has been called as, e.g., $class -> new(3).

        if (@_ == 1 && !ref($_[0])) {
            $data = [[ $_[0] ]];
        }

        # If there is a single argument, and that is a reference to an array,
        # and that array contains at least one element, and that element is
        # itself a reference to an array, then assume new() has been called
        # with the matrix as one argument, i.e., a reference to an array of
        # arrays, e.g., $class -> new([ [1, 2], [3, 4] ]) ...

        elsif (@_ == 1 && ref($_[0]) eq 'ARRAY'
               && @{$_[0]} > 0 && ref($_[0][0]) eq 'ARRAY')
        {
            $data = $_[0];
        }

        # ... otherwise assume that each argument to new() is a row. Note that
        # new() called with no arguments results in an empty matrix.

        else {
            $data = [ @_ ];
        }

        # Sanity checking.

        if (@$data) {
            my $nrow = @$data;
            my $ncol;

            for my $i (0 .. $nrow - 1) {
                my $row = $data -> [$i];

                # Verify that the row is a reference to an array.

                croak "row with index $i is not a reference to an array"
                  unless ref($row) eq 'ARRAY';

                # In the first round, get the number of elements, i.e., the
                # number of columns in the matrix. In the successive
                # rounds, verify that each row has the same number of
                # elements.

                if ($i == 0) {
                    $ncol = @$row;
                } else {
                    croak "each row must have the same number of elements"
                      unless @$row == $ncol;
                }
            }

            # Copy the data into $self only if the matrix is non-emtpy.

            @$self = map [ @$_ ], @$data if $ncol;
        }
    }

    bless $self, $class;
}


sub new_from_sub {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 4;
    my $class = shift;

    croak +(caller(0))[3], " is a class method, not an instance method"
      if ref $class;

    my $sub = shift;
    croak "The first input argument must be a code reference"
      unless ref($sub) eq 'CODE';

    my ($nrow, $ncol) = @_ == 0 ? (1, 1)
                      : @_ == 1 ? (@_, @_)
                      :           (@_);

    my $x = bless [], $class;
    for my $i (0 .. $nrow - 1) {
        for my $j (0 .. $ncol - 1) {
            $x -> [$i][$j] = $sub -> ($i, $j);
        }
    }

    return $x;
}


sub new_from_rows {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    my $class = shift;

    croak +(caller(0))[3], " is a class method, not an instance method"
      if ref $class;

    my @args = ();
    for (my $i = 0 ; $i <= $#_ ; ++$i) {
        my $x = $_[$i];
        $x = $class -> new($x)
          unless defined(blessed($x)) && $x -> isa($class);
        if ($x -> is_vector()) {
            push @args, $x -> to_row();
        } else {
            push @args, $x;
        }
    }

    $class -> new([]) -> catrow(@args);
}


sub new_from_cols {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    my $class = shift;

    croak +(caller(0))[3], " is a class method, not an instance method"
      if ref $class;

    $class -> new_from_rows(@_) -> swaprc();
}


sub id {
    my $self = shift;
    my $ref = ref $self;
    my $class = $ref || $self;

    my $n;
    if (@_) {
        $n = shift;
    } else {
        if ($ref) {
            my ($mx, $nx) = $self -> size();
            croak "When id() is called as an instance method, the invocand",
              " must be a square matrix" unless $mx == $nx;
            $n = $mx;
        } else {
            croak "When id() is called as a class method, the size must be",
              " given as an input argument";
        }
    }

    bless [ map [ (0) x ($_ - 1), 1, (0) x ($n - $_) ], 1 .. $n ], $class;
}


sub new_identity {
    id(@_);
}


sub eye {
    new_identity(@_);
}


sub exchg {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $class = shift;

    my $n = shift;
    bless [ map [ (0) x ($n - $_), 1, (0) x ($_ - 1) ], 1 .. $n ], $class;
}


sub scalar {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 4;
    my $class = shift;

    croak +(caller(0))[3], " is a class method, not an instance method"
      if ref $class;

    my $c = shift;
    my ($m, $n) = @_ == 0 ? (1, 1)
                : @_ == 1 ? (@_, @_)
                :           (@_);
    croak "The number of rows must be equal to the number of columns"
      unless $m == $n;

    bless [ map [ (0) x ($_ - 1), $c, (0) x ($n - $_) ], 1 .. $m ], $class;
}


sub zeros {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 3;
    my $self = shift;
    $self -> constant(0, @_);
};


sub ones {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 3;
    my $self = shift;
    $self -> constant(1, @_);
};


sub inf {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 3;
    my $self = shift;

    require Math::Trig;
    my $inf = Math::Trig::Inf();
    $self -> constant($inf, @_);
};


sub nan {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 3;
    my $self = shift;

    require Math::Trig;
    my $inf = Math::Trig::Inf();
    my $nan = $inf - $inf;
    $self -> constant($nan, @_);
};


sub constant {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 4;
    my $class = shift;

    croak +(caller(0))[3], " is a class method, not an instance method"
      if ref $class;

    my $c = shift;
    my ($m, $n) = @_ == 0 ? (1, 1)
                : @_ == 1 ? (@_, @_)
                :           (@_);

    bless [ map [ ($c) x $n ], 1 .. $m ], $class;
}


sub rand {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 3;
    my $class = shift;

    croak +(caller(0))[3], " is a class method, not an instance method"
      if ref $class;

    my ($nrow, $ncol) = @_ == 0 ? (1, 1)
                      : @_ == 1 ? (@_, @_)
                      :           (@_);

    my $x = bless [], $class;
    for my $i (0 .. $nrow - 1) {
        for my $j (0 .. $ncol - 1) {
            $x -> [$i][$j] = CORE::rand;
        }
    }

    return $x;
}


sub randi {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 4;
    my $class = shift;

    croak +(caller(0))[3], " is a class method, not an instance method"
      if ref $class;

    my ($min, $max);
    my $lim = shift;
    if (ref($lim) eq 'ARRAY') {
        ($min, $max) = @$lim;
    } else {
        $min = 0;
        $max = $lim;
    }

    my ($nrow, $ncol) = @_ == 0 ? (1, 1)
                      : @_ == 1 ? (@_, @_)
                      :           (@_);

    my $c = $max - $min + 1;
    my $x = bless [], $class;
    for my $i (0 .. $nrow - 1) {
        for my $j (0 .. $ncol - 1) {
            $x -> [$i][$j] = $min + CORE::int(CORE::rand($c));
        }
    }

    return $x;
}


sub randn {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 3;
    my $class = shift;

    croak +(caller(0))[3], " is a class method, not an instance method"
      if ref $class;

    my ($nrow, $ncol) = @_ == 0 ? (1, 1)
                      : @_ == 1 ? (@_, @_)
                      :           (@_);

    my $nelm  = $nrow * $ncol;
    my $twopi = 2 * atan2 0, -1;

    # The following might generate one value more than we need.

    my $x = [];
    for (my $k = 0 ; $k < $nelm ; $k += 2) {
        my $c1 = sqrt(-2 * log(CORE::rand));
        my $c2 = $twopi * CORE::rand;
        push @$x, $c1 * cos($c2), $c1 * sin($c2);
    }
    pop @$x if @$x > $nelm;

    $x = bless [ $x ], $class;
    $x -> reshape($nrow, $ncol);
}


sub clone {
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;
    my $class = ref $x;

    croak +(caller(0))[3], " is an instance method, not a class method"
      unless $class;

    my $y = [ map [ @$_ ], @$x ];
    bless $y, $class;
}


#
# Either class or object call, create a square matrix with the same
# dimensions as the passed-in list or array.
#
sub diagonal {
    my $that = shift;
    my $class = ref($that) || $that;
    my @diag = @_;
    my $self = [];

    # diagonal([2,3]) -> diagonal(2,3)
    @diag = @{$diag[0]} if (ref $diag[0] eq "ARRAY");

    my $len = scalar @diag;
    return undef if ($len == 0);

    for my $idx (0..$len-1) {
        my @r = (0) x $len;
        $r[$idx] = $diag[$idx];
        push(@{$self}, [@r]);
    }
    bless $self, $class;
}


#
# Either class or object call, create a square matrix with the same
# dimensions as the passed-in list or array.
#
sub tridiagonal {
    my $that = shift;
    my $class = ref($that) || $that;
    my(@up_d, @main_d, @low_d);
    my $self = [];

    #
    # Handle the different ways the tridiagonal vectors could
    # be passed in.
    #
    if (ref $_[0] eq "ARRAY") {
        @main_d = @{$_[0]};

        if (ref $_[1] eq "ARRAY") {
            @up_d = @{$_[1]};

            if (ref $_[2] eq "ARRAY") {
                @low_d = @{$_[2]};
            }
        }
    } else {
        @main_d = @_;
    }

    my $len = scalar @main_d;
    return undef if ($len == 0);

    #
    # Default the upper and lower diagonals if no vector
    # was passed in for them.
    #
    @up_d = (1) x ($len -1) if (scalar @up_d == 0);
    @low_d = @up_d if (scalar @low_d == 0);

    #
    # First row...
    #
    my @arow = (0) x $len;
    @arow[0..1] = ($main_d[0], $up_d[0]);
    push (@{$self}, [@arow]);

    #
    # Bulk of the matrix...
    #
    for my $idx (1 .. $#main_d - 1) {
        my @r = (0) x $len;
        @r[$idx-1 .. $idx+1] = ($low_d[$idx-1], $main_d[$idx], $up_d[$idx]);
        push (@{$self}, [@r]);
    }

    #
    # Last row.
    #
    my @zrow = (0) x $len;
    @zrow[$len-2..$len-1] = ($low_d[$#main_d -1], $main_d[$#main_d]);
    push (@{$self}, [@zrow]);

    bless $self, $class;
}


sub blkdiag {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    #croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $class = shift;

    my $y = [];
    my $nrowy = 0;
    my $ncoly = 0;

    for my $i (0 .. $#_) {
        my $x = $_[$i];

        $x = $class -> new($x)
          unless defined(blessed($x)) && $x -> isa($class);

        my ($nrowx, $ncolx) = $x -> size();

        # Upper right submatrix.

        for my $i (0 .. $nrowy - 1) {
            for my $j (0 .. $ncolx - 1) {
                $y -> [$i][$ncoly + $j] = 0;
            }
        }

        # Lower left submatrix.

        for my $i (0 .. $nrowx - 1) {
            for my $j (0 .. $ncoly - 1) {
                $y -> [$nrowy + $i][$j] = 0;
            }
        }

        # Lower right submatrix.

        for my $i (0 .. $nrowx - 1) {
            for my $j (0 .. $ncolx - 1) {
                $y -> [$nrowy + $i][$ncoly + $j] = $x -> [$i][$j];
            }
        }

        $nrowy += $nrowx;
        $ncoly += $ncolx;
    }

    bless $y, $class;
}


sub is_empty {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;
    return $x -> nelm() == 0;
}


sub is_scalar {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;
    return $x -> nelm() == 1 ? 1 : 0;
}


sub is_vector {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;
    return $x -> is_col() || $x -> is_row() ? 1 : 0;
}


sub is_row {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;
    return $x -> nrow() == 1 ? 1 : 0;
}


sub is_col {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;
    return $x -> ncol() == 1 ? 1 : 0;
}


sub is_square {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;
    my ($nrow, $ncol) = $x -> size();
    return $nrow == $ncol ? 1 : 0;
}


sub is_symmetric {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    my ($nrow, $ncol) = $x -> size();
    return 0 unless $nrow == $ncol;

    for my $i (1 .. $nrow - 1) {
        for my $j (0 .. $i - 1) {
            return 0 unless $x -> [$i][$j] == $x -> [$j][$i];
        }
    }

    return 1;
}


sub is_antisymmetric {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    my ($nrow, $ncol) = $x -> size();
    return 0 unless $nrow == $ncol;

    # Check the diagonal.

    for my $i (0 .. $nrow - 1) {
        return 0 unless $x -> [$i][$i] == 0;
    }

    # Check the off-diagonal.

    for my $i (1 .. $nrow - 1) {
        for my $j (0 .. $i - 1) {
            return 0 unless $x -> [$i][$j] == -$x -> [$j][$i];
        }
    }

    return 1;
}


sub is_persymmetric {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    $x -> fliplr() -> is_symmetric();
}


sub is_hankel {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    my ($nrow, $ncol) = $x -> size();
    return 0 unless $nrow == $ncol;

    # Check the lower triangular part.

    for my $i (0 .. $nrow - 2) {
        my $first = $x -> [$i][0];
        for my $k (1 .. $nrow - $i - 1) {
            return 0 unless $x -> [$i + $k][$k] == $first;
        }
    }

    # Check the strictly upper triangular part.

    for my $j (1 .. $ncol - 2) {
        my $first = $x -> [0][$j];
        for my $k (1 .. $nrow - $j - 1) {
            return 0 unless $x -> [$k][$j + $k] == $first;
        }
    }

    return 1;
}


sub is_zero {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;
    return $x -> is_constant(0);
}


sub is_one {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;
    return $x -> is_constant(1);
}


sub is_constant {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;

    my ($nrow, $ncol) = $x -> size();

    # An empty matrix contains no elements that are different from $c.

    return 1 if $nrow * $ncol == 0;

    my $c = @_ ? shift() : $x -> [0][0];
    for my $i (0 .. $nrow - 1) {
        for my $j (0 .. $ncol - 1) {
            return 0 if $x -> [$i][$j] != $c;
        }
    }

    return 1;
}


sub is_identity {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    my ($nrow, $ncol) = $x -> size();
    return 0 unless $nrow == $ncol;

    for my $i (0 .. $nrow - 1) {
        for my $j (0 .. $ncol - 1) {
            return 0 if $x -> [$i][$j] != ($i == $j ? 1 : 0);
        }
    }

    return 1;
}


sub is_exchg {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    my ($nrow, $ncol) = $x -> size();
    return 0 unless $nrow == $ncol;

    my $imax = $nrow - 1;
    for my $i (0 .. $nrow - 1) {
        for my $j (0 .. $ncol - 1) {
            return 0 if $x -> [$i][$j] != ($i + $j == $imax ? 1 : 0);
        }
    }

    return 1;
}


sub is_bool {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    my ($nrow, $ncol) = $x -> size();

    for my $i (0 .. $nrow - 1) {
        for my $j (0 .. $ncol - 1) {
            my $val = $x -> [$i][$j];
            return 0 if $val != 0 && $val != 1;
        }
    }

    return 1;
}


sub is_perm {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    my ($nrow, $ncol) = $x -> size();
    return 0 unless $nrow == $ncol;

    my $rowsum = [ (0) x $nrow ];
    my $colsum = [ (0) x $ncol ];

    for my $i (0 .. $nrow - 1) {
        for my $j (0 .. $ncol - 1) {
            my $val = $x -> [$i][$j];
            return 0 if $val != 0 && $val != 1;
            if ($val == 1) {
                return 0 if ++$rowsum -> [$i] > 1;
                return 0 if ++$colsum -> [$j] > 1;
            }
        }
    }

    for my $i (0 .. $nrow - 1) {
        return 0 if $rowsum -> [$i] != 1;
        return 0 if $colsum -> [$i] != 1;
    }

    return 1;
}


sub is_int {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    my ($nrow, $ncol) = $x -> size();

    for my $i (0 .. $nrow - 1) {
        for my $j (0 .. $ncol - 1) {
            return 0 unless $x -> [$i][$j] == int $x -> [$i][$j];
        }
    }

    return 1;
}


sub is_diag {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;
    $x -> is_band(0);
}


sub is_adiag {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;
    $x -> is_aband(0);
}


sub is_tridiag {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;
    $x -> is_band(1);
}


sub is_atridiag {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;
    $x -> is_aband(1);
}


sub is_pentadiag {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;
    $x -> is_band(2);
}


sub is_apentadiag {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;
    $x -> is_aband(2);
}


sub is_heptadiag {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;
    $x -> is_band(3);
}


sub is_aheptadiag {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;
    $x -> is_aband(3);
}


sub is_band {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    my $class = ref $x;

    my ($nrow, $ncol) = $x -> size();
    return 0 unless $nrow == $ncol;     # must be square

    my $k = shift;                      # bandwidth
    croak "Bandwidth can not be undefined" unless defined $k;
    if (ref $k) {
        $k = $class -> new($k)
          unless defined(blessed($k)) && $k -> isa($class);
        croak "Bandwidth must be a scalar" unless $k -> is_scalar();
        $k = $k -> [0][0];
    }

    return 0 if $nrow <= $k;            # if the band doesn't fit inside
    return 1 if $nrow == $k + 1;        # if the whole band fits exactly

    for my $i (0 .. $nrow - $k - 2) {
        for my $j ($k + 1 + $i .. $ncol - 1) {
            return 0 if ($x -> [$i][$j] != 0 ||
                         $x -> [$j][$i] != 0);
        }
    }

    return 1;
}


sub is_aband {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    my $class = ref $x;

    my ($nrow, $ncol) = $x -> size();
    return 0 unless $nrow == $ncol;     # must be square

    my $k = shift;                      # bandwidth
    croak "Bandwidth can not be undefined" unless defined $k;
    if (ref $k) {
        $k = $class -> new($k)
          unless defined(blessed($k)) && $k -> isa($class);
        croak "Bandwidth must be a scalar" unless $k -> is_scalar();
        $k = $k -> [0][0];
    }

    return 0 if $nrow <= $k;            # if the band doesn't fit inside
    return 1 if $nrow == $k + 1;        # if the whole band fits exactly

    # Check upper part.

    for my $i (0 .. $nrow - $k - 2) {
        for my $j (0 .. $nrow - $k - 2 - $i) {
            return 0 if $x -> [$i][$j] != 0;
        }
    }

    # Check lower part.

    for my $i ($k + 1 .. $nrow - 1) {
        for my $j ($nrow - $i + $k .. $nrow - 1) {
            return 0 if $x -> [$i][$j] != 0;
        }
    }

    return 1;
}


sub is_triu {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    my $nrow = $x -> nrow();
    my $ncol = $x -> ncol();

    return 0 unless $nrow == $ncol;

    for my $i (1 .. $nrow - 1) {
        for my $j (0 .. $i - 1) {
            return 0 unless $x -> [$i][$j] == 0;
        }
    }

    return 1;
}


sub is_striu {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    my $nrow = $x -> nrow();
    my $ncol = $x -> ncol();

    return 0 unless $nrow == $ncol;

    for my $i (0 .. $nrow - 1) {
        for my $j (0 .. $i) {
            return 0 unless $x -> [$i][$j] == 0;
        }
    }

    return 1;
}


sub is_tril {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    my $nrow = $x -> nrow();
    my $ncol = $x -> ncol();

    return 0 unless $nrow == $ncol;

    for my $i (0 .. $nrow - 1) {
        for my $j ($i + 1 .. $ncol - 1) {
            return 0 unless $x -> [$i][$j] == 0;
        }
    }

    return 1;
}


sub is_stril {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    my $nrow = $x -> nrow();
    my $ncol = $x -> ncol();

    return 0 unless $nrow == $ncol;

    for my $i (0 .. $nrow - 1) {
        for my $j ($i .. $ncol - 1) {
            return 0 unless $x -> [$i][$j] == 0;
        }
    }

    return 1;
}


sub is_atriu {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    my $nrow = $x -> nrow();
    my $ncol = $x -> ncol();

    return 0 unless $nrow == $ncol;

    for my $i (1 .. $nrow - 1) {
        for my $j ($ncol - $i .. $ncol - 1) {
            return 0 unless $x -> [$i][$j] == 0;
        }
    }

    return 1;
}


sub is_satriu {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    my $nrow = $x -> nrow();
    my $ncol = $x -> ncol();

    return 0 unless $nrow == $ncol;

    for my $i (0 .. $nrow - 1) {
        for my $j ($ncol - $i - 1 .. $ncol - 1) {
            return 0 unless $x -> [$i][$j] == 0;
        }
    }

    return 1;
}


sub is_atril {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    my $nrow = $x -> nrow();
    my $ncol = $x -> ncol();

    return 0 unless $nrow == $ncol;

    for my $i (0 .. $nrow - 1) {
        for my $j (0 .. $ncol - $i - 2) {
            return 0 unless $x -> [$i][$j] == 0;
        }
    }

    return 1;
}


sub is_satril {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    my $nrow = $x -> nrow();
    my $ncol = $x -> ncol();

    return 0 unless $nrow == $ncol;

    for my $i (0 .. $nrow - 1) {
        for my $j (0 .. $ncol - $i - 1) {
            return 0 unless $x -> [$i][$j] == 0;
        }
    }

    return 1;
}


sub find {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    my ($m, $n) = $x -> size();

    my $I = [];
    my $J = [];
    for my $j (0 .. $n - 1) {
        for my $i (0 .. $m - 1) {
            next unless $x->[$i][$j];
            push @$I, $i;
            push @$J, $j;
        }
    }

    return $I, $J if wantarray;

    my $K = [ map { $m * $J -> [$_] + $I -> [$_] } 0 .. $#$I ];
    return $K;
}


sub is_finite {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    require Math::Trig;
    my $pinf = Math::Trig::Inf();       # positiv infinity
    my $ninf = -$pinf;                  # negative infinity

    bless [ map { [
                   map {
                       $ninf < $_ && $_ < $pinf ? 1 : 0
                   } @$_
                  ] } @$x ], ref $x;
}


sub is_inf {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    require Math::Trig;
    my $pinf = Math::Trig::Inf();       # positiv infinity
    my $ninf = -$pinf;                  # negative infinity

    bless [ map { [
                   map {
                       $_ == $pinf || $_ == $ninf ? 1 : 0;
                   } @$_
                  ] } @$x ], ref $x;
}


sub is_nan {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    bless [ map [ map { $_ != $_ ? 1 : 0 } @$_ ], @$x ], ref $x;
}


sub all {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    $x -> apply(\&_all, @_);
}


sub any {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    $x -> apply(\&_any, @_);
}


sub cumall {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    $x -> apply(\&_cumall, @_);
}


sub cumany {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    $x -> apply(\&_cumany, @_);
}


sub size {
    my $self = shift;
    my $m = @{$self};
    my $n = $m ? @{$self->[0]} : 0;
    ($m, $n);
}


sub nelm {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;
    return @$x ? @$x * @{$x->[0]} : 0;
}


sub nrow {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;
    return scalar @$x;
}


sub ncol {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;
    return @$x ? scalar(@{$x->[0]}) : 0;
}


sub npag {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;
    return @$x ? 1 : 0;
}


sub ndim {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;
    my ($nrow, $ncol) = $x -> size();
    my $ndim = 0;
    ++$ndim if $nrow != 1;
    ++$ndim if $ncol != 1;
    return $ndim;
}


sub bandwidth {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    my ($nrow, $ncol) = $x -> size();

    my $upper = 0;
    my $lower = 0;

    for my $i (0 .. $nrow - 1) {
        for my $j (0 .. $ncol - 1) {
            next if $x -> [$i][$j] == 0;
            my $dist = $j - $i;
            if ($dist > 0) {
                $upper = $dist if $dist > $upper;
            } else {
                $lower = $dist if $dist < $lower;
            }
        }
    }

    $lower = -$lower;
    return $lower, $upper if wantarray;
    return $lower > $upper ? $lower : $upper;
}


sub catrow {
    my $x = shift;
    my $class = ref $x;

    my $ncol;
    my $z = bless [], $class;           # initialize output

    for my $y ($x, @_) {
        my $ncoly = $y -> ncol();
        next if $ncoly == 0;            # ignore empty $y

        if (defined $ncol) {
            croak "All operands must have the same number of columns in ",
              (caller(0))[3] unless $ncoly == $ncol;
        } else {
            $ncol = $ncoly;
        }

        push @$z, map [ @$_ ], @$y;
    }

    return $z;
}


sub catcol {
    my $x = shift;
    my $class = ref $x;

    my $nrow;
    my $z = bless [], $class;           # initialize output

    for my $y ($x, @_) {
        my $nrowy = $y -> nrow();
        next if $nrowy == 0;            # ignore empty $y

        if (defined $nrow) {
            croak "All operands must have the same number of rows in ",
              (caller(0))[3] unless $nrowy == $nrow;
        } else {
            $nrow = $nrowy;
        }

        for my $i (0 .. $nrow - 1) {
            push @{ $z -> [$i] }, @{ $y -> [$i] };
        }
    }

    return $z;
}


sub getrow {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    my $class = ref $x;

    my $idx = shift;
    croak "Row index can not be undefined" unless defined $idx;
    if (ref $idx) {
        $idx = __PACKAGE__ -> new($idx)
          unless defined(blessed($idx)) && $idx -> isa($class);
        $idx = $idx -> to_row();
        $idx = $idx -> [0];
    } else {
        $idx = [ $idx ];
    }

    my ($nrowx, $ncolx) = $x -> size();

    my $y = [];
    for my $iy (0 .. $#$idx) {
        my $ix = $idx -> [$iy];
        croak "Row index value $ix too large for $nrowx-by-$ncolx matrix in ",
          (caller(0))[3] if $ix >= $nrowx;
        $y -> [$iy] = [ @{ $x -> [$ix] } ];
    }

    bless $y, $class;
}


sub getcol {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    my $class = ref $x;

    my $idx = shift;
    croak "Column index can not be undefined" unless defined $idx;
    if (ref $idx) {
        $idx = __PACKAGE__ -> new($idx)
          unless defined(blessed($idx)) && $idx -> isa($class);
        $idx = $idx -> to_row();
        $idx = $idx -> [0];
    } else {
        $idx = [ $idx ];
    }

    my ($nrowx, $ncolx) = $x -> size();

    my $y = [];
    for my $jy (0 .. $#$idx) {
        my $jx = $idx -> [$jy];
        croak "Column index value $jx too large for $nrowx-by-$ncolx matrix in ",
          (caller(0))[3] if $jx >= $ncolx;
        for my $i (0 .. $nrowx - 1) {
            $y -> [$i][$jy] = $x -> [$i][$jx];
        }
    }

    bless $y, $class;
}


sub delrow {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    my $class = ref $x;

    my $idxdel = shift;
    croak "Row index can not be undefined" unless defined $idxdel;
    if (ref $idxdel) {
        $idxdel = __PACKAGE__ -> new($idxdel)
          unless defined(blessed($idxdel)) && $idxdel -> isa($class);
        $idxdel = $idxdel -> to_row();
        $idxdel = $idxdel -> [0];
    } else {
        $idxdel = [ $idxdel ];
    }

    my $nrowx = $x -> nrow();

    # This should be made faster.

    my $idxget = [];
    for my $i (0 .. $nrowx - 1) {
        my $seen = 0;
        for my $idx (@$idxdel) {
            if ($i == int $idx) {
                $seen = 1;
                last;
            }
        }
        push @$idxget, $i unless $seen;
    }

    my $y = [];
    @$y = map [ @$_ ], @$x[ @$idxget ];
    bless $y, $class;
}


sub delcol {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    my $class = ref $x;

    my $idxdel = shift;
    croak "Column index can not be undefined" unless defined $idxdel;
    if (ref $idxdel) {
        $idxdel = __PACKAGE__ -> new($idxdel)
          unless defined(blessed($idxdel)) && $idxdel -> isa($class);
        $idxdel = $idxdel -> to_row();
        $idxdel = $idxdel -> [0];
    } else {
        $idxdel = [ $idxdel ];
    }

    my ($nrowx, $ncolx) = $x -> size();

    # This should be made faster.

    my $idxget = [];
    for my $j (0 .. $ncolx - 1) {
        my $seen = 0;
        for my $idx (@$idxdel) {
            if ($j == int $idx) {
                $seen = 1;
                last;
            }
        }
        push @$idxget, $j unless $seen;
    }

    my $y = [];
    if (@$idxget) {
        for my $row (@$x) {
            push @$y, [ @{$row}[ @$idxget ] ];
        }
    }
    bless $y, $class;
}


sub concat {
    my $self   = shift;
    my $other  = shift;
    my $result =  $self->clone();

    return undef if scalar(@{$self}) != scalar(@{$other});
    for my $i (0 .. $#{$self}) {
        push @{$result->[$i]}, @{$other->[$i]};
    }
    $result;
}


sub splicerow {
    croak "Not enough input arguments" if @_ < 1;
    my $x = shift;
    my $class = ref $x;

    my $offs = 0;
    my $len  = $x -> nrow();
    my $repl = $class -> new([]);

    if (@_) {
        $offs = shift;
        croak "Offset can not be undefined" unless defined $offs;
        if (ref $offs) {
            $offs = $class -> new($offs)
              unless defined(blessed($offs)) && $offs -> isa($class);
            croak "Offset must be a scalar" unless $offs -> is_scalar();
            $offs = $offs -> [0][0];
        }

        if (@_) {
            $len = shift;
            croak "Length can not be undefined" unless defined $len;
            if (ref $len) {
                $len = $class -> new($len)
                  unless defined(blessed($len)) && $len -> isa($class);
                croak "length must be a scalar" unless $len -> is_scalar();
                $len = $len -> [0][0];
            }

            if (@_) {
                $repl = $repl -> catrow(@_);
            }
        }
    }

    my $y = $x -> clone();
    my $z = $class -> new([]);

    @$z = splice @$y, $offs, $len, @$repl;
    return wantarray ? ($y, $z) : $y;
}


sub splicecol {
    croak "Not enough input arguments" if @_ < 1;
    my $x = shift;
    my $class = ref $x;

    my ($nrowx, $ncolx) = $x -> size();

    my $offs = 0;
    my $len  = $ncolx;
    my $repl = $class -> new([]);

    if (@_) {
        $offs = shift;
        croak "Offset can not be undefined" unless defined $offs;
        if (ref $offs) {
            $offs = $class -> new($offs)
              unless defined(blessed($offs)) && $offs -> isa($class);
            croak "Offset must be a scalar" unless $offs -> is_scalar();
            $offs = $offs -> [0][0];
        }

        if (@_) {
            $len = shift;
            croak "Length can not be undefined" unless defined $len;
            if (ref $len) {
                $len = $class -> new($len)
                  unless defined(blessed($len)) && $len -> isa($class);
                croak "length must be a scalar" unless $len -> is_scalar();
                $len = $len -> [0][0];
            }

            if (@_) {
                $repl = $repl -> catcol(@_);
            }
        }
    }

    my $y = $x -> clone();
    my $z = $class -> new([]);

    if ($offs > $len) {
        carp "splicecol() offset past end of array";
        $offs = $len;
    }

    # The case when we are not removing anything from the invocand matrix: If
    # the offset is identical to the number of columns in the invocand matrix,
    # just appending the replacement matrix to the invocand matrix.

    if ($offs == $len) {
        unless ($repl -> is_empty()) {
            for my $i (0 .. $nrowx - 1) {
                push @{ $y -> [$i] }, @{ $repl -> [$i] };
            }
        }
    }

    # The case when we are removing everything from the invocand matrix: If the
    # offset is zero, and the length is identical to the number of columns in
    # the invocand matrix, replace the whole invocand matrix with the
    # replacement matrix.

    elsif ($offs == 0 && $len == $ncolx) {
        @$z = @$y;
        @$y = @$repl;
    }

    # The case when we are removing parts of the invocand matrix.

    else {
        if ($repl -> is_empty()) {
            for my $i (0 .. $nrowx - 1) {
                @{ $z -> [$i] } = splice @{ $y -> [$i] }, $offs, $len;
            }
        } else {
            for my $i (0 .. $nrowx - 1) {
                @{ $z -> [$i] } = splice @{ $y -> [$i] }, $offs, $len, @{ $repl -> [$i] };
            }
        }
    }

    return wantarray ? ($y, $z) : $y;
}


sub swaprc {
    my $x = shift;
    my $class = ref $x;

    my $y = bless [], $class;
    my $ncolx = $x -> ncol();
    return $y if $ncolx == 0;

    for my $j (0 .. $ncolx - 1) {
        push @$y, [ map $_->[$j], @$x ];
    }
    return $y;
}


sub flipud {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;
    my $class = ref $x;

    my $y = [ reverse map [ @$_ ], @$x ];
    bless $y, $class;;
}


sub fliplr {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;
    my $class = ref $x;

    my $y = [ map [ reverse @$_ ], @$x ];
    bless $y, $class;
}


sub flip {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    $x -> apply(sub { reverse @_ }, @_);
}


sub rot90 {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    my $class = ref $x;

    my $n = 1;
    if (@_) {
        $n = shift;
        if (ref $n) {
            $n = $class -> new($n)
              unless defined(blessed($n)) && $n -> isa($class);
            croak "Argument must be a scalar" unless $n -> is_scalar();
            $n = $n -> [0][0];
        }
        croak "Argument must be an integer" unless $n == int $n;
    }

    my $y = [];

    # Rotate 0 degrees, i.e., clone.

    $n %= 4;
    if ($n == 0) {
        $y = [ map [ @$_ ], @$x ];
    }

    # Rotate 90 degrees.

    elsif ($n == 1) {
        my ($nrowx, $ncolx) = $x -> size();
        my $jmax = $ncolx - 1;
        for my $i (0 .. $nrowx - 1) {
            for my $j (0 .. $ncolx - 1) {
                $y -> [$jmax - $j][$i] = $x -> [$i][$j];
            }
        }
    }

    # Rotate 180 degrees.

    elsif ($n == 2) {
        $y = [ map [ reverse @$_ ], reverse @$x ];
    }

    # Rotate 270 degrees.

    elsif ($n == 3) {
        my ($nrowx, $ncolx) = $x -> size();
        my $imax = $nrowx - 1;
        for my $i (0 .. $nrowx - 1) {
            for my $j (0 .. $ncolx - 1) {
                $y -> [$j][$imax - $i] = $x -> [$i][$j];
            }
        }
    }

    bless $y, $class;
}


sub rot180 {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;
    $x -> rot90(2);
}


sub rot270 {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;
    $x -> rot90(3);
}


sub repelm {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    my $class = ref $x;

    my $y = shift;
    $y = __PACKAGE__ -> new($y)
      unless defined(blessed($y)) && $y -> isa(__PACKAGE__);
    croak "Input argument must contain two elements"
      unless $y -> nelm() == 2;

    my ($nrowx, $ncolx) = $x -> size();

    $y = $y -> to_col();
    my $nrowrep = $y -> [0][0];
    my $ncolrep = $y -> [1][0];

    my $z = [];
    for my $ix (0 .. $nrowx - 1) {
        for my $jx (0 .. $ncolx - 1) {
            for my $iy (0 .. $nrowrep - 1) {
                for my $jy (0 .. $ncolrep - 1) {
                    my $iz = $ix * $nrowrep + $iy;
                    my $jz = $jx * $ncolrep + $jy;
                    $z -> [$iz][$jz] = $x -> [$ix][$jx];
                }
            }
        }
    }

    bless $z, $class;
}


sub repmat {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    my $class = ref $x;

    my $y = shift;
    $y = __PACKAGE__ -> new($y)
      unless defined(blessed($y)) && $y -> isa(__PACKAGE__);
    croak "Input argument must contain two elements"
      unless $y -> nelm() == 2;

    my ($nrowx, $ncolx) = $x -> size();

    $y = $y -> to_col();
    my $nrowrep = $y -> [0][0];
    my $ncolrep = $y -> [1][0];

    my $z = [];
    for my $ix (0 .. $nrowx - 1) {
        for my $jx (0 .. $ncolx - 1) {
            for my $iy (0 .. $nrowrep - 1) {
                for my $jy (0 .. $ncolrep - 1) {
                    my $iz = $iy * $nrowx + $ix;
                    my $jz = $jy * $ncolx + $jx;
                    $z -> [$iz][$jz] = $x -> [$ix][$jx];
                }
            }
        }
    }

    bless $z, $class;
}


sub reshape {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 3;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 3;
    my $x = shift;
    my $class = ref $x;

    my ($nrowx, $ncolx) = $x -> size();
    my $nelmx = $nrowx * $ncolx;

    my ($nrowy, $ncoly) = @_;
    my $nelmy = $nrowy * $ncoly;

    croak "when reshaping, the number of elements can not change in ",
      (caller(0))[3] unless $nelmx == $nelmy;

    my $y = [];

    # No reshaping; just clone.

    if ($nrowx == $nrowy && $ncolx == $ncoly) {
        $y = [ map [ @$_ ], @$x ];
    }

    elsif ($nrowx == 1) {

        # Reshape from a row vector to a column vector.

        if ($ncoly == 1) {
            $y = [ map [ $_ ], @{ $x -> [0] } ];
        }

        # Reshape from a row vector to a matrix.

        else {
            my $k = 0;
            for my $j (0 .. $ncoly - 1) {
                for my $i (0 .. $nrowy - 1) {
                    $y -> [$i][$j] = $x -> [0][$k++];
                }
            }
        }
    }

    elsif ($ncolx == 1) {

        # Reshape from a column vector to a row vector.

        if ($nrowy == 1) {
            $y = [[ map { @$_ } @$x ]];
        }

        # Reshape from a column vector to a matrix.

        else {
            my $k = 0;
            for my $j (0 .. $ncoly - 1) {
                for my $i (0 .. $nrowy - 1) {
                    $y -> [$i][$j] = $x -> [$k++][0];
                }
            }
        }
    }

    # The invocand is a matrix. This code works in all cases, but is somewhat
    # slower than the specialized code above.

    else {
        for my $k (0 .. $nelmx - 1) {
            my $ix = $k % $nrowx;
            my $jx = ($k - $ix) / $nrowx;
            my $iy = $k % $nrowy;
            my $jy = ($k - $iy) / $nrowy;
            $y -> [$iy][$jy] = $x -> [$ix][$jx];
        }
    }

    bless $y, $class;
}


sub to_row {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;
    my $class = ref $x;

    my $y = bless [], $class;

    my $ncolx = $x -> ncol();
    return $y if $ncolx == 0;

    for my $j (0 .. $ncolx - 1) {
        push @{ $y -> [0] }, map $_->[$j], @$x;
    }
    return $y;
}


sub to_col {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    my $class = ref $x;

    my $y = bless [], $class;

    my $ncolx = $x -> ncol();
    return $y if $ncolx == 0;

    for my $j (0 .. $ncolx - 1) {
        push @$y, map [ $_->[$j] ], @$x;
    }
    return $y;
}

sub to_permmat {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $v = shift;
    my $class = ref $v;

    my $n = $v -> nelm();
    my $P = $class -> zeros($n, $n);    # initialize output
    return $P if $n == 0;               # if emtpy $v

    croak "Invocand must be a vector" unless $v -> is_vector();
    $v = $v -> to_col();

    for my $i (0 .. $n - 1) {
        my $j = $v -> [$i][0];
        croak "index out of range" unless 0 <= $j && $j < $n;
        $P -> [$i][$j] = 1;
    }

    return $P;
}


sub to_permvec {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $P = shift;
    my $class = ref $P;

    croak "Invocand matrix must be square" unless $P -> is_square();
    my $n = $P -> nrow();

    my $v = $class -> zeros($n, 1);     # initialize output

    my $seen = [ (0) x $n ];            # keep track of the ones

    for my $i (0 .. $n - 1) {
        my $k;
        for my $j (0 .. $n - 1) {
            next if $P -> [$i][$j] == 0;
            if ($P -> [$i][$j] == 1) {
                croak "invalid permutation matrix; more than one row has",
                  " an element with value 1 in column $j" if $seen->[$j]++;
                $k = $j;
                next;
            }
            croak "invalid permutation matrix; element ($i,$j)",
              " is neither 0 nor 1";
        }
        croak "invalid permutation matrix; row $i has no element with value 1"
          unless defined $k;
        $v->[$i][0] = $k;
    }

    return $v;
}


sub triu {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    my $class = ref $x;

    my $n = 0;
    if (@_) {
        $n = shift;
        if (ref $n) {
            $n = $class -> new($n)
              unless defined(blessed($n)) && $n -> isa($class);
            croak "Argument must be a scalar" unless $n -> is_scalar();
            $n = $n -> [0][0];
        }
        croak "Argument must be an integer" unless $n == int $n;
    }

    my ($nrowx, $ncolx) = $x -> size();

    my $y = [];
    for my $i (0 .. $nrowx - 1) {
        for my $j (0 .. $ncolx - 1) {
            $y -> [$i][$j] = $j - $i >= $n ? $x -> [$i][$j] : 0;
        }
    }

    bless $y, $class;
}


sub tril {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    my $class = ref $x;

    my $n = 0;
    if (@_) {
        $n = shift;
        if (ref $n) {
            $n = $class -> new($n)
              unless defined(blessed($n)) && $n -> isa($class);
            croak "Argument must be a scalar" unless $n -> is_scalar();
            $n = $n -> [0][0];
        }
        croak "Argument must be an integer" unless $n == int $n;
    }

    my ($nrowx, $ncolx) = $x -> size();

    my $y = [];
    for my $i (0 .. $nrowx - 1) {
        for my $j (0 .. $ncolx - 1) {
            $y -> [$i][$j] = $j - $i <= $n ? $x -> [$i][$j] : 0;
        }
    }

    bless $y, $class;
}


sub slice {
    my $self = shift;
    my $class = ref($self);
    my $result = [];

    for my $i (0 .. $#$self) {
        push @$result, [ @{$self->[$i]}[@_] ];
    }

    bless $result, $class;
}


sub diagonal_vector {
    my $self = shift;
    my @diag;
    my $idx = 0;
    my($m, $n) = $self->size();

    croak "Not a square matrix" if $m != $n;

    foreach my $r (@{$self}) {
        push @diag, $r->[$idx++];
    }
    return \@diag;
}


sub tridiagonal_vector {
    my $self = shift;
    my(@main_d, @up_d, @low_d);
    my($m, $n) = $self->size();
    my $idx = 0;

    croak "Not a square matrix" if $m != $n;

    foreach my $r (@{$self}) {
        push @low_d, $r->[$idx - 1] if ($idx > 0);
        push @main_d, $r->[$idx++];
        push @up_d, $r->[$idx] if ($idx < $m);
    }
    return ([@main_d],[@up_d],[@low_d]);
}


sub add {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    my $class = ref $x;

    my $y = shift;
    $y = $class -> new($y) unless defined(blessed($y)) && $y -> isa($class);

    $x -> is_scalar() || $y -> is_scalar() ? $x -> sadd($y) : $x -> madd($y);
}


sub madd {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    my $class = ref $x;

    my $y = shift;
    $y = $class -> new($y) unless defined(blessed($y)) && $y -> isa($class);

    my ($nrowx, $ncolx) = $x -> size();
    my ($nrowy, $ncoly) = $y -> size();

    croak "Can't add $nrowx-by-$ncolx matrix to $nrowy-by-$ncoly matrix"
      unless $nrowx == $nrowy && $ncolx == $ncoly;

    my $z = [];
    for my $i (0 .. $nrowx - 1) {
        for my $j (0 .. $ncolx - 1) {
            $z->[$i][$j] = $x->[$i][$j] + $y->[$i][$j];
        }
    }

    bless $z, $class;
}


sub sadd {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;

    my $sub = sub { $_[0] + $_[1] };
    $x -> sapply($sub, @_);
}


sub sub {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    my $class = ref $x;

    my $y = shift;
    $y = $class -> new($y) unless defined(blessed($y)) && $y -> isa($class);

    $x -> is_scalar() || $y -> is_scalar() ? $x -> ssub($y) : $x -> msub($y);
}


sub msub {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    my $class = ref $x;

    my $y = shift;
    $y = $class -> new($y) unless defined(blessed($y)) && $y -> isa($class);

    my ($nrowx, $ncolx) = $x -> size();
    my ($nrowy, $ncoly) = $y -> size();

    croak "Can't subtract $nrowy-by-$ncoly matrix from $nrowx-by-$ncolx matrix"
      unless $nrowx == $nrowy && $ncolx == $ncoly;

    my $z = [];
    for my $i (0 .. $nrowx - 1) {
        for my $j (0 .. $ncolx - 1) {
            $z->[$i][$j] = $x->[$i][$j] - $y->[$i][$j];
        }
    }

    bless $z, $class;
}


sub ssub {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;

    my $sub = sub { $_[0] - $_[1] };
    $x -> sapply($sub, @_);
}


sub subtract {
    my $x = shift;
    $x -> sub(@_);
}


sub neg {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;
    bless [ map [ map -$_, @$_ ], @$x ], ref $x;
}


sub negative {
    my $x = shift;
    $x -> neg(@_);
}


sub Mul {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    my $class = ref $x;

    my $y = shift;
    $y = $class -> new($y) unless defined(blessed($y)) && $y -> isa($class);

    $x -> is_scalar() || $y -> is_scalar() ? $x -> smul($y) : $x -> mmul($y);
}


sub mmul {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    my $class = ref $x;

    my $y = shift;
    $y = $class -> new($y) unless defined(blessed($y)) && $y -> isa($class);

    my $mx = $x -> nrow();
    my $nx = $x -> ncol();

    my $my = $y -> nrow();
    my $ny = $y -> ncol();

    croak "Can't multiply $mx-by-$nx matrix with $my-by-$ny matrix"
      unless $nx == $my;

    my $z = [];
    my $l = $nx - 1;            # "inner length"
    for my $i (0 .. $mx - 1) {
        for my $j (0 .. $ny - 1) {
            $z -> [$i][$j] = _sum(map $x -> [$i][$_] * $y -> [$_][$j], 0 .. $l);
        }
    }

    bless $z, $class;
}


sub smul {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;

    my $sub = sub { $_[0] * $_[1] };
    $x -> sapply($sub, @_);
}


sub mmuladd {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 3;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 3;
    my $x = shift;
    my $class = ref $x;

    my ($mx, $nx) = $x -> size();

    my $y = shift;
    $y = $class -> new($y) unless defined(blessed($y)) && $y -> isa($class);
    my ($my, $ny) = $y -> size();

    croak "Can't multiply $mx-by-$nx matrix with $my-by-$ny matrix"
      unless $nx == $my;

    my $z = shift;
    $z = $class -> new($z) unless defined(blessed($z)) && $z -> isa($class);
    my ($mz, $nz) = $z -> size();

    croak "Can't add $mz-by-$nz matrix to $mx-by-$ny matrix"
      unless $mz == $mx && $nz == $ny;

    my $w = [];
    my $l = $nx - 1;            # "inner length"
    for my $i (0 .. $mx - 1) {
        for my $j (0 .. $ny - 1) {
            $w -> [$i][$j]
              = _sum(map($x -> [$i][$_] * $y -> [$_][$j], 0 .. $l),
                     $z -> [$i][$j]);
        }
    }

    bless $w, $class;
}


sub kron {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    my $class = ref $x;

    my $y = shift;
    $y = $class -> new($y) unless defined(blessed($y)) && $y -> isa($class);

    my ($nrowx, $ncolx) = $x -> size();
    my ($nrowy, $ncoly) = $y -> size();

    my $z = bless [], $class;

    for my $ix (0 .. $nrowx - 1) {
        for my $jx (0 .. $ncolx - 1) {
            for my $iy (0 .. $nrowy - 1) {
                for my $jy (0 .. $ncoly - 1) {
                    my $iz = $ix * $nrowx + $iy;
                    my $jz = $jx * $ncolx + $jy;
                    $z -> [$iz][$jz] = $x -> [$ix][$jx] * $y -> [$iy][$jy];
                }
            }
        }
    }

    return $z;
}


sub multiply {
    my $x = shift;
    $x -> mmul(@_);
}


sub multiply_scalar {
    my $self = shift;
    my $factor = shift;
    my $result = $self->new();

    my $last = $#{$self->[0]};
    for my $i (0 .. $#{$self}) {
        for my $j (0 .. $last) {
            $result->[$i][$j] = $factor * $self->[$i][$j];
        }
    }
    $result;
}


sub Pow {
    my $x = shift;
    $x -> mpow(@_);
}


sub mpow {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    my $class = ref $x;

    croak "Invocand matrix must be square in ", (caller(0))[3]
      unless $x -> is_square();

    my $n = shift;
    croak "Exponent can not be undefined" unless defined $n;
    if (ref $n) {
        $n = $class -> new($n) unless defined(blessed($n)) && $n -> isa($class);
        croak "Exponent must be a scalar in ", (caller(0))[3]
          unless $n -> is_scalar();
        $n = $n -> [0][0];
    }
    croak "Exponent must be an integer" unless $n == int $n;

    return $class -> new([]) if $x -> is_empty();

    my ($nrowx, $ncolx) = $x -> size();
    return $class -> id($nrowx, $ncolx) if $n == 0;
    return $x -> clone()                if $n == 1;

    my $neg = $n < 0;
    $n = -$n if $neg;

    my $y = $class -> id($nrowx, $ncolx);
    my $tmp = $x;
    while (1) {
        my $rem = $n % 2;
        $y *= $tmp if $rem;
        $n = ($n - $rem) / 2;
        last if $n == 0;
        $tmp = $tmp * $tmp;
    }

    $y = $y -> minv() if $neg;

    return $y;
}


sub spow {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;

    my $sub = sub { $_[0] ** $_[1] };
    $x -> sapply($sub, @_);
}


sub Inv {
    my $x = shift;
    $x -> minv();
}


sub invert {
    my $M = shift;
    my ($m, $n) = $M->size;
    croak "Can't invert $m-by-$n matrix; matrix must be square"
      if $m != $n;
    my $I = $M->new_identity($n);
    ($M->concat($I))->solve;
}


sub minv {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    #croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;
    my $class = ref $x;

    my $n = $x -> nrow();
    return $class -> id($n) -> mldiv($x, @_);
}


sub sinv {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    bless [ map [ map 1/$_, @$_ ], @$x ], ref $x;
}


sub mldiv {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    #croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $y = shift;
    my $class = ref $y;

    my $A = shift;
    $A = $class -> new($A) unless defined(blessed($A)) && $A -> isa($class);

    my ($m, $n) = $A -> size();

    if ($m > $n) {

        # If A is an M-by-N matrix where M > N, i.e., an overdetermined system,
        # compute (A'*A)\(A'*y) by doing a one level deep recursion.

        my $At = $A -> transpose();
        return $At -> mmul($y) -> mldiv($At -> mmul($A), @_);

    } elsif ($m < $n) {

        # If A is an M-by-N matrix where M < N, i.e., and underdetermined
        # system, compute A'*((A*A')\y) by doing a one level deep recursion.
        # This solution is not unique.

        my $At = $A -> transpose();
        return $At -> mldiv($At -> mmul($A), @_);
    }

    # If extra arguments are given ...

    if (@_) {

        require Config;
        my $max_iter = 20;
        my $rel_tol  = ($Config::Config{uselongdouble} ||
                        $Config::Config{usequadmath}) ? 1e-19 : 1e-9;
        my $abs_tol  = 0;
        my $debug;

        while (@_) {
            my $param = shift;
            croak "parameter name can not be undefined" unless defined $param;

            croak "missing value for parameter '$param'" unless @_;
            my $value = shift;

            if ($param eq 'MaxIter') {
                croak "value for parameter 'MaxIter' can not be undefined"
                  unless defined $value;
                croak "value for parameter 'MaxIter' must be a positive integer"
                  unless $value > 0 && $value == int $value;
                $max_iter = $value;
                next;
            }

            if ($param eq 'RelTol') {
                croak "value for parameter 'RelTol' can not be undefined"
                  unless defined $value;
                croak "value for parameter 'RelTol' must be non-negative"
                  unless $value >= 0;
                $rel_tol = $value;
                next;
            }

            if ($param eq 'AbsTol') {
                croak "value for parameter 'AbsTol' can not be undefined"
                  unless defined $value;
                croak "value for parameter 'AbsTol' must be non-negative"
                  unless $value >= 0;
                $abs_tol = $value;
                next;
            }

            if ($param eq 'Debug') {
                $debug = $value;
                next;
            }

            croak "unknown parameter '$param'";
        }

        if ($debug) {
            printf "\n";
            printf "max_iter = %24d\n", $max_iter;
            printf "rel_tol  = %24.15e\n", $rel_tol;
            printf "abs_tol  = %24.15e\n", $abs_tol;
        }

        my $y_norm = _hypot(map { @$_ } @$y);

        my $x = $y -> mldiv($A);

        my $x_best;
        my $iter_best;
        my $abs_err_best;
        my $rel_err_best;

        for (my $iter = 1 ; ; $iter++) {

            # Compute the residuals.

            my $r = $A -> mmuladd($x, -$y);

            # Compute the errors.

            my $r_norm  = _hypot(map @$_, @$r);
            my $abs_err = $r_norm;
            my $rel_err = $y_norm == 0 ? $r_norm : $r_norm / $y_norm;

            if ($debug) {
                printf "\n";
                printf "iter     = %24d\n", $iter;
                printf "r_norm   = %24.15e\n", $r_norm;
                printf "y_norm   = %24.15e\n", $y_norm;
                printf "abs_err  = %24.15e\n", $abs_err;
                printf "rel_err  = %24.15e\n", $rel_err;
            }

            # See if this is the first round or we have an new all-time best.

            if ($iter == 1 ||
                $abs_err < $abs_err_best ||
                $rel_err < $rel_err_best)
            {
                $x_best       = $x;
                $iter_best    = $iter;
                $abs_err_best = $abs_err;
                $rel_err_best = $rel_err;
            }

            if ($abs_err_best <= $abs_tol || $rel_err_best <= $rel_tol) {
                last;
            } else {

                # If we still haven't got the desired result, but have reached
                # the maximum number of iterations, display a warning.

                if ($iter == $max_iter) {
                    carp "mldiv() stopped because the maximum number of",
                      " iterations (max. iter = $max_iter) was reached without",
                      " converging to any of the desired tolerances (",
                      "rel_tol = ", $rel_tol, ", ",
                      "abs_tol = ", $abs_tol, ").",
                      " The best iterate (iter. = ", $iter_best, ") has",
                      " a relative residual of ", $rel_err_best, " and",
                      " an absolute residual of ", $abs_err_best, ".";
                    last;
                }
            }

            # Compute delta $x.

            my $d = $r -> mldiv($A);

            # Compute the improved solution $x.

            $x -= $d;
        }

        return $x_best, $rel_err_best, $abs_err_best, $iter_best if wantarray;
        return $x_best;
    }

    # If A is an M-by-M, compute A\y directly.

    croak "mldiv(): sizes don't match" unless $y -> nrow() == $n;

    # Create the augmented matrix.

    my $x = $A -> catcol($y);

    # Perform forward elimination.

    my ($rowperm, $colperm);
    eval { ($x, $rowperm, $colperm) = $x -> felim_fp() };
    croak "mldiv(): matrix is singular or close to singular" if $@;

    # Perform backward substitution.

    eval { $x = $x -> bsubs() };
    croak "mldiv(): matrix is singular or close to singular" if $@;

    # Remove left half to keep only the augmented matrix.

    $x = $x -> splicecol(0, $n);

    # Reordering the rows is only necessary when full (complete) pivoting is
    # used above. If partial pivoting is used, this reordeing could be skipped,
    # but it executes so fast that it causes no harm to do it anyway.

    @$x[ @$colperm ] = @$x;

    return $x;
}


sub sldiv {
    my $x = shift;
    $x -> sdiv(@_)
}


sub mrdiv {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    #croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $y = shift;
    my $class = ref $y;

    my $A = shift;
    $A = $class -> new($A) unless defined(blessed($A)) && $A -> isa($class);

    $y -> transpose() -> mldiv($A -> transpose(), @_) -> transpose();
}


sub srdiv {
    my $x = shift;
    $x -> sdiv(@_)
}


sub sdiv {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;

    my $sub = sub { $_[0] / $_[1] };
    $x -> sapply($sub, @_);
}


sub mpinv {
    my $A = shift;

    my $At = $A -> transpose();
    return $At -> mldiv($At -> mmul($A), @_);
}


sub pinv {
    my $x = shift;
    $x -> mpinv();
}


sub pinvert {
    my $x = shift;
    $x -> mpinv();
}


sub solve {
    my $self  = shift;
    my $class = ref($self);

    my $m    = $self->clone();
    my $mr   = $#{$m};
    my $mc   = $#{$m->[0]};
    my $f;
    my $try;

    return undef if $mc <= $mr;
  ROW: for(my $i = 0; $i <= $mr; $i++) {
        $try=$i;
        # make diagonal element nonzero if possible
        while (abs($m->[$i]->[$i]) < $eps) {
            last ROW if $try++ > $mr;
            my $row = splice(@{$m},$i,1);
            push(@{$m}, $row);
        }

        # normalize row
        $f = $m->[$i]->[$i];
        for (my $k = 0; $k <= $mc; $k++) {
            $m->[$i]->[$k] /= $f;
        }
        # subtract multiple of designated row from other rows
        for (my $j = 0; $j <= $mr; $j++) {
            next if $i == $j;
            $f = $m->[$j]->[$i];
            for (my $k = 0; $k <= $mc; $k++) {
                $m->[$j]->[$k] -= $m->[$i]->[$k] * $f;
            }
        }
    }

    # Answer is in augmented column
    $class -> new([ @{ $m -> transpose }[$mr+1 .. $mc] ]) -> transpose;
}


sub chol {
    my $x = shift;
    my $class = ref $x;

    croak "Input matrix must be a symmetric" unless $x -> is_symmetric();

    my $y = [ map [ (0) x @$x ], @$x ];         # matrix of zeros
    for my $i (0 .. $#$x) {
        for my $j (0 .. $i) {
            my $z = $x->[$i][$j];
            $z -= $y->[$i][$_] * $y->[$j][$_] for 0 .. $j;
            if ($i == $j) {
                croak "Matrix is not positive definite" if $z < 0;
                $y->[$i][$j] = sqrt($z);
            } else {
                croak "Matrix is not positive definite" if $y->[$j][$j] == 0;
                $y->[$i][$j] = $z / $y->[$j][$j];
            }
        }
    }
    bless $y, $class;
}


sub transpose {
    my $x = shift;
    my $class = ref $x;

    my $y = bless [], $class;
    my $ncolx = $x -> ncol();
    return $y if $ncolx == 0;

    for my $j (0 .. $ncolx - 1) {
        push @$y, [ map $_->[$j], @$x ];
    }
    return $y;
}


sub minormatrix {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 3;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 3;
    my $x = shift;
    my $class = ref $x;

    my ($m, $n) = $x -> size();

    my $i = shift;
    croak "Row index value $i outside of $m-by-$n matrix"
      unless 0 <= $i && $i < $m;

    my $j = shift;
    croak "Column index value $j outside of $m-by-$n matrix"
      unless 0 <= $j && $j < $n;

    # We could just use the following, which is simpler, but also slower:
    #
    #     $x -> delrow($i) -> delcol($j);

    my @rowidx = 0 .. $m - 1;
    splice @rowidx, $i, 1;

    my @colidx = 0 .. $n - 1;
    splice @colidx, $j, 1;

    bless [ map [ @{$_}[@colidx] ], @{$x}[@rowidx] ], $class;
}


sub minor {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 3;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 3;
    my $x = shift;

    croak "Matrix must be square" unless $x -> is_square();

    $x -> minormatrix(@_) -> determinant();
}


sub cofactormatrix {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    my ($m, $n) = $x -> size();
    croak "matrix must be square" unless $m == $n;

    my $y = [];
    for my $i (0 .. $m - 1) {
        for my $j (0 .. $n - 1) {
            $y -> [$i][$j] = (-1) ** ($i + $j) * $x -> minor($i, $j);
        }
    }

    bless $y;
}


sub cofactor {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 3;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 3;
    my $x = shift;

    my ($m, $n) = $x -> size();
    croak "matrix must be square" unless $m == $n;

    my ($i, $j) = @_;
    (-1) ** ($i + $j) * $x -> minor($i, $j);
}


sub adjugate {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    $x -> cofactormatrix() -> transpose();
}


sub det {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;
    my $class = ref $x;

    my ($nrowx, $ncolx) = $x -> size();
    croak "matrix must be square" unless $nrowx == $ncolx;

    # Create the augmented matrix.

    $x = $x -> catcol($class -> id($nrowx));

    # Perform forward elimination.

    my ($iperm, $jperm, $iswap, $jswap);
    eval { ($x, $iperm, $jperm, $iswap, $jswap) = $x -> felim_fp() };

    # Compute the product of the elements on the diagonal.

    my $det = 1;
    for (my $i = 0 ; $i < $nrowx ; ++$i) {
        last if ($det *= $x -> [$i][$i]) == 0;
    }

    # Adjust the sign according to the number of inversions.

    $det = ($iswap + $jswap) % 2 ? -$det : $det;

    return $det;
}


sub determinant {
    my $x = shift;
    $x -> det(@_);
}


sub detr {
    my $x = shift;
    my $class = ref($x);
    my $imax = $#$x;
    my $jmax = $#{$x->[0]};

    return undef unless $imax == $jmax;     # input must be a square matrix

    # Matrix is 3 × 3

    return
        $x -> [0][0] * ($x -> [1][1] * $x -> [2][2] - $x -> [1][2] * $x -> [2][1])
      - $x -> [0][1] * ($x -> [1][0] * $x -> [2][2] - $x -> [1][2] * $x -> [2][0])
      + $x -> [0][2] * ($x -> [1][0] * $x -> [2][1] - $x -> [1][1] * $x -> [2][0])
      if $imax == 2;

    # Matrix is 2 × 2

    return $x -> [0][0] * $x -> [1][1] - $x -> [1][0] * $x -> [0][1]
      if $imax == 1;

    # Matrix is 1 × 1

    return $x -> [0][0] if $imax == 0;

    # Matrix is N × N for N > 3.

    my $det = 0;

    # Create a matrix with column 0 removed. We only need to do this once.
    my $x0 = bless [ map [ @{$_}[1 .. $jmax] ], @$x ], $class;

    for my $i (0 .. $imax) {

        # Create a matrix with row $i and column 0 removed.
        my $x1 = bless [ map [ @$_ ], @{$x0}[ 0 .. $i-1, $i+1 .. $imax ] ], $class;

        my $term = $x1 -> determinant();
        $term *= $i % 2 ? -$x->[$i][0] : $x->[$i][0];

        $det += $term;
    }

    return $det;
}


sub int {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    bless [ map [ map int($_), @$_ ], @$x ], ref $x;
}

sub Floor {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    bless [ map { [
                   map {
                       my $ix = CORE::int($_);
                       ($ix <= $_) ? $ix : $ix - 1;
                   } @$_
                  ] } @$x ], ref $x;
}

sub Ceil {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    bless [ map { [
                   map {
                       my $ix = CORE::int($_);
                     ($ix >= $_) ? $ix : $ix + 1;
                   } @$_
                  ] } @$x ], ref $x;
}


sub Abs {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    bless [ map [ map abs($_), @$_ ], @$x ], ref $x;
}


sub Sign {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    bless [ map [ map { $_ <=> 0 } @$_ ], @$x ], ref $x;
}


sub Sum {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    $x -> apply(\&_sum, @_);
}


sub Prod {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    $x -> apply(\&_prod, @_);
}


sub mean {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    $x -> apply(\&_mean, @_);
}


sub hypot {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    $x -> apply(\&_hypot, @_);
}


sub min {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    $x -> apply(\&_min, @_);
}


sub max {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    $x -> apply(\&_max, @_);
}


sub median {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    $x -> apply(\&_median, @_);
}


sub cumsum {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    $x -> apply(\&_cumsum, @_);
}


sub cumprod {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    $x -> apply(\&_cumprod, @_);
}


sub cummean {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    $x -> apply(\&_cummean, @_);
}


sub diff {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    $x -> apply(\&_diff, @_);
}


sub vecnorm {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 3;
    my $x = shift;
    my $class = ref $x;

    my $p = 2;
    if (@_) {
        $p = shift;
        croak 'When the \$p argument is given, it can not be undefined'
          unless defined $p;
        if (ref $p) {
            $p = $class -> new($p)
              unless defined(blessed($p)) && $p -> isa($class);
            croak 'The $p argument must be a scalar' unless $p -> is_scalar();
            $p = $p -> [0][0];
        }
    }

    my $sub = sub { _vecnorm($p, @_) };
    $x -> apply($sub, @_);
}


sub apply {
    my $x = shift;
    my $class = ref $x;

    my $sub = shift;

    # Get the size of the input $x.

    my ($nrowx, $ncolx) = $x -> size();

    # Get the dimension along which to apply the subroutine.

    my $dim;
    if (@_) {
        $dim = shift;
        croak "Dimension can not be undefined" unless defined $dim;
        if (ref $dim) {
            $dim = $class -> new($dim)
              unless defined(blessed($dim)) && $dim -> isa($class);
            croak "Dimension must be a scalar" unless $dim -> is_scalar();
            $dim = $dim -> [0][0];
            croak "Dimension must be a positive integer"
              unless $dim > 0 && $dim == CORE::int($dim);
        }
        croak "Dimension must be 1 or 2" unless $dim == 1 || $dim == 2;
    } else {
        $dim = $nrowx > 1 ? 1 : 2;
    }

    # Initialise output.

    my $y = [];

    # Work along the first dimension, i.e., each column.

    my ($nrowy, $ncoly);
    if ($dim == 1) {
        $nrowy = 0;
        for my $j (0 .. $ncolx - 1) {
            my @col = $sub -> (map $_ -> [$j], @$x);
            if ($j == 0) {
                $nrowy = @col;
            } else {
                croak "The number of elements in each column must be the same"
                  unless $nrowy == @col;
            }
            $y -> [$_][$j] = $col[$_] for 0 .. $#col;
        }
        $y = [] if $nrowy == 0;
    }

    # Work along the second dimension, i.e., each row.

    elsif ($dim == 2) {
        $ncoly = 0;
        for my $i (0 .. $nrowx - 1) {
            my @row = $sub -> (@{ $x -> [$i] });
            if ($i == 0) {
                $ncoly = @row;
            } else {
                croak "The number of elements in each row must be the same"
                  unless $ncoly == @row;
            }
            $y -> [$i] = [ @row ];
        }
        $y = [] if $ncoly == 0;
    }

    bless $y, $class;
}


sub meq {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    my $class = ref $x;

    my $y = shift;
    $y = $class -> new($y)
      unless defined(blessed($y)) && $y -> isa($class);

    my ($nrowx, $ncolx) = $x -> size();
    my ($nrowy, $ncoly) = $y -> size();

    # Quick exit if the sizes don't match.

    return 0 unless $nrowx == $nrowy && $ncolx == $ncoly;

    # Compare the elements.

    for my $i (0 .. $nrowx - 1) {
        for my $j (0 .. $ncolx - 1) {
            return 0 if $x->[$i][$j] != $y->[$i][$j];
        }
    }
    return 1;
}


sub mne {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    my $class = ref $x;

    my $y = shift;
    $y = $class -> new($y)
      unless defined(blessed($y)) && $y -> isa($class);

    my ($nrowx, $ncolx) = $x -> size();
    my ($nrowy, $ncoly) = $y -> size();

    # Quick exit if the sizes don't match.

    return 1 unless $nrowx == $nrowy && $ncolx == $ncoly;

    # Compare the elements.

    for my $i (0 .. $nrowx - 1) {
        for my $j (0 .. $ncolx - 1) {
            return 1 if $x->[$i][$j] != $y->[$i][$j];
        }
    }
    return 0;
}


sub equal {
    my $A = shift;
    my $B = shift;

    my $jmax = $#{$A->[0]};
    for my $i (0 .. $#{$A}) {
        for my $j (0 .. $jmax) {
            return 0 if CORE::abs($A->[$i][$j] - $B->[$i][$j]) >= $eps;
        }
    }
    return 1;
}


sub seq {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    my $class = ref $x;

    my $y = shift;
    $y = $class -> new($y)
      unless defined(blessed($y)) && $y -> isa($class);

    $x -> sapply(sub { $_[0] == $_[1] ? 1 : 0 }, $y);
}


sub sne {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    my $class = ref $x;

    my $y = shift;
    $y = $class -> new($y)
      unless defined(blessed($y)) && $y -> isa($class);

    $x -> sapply(sub { $_[0] != $_[1] ? 1 : 0 }, $y);
}


sub slt {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    my $class = ref $x;

    my $y = shift;
    $y = $class -> new($y)
      unless defined(blessed($y)) && $y -> isa($class);

    $x -> sapply(sub { $_[0] < $_[1] ? 1 : 0 }, $y);
}


sub sle {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    my $class = ref $x;

    my $y = shift;
    $y = $class -> new($y)
      unless defined(blessed($y)) && $y -> isa($class);

    $x -> sapply(sub { $_[0] <= $_[1] ? 1 : 0 }, $y);
}


sub sgt {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    my $class = ref $x;

    my $y = shift;
    $y = $class -> new($y)
      unless defined(blessed($y)) && $y -> isa($class);

    $x -> sapply(sub { $_[0] > $_[1] ? 1 : 0 }, $y);
}


sub sge {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    my $class = ref $x;

    my $y = shift;
    $y = $class -> new($y)
      unless defined(blessed($y)) && $y -> isa($class);

    $x -> sapply(sub { $_[0] >= $_[1] ? 1 : 0 }, $y);
}


sub scmp {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 2;
    my $x = shift;
    my $class = ref $x;

    my $y = shift;
    $y = $class -> new($y)
      unless defined(blessed($y)) && $y -> isa($class);

    $x -> sapply(sub { $_[0] <=> $_[1] }, $y);
}


sub dot_product {
    my $x = shift;
    my $class = ref $x;

    my $y = shift;
    $y = $class -> new($y)
      unless defined(blessed($y)) && $y -> isa($class);

    croak "First argument must be a vector"  unless $x -> is_vector();
    $x = $x -> to_row() unless $x -> is_row();

    croak "Second argument must be a vector" unless $x -> is_vector();
    $y = $y -> to_col() unless $x -> is_col();

    croak "The two vectors must have the same length"
      unless $x -> nelm() == $y -> nelm();

    $x -> multiply($y) -> [0][0];
}


sub outer_product {
    my $x = shift;
    my $class = ref $x;

    my $y = shift;
    $y = $class -> new($y)
      unless defined(blessed($y)) && $y -> isa($class);

    croak "First argument must be a vector"  unless $x -> is_vector();
    $x = $x -> to_col() unless $x -> is_col();

    croak "Second argument must be a vector" unless $x -> is_vector();
    $y = $y -> to_row() unless $x -> is_row();

    $x -> multiply($y);
}


sub absolute {
    my $x = shift;
    croak "Argument must be a vector"  unless $x -> is_vector();

    _hypot(@{ $x -> to_row() -> [0] });
}


sub normalize {
    my $vector = shift;
    my $length = $vector->absolute();
    return undef
      unless $length;
    $vector->multiply_scalar(1 / $length);
}


sub cross_product {
    my $vectors = shift;
    my $class = ref($vectors);

    my $dimensions = @{$vectors->[0]};
    return undef
      unless $dimensions == @$vectors + 1;

    my @axis;
    foreach my $column (0..$dimensions-1) {
        my $tmp = $vectors->slice(0..$column-1,
                                  $column+1..$dimensions-1);
        my $scalar = $tmp->determinant;
        $scalar *= ($column % 2) ? -1 : 1;
        push @axis, $scalar;
    }
    my $axis = $class->new(\@axis);
    $axis = $axis->multiply_scalar(($dimensions % 2) ? 1 : -1);
}


sub as_string {
    my $self = shift;
    my $out = "";
    for my $row (@{$self}) {
        for my $col (@{$row}) {
            $out = $out . sprintf "%10.5f ", $col;
        }
        $out = $out . sprintf "\n";
    }
    $out;
}


sub as_array {
    my $x = shift;
    [ map [ @$_ ], @$x ];
}


sub map {
    my $x = shift;
    my $class = ref $x;

    my $sub = shift;
    croak "The first input argument must be a code reference"
      unless ref($sub) eq 'CODE';

    my $y = [];
    my ($nrow, $ncol) = $x -> size();
    for my $i (0 .. $nrow - 1) {
        for my $j (0 .. $ncol - 1) {
            local $_ = $x -> [$i][$j];
            $y -> [$i][$j] = $sub -> ($i, $j);
        }
    }

    bless $y, $class;
}


sub sapply {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 2;
    my $x = shift;
    my $class = ref $x;

    # Get the subroutine to apply on all the elements.

    my $sub = shift;
    croak "input argument must be a reference to a subroutine"
      unless ref($sub) eq 'CODE';

    my $y = bless [], $class;

    # For speed, treat a single matrix operand as a special case.

    if (@_ == 0) {
        my ($nrowx, $ncolx) = $x -> size();
        return $y if $nrowx * $ncolx == 0;      # quick exit if $x is empty

        for my $i (0 .. $nrowx - 1) {
            for my $j (0 .. $ncolx - 1) {
                $y -> [$i][$j] = $sub -> ($x -> [$i][$j]);
            }
        }

        return $y;
    }

    # Create some auxiliary arrays.

    my @args = ($x, @_);    # all matrices
    my @size = ();          # size of each matrix
    my @nelm = ();          # number of elements in each matrix

    # Loop over the input arguments to perform some checks and get their
    # properties. Also get the size (number of rows and columns) of the output
    # matrix.

    my $nrowy = 0;
    my $ncoly = 0;

    for my $k (0 .. $#args) {

        # Make sure the k'th argument is a matrix object.

        $args[$k] = $class -> new($args[$k])
          unless defined(blessed($args[$k])) && $args[$k] -> isa($class);

        # Get the number of rows, columns, and elements in the k'th argument,
        # and save this information for later.

        my ($nrowk, $ncolk) = $args[$k] -> size();
        $size[$k] = [ $nrowk, $ncolk ];
        $nelm[$k] = $nrowk * $ncolk;

        # Update the size of the output matrix.

        $nrowy = $nrowk if $nrowk > $nrowy;
        $ncoly = $ncolk if $ncolk > $ncoly;
    }

    # We only accept empty matrices if all matrices are empty.

    my $n_empty = grep { $_ == 0 } @nelm;
    return $y if $n_empty == @args;     # quick exit if all are empty

    # At ths point, we know that not all matrices are empty, but some might be
    # empty. We only continue if none are empty.

    croak "Either all or none of the matrices must be empty in ", (caller(0))[3]
      unless $n_empty == 0;

    # Loop over the subscripts into the output matrix.

    for my $i (0 .. $nrowy - 1) {
        for my $j (0 .. $ncoly - 1) {

            # Initialize the argument list for the subroutine call that will
            # give the value for element ($i,$j) in the output matrix.

            my @elms = ();

            # Loop over the matrices.

            for my $k (0 .. $#args) {

                # Get the number of rows and columns in the k'th matrix.

                my $nrowk = $size[$k][0];
                my $ncolk = $size[$k][1];

                # Compute the subscripts of the element to use in the k'th
                # matrix.

                my $ik = $i % $nrowk;
                my $jk = $j % $ncolk;

                # Get the element from the k'th matrix to use in this call.

                $elms[$k] = $args[$k][$ik][$jk];
            }

            # Now we have the argument list for the subroutine call.

            $y -> [$i][$j] = $sub -> (@elms);
        }
    }

    return $y;
}


sub felim_np {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    $x = $x -> clone();
    my $nrow = $x -> nrow();
    my $ncol = $x -> ncol();

    my $imax = $nrow - 1;
    my $jmax = $ncol - 1;

    my $iperm = [ 0 .. $imax ];         # row permutation vector
    my $jperm = [ 0 .. $imax ];         # column permutation vector
    my $iswap = 0;                      # number of row swaps
    my $jswap = 0;                      # number of column swaps

    my $debug = 0;

    printf "\nfelim_np(): before 0:\n\n%s\n", $x if $debug;

    for (my $i = 0 ; $i <= $imax && $i <= $jmax ; ++$i) {

        # The so far remaining unreduced submatrix starts at element ($i,$i).

        # Skip this round, if all elements below (i,i) are zero.

        my $saw_non_zero = 0;
        for (my $u = $i + 1 ; $u <= $imax ; ++$u) {
            if ($x->[$u][$i] != 0) {
                $saw_non_zero = 1;
                last;
            }
        }
        next unless $saw_non_zero;

        # Since we don't use pivoting, element ($i,$i) must be non-zero.

        if ($x->[$i][$i] == 0) {
            croak "No pivot element found for row $i";
        }

        # Subtract row $i from each row $u below $i.

        for (my $u = $i + 1 ; $u <= $imax ; ++$u) {
            for (my $j = $jmax ; $j >= $i ; --$j) {
                $x->[$u][$j] -= ($x->[$i][$j] * $x->[$u][$i]) / $x->[$i][$i];
            }

            # In case of round-off errors.

            $x->[$u][$i] *= 0;
        }

        printf "\nfelim_np(): after %u:\n\n%s\n\n", $i, $x if $debug;
    }

    return $x, $iperm, $jperm, $iswap, $jswap if wantarray;
    return $x;
}


sub felim_tp {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    croak "felim_tp(): too many input arguments" if @_ > 0;

    $x = $x -> clone();
    my $nrow = $x -> nrow();
    my $ncol = $x -> ncol();

    my $imax = $nrow - 1;
    my $jmax = $ncol - 1;

    my $iperm = [ 0 .. $imax ];         # row permutation vector
    my $jperm = [ 0 .. $imax ];         # column permutation vector
    my $iswap = 0;                      # number of row swaps
    my $jswap = 0;                      # number of column swaps

    my $debug = 0;

    printf "\nfelim_tp(): before 0:\n\n%s\n", $x if $debug;

    for (my $i = 0 ; $i <= $imax && $i <= $jmax ; ++$i) {

        # The so far remaining unreduced submatrix starts at element ($i,$i).

        # Skip this round, if all elements below (i,i) are zero.

        my $saw_non_zero = 0;
        for (my $u = $i + 1 ; $u <= $imax ; ++$u) {
            if ($x->[$u][$i] != 0) {
                $saw_non_zero = 1;
                last;
            }
        }
        next unless $saw_non_zero;

        # The pivot element is the first element in column $i (in the unreduced
        # submatrix) that is non-zero.

        my $p;          # index of pivot row

        for (my $u = $i ; $u <= $imax ; ++$u) {
            if ($x->[$u][$i] != 0) {
                $p = $u;
                last;
            }
        }

        printf "\nfelim_tp(): pivot element is (%u,%u)\n", $p, $i if $debug;

        # Swap rows $i and $p.

        if ($p != $i) {
            ($x->[$i], $x->[$p]) = ($x->[$p], $x->[$i]);
            ($iperm->[$i], $iperm->[$p]) = ($iperm->[$p], $iperm->[$i]);
            $iswap++;
        }

        # Subtract row $i from all following rows.

        for (my $u = $i + 1 ; $u <= $imax ; ++$u) {

            for (my $j = $jmax ; $j >= $i ; --$j) {
                $x->[$u][$j] -= ($x->[$i][$j] * $x->[$u][$i]) / $x->[$i][$i];
            }

            # In case of round-off errors.

            $x->[$u][$i] *= 0;
        }

        printf "\nfelim_tp(): after %u:\n\n%s\n\n", $i, $x if $debug;
    }

    return $x, $iperm, $jperm, $iswap, $jswap if wantarray;
    return $x;
}


sub felim_pp {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    croak "felim_pp(): too many input arguments" if @_ > 0;

    $x = $x -> clone();
    my $nrow = $x -> nrow();
    my $ncol = $x -> ncol();

    my $imax = $nrow - 1;
    my $jmax = $ncol - 1;

    my $iperm = [ 0 .. $imax ];         # row permutation vector
    my $jperm = [ 0 .. $imax ];         # column permutation vector
    my $iswap = 0;                      # number of row swaps
    my $jswap = 0;                      # number of column swaps

    my $debug = 0;

    printf "\nfelim_pp(): before 0:\n\n%s\n", $x if $debug;

    for (my $i = 0 ; $i <= $imax && $i <= $jmax ; ++$i) {

        # The so far remaining unreduced submatrix starts at element ($i,$i).

        # Skip this round, if all elements below (i,i) are zero.

        my $saw_non_zero = 0;
        for (my $u = $i + 1 ; $u <= $imax ; ++$u) {
            if ($x->[$u][$i] != 0) {
                $saw_non_zero = 1;
                last;
            }
        }
        next unless $saw_non_zero;

        # The pivot element is the element in column $i (in the unreduced
        # submatrix) that has the largest absolute value.

        my $p;                  # index of pivot row
        my $max_abs_val = 0;

        for (my $u = $i ; $u <= $imax ; ++$u) {
            my $abs_val = CORE::abs($x->[$u][$i]);
            if ($abs_val > $max_abs_val) {
                $max_abs_val = $abs_val;
                $p = $u;
            }
        }

        printf "\nfelim_pp(): pivot element is (%u,%u)\n", $p, $i if $debug;

        # Swap rows $i and $p.

        if ($p != $i) {
            ($x->[$p], $x->[$i]) = ($x->[$i], $x->[$p]);
            ($iperm->[$p], $iperm->[$i]) = ($iperm->[$i], $iperm->[$p]);
            $iswap++;
        }

        # Subtract row $i from all following rows.

        for (my $u = $i + 1 ; $u <= $imax ; ++$u) {

            for (my $j = $jmax ; $j >= $i ; --$j) {
                $x->[$u][$j] -= ($x->[$i][$j] * $x->[$u][$i]) / $x->[$i][$i];
            }

            # In case of round-off errors.

            $x->[$u][$i] *= 0;
        }

        printf "\nfelim_pp(): after %u:\n\n%s\n\n", $i, $x if $debug;
    }

    return $x, $iperm, $jperm, $iswap, $jswap if wantarray;
    return $x;
}


sub felim_sp {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    croak "felim_sp(): too many input arguments" if @_ > 0;

    $x = $x -> clone();
    my $nrow = $x -> nrow();
    my $ncol = $x -> ncol();

    my $imax = $nrow - 1;
    my $jmax = $ncol - 1;

    my $iperm = [ 0 .. $imax ];         # row permutation vector
    my $jperm = [ 0 .. $imax ];         # column permutation vector
    my $iswap = 0;                      # number of row swaps
    my $jswap = 0;                      # number of column swaps

    my $debug = 0;

    printf "\nfelim_sp(): before 0:\n\n%s\n", $x if $debug;

    for (my $i = 0 ; $i <= $imax && $i <= $jmax ; ++$i) {

        # The so far remaining unreduced submatrix starts at element ($i,$i).

        # Skip this round, if all elements below (i,i) are zero.

        my $saw_non_zero = 0;
        for (my $u = $i + 1 ; $u <= $imax ; ++$u) {
            if ($x->[$u][$i] != 0) {
                $saw_non_zero = 1;
                last;
            }
        }
        next unless $saw_non_zero;

        # The pivot element is the element in column $i (in the unreduced
        # submatrix) that has the largest absolute value relative to the other
        # elements on the same row.

        my $p;
        my $max_abs_ratio = 0;

        for (my $u = $i ; $u <= $imax ; ++$u) {

            # Find the element with the largest absolute value in row $u.

            my $max_abs_val = 0;
            for (my $v = $i ; $v <= $jmax ; ++$v) {
                my $abs_val = CORE::abs($x->[$u][$v]);
                $max_abs_val = $abs_val if $abs_val > $max_abs_val;
            }

            next if $max_abs_val == 0;

            # Find the ratio for this row and see if it the best so far.

            my $abs_ratio = CORE::abs($x->[$u][$i]) / $max_abs_val;
            #croak "column ", $i + 1, " has only zeros"
            #  if $ratio == 0;

            if ($abs_ratio > $max_abs_ratio) {
                $max_abs_ratio = $abs_ratio;
                $p = $u;
            }

        }

        printf "\nfelim_sp(): pivot element is (%u,%u)\n", $p, $i if $debug;

        # Swap rows $i and $p.

        if ($p != $i) {
            ($x->[$p], $x->[$i]) = ($x->[$i], $x->[$p]);
            ($iperm->[$p], $iperm->[$i]) = ($iperm->[$i], $iperm->[$p]);
            $iswap++;
        }

        # Subtract row $i from all following rows.

        for (my $u = $i + 1 ; $u <= $imax ; ++$u) {

            for (my $j = $jmax ; $j >= $i ; --$j) {
                $x->[$u][$j] -= ($x->[$i][$j] * $x->[$u][$i]) / $x->[$i][$i];
            }

            # In case of round-off errors.

            $x->[$u][$i] *= 0;
        }

        printf "\nfelim_sp(): after %u:\n\n%s\n\n", $i, $x if $debug;
    }

    return $x, $iperm, $jperm, $iswap, $jswap if wantarray;
    return $x;
}


sub felim_fp {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    croak "felim_fp(): too many input arguments" if @_ > 0;

    $x = $x -> clone();
    my $nrow = $x -> nrow();
    my $ncol = $x -> ncol();

    my $imax = $nrow - 1;
    my $jmax = $ncol - 1;

    my $iperm = [ 0 .. $imax ];         # row permutation vector
    my $jperm = [ 0 .. $imax ];         # column permutation vector
    my $iswap = 0;                      # number of row swaps
    my $jswap = 0;                      # number of column swaps

    my $debug = 0;

    printf "\nfelim_fp(): before 0:\n\n%s\n", $x if $debug;

    for (my $i = 0 ; $i <= $imax && $i <= $jmax ; ++$i) {

        # The so far remaining unreduced submatrix starts at element ($i,$i).
        # The pivot element is the element in the whole submatrix that has the
        # largest absolute value.

        my $p;                  # index of pivot row
        my $q;                  # index of pivot column

        # Loop over each row and column in the submatrix to find the element
        # with the largest absolute value.

        my $max_abs_val = 0;
        for (my $u = $i ; $u <= $imax ; ++$u) {
            for (my $v = $i ; $v <= $imax && $v <= $jmax ; ++$v) {
                my $abs_val = CORE::abs($x->[$u][$v]);
                if ($abs_val > $max_abs_val) {
                    $max_abs_val = $abs_val;
                    $p = $u;
                    $q = $v;
                }
            }
        }

        # If we didn't find a pivot element, it means that the so far unreduced
        # submatrix contains zeros only, in which case we're done.

        last unless defined $p;

        printf "\nfelim_fp(): pivot element is (%u,%u)\n", $p, $q if $debug;

        # Swap rows $i and $p.

        if ($p != $i) {
            printf "\nfelim_fp(): swapping rows %u and %u\n", $p, $i if $debug;
            printf "\nfrom this:\n\n%s\n", $x if $debug;
            ($x->[$p], $x->[$i]) = ($x->[$i], $x->[$p]);
            printf "\nto this:\n\n%s\n", $x if $debug;
            ($iperm->[$p], $iperm->[$i]) = ($iperm->[$i], $iperm->[$p]);
            $iswap++;
        }

        # Swap columns $i and $q.

        if ($q != $i) {
            printf "\nfelim_fp(): swapping columns %u and %u\n", $q, $i if $debug;
            printf "\nfrom this:\n\n%s\n", $x if $debug;
            for (my $u = 0 ; $u <= $imax ; ++$u) {
                ($x->[$u][$q], $x->[$u][$i]) = ($x->[$u][$i], $x->[$u][$q]);
            }
            printf "\nto this:\n\n%s\n", $x if $debug;
            ($jperm->[$q], $jperm->[$i]) = ($jperm->[$i], $jperm->[$q]);
            $jswap++;
        }

        # Subtract row $i from all following rows.

        for (my $u = $i + 1 ; $u <= $imax ; ++$u) {

            for (my $j = $jmax ; $j >= $i ; --$j) {
                $x->[$u][$j] -= ($x->[$i][$j] * $x->[$u][$i]) / $x->[$i][$i];
            }

            # In case of round-off errors.

            $x->[$u][$i] *= 0;
        }

        printf "\nfelim_fp(): after %u:\n\n%s\n\n", $i, $x if $debug;
    }

    return $x, $iperm, $jperm, $iswap, $jswap if wantarray;
    return $x;
}

sub bsubs {
    croak "Not enough arguments for ", (caller(0))[3] if @_ < 1;
    croak "Too many arguments for ", (caller(0))[3] if @_ > 1;
    my $x = shift;

    croak "bsubs(): too many input arguments" if @_ > 0;

    my $nrow = $x -> nrow();
    my $ncol = $x -> ncol();

    my $imax = $nrow - 1;
    my $jmax = $ncol - 1;

    my $debug = 0;

    printf "\nbsubs(): before 0:\n\n%s\n", $x if $debug;

    for (my $i = 0 ; $i <= $imax ; ++$i) {

        # Check the elements below ($i,$i). They should all be zero.

        for (my $k = $i + 1 ; $k <= $imax ; ++$k) {
            croak "matrix is not upper triangular; element ($i,$i) is non-zero"
              unless $x->[$k][$i] == 0;
        }

        # There is no rows above the first row to perform back-substitution on.

        next if $i == 0;

        # If the element on the diagonal is zero, we can't use it to perform
        # back-substitution. However, this is not a problem if all the elements
        # above ($i,$i) are zero.

        if ($x->[$i][$i] == 0) {
            my $non_zero = 0;
            my $k;
            for ($k = 0 ; $k < $i ; ++$k) {
                if ($x->[$k][$i] != 0) {
                    $non_zero++;
                    last;
                }
            }
            if ($non_zero) {
                croak "bsubs(): back substitution failed; diagonal element",
                  " ($i,$i) is zero, but ($k,$i) isn't";
                next;
            }
        }

        # Subtract row $i from each row $u above row $i.

        for (my $u = $i - 1 ; $u >= 0 ; --$u) {

            # From row $u subtract $c times of row $i.

            my $c = $x->[$u][$i] / $x->[$i][$i];

            for (my $j = $jmax ; $j >= $i ; --$j) {
                $x->[$u][$j] -= $c * $x->[$i][$j];
            }

            # In case of round-off errors.  (Will they ever happen?)

            $x->[$u][$i] *= 0;
        }

        printf "\nbsubs(): after %u:\n\n%s\n\n", $i, $x if $debug;
    }

    # Normalise.

    for (my $i = 0 ; $i <= $imax ; ++$i) {
        next if $x->[$i][$i] == 1;      # row is already normalized
        next if $x->[$i][$i] == 0;      # row can't be normalized
        for (my $j = $imax + 1 ; $j <= $jmax ; ++$j) {
            $x->[$i][$j] /= $x->[$i][$i];
        }
        $x->[$i][$i] = 1;
    }

    printf "\nbsubs(): after normalisation:\n\n%s\n\n", $x if $debug;

    return $x;
}


sub print {
    my $self = shift;

    print @_ if scalar(@_);
    print $self->as_string;
}


sub version {
    return "Math::Matrix $VERSION";
}

# Internal utility methods.

# Compute the sum of all elements using Neumaier's algorithm, an improvement
# over Kahan's algorithm.
#
# See
# https://en.wikipedia.org/wiki/Kahan_summation_algorithm#Further_enhancements

sub _sum {
    my $sum = 0;
    my $c = 0;

    for (@_) {
        my $t = $sum + $_;
        if (CORE::abs($sum) >= CORE::abs($_)) {
            $c += ($sum - $t) + $_;
        } else {
            $c += ($_ - $t) + $sum;
        }
        $sum = $t;
    }

    return $sum + $c;
}

# _prod LIST
#

sub _prod {
    my $prod = 1;
    $prod *= $_ for @_;
    return $prod;
}

# _mean LIST
#
# Method for finding the mean.

sub _mean {
    return 0 unless @_;
    _sum(@_) / @_;
}

# Method used to calculate the length of the hypotenuse of a right-angle
# triangle. It is designed to avoid errors arising due to limited-precision
# calculations performed on computers. E.g., with double-precision arithmetic:
#
#     sqrt(3e200**2 + 4e200**2)    # = Inf, due to overflow
#     _hypot(3e200, 4e200)         # = 5e200, which is correct
#
#     sqrt(3e-200**2 + 4e-200**2)  # = 0, due to underflow
#     _hypot(3e-200, 4e-200)       # = 5e-200, which is correct
#
# See https://en.wikipedia.org/wiki/Hypot

sub _hypot {
    my @x = map { CORE::abs($_) } @_;

    # Compute the maximum value.

    my $max = _max(@x);
    return 0 if $max == 0;

    # Scale and square the values.

    for (@x) {
        $_ /= $max;
        $_ *= $_;
    }

    $max * sqrt(_sum(@x))
}

# _sumsq LIST
#
# Sum of squared absolute values.

sub _sumsq {
    _sum(map { $_ * $_ } map { CORE::abs($_) } @_);
}

# _vecnorm P, LIST
#
# Vector P-norm. If the input is $x[0], $x[1], ..., then the output is
#
#   (abs($x[0])**$p + abs($x[1])**$p + ...)**(1/$p)

sub _vecnorm {
    my $p = shift;
    my @x = map { CORE::abs($_) } @_;

    return _sum(@x) if $p == 1;

    require Math::Trig;
    my $inf = Math::Trig::Inf();

    return _max(@x) if $p == $inf;

    # Compute the maximum value.

    my $max = 0;
    for (@x) {
        $max = $_ if $_ > $max;
    }

    # Scale and apply power function.

    for (@x) {
        $_ /= $max;
        $_ **= $p;
    }

    $max * _sum(@x) ** (1/$p);
}

# _min LIST
#
# Minimum value.

sub _min {
    my $min = shift;
    for (@_) {
        $min = $_ if $_ < $min;
    }

    return $min;
}

# _max LIST
#
# Maximum value.

sub _max {
    my $max = shift;
    for (@_) {
        $max = $_ if $_ > $max;
    }

    return $max;
}

# _median LIST
#
# Method for finding the median.

sub _median {
    my @x = sort { $a <=> $b } @_;
    if (@x % 2) {
         $x[$#x / 2];
    } else {
        ($x[@x / 2] + $x[@x / 2 - 1]) / 2;
    }
}

# _any LIST
#
# Method that returns 1 if at least one value in LIST is non-zero and 0
# otherwise.

sub _any {
    for (@_) {
        return 1 if $_ != 0;
    }
    return 0;
}

# _all LIST
#
# Method that returns 1 if all values in LIST are non-zero and 0 otherwise.

sub _all {
    for (@_) {
        return 0 if $_ == 0;
    }
    return 1;
}

# _cumsum LIST
#
# Cumulative sum. If the input is $x[0], $x[1], ..., then output element $y[$i]
# is the sum of the elements $x[0], $x[1], ..., $x[$i].

sub _cumsum {
    my @sum = ();

    my $sum = 0;
    my $c = 0;

    for (@_) {
        my $t = $sum + $_;
        if (CORE::abs($sum) >= CORE::abs($_)) {
            $c += ($sum - $t) + $_;
        } else {
            $c += ($_ - $t) + $sum;
        }
        $sum = $t;
        push @sum, $sum + $c;
    }

    return @sum;
}

# _cumprod LIST
#
# Cumulative product. If the input is $x[0], $x[1], ..., then output element
# $y[$i] is the product of the elements $x[0], $x[1], ..., $x[$i].

sub _cumprod {
    my @prod = shift;
    push @prod, $prod[-1] * $_ for @_;
    return @prod;
}

# _cummean LIST
#
# Cumulative mean. If the input is $x[0], $x[1], ..., then output element $y[$i]
# is the mean of the elements $x[0], $x[1], ..., $x[$i].

sub _cummean {
    my @mean = ();
    my $sum = 0;
    for my $i (0 .. $#_) {
        $sum += $_[$i];
        push @mean, $sum / ($i + 1);
    }
    return @mean;
}

# _cummean LIST
#
# Cumulative minimum. If the input is $x[0], $x[1], ..., then output element
# $y[$i] is the minimum of the elements $x[0], $x[1], ..., $x[$i].

sub _cummin {
    my @min = shift;
    for (@_) {
        push @min, $min[-1] < $_ ? $min[-1] : $_;
    }
    return @min;
}

# _cummax LIST
#
# Cumulative maximum. If the input is $x[0], $x[1], ..., then output element
# $y[$i] is the maximum of the elements $x[0], $x[1], ..., $x[$i].

sub _cummax {
    my @max = shift;
    for (@_) {
        push @max, $max[-1] > $_ ? $max[-1] : $_;
    }
    return @max;
}

# _cumany LIST
#
# Cumulative any. If the input is $x[0], $x[1], ..., then output element $y[$i]
# is 1 if at least one of the elements $x[0], $x[1], ..., $x[$i] is non-zero,
# and 0 otherwise.

sub _cumany {
    my @any = ();
    for (@_) {
        if ($_ != 0) {
            push @any, (1) x (@_ - @any);
            last;
        }
        push @any, 0;
    }
    return @any;
}

# _cumall LIST
#
# Cumulative all. If the input is $x[0], $x[1], ..., then output element $y[$i]
# is 1 if all of the elements $x[0], $x[1], ..., $x[$i] are non-zero, and 0
# otherwise.

sub _cumall {
    my @all = ();
    for (@_) {
        if ($_ == 0) {
            push @all, (0) x (@_ - @all);
            last;
        }
        push @all, 1;
    }
    return @all;
}

# _diff LIST
#
# Difference. If the input is $x[0], $x[1], ..., then output element $y[$i] =
# $x[$i+1] - $x[$i].

sub _diff {
    my @diff = ();
    for my $i (1 .. $#_) {
        push @diff, $_[$i] - $_[$i - 1];
    }
    return @diff;
}
1;
