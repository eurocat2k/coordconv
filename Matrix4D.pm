package Matrix4D;

=head1 NAME

Matrix4D

=head1 SYNOPSYS

use Matrix4D;

my $vector = Matrix4D->new();

my $vector = Matrix4D->new(1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15, 16);

=cut

use utf8;
use strict;
use warnings;
use Data::Dumper;
use POSIX      qw(ceil sqrt sin cos round floor);
use Math::Trig qw (:pi);
use Math::Trig qw(deg2rad rad2deg acos);
use List::Util qw(min max);
use Carp;
use Scalar::Util qw(looks_like_number);
use constant MAXSIZE => 2;                   # 1X2 vector X,Y
use constant DEBUG   => 0;                   # 1 uses DEBUG constants
use constant PI      => atan2( 1, 1 ) * 4;

# use constant PI => pi;
# use constant PI => POSIX::M_PI;
use constant HALF_PI => PI * .5;
use constant TWO_PI  => PI * 2;
use FindBin;
use lib "$FindBin::Bin";

BEGIN {
    require Exporter;

    # printf "PI: %.12e\n", PI;
    # printf "PI: %.12e\n", pi;
    # printf "PI: %.12e\n", (atan2(1,1) * 4);
}
our @ISA     = qw(Exporter);
our $VERSION = qw(1.0.0);
our @EXPORT  = qw(new);
our @EXPORT_OK =
  qw(dim size debug normalize_angle_degrees normalize_angle_radians);
my $dim;
my $size;

# # Utilities
sub debug {
    my ( $line, $file, $msg ) = @_;
    printf "DEBUG::\"%s\" @ line %d in \"%s\".\n",
      defined $msg ? $msg : "info", $line, $file;
}

sub normalize_angle_degrees {
    my ($angle) = @_;
    croak "Error: missing argument", ( caller(0) )[3] unless defined $angle;
    croak "Error: invalid argument detected at pos 1, expected SCALAR ",
      ( caller(0) )[3]
      unless ( ref \$angle eq 'SCALAR' );
    return ( $angle % 360 + 360 ) % 360;
}

sub normalize_angle_radians {
    my ($angle) = @_;
    croak "Error: missing argument", ( caller(0) )[3] unless defined $angle;
    croak "Error: invalid argument detected at pos 1, expected SCALAR ",
      ( caller(0) )[3]
      unless ( ref \$angle eq 'SCALAR' );
    return ( $angle % ( 2 * PI ) + ( 2 * PI ) ) % ( 2 * PI );
}

sub clamp {
    my ( $value, $min, $max ) = @_;
    return max( $min, min( $max, $value ) );

}
#
1;
