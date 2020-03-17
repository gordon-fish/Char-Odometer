use strict;
use warnings;

my @chr = (0..9, 'a'..'z');
my %ord = map { $chr[$_], $_ } 0..$#chr;

sub chr_range {
    map {
        my $chr = '';
        do { $chr = $chr[$_ % @chr]. $chr } while $_ = int $_/@chr;
        $chr;
    } map {
        $_->[0] .. $_->[1]
    } [ map {
        my @digits = @$_;
        my $sum = 0;
        $sum += $digits[$_] * @chr ** ($#digits - $_) for 0..$#digits;
        $sum;
    } map [map $ord{$_}, split//], @_ ];
}

#[ chr_range qw(8a 9b) ]; 
print join( ' ', chr_range qw(8a 9b) ), "\n";