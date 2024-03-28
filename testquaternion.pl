use strict;
use warnings;
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin";
use MathUtils;
use Quaternion;

my $q0 = Quaternion->new();
my $q1 = Quaternion->new(3, 4, 2, 1);
# print Dumper($q0);
# $q0->print;
# Quaternion->print($q0, 'static q0 scalar');
# $q0->X(5)->Y(-12)->Z(3)->W(1)->print('instance set X,Y,Z,W');
# Quaternion->print($q0, 'print static q0 after set X,Y,Z,W');
# Quaternion->X($q0, 13)->Y(21)->Z(7)->W(-1)->print('static set X, Y, Z, W');
# printf "X = %12e\n", $q0->X;
# printf "Y = %12e\n", $q0->Y;
# printf "Z = %12e\n", $q0->Z;
# printf "W = %12e\n", $q0->W;
$q0->set(3, 4, 2, 1)->print('q0');
# my $q1 = Quaternion->set($q0, 3, 4, 2, 1)->print();
$q1 = $q0->clone()->print('q1');
# equals
printf "overload q0 equals q1: %s\n", ($q0 == $q1) ? "YES" : "NO";
printf "overload q0 equals q1: %s\n", $q0->equals($q1) ? "YES" : "NO";
printf "overload q0 equals q1: %s\n", Quaternion->equals($q0, $q1) ? "YES" : "NO";
