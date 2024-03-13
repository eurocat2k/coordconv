package Stereo;
use v5.28.0;
use strict;
require Exporter;
use FindBin;
use lib "$FindBin::Bin";
use POSIX;
use Math::Trig;
use Math::Trig ':pi';
use Math::BigFloat;
use Scalar::Util qw(looks_like_number);
# 
our @ISA = qw(Exporter);
our $VERSION = qw(1.0.0);
our @EXPORT = qw(new);
our @EXPORT_OK = qw();
BEGIN {
    require Sphere;
    require Wgs84;
}
# Constants
my $SPI = 3.14159265359;
my $SYS_CENTER_LON = 19.2322222222222;
my $SYS_CENTER_LAT = 47.4452777777778;
my $SIXTH = 0.1666666666666666667;  # 1/6
my $RA4 = 0.04722222222222222222;   # 17/360
my $RA6 = 0.02215608465608465608;   #
my $EPSLN = 1.0e-10;                # epsilon
# Params
my $params = {
    SYS_CENTER_LAT => $SYS_CENTER_LAT,
    SYS_CENTER_LON => $SYS_CENTER_LON
};
# Predefinitions
sub phi2z($$);

# Constructor
sub new {
    my $inv = shift;
    my $class = ref($inv) || $inv;
    if (@_ eq 2) {
        my ($lon, $lat) = @_;
        $params->{SYS_CENTER_LAT} = $lat unless not looks_like_number($lat);
        $params->{SYS_CENTER_LON} = $lon unless not looks_like_number($lon);
    }
    my $self = {};
    bless($self, $class);
    return $self;
}
# getters/setters
sub sys_center_lat {
    my $self = shift;
    if (@_) {
        my $lat = shift;
        $params->{SYS_CENTER_LAT} = $lat unless not looks_like_number($lat);    # otherwise keep the original value for latitude of the system center
    }
    return $params->{SYS_CENTER_LAT};
}
sub sys_center_lon {
    my $self = shift;
    if (@_) {
        my $lon = shift;
        $params->{SYS_CENTER_LON} = $lon unless not looks_like_number($lon);    # otherwise keep the original value for longitude of the system center
    }
    return $params->{SYS_CENTER_LON};
}
sub _init {
    
}
# sphere
sub sphere($$$$$) {
    my ($a, $b, $rf, $ellps, $sphere) = @_;
    $ellps = wgs84 unless defined $ellps;
    $sphere = 0;
    if (!a) { // do we have an ellipsoid?
        // let ellipse = (!!ellps && typeof ellps === 'string') ? ellps.match(/wgs84/i) ? WGS84 : WGS84 : WGS84;
        // if (!ellipse) {
        //     ellipse = WGS84;
        // }
        let ellipse = WGS84;
        a = ellipse.a;
        b = ellipse.b;
        rf = ellipse.rf;
    }
    if (rf && !b) {
        b = (1.0 - 1.0 / rf) * a;
    }
    if (rf === 0 || Math.abs(a - b) < EPSLN) {
        sphere = true;
        b = a;
    }
    return {
        a: a,
        b: b,
        rf: rf,
        sphere: sphere
    };
}
# eccentricity
sub eccentricity($$$$) {
    my ($a, $b, $rf, $R_A) = @_;
    my $a2 = $a * $a; # used in geocentric
    my $b2 = $b * $b; # used in geocentric
    my $es = ($a2 - $b2) / $a2; # e ^ 2
    my $e = 0;
    if ($R_A) {
        $a *= 1 - $es * ($SIXTH + $es * ($RA4 + $es * $RA6));
        $a2 = $a * $a;
        $es = 0;
    } else {
        $e = sqrt($es); # eccentricity
    }
    my $ep2 = ($a2 - $b2) / $b2; # used in geocentric
    return {
        es => $es,
        e => $e,
        ep2 => $ep2
    };
}
# ssfn_
sub ssfn_($$$) {
    my ($phit, $sinphi, $eccen) = @_;
    $sinphi *= $eccen;
    return (tan(0.5 * ((pi * .5) + $phit)) * pow((1 - $sinphi) / (1 + $sinphi), 0.5 * $eccen));
}
# tsfnz
sub tsfnz($$$) {
    my ($eccent, $phi, $sinphi) = @_;
    my $con = $eccent * $sinphi;
    my $com = 0.5 * $eccent;
    $con = pow(((1 - $con) / (1 + $con)), $com);
    return (tan(0.5 * (pip2 - $phi)) / $con);
}
# msfnz
sub msfnz($$$) {
    my ($eccent, $sinphi, $cosphi) = @_;
    my $con = $eccent * $sinphi;
    return $cosphi / (sqrt(1 - $con * $con));
}
# adjust_lon
sub adjust_lon($) {
    my $x = shift;
    return (abs($x) <= $SPI) ? $x : ($x - (sign($x) * pi2));
}
# adjust_lat
sub adjust_lat($) {
    my $x = shift;
    return (abs($x) < pip2) ? $x : ($x - (sign($x) * pi));
}
# phi2z
sub phi2z($$) {
    my ($eccent, $ts) = @_;
    my $eccnth = 0.5 * $eccent;
    my $con;
    my $dphi;
    my $phi = pip2 - 2.0 * atan($ts);
    for (my $i = 0; $i <= 15; $i++) {
        $con = $eccent * sin($phi);
        $dphi = pip2 - 2.0 * atan($ts * (pow(((1 - $con) / (1 + $con)), $eccnth))) - $phi;
        $phi += $dphi;
        if (abs($dphi) <= 0.0000000001) {
            return $phi;
        }
    }
    # console.log("phi2z has NoConvergence");
    return -9999;
}
END {

}
1;