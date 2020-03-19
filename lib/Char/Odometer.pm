package Char::Odometer;

use strict;
use warnings;

use List::Util qw(first);



use overload (
    q{""}    => sub { shift->reading; },
    q<@{}>   => sub { [shift->digits]; },
    q{++}    => sub { shift->inc; },
    q{--}    => sub { shift->dec; },
    q{+=}    => sub { shift->inc(shift); },
    q{-=}    => sub { shift->dec(shift); },
    bool     => sub { 1; },
    fallback => 1
);



# ->new( 0..9, 'a'..'z' );
# ->new( [0..9], ['A'..'Z'], ['a'..'z'] );
sub new {
    my $invokant = shift;
    
    # If $[0] is a ref, then assume each element is a set (arrayref.)
    # Otherwise expect @_ to be a list representing a single set.
    my $sets = [ ref $_[0] ? @_ : [@_] ];
    
    return $invokant->_construct($sets);
}

sub clone {
    my $self = shift;
    my $sync_sets = shift // 1;
    my $sets = $self->{sets};
    
    my $clone = $self->_construct(
        $sync_sets
            ? $sets                 # Stay in sync with the original's.
            : [ map [@$_], @$sets ] # Duplicate all sets.
    );
    
    # Return clone after copying the reading.
    return $clone->reset( $self->reading );
}

sub _construct {
    my ($class) = map { ref || $_ } shift;
    
    my $sets = shift;
    die "At least one digit-set must be provided" unless @$sets;
    
    return bless { sets => $sets, digits => [] }, $class;
}


# Odometer reading as a string.
sub reading { join '', shift->digits; }

# Odometer reading as a list of digits.
sub digits {
    map $_->digit, @{ shift->{digits} };
}



# ->reset;
# ->reset(string)
# ->reset(string, set-index|undef [, ...])

# Resets all digits to their lowest position, akin to all zeros in
# a car's odometer. If a string is given, then attemts to reset to
# that instead. A list of set indices may follow, corrasponding to
# each character. For any index is omitted, then the first set 
# containing the character is used. This happens for each character
# if the indices are omitted.
# Specifying indices is most useful when a digit exists in multiple 
# sets and a specific set should be associated with it.

# Example:
#                                0       1           2
# my $co = Char::Odometer->new( [0..9], ['A'..'Z'], ['a'..'z'] );
#
# $co->reset('a1',
#     2, # Use $self->{sets}->[2], aka (a .. z), for 'a'.
#     0  # Use $self->{sets}->[0], aka (0 .. 9), for '1'.
# );
sub reset { no overloading;
    my $self = shift;
    my $digits = $self->{digits};
    my $last_digit;
    
    unless (@_) {
        $_->reset for @$digits; # Reset to "all zeros."
        return $self;
    }
    
    my @chars = split //, shift;
    
    # Remove all digits before adding again.
    # * This'll likely be optimized in the future to only grow/shink the
    # * $self->{digits} array as needed.
    $self->clear if @chars;
    
    for my $char (@chars) {
        my ($set, $digit_index) = $self->find_set_with(
            $char,
            shift // ()
        );
        
        die "Character does not belong to any set: $char" unless $set;
        
        my $digit = Char::Odometer::Digit->new(
            $set,
            $digit_index,
            $last_digit
        );
        
        push @$digits, $last_digit = $digit;
    }
    
    return $self;
}

# Clear the odometer's "readout."
sub clear {
    my $self = shift;
    @{ $self->{digits} } = ();
    return $self;
}



# Return the set at index if valid, otherwise return undef.
sub set_at { 
    my ($self, $index) = @_;
    my $sets = $self->{sets};
    
    return undef if !defined $index || $index < 0 || $index > $#$sets;
    return $sets->[$index];
}

# Find the first set containing a specific digit.
# Returns the set and index of digit in the set.
# Returns empty list (undef in scalar context) if not found.
sub find_set_with {
    my ($self, $char, @set_indices) = @_;
    my $sets = $self->{sets};
    @set_indices = 0 .. $#$sets unless @set_indices;
    
    for (@set_indices) {
        my $set = $sets->[$_];
        my $digit_index = $self->index_of_digit($char, $_);
        return ($set, $digit_index) if defined $digit_index;
    }
    
    return;
}

# Return index of digit in set, if found, or undef if it doesn't exist.
sub index_of_digit {
    my ($self, $char, $set_index) = @_;
    my $set = $self->set_at($set_index) // return undef;
    return first { $set->[$_] eq $char } 0 .. $#$set;
}



sub inc {
    my $self = shift;
    my $digits = $self->{digits};
    $digits->[ -1 ]->inc(@_) if @$digits;
    return $self;
}

sub dec {
    my $self = shift;
    my $digits = $self->{digits};
    $digits->[ -1 ]->dec(@_) if @$digits;
    return $self;
}



sub range {
    my $self = shift;
    my $from = @_ > 1 ? shift : $self;
    my $to = shift;
    
    # If $_ is a ref, assume it is an object that isa() __PACKAGE__,
    # otherwise use as digits for a clone of $self.
    ref or $_ = $self->clone->reset($_) for $from, $to;
    
    my $current = $from->clone;
    my @readings = ( $current->reading );
    
    while ($current->reading ne $to->reading) {
        $current->inc;
        push @readings, $current->reading;
        
        # Limit to one full revolution of the odometer.
        last unless $current->reading ne $from->reading;
    }
    
    return @readings;
}

sub range_of {
    my $self = shift;
    my $from = @_ > 1 ? shift : $self;
    my $count = shift // 0;
    
    my $current = ref $from ? $from->clone : $self->clone->reset($from);
    
    return map {
       my $reading = $current->reading;
       $current->inc;
       $reading;
    } 1 .. $count;
}

1;
#---------------------------------------------------------------------------

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
