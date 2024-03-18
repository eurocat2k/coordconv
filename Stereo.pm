package Stereo;
use v5.28.0;
use strict;
require Exporter;
use FindBin;
use lib "$FindBin::Bin";
use POSIX;
use Data::Dumper;
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
my $false = 0;
my $true = 1;
my $NaN = POSIX::nan();
# Params
my $params;
# Predefinitions
sub phi2z($$);
sub sign($);
sub sphere($$$$$);
# Constructor
sub new {
    my $inv = shift;
    my ($lon, $lat) = @_;
    print Dumper ("PARAMS", @_);
    my $class = ref($inv) || $inv;
    my $self = {
        params => {
            SYS_CENTER_LAT => 0,
            SYS_CENTER_LON => 0,
            x0 => 0,
            y0 => 0,
            lat0 => 0,
            lon0 => 0,
            lat1 => 0,
            k0 => 1,
            axis => 'enu',
            ellps => 'wgs84',
            a => 0,
            a => 0,
            es => 0,
            e => 0,
            ep2 => 0,
            sinlat0 => 0,
            coslat0 => 0,
            cons => 0,
            ms1 => 0,
            X0 => 0,
            cosX0 => 0,
            sinX0 => 0
        }
    };
    bless($self, $class);
    if (defined $lon and defined $lat) {
        print "USING CUSTOM CENTER\n";
        $self->_init($lon, $lat);
    } else {
        print "USING DEFAULT CENTER\n";
        $self->_init($SYS_CENTER_LON, $SYS_CENTER_LAT);
    }
    print Dumper $self;
    return $self;
}
sub sign($) {
    my $x = shift;
    if (defined $x and looks_like_number($x)) {
        return $x < 0 ? -1 : 1;
    }
    return $NaN;
}
# getters/setters
sub sys_center_lat {
    my $self = shift;
    if (@_) {
        my $lat = shift;
        $self->{params}->{SYS_CENTER_LAT} = $lat unless not looks_like_number($lat);    # otherwise keep the original value for latitude of the system center
    }
    return $self->{params}->{SYS_CENTER_LAT};
}
sub sys_center_lon {
    my $self = shift;
    if (@_) {
        my $lon = shift;
        $self->{params}->{SYS_CENTER_LON} = $lon unless not looks_like_number($lon);    # otherwise keep the original value for longitude of the system center
    }
    return $self->{params}->{SYS_CENTER_LON};
}
sub params {
    return $params;
}
sub _init {
    my $self = shift;
    my ($lon, $lat) = @_;
    $self->{params}->{SYS_CENTER_LAT} = $lat;
    $self->{params}->{SYS_CENTER_LON} = $lon;
    $self->{params}->{x0} = $self->{params}->{x0} || 0;
    $self->{params}->{y0} = $self->{params}->{y0} || 0;
    $self->{params}->{lat0} = deg2rad($self->{params}->{SYS_CENTER_LAT});
    $self->{params}->{lon0} = deg2rad($self->{params}->{SYS_CENTER_LON});
    $self->{params}->{axis} = 'enu';
    $self->{params}->{ellps} = 'wgs84';
    $self->{params}->{k0} = $self->{params}->{k0} || 1.0;
    $self->{params}->{lat1} = $self->{params}->{lat1} || $self->{params}->{lat0};
    $self->{params}->{a} = sphere(Wgs84::wgs84->{a}, undef, Wgs84::wgs84->{rf}, 'wgs84', $false)->{a};
    $self->{params}->{b} = sphere(Wgs84::wgs84->{a}, undef, Wgs84::wgs84->{rf}, 'wgs84', $false)->{b};
    $self->{params}->{es} = eccentricity($self->{params}->{a}, $self->{params}->{b}, $self->{params}->{rf})->{es};
    $self->{params}->{e} = eccentricity($self->{params}->{a}, $self->{params}->{b}, $self->{params}->{rf})->{e};
    $self->{params}->{ep2} = eccentricity($self->{params}->{a}, $self->{params}->{b}, $self->{params}->{rf})->{ep2};
    $self->{params}->{coslat0} = cos($self->{params}->{lat0});
    $self->{params}->{sinlat0} = sin($self->{params}->{lat0});
    if (abs($self->{params}->{coslat0}) <= $EPSLN) {
        if ($self->{params}->{lat0} > 0) {
            # North pole
            # trace('stere:north pole');
            $self->{params}->{con} = 1;
        } else {
            # South pole
            # trace('stere:south pole');
            $self->{params}->{con} = -1;
        }
    }
    $self->{params}->{cons} = sqrt(pow(1 + $self->{params}->{e}, 1 + $self->{params}->{e}) * pow(1 - $self->{params}->{e}, 1 - $self->{params}->{e}));
    $self->{params}->{ms1} = msfnz($self->{params}->{e}, $self->{params}->{sinlat0}, $self->{params}->{coslat0});
    $self->{params}->{X0} = 2 * atan(ssfn_($self->{params}->{lat0}, $self->{params}->{sinlat0}, $self->{params}->{e})) - (pip2);
    $self->{params}->{cosX0} = cos($self->{params}->{X0});
    $self->{params}->{sinX0} = sin($self->{params}->{X0});
}
# sphere
sub sphere($$$$$) {
    my ($a, $b, $rf, $ellps, $sphere) = @_;
    $ellps = Wgs84::wgs84 unless defined $ellps;
    $sphere = 0;
    if (not defined $a) { # do we have an ellipsoid?
        # my $ellipse = Wgs84::wgs84;
        $a = $ellps->{a};
        $b = $ellps->{b};
        $rf = $ellps->{rf};
    }
    if (defined $rf and not defined $b) {
        $b = (1.0 - 1.0 / $rf) * $a;
    }
    if ($rf eq 0 || abs($a - $b) < $EPSLN) {
        $sphere = $true;
        $b = $a;
    }
    return {
        a => $a,
        b => $b,
        rf => $rf,
        sphere => $sphere
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
    return (tan(0.5 * ((pip2) + $phit)) * pow((1 - $sinphi) / (1 + $sinphi), 0.5 * $eccen));
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
sub isinf { $_[0]==9**9**9 || $_[0]==-9**9**9 }
sub isnan { ! defined( $_[0] <=> 9**9**9 ) }
# useful for detecting negative zero
sub signbit { substr( sprintf( '%g', $_[0] ), 0, 1 ) eq '-' }
sub forward($$) {
    my $self = shift;
    my ($_lon, $_lat) = @_;
    my $lon = deg2rad($_lon);
    my $lat = deg2rad($_lat);
    my $sinlat = sin($lat);
    my $coslat = cos($lat);
    my $A;
    my $X;
    my $sinX;
    my $cosX;
    my $ts;
    my $rh;
    my $p = {x => 0, y => 0};
    my $dlon = adjust_lon($lon - $self->{params}->{lon0});
    if (abs(abs($lon - $self->{params}->{lon0}) - pi) <= $EPSLN and abs($lat + $self->{params}->{lat0}) <= $EPSLN) {
        # case of the origine point
        # trace('stere:this is the origin point');
        # p.x = NaN;
        # p.y = NaN;
        return {x => $NaN, y => $NaN};
    }
    if ($self->{params}->{sphere}) {
        # trace('stere:sphere case');
        $A = 2 * $self->{params}->{k0} / (1 + $self->{params}->{sinlat0} * $sinlat + $self->{params}->{coslat0} * {$coslat} * cos($dlon));
        #  p.x = this.a * A * coslat * sin(dlon) + this.x0;
        #  p.y = this.a * A * (this.coslat0 * sinlat - this.sinlat0 * coslat * cos(dlon)) + this.y0;
        return {
            x => $self->{params}->{a} * $A * $coslat * sin($dlon) + $self->{params}->{x0},
            y => $self->{params}->{a} * $A * ($self->{params}->{coslat0} * $sinlat - $self->{params}->{sinlat0} * $coslat * cos($dlon)) + $self->{params}->{y0}
        };
    } else {
        $X = 2 * atan(ssfn_($lat, $sinlat, $self->{params}->{e})) - pip2;
        $cosX = cos($X);
        $sinX = sin($X);
        if (abs($self->{params}->{coslat0}) <= $EPSLN) {
            $ts = tsfnz($self->{params}->{e}, $lat * $self->{params}->{con}, $self->{params}->{con} * $sinlat);
            $rh = 2 * $self->{params}->{a} * $self->{params}->{k0} * $ts / $self->{params}->{cons};
            #  p.x = this.x0 + rh * sin(lon - this.lon0);
            #  p.y = this.y0 - this.con * rh * cos(lon - this.lon0);
            # trace(p.toString());
            return {
                x => $self->{params}->{x0} + $rh * sin($lon - $self->{params}->{lon0}),
                y => $self->{params}->{y0} - $self->{params}->{con} * $rh * cos($lon - $self->{params}->{lon0})
            };
        } elsif (abs($self->{params}->{sinlat0}) < $EPSLN) {
            # Eq
            # trace('stere:equateur');
            $A = 2 * $self->{params}->{a} * $self->{params}->{k0} / (1 + $cosX * cos($dlon));
            $p->{y} = $A * $sinX;
        } else {
            # other case
            # trace('stere:normal case');
            $A = 2 * $self->{params}->{a} * $self->{params}->{k0} * $self->{params}->{ms1} / ($self->{params}->{cosX0} * (1 + $self->{params}->{sinX0} * $sinX + $self->{params}->{cosX0} * $cosX * cos($dlon)));
            $p->{y} = $A * ($self->{params}->{cosX0} * $sinX - $self->{params}->{sinX0} * $cosX * cos($dlon)) + $self->{params}->{y0};
        }
        $p->{x} = $A * $cosX * sin($dlon) + $self->{params}->{x0};
    }
    return $p;
}
sub inverse($$) {
    my $self = shift;
    my ($x, $y) = @_;
    $x -= $self->{params}->{x0};
    $y -= $self->{params}->{y0};
    my ($lon, $lat, $ts, $ce, $Chi);
    my $rh = sqrt($x * $x + $y * $y);
    if ($self->{params}->{sphere}) {
        my $c = 2 * atan($rh / (2 * $self->{params}->{a} * $self->{params}->{k0}));
        $lon = $self->{params}->{lon0};
        $lat = $self->{params}->{lat0};
        if ($rh <= $EPSLN) {
            # p.x = lon;
            # p.y = lat;
            # return p;
            return {
                lon => rad2deg($lon), lat => rad2deg($lat)
            };
        }
        $lat = asin(cos($c) * $self->{params}->{sinlat0} + $y * sin($c) * $self->{params}->{coslat0} / $rh);
        if (abs($self->{params}->{coslat0}) < $EPSLN) {
            if ($self->{params}->{lat0} > 0) {
                $lon = adjust_lon($self->{params}->{lon0} + atan2($x, -1 * $y));
            } else {
                $lon = adjust_lon($self->{params}->{lon0} + atan2($x, $y));
            }
        } else {
            $lon = adjust_lon($self->{params}->{lon0} + atan2($x * sin($c), $rh * $self->{params}->{coslat0} * cos($c) - $y * $self->{params}->{sinlat0} * sin($c)));
        }
        # p.x = lon;
        # p.y = lat;
        # return p;
        return {
            lon => rad2deg($lon), lat => rad2deg($lat)
        };
    } else {
        if (abs($self->{params}->{coslat0}) <= $EPSLN) {
            if ($rh <= $EPSLN) {
                $lat = $self->{params}->{lat0};
                $lon = $self->{params}->{lon0};
                # trace(p.toString());
                # return p;
                return {
                    lon => rad2deg($lon), lat => rad2deg($lat)
                };
            }
            $x *= $self->{params}->{con};
            $y *= $self->{params}->{con};
            $ts = $rh * $self->{params}->{cons} / (2 * $self->{params}->{a} * $self->{params}->{k0});
            $lat = $self->{params}->{con} * phi2z($self->{params}->{e}, $ts);
            $lon = $self->{params}->{con} * adjust_lon($self->{params}->{con} * $self->{params}->{lon0} + atan2($x, -1 * $y));
        } else {
            $ce = 2 * atan($rh * $self->{params}->{cosX0} / (2 * $self->{params}->{a} * $self->{params}->{k0} * $self->{params}->{ms1}));
            $lon = $self->{params}->{lon0};
            if ($rh <= $EPSLN) {
                $Chi = $self->{params}->{X0};
            } else {
                $Chi = asin(cos($ce) * $self->{params}->{sinX0} + $y * sin($ce) * $self->{params}->{cosX0} / $rh);
                $lon = adjust_lon($self->{params}->{lon0} + atan2($x * sin($ce), $rh * $self->{params}->{cosX0} * cos($ce) - $y * $self->{params}->{sinX0} * sin($ce)));
            }
            $lat = -1 * phi2z($self->{params}->{e}, tan(0.5 * (pip2 + $Chi)));
        }
    }
    # p.x = lon;
    # p.y = lat;

    # trace(p.toString());
    # return p;
    return { lon => rad2deg($lon), lat => rad2deg($lat) };
}
END {

}
1;
