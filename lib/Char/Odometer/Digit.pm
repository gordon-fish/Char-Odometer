package Char::Odometer::Digit;

use strict;
use warnings;



use overload (
    q{""}    => sub { shift->digit },
    bool     => sub { 1; },
    fallback => 1
);



sub new {
    my ($class) = map { ref || $_ } shift;
    my ($set, $index, $next) = @_;
    
    my $self = bless {
        set   => $set,
        index => $index // 0,
        next  => $next
    }, $class;
    
    return $self;
}



sub inc {
    my $self = shift;
    my $by = shift // 1;
    
    return $self->dec(abs $by) if $by < 0;
    
    my ($set, $index, $next) = ( @$self{qw(set index next)} );
    
    $next->inc if defined $next && ($index + $by) > $#$set;
    $self->{index} = ($index + $by) % @$set;
    
    return $self;
}

sub dec {
    my $self = shift;
    my $by = shift // 1;
    
    return $self->inc(abs $by) if $by < 0;
    
    my ($set, $index, $next) = ( @$self{qw(set index next)} );
    
    $next->dec if defined $next && ($index - $by) < 0;
    $self->{index} = ($index - $by) % @$set;
    
    return $self;
}



sub digit {
    my $self = shift;
    my ($set, $index) = ( $self->{set}, $self->{index} );
    
    return undef if $index < 0 || $index > $#$set;
    return $self->{set}->[ $self->{index} ];
}

sub reset { shift->{index} = 0; }

1;
