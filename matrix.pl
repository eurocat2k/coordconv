use strict;
use warnings;
use POSIX qw(round ceil nearbyint);
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin";
use Matrix3;

# constructor of 3x3 matrix
my $m = Matrix3->new(1,2,3,4,5,6,7,8,9,10,11,12);
my $m1 = Matrix3->new;
my $m2 = Matrix3->new;
# print
$m->print;
# set
warn "set(4,8,99,undef,3)\n";
$m->set(undef,114,-18,-99,undef,36,1,undef,13,65)->print;
# identity
$m1->identity->print;
# copy from another matrix
$m1->copy($m)->print;
# mul
$m1->set(.5, .3, .1, .5, .25, .75, .25, .05, .01)->print;
$m2->set(2, 3, 4, 5, 6, 7, 8, 9, 10);
# static
Matrix3->multipleMatrices($m1, $m2)->print;
$m->multipleMatrices($m1, $m2)->print;
# destructive
$m->mul($m2)->mul($m1)->print;
# multiply with scalar
$m->mulscale(.5)->print->mulscale(-1)->print;
# determinant
print "det m = ".$m->det."\n";
# inverse
$m->set(1,5,-9,10,1,12,-8,3,1)->invert->print;
$m->invert->print;
# transpose
$m->transpose->print;
# setUvTransform
$m1->setUvTransform(13, 11, -9, 23, 12, 0, 0)->print;
