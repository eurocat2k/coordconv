package Vector3D;
use v5.28.0;
use strict;
require Exporter;
use FindBin;
use lib "$FindBin::Bin";
use POSIX;
use Data::Dumper;
use Math::Trig;
use Math::Trig ':pi';
use Math::BigFloat;
use Scalar::Util qw(looks_like_number);
#
our @terse_exp = qw(
    V
    U
    X
    Y
    Z
);
our @ISA       = qw(Exporter);
our $VERSION   = qw(1.0.0);
our @EXPORT    = qw(new);
our @EXPORT_OK = qw();
our %EXPORT_TAGS = ( terse => [@terse_exp] );
Exporter::export_ok_tags(keys(%EXPORT_TAGS));

sub new {
    my $caller = shift;
    my $class  = ref($caller) || $caller;
    my $self   = [ map( { defined($_) ? $_ : 0 } @_[ 0, 1, 2 ] ) ];
    bless( $self, $class );
    return ($self);
}

sub NewVec {
    return Vector3D->new(@_);
}

sub V {
    return Vector3D->new(@_);
}

sub U {
    my $v;
    if ( ref( $_[0] ) ) {
        $v = _vec_check( $_[0] );
    }
    else {
        $v = V(@_);
    }
    return ( V( $v->UnitVector() ) );
}    # end subroutine U definition

sub X {
    V( 1, 0, 0 );
}    # end subroutine X definition

sub Y {
        V(0,1,0);
} # end subroutine X definition

sub Z {
        V(0,0,1);
} # end subroutine X definition

use overload
    'neg' => sub {
            return(V($_[0]->ScalarMult(-1)));
    },
    '""' => sub {
            return(join(",", @{$_[0]}));
    },
    '+' => sub {
            my ($v, $arg) = @_;
            $arg = _vec_check($arg);
            return(V($v->Plus($arg)));
    },
    '-' => sub {
            my ($v, $arg, $flip) = @_;
            $arg = _vec_check($arg);
            $flip and (($v, $arg) = ($arg, $v));
            return(V($v->Minus($arg)));
    },
    '*' => sub {
            my($v, $arg) = @_;
            ref($arg) and
                    return($v->Dot($arg));
            return(V($v->ScalarMult($arg)));
    },
    '/' => sub {
            my($v, $arg, $flip) =  @_;
            $flip and croak("cannot divide by vector");
            $arg or croak("cannot divide vector by zero");
            return(V($v->ScalarMult(1 / $arg)));
    },
    'x' => sub {
            my ($v, $arg, $flip) = @_;
            $arg = _vec_check($arg);
            $flip and (($v, $arg) = ($arg, $v));
            return(V($v->Cross($arg)));
    },
    '==' => sub {
            my ($v, $arg) = @_;
            $arg = _vec_check($arg);
            for(my $i = 0; $i < 3; $i++) {
                    ($v->[$i] == $arg->[$i]) or return(0);
            }
            return(1);
    },
    '!=' => sub {
            my ($v, $arg) = @_;
            return(! ($v == $arg));
    },
    'abs' => sub {
            return($_[0]->Length());
    },
    '>>' => sub {
            my ($v, $arg, $flip) = @_;
            $arg = _vec_check($arg);
            $flip and (($v, $arg) = ($arg, $v));
            return(V($arg->Proj($v)));
    };

# Check and return a vector (or array reference turns into a vector.)
# also serves to initialize Z-coordinate.
sub _vec_check {
        my $arg = shift;
        if(ref($arg)) {
                if(ref($arg) eq "ARRAY") {
                        $arg = V(@$arg);
                }
                else {
                        eval{$arg->isa('Vector3D')};
                        $@ and
                                croak("cannot use $arg as a vector");
                }
        }
        else {
                croak("cannot use $arg as a vector");
        }
        return($arg);
} # end subroutine _vec_check definition
########################################################################

sub Dot {
        my $self = shift;
        my ($operand) = @_;
        $operand = _vec_check($operand);
        my @r = map( {$self->[$_] * $operand->[$_]} 0,1,2);
        return( $r[0] + $r[1] + $r[2]);
} # end subroutine Dot definition
########################################################################
sub DotProduct {
        my Vector3D $self = shift;
        return($self->Dot(@_));
} # end subroutine DotProduct definition
########################################################################
sub Cross {
        my Vector3D $a = shift;
        my Vector3D $b = shift;
        $b = _vec_check($b);
        my $x = (($a->[1] * $b->[2]) - ($a->[2] * $b->[1]));
        my $y = (($a->[2] * $b->[0]) - ($a->[0] * $b->[2]));
        my $z = (($a->[0] * $b->[1]) - ($a->[1] * $b->[0]));
        return($x, $y, $z);
} # end subroutine Cross definition
########################################################################
sub CrossProduct {
        my Vector3D $self = shift;
        return($self->Cross(@_));
} # end subroutine CrossProduct definition
########################################################################
sub Length {
        my Vector3D $self = shift;
        my $sum;
        map( {$sum+=$_**2} @$self );
        return(sqrt($sum));
} # end subroutine Length definition
########################################################################
sub Magnitude {
        my Vector3D $self = shift;
        return($self->Length());
} # end subroutine Magnitude definition
########################################################################
sub UnitVector {
        my Vector3D $self = shift;
        my $mag = $self->Length();
        $mag || croak("zero-length vector (@$self) has no unit vector");
        return(map({$_ / $mag} @$self) );
} # end subroutine UnitVector definition
########################################################################
sub ScalarMult {
        my Vector3D $self = shift;
        my($factor) = @_;
        return(map( {$_ * $factor} @{$self}));
} # end subroutine ScalarMult definition
########################################################################
sub Minus {
        my Vector3D $self = shift;
        my @list = @_;
        my @result = @$self;
        foreach my $vec (@list) {
                @result = map( {$result[$_] - $vec->[$_]} 0..$#$vec);
                }
        return(@result);
} # end subroutine Minus definition
########################################################################
sub VecSub {
        my Vector3D $self = shift;
        return($self->Minus(@_));
} # end subroutine VecSub definition
########################################################################
sub InnerAngle {
        my Vector3D $A = shift;
        my Vector3D $B = shift;
        my $dot_prod = $A->Dot($B);
        my $m_A = $A->Length();
        my $m_B = $B->Length();
        # NOTE occasionally returned an answer with a very small imaginary
        # part (for d/(A*B) values very slightly under -1 or very slightly
        # over 1.)  Large imaginary results are not possible with vector
        # inputs, so we can just drop the imaginary bit.
        return( acos($dot_prod / ($m_A * $m_B)) );
} # end subroutine InnerAngle definition
########################################################################
sub DirAngles {
        my Vector3D $self = shift;
        my @unit = $self->UnitVector();
        return( map( {acos($_)} @unit) );
} # end subroutine DirAngles definition
########################################################################
sub Plus {
        my Vector3D $self = shift;
        my @list = @_;
        my @result = @$self;
        foreach my $vec (@list) {
                @result = map( {$result[$_] + $vec->[$_]} 0..$#$vec);
        }
        return(@result);
} # end subroutine Plus definition
########################################################################
sub PlanarAngles {
        my Vector3D $self = shift;
        my $xy = atan2($self->[1], $self->[0]);
        wantarray || return($xy);
        my $xz = atan2($self->[2], $self->[0]);
        my $yz = atan2($self->[2], $self->[1]);
        return($xy, $xz, $yz);
} # end subroutine PlanarAngles definition
########################################################################
sub Ang {
        my Vector3D $self = shift;
        my ($xy) = $self->PlanarAngles();
        return($xy);
} # end subroutine Ang definition
########################################################################
sub VecAdd {
        my Vector3D $self = shift;
        return($self->Plus(@_));
} # end subroutine VecAdd definition
########################################################################
sub UnitVectorPoints {
        my $A = shift;
        my $B = shift;
        $B = NewVec(@$B); # because we cannot guarantee that it was blessed
        return(NewVec($B->Minus($A))->UnitVector());
} # end subroutine UnitVectorPoints definition
########################################################################
sub InnerAnglePoints {
        my $v = shift;
        my ($A, $B) = @_;
        my $lead = NewVec($v->UnitVectorPoints($A));
        my $tail = NewVec($v->UnitVectorPoints($B));
        return($lead->InnerAngle($tail));
} # end subroutine InnerAnglePoints definition
########################################################################
sub PlaneUnitNormal {
        my $v = shift;
        my ($A, $B) = @_;
        $A = NewVec(@$A);
        $B = NewVec(@$B);
        my $lead = NewVec($A->Minus($v));
        my $tail = NewVec($B->Minus($v));
        return(NewVec($lead->Cross($tail))->UnitVector);
} # end subroutine PlaneUnitNormal definition
########################################################################
sub TriAreaPoints {
        my $A = shift;
        my ($B, $C) = @_;
        $B = NewVec(@$B);
        $C = NewVec(@$C);
        my $lead = NewVec($A->Minus($B));
        my $tail = NewVec($A->Minus($C));
        return(NewVec($lead->Cross($tail))->Length() / 2);
} # end subroutine TriAreaPoints definition
########################################################################
sub Comp {
        my $self = shift;
        my $B = _vec_check(shift);
        my $length = $self->Length();
        $length || croak("cannot Comp() vector without length");
        return($self->Dot($B) / $length);
} # end subroutine Comp definition
########################################################################
sub Proj {
        my $self = shift;
        my $B = shift;
        return(NewVec($self->UnitVector())->ScalarMult($self->Comp($B)));
} # end subroutine Proj definition
########################################################################
sub PerpFoot {
        my $pt = shift;
        my ($A, $B) = @_;
        $pt = NewVec($pt->Minus($A));
        $B = NewVec(NewVec(@$B)->Minus($A));
        my $proj = NewVec($B->Proj($pt));
        return($proj->Plus($A));
} # end subroutine PerpFoot definition
########################################################################
sub TripleProduct {
        die("not written");
} # end subroutine TripleProduct definition
########################################################################
sub IJK {
        die("not written");

} # end subroutine IJK definition
########################################################################
sub OrdTrip {
        die("not written");

} # end subroutine OrdTrip definition
########################################################################
sub STV {
        die("not written");

} # end subroutine STV definition
########################################################################
sub Equil {
        die("not written");

} # end subroutine Equil definition

1;
