package Vector2;
use strict;
use warnings;
use Data::Dumper;
use POSIX qw(ceil sqrt sin cos round floor);
use Math::Trig qw(deg2rad rad2deg);
use Carp;
use Scalar::Util qw(looks_like_number);
use FindBin;
use lib "$FindBin::Bin";
BEGIN {
    require Exporter;    
}
our @ISA = qw(Exporter);
our $VERSION = qw(1.0.0);
our @EXPORT = qw(new);
our @EXPORT_OK = qw(dim size debug);
#
use constant MAXSIZE => 2;    # 1X2 vector X,Y
my $dim;
my $size;
#
my $private_nearest_square = sub {
    my $n = @_;
    my $sq = round(sqrt($n))**2;
    if ($sq < 2) {
        return 2;
    }
    if ($sq < $n) {
        return Vector2::private_nearest_square->($n+1);
    }
    return $sq;
};
my $private_nearest_square_root = sub {
    my $n = shift;
    my $sq = $private_nearest_square->($n);
    return sqrt($sq);
};
#
sub new {
    my $class = shift;                              # Store the package name
    my $self = [];                                  # it's an ARRAY object
    bless($self, $class);                           # Bless the reference into that package
    my @args = @_;                                  # save arguments
    @args = splice(@_, 0, &MAXSIZE);
    $dim = 1;
    $size = &MAXSIZE;
    my $aref = \@$self;                             # make an array reference of the class instance
    @$aref = (0) x $size;
    my @a = [ @args[0..&MAXSIZE-1] ];
    for (my $i = 0; $i < &MAXSIZE; $i += 1) {
        if (defined $args[$i]) {
            @$aref[$i] = $args[$i];
        } else {
            @$aref[$i] = 0;
        }
    }
    return $self;
}
#
sub dim {
    my ($self, $v0) = @_;
    unless (ref $self) {
        # Static
        unless (ref($v0) ne __PACKAGE__ ) {
            return round(sqrt(scalar @$v0));
        }
        die "Error: ".__PACKAGE__."->dim expects ".__PACKAGE__." type argument";
    } else {
        # Instance
        my $aref = \@$self;
        return round(sqrt(scalar @$aref));
    }
}
#
sub size {
    my ($self, $v0) = @_;
    unless (ref $self) {
        # Static
        unless (ref($v0) ne __PACKAGE__ ) {
            return &MAXSIZE;
        }
        die "Error: ".__PACKAGE__."->dim expects ".__PACKAGE__." type argument";
    } else {
        # Instance
        return &MAXSIZE;
    }
}
#
sub set {
    my ($self, @args) = @_;
    my @idxs = ( 0 .. &MAXSIZE -1);
    unless (ref $self) {
        # Static
        # unless (ref($v0) ne __PACKAGE__ ) {
        #     @args = splice(@args, 0, &MAXSIZE);
        #     foreach (@idxs) {
        #         @$self[ $idxs[$_] ] = $args[$_] unless not defined $args[$_];
        #     }
        #     return $self;    
        # }
        # die "Error: ".__PACKAGE__."->dim expects ".__PACKAGE__." type argument";
    } else {
        # Instance
        @args = splice(@args, 0, &MAXSIZE);
        foreach (@idxs) {
            @$self[ $idxs[$_] ] = $args[$_] unless not defined $args[$_];
        }
        return $self;
    }
}
# 
sub clone {
    my $self = shift;
    my Vector2 ($v) = @_;
    my @idxs = ( 0 .. &MAXSIZE -1);
    my $ve = Vector2->new();
    my $vs;
    if (@_ eq 1) {
        die "Error: expected 'Vector2' argument." unless defined $v and ref($v) eq 'Vector2';
        $vs = $v;
    } elsif (@_ eq 0) {
        $vs = $self;
    } 
    for (@idxs) {
        $ve->[$_] = $vs->[$_];
    }
    return $ve;
}
# 
sub print {
    # where $self could be instance or class or even a text 
    my ($self, $a1, $a2 ) = @_;
    unless (ref $self) {    # static call if ref $self eq ''
        # print "ARGCNT=".@_." => \n";
        if (@_ eq 3) {
            # $a1 is the vector, $a2 is the label text
            print $a2.":[\n";
            if (0) {
                print "\t3 Static: argcount = ". @_ ." eq 3 [".ref($self)."]\n";
                debug(__LINE__, __FILE__, $a2);
            }
            for (0..($a1->dim)) {
                if ($_ < $a1->dim - 1) {
                    printf ("%.*s%.8e,\n", 2, " ", $a1->[$_]);
                } else {
                    printf("%.*s%.8e\n", 2, " ", $a1->[$_]);
                }
            }
            print "]\n";
        }
        if (@_ eq 2) {
            # $a1 is the vector
            if (0) {
                print "\t2 Static: argcount = ". @_ ." eq 2 [".ref($a1)."]\n";
                debug(__LINE__, __FILE__, $a1);
            }
            unless (ref($a1) ne __PACKAGE__) {  # if not true $a1 not equal __PACKAGE__...I love Perl!!!!!!
                print "[\n";
                for (0..($a1->dim)) {
                    if ($_ < $a1->dim - 1) {
                        printf ("%.*s%.8e,\n", 2, " ", $a1->[$_]);
                    } else {
                        printf("%.*s%.8e\n", 2, " ", $a1->[$_]);
                    }
                }   
                print "]\n";   
            }
        }
        return 0;
    } else {                # instance call if not ref $self eq ''
        if (0) {
            print "Instance argcount =". @_ ." [".ref($self)."]\n";
            debug(__LINE__, __FILE__, 'instance call');
        }
        if (@_ eq 2) {
            # $self and message
            unless (ref($self) ne __PACKAGE__) {  # if not true $self not equal __PACKAGE__...I love Perl!!!!!!
                print $a1.": [\n";
                for (0..($self->dim)) {
                    if ($_ < $self->dim - 1) {
                        printf ("%.*s%.8e,\n", 2, " ", $self->[$_]);
                    } else {
                        printf("%.*s%.8e\n", 2, " ", $self->[$_]);
                    }
                }   
                print "]\n";   
            }
        } elsif (@_ eq 1) {
            # only $self
            unless (ref($self) ne __PACKAGE__) {  # if not true $self not equal __PACKAGE__...I love Perl!!!!!!
                print "[\n";
                for (0..($self->dim)) {
                    if ($_ < $self->dim - 1) {
                        printf ("%.*s%.8e,\n", 2, " ", $self->[$_]);
                    } else {
                        printf("%.*s%.8e\n", 2, " ", $self->[$_]);
                    }
                }   
                print "]\n";   
            }
        }
    }
}
# 
sub copy {
    my $self = shift;
    my Vector2 ($v1, $v2) = @_;
    my @idxs = ( 0 .. &MAXSIZE -1);
    my $vs;
    my $ve;
    if (@_ eq 2) {
        die "Error: expected two 'Vector2' arguments." unless ref($v1) eq 'Vector2' and ref($v2) eq 'Vector2';
        $vs = $v1;
        $ve = $v2; 
    } elsif (@_ eq 1) {
        die "Error: expected 'Vector2' argument." unless ref($v1) eq 'Vector2';
        $vs = $v1;
        $ve = Vector2->new(); 
    } elsif (@_ eq 0) {
        $vs = $self;
        $ve = Vector2->new(); 
    }
    for (@idxs) {
        $ve->[$_] = $vs->[$_];
    }
    return $ve;
}
# 
sub add {
    my $self = shift;
    my Vector2 ($v1, $v2) = @_;
    my @idxs = ( 0 .. &MAXSIZE -1);
    my $vs;
    my $ve;
    if (@_ eq 2) {
        die "Error: expected two 'Vector2' arguments." unless ref($v1) eq 'Vector2' and ref($v2) eq 'Vector2';
        $vs = $v1;
        $ve = $v2; 
    } elsif (@_ eq 1) {
        $vs = $v1;
        $ve = $self; 
    }
    $v1->print;
    $v2->print;
    for (@idxs) {
        $ve->[$_] += $vs->[$_];
    }
    return $ve;
}
# 
sub subtract {
    my $self = shift;
    my Vector2 ($v1, $v2) = @_;
    my @idxs = ( 0 .. &MAXSIZE -1);
    my $vs;
    my $ve;
    if (@_ eq 2) {
        die "Error: expected two 'Vector2' arguments." unless ref($v1) eq 'Vector2' and ref($v2) eq 'Vector2';
        $vs = $v2;
        $ve = $v1; 
    } elsif (@_ eq 1) {
        $vs = $v1;
        $ve = $self; 
    }
    for (@idxs) {
        $ve->[$_] -= $vs->[$_];
    }
    return $ve;
}
# 
# 
sub debug {
    my ($line, $file, $msg) = @_;
    printf "DEBUG::\"%s\" @ line %d in \"%s\".\n", length $msg ? $msg : "info", $line, $file;
};
1;