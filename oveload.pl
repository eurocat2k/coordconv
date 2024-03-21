use strict;
use warnings;
use Data::Dumper;

package MyPackage;
use strict;
use warnings;
use Carp;
use Data::Dumper;
use constant MAXSIZE => 2;
use overload q/+/ => \&add;
sub new {
    my $self = $_[0];
    my @params = @_;
    # print Dumper {params => @params};
    # @params = splice(@params, 0, MAXSIZE);
    my $elems = [];
    for (0..MAXSIZE-1){
        if (defined $params[$_+1]) {
            @$elems[$_] = $params[$_+1];
        } else {
            @$elems[$_] = 0;
        }
    }
    return bless { elems => $elems, dim => 1, size => MAXSIZE }, ref($self) || $self;
}

sub add {
    my ($v0, $v1, $opt) = @_;
    print "argcount:".scalar @_."\n";
    croak "Not enough arguments for ", ( caller(0) )[3] if @_ < 2;
    croak "Too many arguments for ",   ( caller(0) )[3] if @_ > 3;
    unless (ref($v0)) {
        if ( ref($v1) eq ref($opt) and ref($v1) eq __PACKAGE__ ) {
            my $vr = $v1->new;
            for ( 0 .. MAXSIZE - 1 ) {
                $vr->{elems}[$_] = $v1->{elems}[$_] + $opt->{elems}[$_];
            }
            return $vr;
        }
    } else {
    # # returns new vector
        if ( ref($v0) eq ref($v1) and ref($v0) eq __PACKAGE__ ) {
            my $vr = $v0->new;
            for ( 0 .. MAXSIZE - 1 ) {
                $vr->{elems}[$_] = $v0->{elems}[$_] + $v1->{elems}[$_];
            }
            return $vr;
        }
    }
}

package main;
my $a = MyPackage->new(1, 2);
my $b = MyPackage->new(3, 4);
# my $c = $a + $b;
# my $c = $a->add($b);
my $c = MyPackage->add($a, $b);
print Dumper $c;
