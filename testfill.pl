use strict;
use warnings;
use Data::Dumper;
use Carp;

# my $array = [1, undef, 2, 3, 4];
use constant MAXSIZE => 9;
my @array = (11, undef, 8, 32, undef, 1, undef, 2, 3, 4);
@array = splice(@array, 0, &MAXSIZE);
my $aref = \@array;
defined or $_ = 0 for @$aref;

print Dumper @array;

my @a1 = (0..26);
my @a2 = ("a".."e",undef,"h".."m",undef, undef, "p".."z");

print Dumper \@a1, \@a2;

foreach (@a1){
    print $a2[$_] . " at " . $_ . "\n" unless not defined $a2[$_];
}

@a1 = (0..4);
@a2 = (5..9);
my $ar1 = \@a1;
my $ar2 = \@a2;

for (@$ar1) {
    $ar1->[$_] = $ar2->[$_];
}

print Dumper($ar1, $ar2);
