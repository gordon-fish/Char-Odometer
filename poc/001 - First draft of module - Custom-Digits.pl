#!/usr/bin/perl

# FIRST DRAFT of Custom Digits module

# Based on this exchange from Freenode's #perl channel:
# <phr3ak> how could I get this range:
# <phr3ak> perl -e 'for (8a .. 9b) {print "$_\n"}'

# Inspired to turn my example https://perl.bot/p/sxoigi into a CPAN module 
# by this reply from the same channel:
# <Grinnz> i'd probably make it less cryptic for a cpan module, but sure

# I would like to know if 'Custom::Digits' a reasonable name, or if there
# might there be something that fits better?
#
# I welcome Any other comments or critiques.

# Note, this package will be separated to it's own module and is combined
# here with package main for demonstration/bot purposes.

{
   package Custom::Digits;
   
   use strict;
   use warnings;
   
   use Safe::Isa;
   
   
   
   use overload (
       q{""}    => \&to_string,
       q{0+}    => \&to_value,
       q<@{}>   => \&to_ordinals,
       fallback => 1,
   );
   
   
   
   sub new {
      return bless( {}, shift )->_set_symbols(@_);
   }
   
   
   
   sub v {
      my $parent = shift;
      
      my @v = map {
         ref
            ? ref eq 'ARRAY'
               ? $parent->new_from_ordinals(@$_)
               : $parent->new_from_value($$_)
            :
               $parent->new_from_string($_)
      } ( wantarray ? @_ : shift );
      
      return wantarray ? @v : $v[0];
   }
   
   
   
   sub new_from_string {
      my ($parent, $string) = @_;
      die 'Object required' unless $parent->$_isa(__PACKAGE__);
      
      return $parent->new_from_ordinals(
         $parent->ordinals_from_string($string)
      );
   }
   
   sub new_from_ordinals {
      my ($parent, @ordinals) = @_;
      die 'Object required' unless $parent->$_isa(__PACKAGE__);
      
      my $symbols  = $parent->{symbols};
      
      my $value = 0;
      $value += $ordinals[$_] * @$symbols ** ($#ordinals - $_) for 0..$#ordinals;
      
      return $parent->new_from_value($value);
   }
   
   sub new_from_value {
      my ($parent, $value) = @_;
      die 'Object required' unless $parent->$_isa(__PACKAGE__);
      
      return bless {
         value => $value,
         map { $_ => $parent->{$_} } qw(symbols ordinal_map)
      }, ref $parent;
   }
   
   
   
   sub ordinals_from_string {
      my ($self, $string) = @_;
      
      my @digits = split //, $string;
      die if grep !$self->is_valid_digit($_), @digits;
      
      my @ordinals = map $self->{ordinal_map}{$_}, @digits;
      return wantarray ? @ordinals : \@ordinals;
   }
   
   sub ordinals_from_value {
      my $self = shift;
      my $value = $_[0] // $self->{value};
      
      my $symbols = $self->{symbols};
      my @ordinals;
      
      do {
         unshift @ordinals, $value % @$symbols;
      } while $value = int $value/@$symbols;
      
      return wantarray ? @ordinals : \@ordinals;
   }
   
   
   
   sub to_string {
      my $self = shift;
      
      return join '', map {
         $self->{symbols}->[$_];
      } $self->ordinals_from_value( $_[0] );
   }
   
   sub to_value { $_[0]->{value}; }
   
   sub to_ordinals {
      my $self = shift;
      return scalar $self->ordinals_from_value;
   }
   
   
   
   sub range {
      my $self = shift;
      
      my $from = @_ > 1 ? $self->_get_object(shift) : $self;
      my $to   = $self->_get_object(shift);
      
      return map { $self->new_from_value($_) } $from .. $to;
   }
   
   sub is_valid_digit {
      my $self = shift;
      $_[0] eq $_ and return 1 for @{ $self->{symbols} };
   }
   
   
   
   sub _set_symbols {
      my $self = shift;
      my $symbols = $self->{symbols} = \@_;
      
      $self->{ordinal_map} = {
         map { $symbols->[$_] => $_ } 0 .. $#$symbols
      };
      
      return $self;
   }
   
   sub _get_object {
      my $self = shift;
      ref $_[0] ? $_[0] : $self->new_from_string( $_[0] );
   }
}
################################################################################

package main;

use strict;
use warnings;


# Create a custom digits/alphabet.
my $cd = Custom::Digits->new(0..9, 'a'..'z');

# Create values composed of the symbols in $cd.
my ($d1, $d2) = $cd->v( qw(8a 9b) );

# These are equivalent alternatives to the above:
#my ($d1, $d2) = $cd->v( \(298, 335) ); # Or: $cd->v( \298, \335 );
#my ($d1, $d2) = $cd->v( [8,10], [9,11] );

printf "d1: str[%s] val[%d] ord[%s]\n", $d1, $d1, join ',', @$d1;
printf "d2: str[%s] val[%d] ord[%s]\n", $d2, $d2, join ',', @$d2;

printf "(%s)\n", join ',', $d1->range($d2);
#printf "(%s)\n", join ',', map $cd->to_string($_), $d1 .. $d2;
