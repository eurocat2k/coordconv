use v5.28.0;
use strict;
use warnings;
use Data::Dumper;
use FindBin;
use lib "$FindBin::Bin";
use Stereo;

my ($lon, $lat) = (19.18, 47.35);
my $s0 = Stereo->new();
my $s1 = Stereo->new($lon, $lat);
my $xy0 = $s0->forward($lat, $lon);
my $xy1 = $s1->forward($lon, $lat);
print Dumper ({s0 => $s0, s1 => $s1});
print Dumper ({forward0 => $s0->forward($lon, $lat)});
print Dumper ({forward1 => $s1->forward($lon, $lat)});

print Dumper({inverse1 => $s1->inverse(0,0)});
print Dumper ({s0 => $s0});

print Dumper({inverse1 => $s1->inverse(0,0)});
print Dumper({inverse0 => $s0->inverse($xy0->{x},$xy0->{y})});

# print Dumper $s1, $xy, $s1->params;
# print "The original geo coordinates\n";
# print "lat=$lat\n";
# print "lon=$lon\n";
# print "FORWARD - calculate X,Y values in meters from system's center coordinates\n";
# print "x0 = ".$xy0->{x}."\n";
# print "y0 = ".$xy0->{y}."\n";
# print "x1 = ".$xy1->{x}."\n";
# print "y1 = ".$xy1->{y}."\n";
# print "INVERSE - calculate LAT,LON values in degrees from given coordinates relative to the system's center\n";
# my $ll0 = $s0->inverse($xy0->{x}, $xy0->{y});
# my $ll1 = $s1->inverse($xy1->{x}, $xy1->{y});
# print Dumper $ll0;
# print Dumper $ll1;
# print "lat0 = ". $ll0->{lat}."\n";
# print "lon0 = ". $ll0->{lon}."\n";
# print "lat1 = ". $ll1->{lat}."\n";
# print "lon1 = ". $ll1->{lon}."\n";