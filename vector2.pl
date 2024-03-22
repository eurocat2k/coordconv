use strict;
use warnings;
use POSIX qw(round ceil nearbyint);
use Data::Dumper;
use Math::Trig;
use FindBin;
use lib "$FindBin::Bin";
use Vector2D;
# new and set and print
my ($v0, $v1, $v2) = (Vector2D->new(1,2), Vector2D->new(3, 4));
printf "%f rad\n", (Vector2D->angleTo($v1, $v0));
printf "%f deg\n", rad2deg( Vector2D->angleTo( $v1, $v0 ) );

printf "v1(3,4) => v0(1,2) %f rad\n", ( $v0->angleTo($v1) );
printf "v1(3,4) => v0(1,2) %f deg\n", rad2deg( $v0->angleTo($v1) );
printf "v1(3,4) => v0(1,2) (NU) %f deg\n", rad2deg( $v0->angleToNU($v1) );
# $v0->sdiv(2)->print('v0 sdiv 2')->smul(4)->print('v0 smul 4');
# ($v0 * .5)->print('v0 * scalar');
# ( .5 * $v0 )->print('scalar * v0')->set(-5, -7)->normalize->print('normalized');
# printf "in radian: %f\n",  ($v0->set(1, -1)->angle);
# printf "(1, -1) in degrees: %f\n",  Vector2D::normalize_angle_degrees (rad2deg($v0->set(1, -1)->angle));
# printf "(1, -1) NU in degrees: %f\n",  Vector2D::normalize_angle_degrees (rad2deg($v0->set(1, -1)->angleNU));
# $v2 = ($v0 + $v1)->print('v0 + v1');
# $v2 = ($v2 - $v1)->print('v2 - v1');
# Vector2D->print($v1, 'v1');
# $v2->print('v0');
# $v1->set(10,20)->print('v1 after set');
# Vector2D->set($v1, -1, -2)->print('v1 after static set');
# Vector2D->zero($v1)->print('static zeroed v1');
# $v1->set(99,99)->print('v1 reste')->zero->print('instance zeroed v1');
# Vector2D->clone($v0)->print('static clone of v0');
# $v1->set(4, 4)->clone->print('cloned v1 instance');
# printf "v1 dot v2 static = %f\n", Vector2D->dot($v1, $v2);
# printf "v1 dot v2 instances = %f\n", $v1->print('v1 before dot ')->dot($v2->print('v2 before dot'));
# $v0->print('v0');
# $v1->print('v1');
# ($v1 + $v0)->print('Static v1 + v0');
# $v0->print('v0');
# $v1->print('v1');
# Vector2D->subtract($v1, $v0)->print('static v1 subtract v0');
# ($v1 * $v2)->print('v1 * v2');
# $v1->div($v2)->print('v1 div v2 instance');
# ($v1 / $v2)->print('v1 / v2');
# $v1->print('v1 after / call');
# $v2->print('v2 after / call');
# ($v1 . $2)->print('v1 dot v2');
#  print Dumper @{$v0->{elems}};
# print Dumper $v2;
