package MathUtils;
use utf8;
use strict;
use warnings;
use POSIX      qw(ceil sqrt sin cos round floor exp);
use Math::Trig qw (:pi);
use Math::Trig qw(deg2rad rad2deg acos);
use Math::Complex qw(logn);
use List::Util qw(min max);
use Carp;
use Scalar::Util qw(looks_like_number);
use constant PI => atan2( 1, 1 ) * 4;
use constant HALF_PI => PI * .5;
use constant TWO_PI  => PI * 2;
use constant LN2 => logn(2, exp(1));
# use constant LUT  => [
our @LUT =(
    '00', '01', '02', '03', '04', '05', '06', '07', '08', '09', '0a', '0b',
    '0c', '0d', '0e', '0f', '10', '11', '12', '13', '14', '15', '16', '17',
    '18', '19', '1a', '1b', '1c', '1d', '1e', '1f', '20', '21', '22', '23',
    '24', '25', '26', '27', '28', '29', '2a', '2b', '2c', '2d', '2e', '2f',
    '30', '31', '32', '33', '34', '35', '36', '37', '38', '39', '3a', '3b',
    '3c', '3d', '3e', '3f', '40', '41', '42', '43', '44', '45', '46', '47',
    '48', '49', '4a', '4b', '4c', '4d', '4e', '4f', '50', '51', '52', '53',
    '54', '55', '56', '57', '58', '59', '5a', '5b', '5c', '5d', '5e', '5f',
    '60', '61', '62', '63', '64', '65', '66', '67', '68', '69', '6a', '6b',
    '6c', '6d', '6e', '6f', '70', '71', '72', '73', '74', '75', '76', '77',
    '78', '79', '7a', '7b', '7c', '7d', '7e', '7f', '80', '81', '82', '83',
    '84', '85', '86', '87', '88', '89', '8a', '8b', '8c', '8d', '8e', '8f',
    '90', '91', '92', '93', '94', '95', '96', '97', '98', '99', '9a', '9b',
    '9c', '9d', '9e', '9f', 'a0', 'a1', 'a2', 'a3', 'a4', 'a5', 'a6', 'a7',
    'a8', 'a9', 'aa', 'ab', 'ac', 'ad', 'ae', 'af', 'b0', 'b1', 'b2', 'b3',
    'b4', 'b5', 'b6', 'b7', 'b8', 'b9', 'ba', 'bb', 'bc', 'bd', 'be', 'bf',
    'c0', 'c1', 'c2', 'c3', 'c4', 'c5', 'c6', 'c7', 'c8', 'c9', 'ca', 'cb',
    'cc', 'cd', 'ce', 'cf', 'd0', 'd1', 'd2', 'd3', 'd4', 'd5', 'd6', 'd7',
    'd8', 'd9', 'da', 'db', 'dc', 'dd', 'de', 'df', 'e0', 'e1', 'e2', 'e3',
    'e4', 'e5', 'e6', 'e7', 'e8', 'e9', 'ea', 'eb', 'ec', 'ed', 'ee', 'ef',
    'f0', 'f1', 'f2', 'f3', 'f4', 'f5', 'f6', 'f7', 'f8', 'f9', 'fa', 'fb',
    'fc', 'fd', 'fe', 'ff'
);

use constant LUT => @LUT;

BEGIN {
    require Exporter;
}

our @ISA     = qw(Exporter);
our $VERSION = qw(1.0.0);

our @EXPORT  = qw(
    smoothstep
    euclideanModulo
    pingpong
    generateUUID
    euclideanModulo
    damp
    mapLinear
    inverseLerp
    lerp
    nearest_square
    nearest_square_root
    normalize_angle_degrees
    normalize_angle_radians
    clamp
    smootherstep
    randInt
    randFloat
    randFloatSpread
    ceilPowerOfTwo
    floorPowerOfTwo
    setQuaternionFromProperEuler
    isWithin
    roundNearest
    LN2
    LUT
);
our @EXPORT_OK = qw(debug);

sub roundNearest($$) {
    my ($v, $m) = @_;
    round($v / $m) * $m;
}

sub isWithin($$$) {
    my ($v, $l, $h) = @_;
    return $v >= $l && $v <= $h;
}

sub setQuaternionFromProperEuler($$$$$) {

	# Intrinsic Proper Euler Angles - see https://en.wikipedia.org/wiki/Euler_angles
	# rotations are applied to the axes in the order specified by 'order'
	# rotation by angle 'a' is applied first, then by angle 'b', then by angle 'c'
	# angles are in radians

    my ( $q, $a, $b, $c, $order ) = @_;
	my $c2 = cos( $b / 2 );
	my $s2 = sin( $b / 2 );

	my $c13 = cos( ( $a + $c ) / 2 );
	my $s13 = sin( ( $a + $c ) / 2 );

	my $c1_3 = cos( ( $a - $c ) / 2 );
	my $s1_3 = sin( ( $a - $c ) / 2 );

	my $c3_1 = cos( ( $c - $a ) / 2 );
	my $s3_1 = sin( ( $c - $a ) / 2 );

	# switch ( order ) {

	# 	case 'XYX':
	# 		q.set( c2 * s13, s2 * c1_3, s2 * s1_3, c2 * c13 );
	# 		break;

	# 	case 'YZY':
	# 		q.set( s2 * s1_3, c2 * s13, s2 * c1_3, c2 * c13 );
	# 		break;

	# 	case 'ZXZ':
	# 		q.set( s2 * c1_3, s2 * s1_3, c2 * s13, c2 * c13 );
	# 		break;

	# 	case 'XZX':
	# 		q.set( c2 * s13, s2 * s3_1, s2 * c3_1, c2 * c13 );
	# 		break;

	# 	case 'YXY':
	# 		q.set( s2 * c3_1, c2 * s13, s2 * s3_1, c2 * c13 );
	# 		break;

	# 	case 'ZYZ':
	# 		q.set( s2 * s3_1, s2 * c3_1, c2 * s13, c2 * c13 );
	# 		break;

	# 	default:
	# 		console.warn( 'THREE.MathUtils: .setQuaternionFromProperEuler() encountered an unknown order: ' + order );

	# }

}

sub floorPowerOfTwo($) {
    my ($value) = @_;
    return pow( 2, ceil( log($value) / LN2 ) );
}

sub ceilPowerOfTwo ($) {
    my ($value) = @_;
    return pow( 2, ceil( log($value) / LN2 ) );
}

sub isPowerOfTwo ($) {
    # my ($value) = @_;
    # return (( hex($value) & ( hex($value - 1) ) ) eq 0) and (hex($value) ne 0);
}

sub randFloatSpread ($)  {
    my ($range) = @_;
    return $range * ( 0.5 - rand() );
}

sub randFloat($$) {
    my ( $low, $high ) = @_;
    return $low + rand() * ( $high - $low );
}

sub randInt($$) {
    my ( $low, $high ) = @_;
    return $low + floor( rand() * ( ( $high - $low ) + 1 ) );
}

sub smootherstep($$$)  {
    my ( $x, $min, $max ) = @_;
    return 0 if ( $x <= $min );
    return 1 if ( $x >= $max );
    $x = ( $x - $min ) / ( $max - $min );
    return ($x ** 3) * ( $x * ( $x * $6 - $15 ) + $10 );
}

sub smoothstep($$$)  {
    my ( $x, $min, $max ) = @_;
    return 0 if ( $x <= $min );
    return 1 if ( $x >= $max );
    $x = ( $x - $min ) / ( $max - $min );
    return ($x ** 2) * ( 3 - 2 * $x );

}

sub pingpong($$)  {
    my ( $x, $length ) = @_;
    $length = 1 unless (defined $length and ref \$length eq 'SCALAR' and $length ne 0);
    return $length - abs( euclideanModulo( $x, $length * 2 ) - $length );

}

sub euclideanModulo($$) {
    my ( $n, $m ) = @_;
	return ( ( $n % $m ) + $m ) % $m;

}

sub generateUUID {
    my $d0 = rand() * 0xffffffff | 0;
    my $d1 = rand() * 0xffffffff | 0;
    my $d2 = rand() * 0xffffffff | 0;
    my $d3 = rand() * 0xffffffff | 0;
    my $uuid =
    $LUT[ $d0 & 0xff ] . '' . $LUT[ ( $d0 >> 8 ) & 0xff ]
    . '' . $LUT[ ( $d0 >> 16 ) & 0xff ]
    . '' . $LUT[ ( $d0 >> 24 ) & 0xff ]
    . '' . '-'
    . '' . $LUT [ ($d1 & 0xff) ]
    . '' . $LUT[ ( $d1 >> 8 ) & 0xff ]
    . '' . '-'
    . '' . $LUT [ ($d1 >> 16) & 0x0f | 0x40 ]
    . '' . $LUT [ ($d1 >> 24) & 0xff ]
    . '' . '-'
    . '' . $LUT [ $d2 & 0x3f | 0x80 ]
    . '' . $LUT[ ( $d2 >> 8 ) & 0xff ]
    . '' . '-'
    . '' . $LUT[ ( $d2 >> 16 ) & 0xff ]
    . '' . $LUT[ ( $d2 >> 24 ) & 0xff ]
    . '' . $LUT[ $d3 & 0xff ]
    . '' . $LUT [ ($d3 >> 8) & 0xff ]
    . '' . $LUT [ ($d3 >> 16) & 0xff ]
    . '' . $LUT [ ($d3 >> 24) & 0xff ];
    return lc($uuid);
}

sub nearest_square($) {
    my $n = @_;
    my $sq = round(sqrt($n))**2;
    if ($sq < 2) {
        return 2;
    }
    if ($sq < $n) {
        return Vector2D::private_nearest_square->($n+1);
    }
    return $sq;
}

sub nearest_square_root($) {
    my $n = shift;
    my $sq = nearest_square($n);
    return sqrt($sq);
}

sub debug($$$) {
    my ( $line, $file, $msg ) = @_;
    printf "DEBUG::\"%s\" @ line %d in \"%s\".\n",
      defined $msg ? $msg : "info", $line, $file;
}

sub normalize_angle_degrees($) {
    my ($angle) = @_;
    croak "Error: missing argument", ( caller(0) )[3] unless defined $angle;
    croak "Error: invalid argument detected at pos 1, expected SCALAR ",
      ( caller(0) )[3]
      unless ( ref \$angle eq 'SCALAR' );
    return ( $angle % 360 + 360 ) % 360;
}

sub normalize_angle_radians($) {
    my ($angle) = @_;
    croak "Error: missing argument", ( caller(0) )[3] unless defined $angle;
    croak "Error: invalid argument detected at pos 1, expected SCALAR ",
      ( caller(0) )[3]
      unless ( ref \$angle eq 'SCALAR' );
    return ( $angle % ( 2 * PI ) + ( 2 * PI ) ) % ( 2 * PI );
}

sub clamp($$$) {
    my ( $value, $min, $max ) = @_;
    return max( $min, min( $max, $value ) );

}

sub lerp($$$) {
    my ($x, $y, $t) = @_;
    return (1 - $t) * $x + $t * $y;
}

sub inverseLerp($$$) {
    my ( $x, $y, $t ) = @_;
    if ($x ne $y) {
        return ( $t - $x ) / ($y - $x);
    } else {
        return 0;
    }
}

sub mapLinear($$$$$) {
    my ($x, $a1, $a2, $b1, $b2) = @_;
    return $b1 + ( $x - $a1 ) * ( $b2 - $b1 ) / ( $a2 - $a1 );
}

sub damp($$$$) {
    my ( $x, $y, $lambda, $dt ) = @_;
	return lerp( $x, $y, 1 - exp( -$lambda * $dt ) );
}

1;
