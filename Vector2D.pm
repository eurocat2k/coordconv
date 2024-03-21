package Vector2D;
use utf8;
use strict;
use warnings;
use Data::Dumper;
use POSIX qw(ceil sqrt sin cos round floor);
use Math::Trig qw(deg2rad rad2deg);
use Carp;
use Scalar::Util qw(looks_like_number);
use constant MAXSIZE => 2;    # 1X2 vector X,Y
use FindBin;
use lib "$FindBin::Bin";
BEGIN {
    require Exporter;    
}
our @ISA = qw(Exporter);
our $VERSION = qw(1.0.0);
our @EXPORT = qw(new);
our @EXPORT_OK = qw(dim size debug);
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
        return Vector2D::private_nearest_square->($n+1);
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
    @args = splice(@_, 0, MAXSIZE);
    $dim = 1;
    $size = MAXSIZE;
    my $aref = \@$self;                             # make an array reference of the class instance
    @$aref = (0) x $size;
    my @a = [ @args[0..MAXSIZE-1] ];
    for (my $i = 0; $i < MAXSIZE; $i += 1) {
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
        return MAXSIZE;
    }
}
# 
sub zero {
    my ($self, @args) = @_;
    my $argc = scalar @args;
    my ($vr);
    unless (ref $self) {
        # static
        if ($argc eq 1) {
            $vr = shift @args;
            if (defined $vr) {
                for (0 .. MAXSIZE - 1) {
                    $vr->[$_] = 0;
                }
            }
        }
    } else {
        # instance
        $vr = $self;
        for (0 .. MAXSIZE - 1) {
            $vr->[$_] = 0;
        }
    }
    return $vr;
}
# 
sub copy {
    my ($self, @args) = @_;
    my $argc = scalar @args;
    my ($vs, $vr);
    unless (ref $self) {
        # static
        if ($argc eq 2) {
            $vs = shift @args;
            die "Error: first argument is not defined or not Vector2D type" unless (defined $vs and ref($vs) eq __PACKAGE__);
            $vr = shift @args;
            if (not defined $vr) {
                $vr = Vector2D->new;
            }
            $vr->set(@$vs);
        }
    } else {
        # instance
        $vs = shift @args;
        $vr = Vector2D->new;
        if (not defined $vs) {
            $vs = $self;
        }
        $vr->set($vs);
    }
    return $vr;
}
# 
sub clone {
    my ($self, @args) = @_;
    my $argc = scalar @args;
    my ($vr, $vs) = Vector2D->new;
    unless (ref $self) {
        # static
        $vs = shift @args;
        # for (0 .. MAXSIZE - 1) {
        #     $vr->[$_] = $vs->[$_] unless not defined $vs->[$_];
        # }
    } else {
        # instance
        $vs = $self;
        # for (0 .. MAXSIZE - 1) {
        #     $vr->[$_] = $self->[$_] unless not defined $self->[$_];
        # }
    }
    $vr->set(@$vs);
    return $vr;
}
# 
sub values {
    my ($self, @args) = @_;
    my $argc = scalar @args;
    unless (ref $self) {
        # Static
        my $vr = shift @args;
        return @$vr;
    } else {
        # Instance
        return @$self;
    }
}
# 
sub set {
    my ($self, @args) = @_;
    my $argc = scalar @args;
    unless (ref $self) {
        # Static
        my $vr = shift @args;
        for (0..MAXSIZE-1) {
            $vr->[$_] = $args[$_] unless (not defined $_);
        }
        return $vr;
    } else {
        # Instance
        if (ref $args[0] eq __PACKAGE__) {
            my $vs = shift @args;
            for (0..MAXSIZE-1) {
                $self->[$_] = $vs->[$_] unless (not defined $_);
                # debug(__LINE__, __FILE__, "set $_ with ".$vs->[$_]);
            }
        } else {
            for (0..MAXSIZE-1) {
                $self->[$_] = $args[$_] unless (not defined $_);
            }
        }
        return $self;
    }
}
#
sub print {
    my ($self, @args) = @_;
    my $argc = scalar @args;
    # static first
    unless (ref($self)) {
        if ($argc eq 1 and ref($args[0]) eq __PACKAGE__) {
            # print without custom label
            my $v = shift @args;
            print "[\n";
            for (0..MAXSIZE-1) {
                if ($_ < MAXSIZE-1) {
                    printf("    %.12e,\n", $v->[$_]);
                } else {
                    printf("    %.12e\n", $v->[$_]);
                }
            }
            print "]\n";
            return $v;
        } elsif ($argc eq 2 and ref($args[0]) eq __PACKAGE__) {
            # print without custom label
            my $v = shift @args;
            print "$args[0]: [\n";
            for (0..MAXSIZE-1) {
                if ($_ < MAXSIZE-1) {
                    printf("    %.12e,\n", $v->[$_]);
                } else {
                    printf("    %.12e\n", $v->[$_]);
                }
            }
            print "]\n";
            return $v;
        }
    } else {
        if ($argc eq 1) {
            # there is a label
            print "$args[0]: [\n";
        } else {
            print "[\n";
        }
        for (0..MAXSIZE-1) {
            if ($_ < MAXSIZE-1) {
                printf("    %.12e,\n", $self->[$_]);
            } else {
                printf("    %.12e\n", $self->[$_]);
            }
        }
        print "]\n";
        return $self;
    }
}
# 
sub debug {
    my ($line, $file, $msg) = @_;
    printf "DEBUG::\"%s\" @ line %d in \"%s\".\n", length $msg ? $msg : "info", $line, $file;
};
1;

=head1 B<NAME>

Vector2D

=head1 B<SYNOPSYS>

use Vector2D;

my $vector = Vector2D->new;

my $vector = Vector2D->new(1,2);

=head1 B<DESCRIPTION>

Vector2D is a 2D vector manipulation package. The following methods defined:

=head2 B<constructor>

=over

=item new([args,...])

Without any arguments the vector will be initialized with 0s. However any arguments - in range of [0..1] - defined,
it will be placed into the vector instance at the same index. The remaining will not modify the original value.

=back

=head2 B<Static calls>

These calls utilize Vector2D instead it's instance. In most cases the manipulations result
a brand new Vector2D instance. Whence does not, it will be said so.

=over

=item - print(vector[,label])

prints out the vector elements. If C<label> defined, then adds the label text up front of the printout.

=item - set(vector)

sets the elements from arguments - as a Vector2D instance, or list of elements. 

Returns with the modified vector.

=item - size(vector)

returns the element count of the vector instance.

=item - dim(vector)

returns the number of rows or dimensions - I<X,Y> - of the vector instance.

=back

=head2 B<Prototype calls>

These calls utilize Vector2D instance. These calls used to call as destructive functions, because most of
the time the manipulations going to happen with the instance itself.

=over

=back

=head2 B<Auxiliary methods>

These methods extends the capabilities of the Vector2D package.

=over

=item - debug(__LINE__,__FILE__[,message])

prints out debug information.

=back

=head1 FILES

F<Vector2D.pm>

=head1 SEE ALSO

L<Vector3D(3)>, L<Matrix2D(3)>, L<Matrix3D(3)>, L<Matrix4D(3)>

=head1 AUTHOR

G.Zelenak


