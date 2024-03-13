# export const WGS84 = Constants.WGS84 = {
#     a: 6378137.0,
#     rf: 298.257223563,
#     ellipseName: "WGS84"
# }
package Wgs84;
use strict;
require Exporter;
our @ISA = qw(Exporter);
our $VERSION = qw(1.0.0);
our @EXPORT = qw(wgs84);
sub wgs84 {
    return {
        a => 6378137.0,
        rf => 298.257223563,
        ellipseName => "WGS84"
    }
}
1;