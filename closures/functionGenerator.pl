#!/usr/bin/perl
use strict;
use warnings;

=pod

Programming Perl, 3rd Edition
Closures

Another use for closures is within function generators; that is, functions that create
and return brand new functions. Here’s an example of a function generator implemented
with closures:

=cut

use Data::Dumper::Simple;


my $f = make_saying('Howdy');     # Create a closure
my $g = make_saying('Greetings'); # Create another closure


# Time passes...


$f->("world");
$g->("earthlings");


exit;

################################################################################

sub make_saying
{
  my $salute  = shift;
  my( $subroutine ) = (caller(0))[3];
  my $newfunc = sub {
                      my $target = shift;
                      print $subroutine, ' ', __LINE__, " $salute, $target!\n";
                    };
  return $newfunc; # Return a closure
}

__END__
