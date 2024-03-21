use v5.28.0;
use strict;
use warnings;
use Data::Dumper;
use POSIX qw(round nearbyint); 
use FindBin;
use lib "$FindBin::Bin";
use Stereo;
use CoordConv;
use Vector;
# use Matrix;
use Math::Trig;

# my ($lon, $lat, $elev) = (19.18, 47.35, 440);

# sub nearest_squared {
#     my ($n) = @_;
#     $n = nearbyint($n);
#     return $n if ((sqrt($n) % 1) eq 0);
#     return nearest_squared($n+1);
# }

# my $nearest_squared = &nearest_squared;

package A;
use Data::Dumper;
sub new {
    my $class = shift;                              # Store the package name
    my $self = [];                                  # it's an ARRAY object
    bless($self, $class);                           # Bless the reference into that package
    # my @args = @_;                                  # save arguments
    # @args = splice(@_, 0, &MAXSIZE);
    # $dim = 1;
    # $size = &MAXSIZE;
    # my $aref = \@$self;                             # make an array reference of the class instance
    # @$aref = (0) x $size;
    # my @a = [ @args[0..&MAXSIZE-1] ];
    # for (my $i = 0; $i < &MAXSIZE; $i += 1) {
    #     if (defined $args[$i]) {
    #         @$aref[$i] = $args[$i];
    #     } else {
    #         @$aref[$i] = 0;
    #     }
    # }
    return $self;

    sub demo_sub {
        my ($self, @args) = @_;
        # Static part
        unless (ref($self) eq __PACKAGE__) {
            print "Class call::";
            # handle arguments
            if (@args) {
                # if sub expects only one argument and it shall be an instance of the class
                # we need to check if argument'ref is not equal with __PACKAGE__
                my $idx = 0;
                for (@args) {
                    unless (ref($_) ne __PACKAGE__) {
                        # so, it equals...
                        print "\n   $idx. argument in Instance clall is an instance of : [".ref($_)."]";
                    } else {
                        print "\n   $idx. argument in Instance clall is an instance of : [".ref(\$_)."] = ".$_;
                    }
                    $idx += 1;
                }
            }
            print "\n\n";
            return;
        }
        # Instance call
        unless (ref($self) ne __PACKAGE__) {
            print "Instance call::";
            # handle arguments
            if (scalar @args) {
                # if sub expects only one argument and it shall be an instance of the class
                # we need to check if argument'ref is not equal with __PACKAGE__
                my $idx = 0;
                for (@args) {
                    unless (ref($_) ne __PACKAGE__) {
                        # so, it equals...
                        print "\n   $idx. argument in Instance clall is an instance of : [".ref($_)."]";
                    } else {
                        print "\n   $idx. argument in Instance clall is an instance of : [".ref(\$_)."] = ".$_;
                    }
                    $idx += 1;
                }
            }
            print "\n\n";
            return;
        }
    }
}

package main;

my $a = A->new();

# instance call
$a->demo_sub;
$a->demo_sub($a);
$a->demo_sub($a, 'text');
# 
A->demo_sub;
A->demo_sub($a);
A->demo_sub($a, 'text');


# warn $nearest_squared(5);

# my $cc = CoordConv->new($lon, $lat, $elev);
# my $vec = Vector->new(-123, 123, -232);
# my $vec1 = Vector->new( 91, 42, 21 );
# my $m = Matrix->new([[1,2,3],[4,3,2], [7,3,2]]);
# my $m1 = Matrix->new();
# # my $mt = Matrix3D->new([[1,2,3],[4,5,6],[7,8,9]]);
# print Dumper {vector => $vec, mag => $vec->mag, unit => $vec->unit};
# print Dumper {
#     vec => $vec,
#     vec1 => $vec1,
#     add10 => $vec->add(10),
#     addvec => $vec->add(Vector->new(1,2,3)),
#     # `addvec => $vec->add($vec),
#     sub => $vec->sub($vec1),
#     matrix => $m,
#     matrix1 => $m1
# };
# print Dumper ($vec->mag);
# # print Dumper $mt * $mt;
# # print Dumper $cc;
# # my $s0 = Stereo->new();
# # my $s1 = Stereo->new($lon, $lat);
# # my $xy0 = $s0->forward($lat, $lon);
# # my $xy1 = $s1->forward($lon, $lat);
# # print Dumper ({s0 => $s0, s1 => $s1});
# # print Dumper ({forward0 => $s0->forward($lon, $lat)});
# # print Dumper ({forward1 => $s1->forward($lon, $lat)});

# # print Dumper({inverse1 => $s1->inverse(0,0)});
# # print Dumper ({s0 => $s0});

# # print Dumper({inverse1 => $s1->inverse(0,0)});
# # print Dumper({inverse0 => $s0->inverse($xy0->{x},$xy0->{y})});

# # print Dumper $s1, $xy, $s1->params;
# # print "The original geo coordinates\n";
# # print "lat=$lat\n";
# # print "lon=$lon\n";
# # print "FORWARD - calculate X,Y values in meters from system's center coordinates\n";
# # print "x0 = ".$xy0->{x}."\n";
# # print "y0 = ".$xy0->{y}."\n";
# # print "x1 = ".$xy1->{x}."\n";
# # print "y1 = ".$xy1->{y}."\n";
# # print "INVERSE - calculate LAT,LON values in degrees from given coordinates relative to the system's center\n";
# # my $ll0 = $s0->inverse($xy0->{x}, $xy0->{y});
# # my $ll1 = $s1->inverse($xy1->{x}, $xy1->{y});
# # print Dumper $ll0;
# # print Dumper $ll1;
# # print "lat0 = ". $ll0->{lat}."\n";
# # print "lon0 = ". $ll0->{lon}."\n";
# # print "lat1 = ". $ll1->{lat}."\n";
# # print "lon1 = ". $ll1->{lon}."\n";
