package Vector;
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
our @terse_exp = qw(
  V
  U
  X
  Y
  Z
);
our @ISA         = qw(Exporter);
our $VERSION     = qw(1.0.0);
our @EXPORT      = qw(new);
our @EXPORT_OK   = qw();
our %EXPORT_TAGS = ( terse => [@terse_exp] );
Exporter::export_ok_tags( keys(%EXPORT_TAGS) );

sub new {
    my $caller = shift;
    my $class  = ref($caller) || $caller;
    my $self   = [ map( { defined($_) ? $_ : 0 } @_[ 0, 1, 2 ] ) ];
    bless( $self, $class );
    return ($self);
}

sub Length {
    my Vector $self = shift;
    my $sum;
    map( { $sum += $_**2 } @$self );
    return ( sqrt($sum) );
}    # end subroutine Length definition

sub Magnitude {
    my Vector $self = shift;
    return ( $self->Length() );
}    # end subroutine Magnitude definition

sub UnitVector {
    my Vector $self = shift;
    my $mag = $self->Length();
    $mag || croak("zero-length vector (@$self) has no unit vector");
    return ( map( { $_ / $mag } @$self ) );
}

1;
