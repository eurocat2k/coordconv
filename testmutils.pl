use strict;
use warnings;
use utf8;
use Data::Dumper;
use POSIX         qw(log exp);
use Math::Complex qw(logn);
use FindBin;
use lib "$FindBin::Bin";
use MathUtils;

printf "pingpong 3, 4 = %f\n", pingpong( 3, 4 );

printf "damp 2, 13, .85, 60 = %f\n", damp( 2, 13, .15, 60 );

printf "lerp -5, 17, .125 = %f\n", lerp( -5, 17, .125 );

printf "uuid = %s\n", generateUUID();
