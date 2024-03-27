use strict;
use warnings;
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin";
use MathUtils;
use Quaternion;

my $q0 = Quaternion->new();
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
my $q1 = Quaternion->set($q0, 3, 4, 2, 1, 4)->print();
$q0->clone()->print;

Quaternion->copy($q1)->print;
