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
# $v2 = Vector2D->copy($v2, $v1)->print('after static copy v2');
# $v1 = $v2->set(-9, 23)->copy($v2)->print('v1 after copy');
# $v1->zero->print('zeroed v1')->set($v0)->print('v0 set v1')->set(7, 8)->print('v1 after set 7, 8');
# $v2 = Vector2D->copy($v2, $v0)->print;
# $v2 = Vector2D->copy($v0, $v2)->print;
$v2 = $v1->copy($v1)->print('v0 copied into v2');


