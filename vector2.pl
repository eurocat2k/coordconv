use strict;
use warnings;
use POSIX qw(round ceil nearbyint);
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin";
use Vector2D;
# new and set and print
my ($v0, $v1, $v2) = Vector2D->new;
$v0->set(3,2)->print('v0');
$v1 = $v0->clone->print('v1')->set(8,4);
Vector2D->add($v0, $v1)->print('static v0 + V1');
$v0->add($v1)->print('v0 + v1');


