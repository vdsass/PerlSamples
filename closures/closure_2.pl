#!/bin/perl
use strict;
use warnings;

# just a simple package
package obj;

sub new { return bless {content => $_[0]}; }
sub print
{ my $self= shift;
  print ref($self), ": ", $self->{content}, " - ", @_, "\n";
}

# now the main stuff
package main;

my $p;                       # that's your method reference
{
  my $o= obj::new( "toto");  # the normal way: create
  $o->print( "tata");        #                 print

  $p=sub { $o->print(@_); }; # create the closure (an anon sub)
  $p->( "titi");             # use it to print

  $o= obj::new "foo";        # change the object
  $p->("tutu");              # print using the new object
}

my $o= obj::new "bar";       # the $o used with the closure is not
                             # in scope any more
$p->("tutu");                # but $p still uses it

=pod

OUTPUT:

obj: toto - tata
obj: toto - titi
obj: foo - tutu
obj: foo - tutu <= # but $p still uses it; $p does not use 'bar'

=cut
