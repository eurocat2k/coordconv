use strict;
use warnings;
use POSIX qw(round ceil nearbyint);
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin";
use Vector2;
# new and set
my $v0 = Vector2->new->set(3, 3);
# my $v1 = Vector2->new;
# my $v2 = Vector2->new;
# clone and copy
# $v1 = Vector2->clone($v0->print('v0'))->print('v0 cloned to v1');
# $v1->print($v1, 'v1 before set new values')->set(-8,4)->print($v1, 'after set (-8, 4)');
# Vector2->print('test', ' meg meg valami');
# Vector2->print;                 # arg count eq 1
Vector2->print('test 1');           # arg count eq 2 no print
Vector2->print($v0);                # arg count eq 2 print vector and no label
Vector2->print($v0, 'test 2');      # arg count eq 3 print $v0 and the label 
Vector2->print($v0, 'test0 with instance and text');
print "Vector2 dim = ".Vector2->dim($v0)."\n";
print "Vector2 size = ".Vector2->size($v0)."\n";
print "\$v0 dim = ".$v0->dim."\n";
print "\$v0 size = ".$v0->size."\n";
$v0->set(1,1)->print('AFTER SET');
$v0->print;
# $v0->print;
# $v0->print('test1');
# $v0->print($v0, 'test2');
# add and subtract
# 