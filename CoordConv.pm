package CoordConv;
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
our @ISA       = qw(Exporter);
our $VERSION   = qw(1.0.0);
our @EXPORT    = qw(new);
our @EXPORT_OK = qw();

BEGIN {
    require Sphere;
    require Wgs84;
}

# private variables
my $EPSLN = 1.0e-10;        # epsilon
my $false = 0;
my $true  = 1;
my $NaN   = POSIX::nan();
my $SYS_CENTER_LON = 19.2322222222222;
my $SYS_CENTER_LAT = 47.4452777777778;
my $FT2M = 0.3048;
my $M2FT = 1 / $FT2M;
# private methods
# sphere
sub sphere($$$$$) {
    my ( $a, $b, $rf, $ellps, $sphere ) = @_;
    $ellps  = Wgs84::wgs84 unless defined $ellps;
    $sphere = 0;
    if ( not defined $a ) {    # do we have an ellipsoid?
                               # my $ellipse = Wgs84::wgs84;
        $a  = $ellps->{a};
        $b  = $ellps->{b};
        $rf = $ellps->{rf};
    }
    if ( defined $rf and not defined $b ) {
        $b = ( 1.0 - 1.0 / $rf ) * $a;
    }
    if ( $rf eq 0 || abs( $a - $b ) < $EPSLN ) {
        $sphere = $true;
        $b      = $a;
    }
    return {
        a      => $a,
        b      => $b,
        rf     => $rf,
        sphere => $sphere
    };
}    # sphere

sub sphere($$$$$) {
    my ( $a, $b, $rf, $ellps, $sphere ) = @_;
    $ellps  = Wgs84::wgs84 unless defined $ellps;
    $sphere = 0;
    if ( not defined $a ) {    # do we have an ellipsoid?
                               # my $ellipse = Wgs84::wgs84;
        $a  = $ellps->{a};
        $b  = $ellps->{b};
        $rf = $ellps->{rf};
    }
    if ( defined $rf and not defined $b ) {
        $b = ( 1.0 - 1.0 / $rf ) * $a;
    }
    if ( $rf eq 0 || abs( $a - $b ) < $EPSLN ) {
        $sphere = $true;
        $b      = $a;
    }
    return {
        a      => $a,
        b      => $b,
        rf     => $rf,
        sphere => $sphere
    };
}

# constructor
sub new {
    my $inv = shift;
    my ( $L, $G, $H ) = @_;
    my $class = ref($inv) || $inv;
    my $self  = {
        a  => 0,
        b  => 0,
        e  => 0,
        ee => 0,
        v  => 0,
        xs => 0,
        ys => 0,
        zs => 0
        ,   # be the coordinates of a point in the reference coordinates system,
        xg => 0,
        yg => 0,
        zg => 0
        , # be the coordinates of the same point in the geocentric reference system,
        xr => 0,
        yr => 0,
        zr => 0,    # its coordinates in the radar cartesian coordinates system,
        El => 0,
        Az => 0,
        r  => 0,    # its coordinates in the radar spherical coordinates system,
        Ls => 0,
        Gs => 0,
        Hs => 0,    # the geodesic coordinates of the reference origin point,
        Lr => 0,
        Gr => 0,
        Hr => 0     # the geodesic coordinates of the radar.
    };
    bless( $self, $class );
    $self->_init( $L, $G, $H );
    return $self;
}

# prototype methods
sub _init {
    my $self = shift;
    my ( $L, $G, $H ) = @_;
    if ( @_ eq 3 ) {
        if (looks_like_number($L) and looks_like_number($G) and looks_like_number($H)) {
            $self->{Ls} = deg2rad($L);
            $self->{Gs} = deg2rad($G);
            $self->{Hs} = $H * $FT2M;
        }
    }
    elsif ( @_ eq 2 ) {
        if (looks_like_number($L) and looks_like_number($G)) {
            $self->{Ls} = deg2rad($L);
            $self->{Gs} = deg2rad($G);
            $self->{Hs} = 440 * $FT2M;
        }
    }
    elsif ( @_ eq 1 ) {
        if (looks_like_number($L)) {
            $self->{Ls} = deg2rad($L);
            $self->{Gs} = deg2rad($SYS_CENTER_LON);
            $self->{Hs} = 440 * $FT2M;
        }
    }
    else {
        $self->{Ls} = deg2rad($SYS_CENTER_LAT);
        $self->{Gs} = deg2rad($SYS_CENTER_LON);
        $self->{Hs} = 0;
    }
    $self->{a} = sphere( Wgs84::wgs84->{a}, undef, Wgs84::wgs84->{rf}, 'wgs84', $false )->{a};
    $self->{b} = sphere( Wgs84::wgs84->{a}, undef, Wgs84::wgs84->{rf}, 'wgs84', $false )->{b};
    $self->{e} = sqrt( 1 - ( ( $self->{b} * $self->{b} ) / ( $self->{a} * $self->{a} ) ) );
    $self->{ee} = $self->{e} * $self->{e};
    $self->{v} = $self->{a} / sqrt(1 - ($self->{ee} * (sin($self->{Ls} * $self->{Ls}))));
}

# destructor
END { }
1;
