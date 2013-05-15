#!/usr/bin/perl
#use strict;
use warnings;

=pod

Programming Perl, 3rd Edition
pp335, Closures

=cut

use Data::Dumper::Simple;

{
  my $critter1 = 'camel';
  $critterRef1 = \$critter1;
}

=pod

The value of $$critterRef1 will be 'camel' even though $critter disappears after
the closing curly bace of the block in which it was defined.

=cut

print Dumper( $$critterRef1 );
print '$$critterRef1 = ', $$critterRef1, "\n";

=pod

But, $critterRef could just as easily referred to  a subroutine that refers to
$critter.

This is a closure: it means that when you define an anonymous function in a particular
lexical scope at a particular moment, it [pretends] to run in that scope even when
called from outside that scope.

=cut

{
  my $critter2 = 'horse';
  $critterRef2 = sub{ return $critter2 };
}

print Dumper( &$critterRef2 );          # Dumper doesn't print as expected. Why?
print '&$critterRef2 = ', &$critterRef2, "\n";

=pod

In other words, you are guaranteed to get the same copy of a lexical variable each
time, even if other instances of that lexical variable have been created before or
since for other instances of that closure. This gives you a way to set values used in
a subroutine when you define it, not just when you call it.

You can also think of closures as a way to write a subroutine template without
using eval. The lexical variables act as parameters for filling in the template, which
is useful for setting up little bits of code to run later.

These are commonly called 'callbacks' in event-based programming, where you associate
a bit of code with a keypress, mouse click, window exposure, and so on. When used as
callbacks, closures do exactly what you expect, even if you don’t know the first thing about
functional programming. (Note that this closure business only applies to my variables.
Global variables work as they’ve always worked, since they’re neither created
nor destroyed the way lexical variables are.)

=cut


exit;

__END__
