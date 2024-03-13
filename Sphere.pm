# export const sphere = Constants.sphere = {
#     a: 6370997.0,
#     b: 6370997.0,
#     ellipseName: "Normal Sphere (r=6370997)"
# };
package Sphere;
use strict;
require Exporter;
our @ISA = qw(Exporter);
our $VERSION = qw(1.0.0);
our @EXPORT = qw(sphere);
sub sphere {
    return {
        a => 6370997.0,
        b => 6370997.0,
        ellipseName => "Normal Sphere (r=6370997)"
    }
}
1;