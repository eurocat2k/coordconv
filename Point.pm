package Point;
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
our @ISA       = qw(Exporter);
our $VERSION   = qw(1.0.0);
our @EXPORT    = qw(new);
our @EXPORT_OK = qw();
sub new {
    my $caller = shift;
    my $class  = ref($caller) || $caller;
    my $self   = [ map( { defined($_) ? $_ : 0 } @_[ 0, 1, 2 ] ) ];
    bless( $self, $class );
    return ($self);
}
sub mag {
    my Point $self = shift;
    my $sum;
    map( { $sum += $_**2 } @$self );
    return (sqrt($sum));
}
sub length {
    my Point $self = shift;
    return $self->mag();
}
END {
}

1;
