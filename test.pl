use v5.28.0;
use strict;
use warnings;
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin";
use Stereo;

# my $s = Stereo->new(19.2322222222222, 47.4452777777778);
my ($lat, $lon) = (19.18, 47.35);

my $s1 = Stereo->new();
my $xy = $s1->forward($lat, $lon);

# print Dumper $s1, $xy, $s1->params;
print "The original geo coordinates\n";
print "lat=$lat\n";
print "lon=$lon\n";
print "FORWARD - calculate X,Y values in meters from system's center coordinates\n";
print "x = ".$xy->{x}."\n";
print "y = ".$xy->{y}."\n";
print "INVERSE - calculate LAT,LON values in degrees from given coordinates relative to the system's center\n";
my $ll = $s1->inverse($xy->{x}, $xy->{y});
print "lat = ". $ll->{lat}."\n";
print "lon = ". $ll->{lon}."\n";