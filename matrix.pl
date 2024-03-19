use strict;
use warnings;
use POSIX qw(round ceil nearbyint);
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin";
use Matrix;

my $m = Matrix->new(12,undef,23,13,-24,undef,-17,2);
my $m1 = Matrix->new;
# print Dumper $m, {mdim => $m->dim}, {msize => $m->size}, $m1, {m1dim => $m1->dim}, {m1size => $m1->size};
print Dumper $m;
$m->print;

# print Dumper $m, $m->size, $m->dim;
# # STEP 0
# my $a = [];         # the self object
# my $aref = \@$a;    # create an array reference
# my @arr0 = (0) x 9; # initialize with zeroes
# push @$aref, [ splice @arr0, 0, 3 ] while @arr0;    # push elements into the original object
# # STEP 1
# my @arr1 = (1,2,3,4,5,6,7);
# my @arr2;
# push @arr2, [ splice @arr1, 0, 3 ] while @arr1;     # make input elements conform to object structure
# # STEP 2
# my $rowId = 0;
# for my $row (@arr2) {
#     for my $col (0..2) {
#         if (defined @$row[$col]) {
#             @$aref[$rowId]->[$col] = @$row[$col];   # set original object's matching element with source element
#         }
#     }
#     $rowId += 1;
# }
# # 
# print Dumper $a;
