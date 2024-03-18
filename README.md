# coordconv

Geographic coordinates conversion module - stereographic conversion implemented using WGS84 ellipse parameters.

## NAME

Stereo - stereographic conversion object module.

## SYNOPSYS

This module performs geographic coordinate - *LAT*, *LON* - conversion to Chartesian coordinate system - *X*, *Y* - and vice versa.

The moduel's instance has two public methods:
    
- forward
- inverse

Both methods expect two arguments.


### sub forward($$)

Expects two argument: *longitude* and *latitude* in degrees, in this order.
    
    Note: the valid range of longitude are: [-180..180], the latitude 
    range is [-90..90]. Negative values in case of longitudes mean 
    western coordinates - coords toward west from Greenwich Meridian -, 
    mean while negative latitudes mean southern - below the Equator - coordinates.

### sub inverse($$)

Expects two arguments: *X* and *Y* in meters, in this order. *X* and *Y* coordinates mean the distance from conversion's center.

    Note: The chartesian coordinate system orientation aligned East to right, 
    North to up, West to left, and South to down. So, in case of negative *X* value
    gives geographic coordinate's longitude toward West from the coordinate 
    conversion's center longitude value.

    Same as negative *Y*, the latitude result goes southward from the center latitude.

## EXAMPLES

```perl
    use lib "<path of the Stereo.pm>";

    use Stereo;

    # Define a point south-west from default center coordinates.
    my ($lon, $lat) = (19.18, 47.35);
    # Uses default system' center coordinates (TAR1 radar coordinates)
    my $s0 = Stereo->new();
    # Uses our custom coordinates as system' center
    my $s1 = Stereo->new($lon, $lat);
    # Call forward - calculate X,Y coords relative from system's center
    # In this case we get X,Y from original center
    my $xy0 = $s0->forward($lat, $lon);
    # In this case we expect 0,0 as the params and the system center are same
    my $xy1 = $s1->forward($lon, $lat);
    print Dumper ({s0 => $s0, s1 => $s1});
    # $VAR1 = {
    #     's0' => bless( {
    #         'params' => {
    #             'k0' => 1,
    #             'X0' => '0.824731187521062',
    #             'lon0' => '0.335665600252998',
    #             'ellps' => 'wgs84',
    #             'b' => '6356752.31424518',
    #             'SYS_CENTER_LON' => '19.2322222222222',
    #             'lat1' => '0.828076311745521',
    #             'cons' => '1.00335655524932',
    #             'sinX0' => '0.734365351129479',
    #             'x0' => 0,
    #             'lat0' => '0.828076311745521',
    #             'axis' => 'enu',
    #             'a' => 6378137,
    #             'coslat0' => '0.676294060392653',
    #             'es' => '0.00669437999014132',
    #             'SYS_CENTER_LAT' => '47.4452777777778',
    #             'y0' => 0,
    #             'ms1' => '0.677525752002813',
    #             'sinlat0' => '0.736631755952469',
    #             'e' => '0.0818191908426215',
    #             'ep2' => '0.00673949674227643',
    #             'cosX0' => '0.678754396715393'
    #         }
    #     }, 'Stereo' ),
    #     's1' => bless( {
    #         'params' => {
    #             'axis' => 'enu',
    #             'a' => 6378137,
    #             'coslat0' => '0.67751807775511',
    #             'sinX0' => '0.733235014582107',
    #             'lat0' => '0.826413400819315',
    #             'x0' => 0,
    #             'cosX0' => '0.679975303515339',
    #             'ep2' => '0.00673949674227643',
    #             'y0' => 0,
    #             'SYS_CENTER_LAT' => '47.35',
    #             'es' => '0.00669437999014132',
    #             'e' => '0.0818191908426215',
    #             'ms1' => '0.678748220135223',
    #             'sinlat0' => '0.7355061211948',
    #             'k0' => 1,
    #             'SYS_CENTER_LON' => '19.18',
    #             'cons' => '1.00335655524932',
    #             'lat1' => '0.826413400819315',
    #             'b' => '6356752.31424518',
    #             'ellps' => 'wgs84',
    #             'lon0' => '0.334754150532512',
    #             'X0' => '0.823067374201278'
    #         }
    #     }, 'Stereo' )
    # };
    print Dumper ({forward0 => $s0->forward($lon, $lat)});
    # $VAR1 = {
    #     'forward0' => {
    #         'y' => '-10591.5029008447',
    #         'x' => '-3945.78240888576'
    #     }
    # };
    print Dumper ({forward1 => $s1->forward($lon, $lat)});
    # $VAR1 = {
    #     'forward1' => {
    #         'y' => 0,
    #         'x' => 0
    #     }
    # };
    print Dumper({inverse1 => $s1->inverse(0,0)});
    # $VAR1 = {
    #     'inverse1' => {
    #         'lat' => '47.3499999999826',
    #         'lon' => '19.18'
    #     }
    # };
    print Dumper({inverse0 => $s0->inverse($xy0->{x},$xy0->{y})});
    # $VAR1 = {
    #     'inverse0' => {
    #         'lon' => '47.35',
    #         'lat' => '19.1799999999991'
    #     }
    # };
```
