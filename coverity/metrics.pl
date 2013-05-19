#!/usr/bin/perl

=pod

create html for CPP/Java metrics on two hardware platforms

$ perl metrics.pl datafile

=cut

use warnings;
use strict;

use Carp;
use Data::Dumper::Simple;
use FindBin;
use Getopt::Long;

use Readonly;

use Storable qw( dclone ); #deep copy array w/refs
use Template;
use utf8;

local $| = 1;
my( $script ) = $FindBin::Script =~ /(.*)\.pl$/x;

my( $TRUE, $FALSE, $logFileName, $CRITICAL_CPP_THRESHOLD, $MAJOR_CPP_THRESHOLD, $MINOR_CPP_THRESHOLD,
    $CRITICAL_JAVA_THRESHOLD, $MAJOR_JAVA_THRESHOLD, $MINOR_JAVA_THRESHOLD );

setConfiguration();

my $debugTrace   = $TRUE;
my $debugTrace_0 = $TRUE;

my $project  = 'Project:';
my $hardware = 'Andromeda';

my @columns   = qw(DATE CRITICAL_PA_CPP CRITICAL_PB_CPP CRITICAL_PA_JAVA MAJOR_PA_CPP MAJOR_PB_CPP MAJOR_PA_JAVA MINOR_PA_CPP MINOR_PB_CPP MINOR_PA_JAVA);
my @xlColumns = qw(DATE FILENAME);
my $nextArgv  = '';
my (@dates, @xlDates);

getData();

print $script, ' ', __LINE__, ' ', Dumper( @dates )   if $debugTrace;
print $script, ' ', __LINE__, ' ', Dumper( @xlDates ) if $debugTrace;

# 1. create a easily sorted temporary date (yyyymmdd) associated with each array hash element
# 2. sort the result
# 3. copy the sorted date & data hashes back into the array
#
@dates =  map  { $_->[0] }
          sort { $a->[1] cmp $b->[1] }
          map  { [ $_, ( sprintf( '%4u%02u%02u', ( split '/', $_->{ DATE } )[2,0,1] ) ) ] } @dates;

# re-format data for display; keep no-color copy for metrics
#
my @colorDates = @{ dclone( \@dates ) };
createColorMarkup( \@colorDates );
print $script, ' ', __LINE__, ' ', Dumper( @colorDates )   if $debugTrace_0;

# Template::Toolkit
# template file, $script.tt will map data to html
#
my $tt = Template->new;

$tt->process( $script . '_html.tt',
             { project    => $project,
               hardware   => $hardware,
               colordates => \@colorDates,
               dates      => \@dates,
               exceldates => \@xlDates,
               copyright  => 'dsassdevatgmaildotcom 2013',
             },
             $script . '.html' )
  or croak '__CROAK__ $tt->error = ', $tt->error;



exit;

################################################################################

sub createColorMarkup
{
  my $aRef    = shift;
  my $aLength = @$aRef;


  for( my $i=0; $i<$aLength; $i++ )
  {
    # configuration PA
    #
    if( $aRef->[$i]{CRITICAL_PA_CPP} < $CRITICAL_CPP_THRESHOLD )
    {
      $aRef->[$i]{CRITICAL_PA_CPP} = '<font color="green">' . $aRef->[$i]{CRITICAL_PA_CPP} . '</font>&nbsp;';
    }
    else
    {
      $aRef->[$i]{CRITICAL_PA_CPP} = '<font color="red">' . $aRef->[$i]{CRITICAL_PA_CPP} . '</font>&nbsp;';
    }

    if( $aRef->[$i]{MAJOR_PA_CPP} < $MAJOR_CPP_THRESHOLD )
    {
      $aRef->[$i]{MAJOR_PA_CPP} = '<font color="green">' . $aRef->[$i]{MAJOR_PA_CPP} . '</font>&nbsp;';
    }
    else
    {
      $aRef->[$i]{MAJOR_PA_CPP} = '<font color="red">' . $aRef->[$i]{MAJOR_PA_CPP} . '</font>&nbsp;';
    }

    if( $aRef->[$i]{MINOR_PA_CPP} < $MINOR_CPP_THRESHOLD )
    {
      $aRef->[$i]{MINOR_PA_CPP} = '<font color="green">' . $aRef->[$i]{MINOR_PA_CPP} . '</font>&nbsp;';
    }
    else
    {
      $aRef->[$i]{MINOR_PA_CPP} = '<font color="red">' . $aRef->[$i]{MINOR_PA_CPP} . '</font>&nbsp;';
    }


    if( $aRef->[$i]{CRITICAL_PA_JAVA} < $CRITICAL_JAVA_THRESHOLD )
    {
      $aRef->[$i]{CRITICAL_PA_JAVA} = '<font color="green">' . $aRef->[$i]{CRITICAL_PA_JAVA} . '</font>&nbsp;';
    }
    else
    {
      $aRef->[$i]{CRITICAL_PA_JAVA} = '<font color="red">' . $aRef->[$i]{CRITICAL_PA_JAVA} . '</font>&nbsp;';
    }

    if( $aRef->[$i]{MAJOR_PA_JAVA} < $MAJOR_JAVA_THRESHOLD )
    {
      $aRef->[$i]{MAJOR_PA_JAVA} = '<font color="green">' . $aRef->[$i]{MAJOR_PA_JAVA} . '</font>&nbsp;';
    }
    else
    {
      $aRef->[$i]{MAJOR_PA_JAVA} = '<font color="red">' . $aRef->[$i]{MAJOR_PA_JAVA} . '</font>&nbsp;';
    }

    if( $aRef->[$i]{MINOR_PA_JAVA} < $MINOR_JAVA_THRESHOLD )
    {
      $aRef->[$i]{MINOR_PA_JAVA} = '<font color="green">' . $aRef->[$i]{MINOR_PA_JAVA} . '</font>&nbsp;';
    }
    else
    {
      $aRef->[$i]{MINOR_PA_JAVA} = '<font color="red">' . $aRef->[$i]{MINOR_PA_JAVA} . '</font>&nbsp;';
    }

    # configuration PB
    #
    if( $aRef->[$i]{CRITICAL_PB_CPP} < $CRITICAL_CPP_THRESHOLD )
    {
      $aRef->[$i]{CRITICAL_PB_CPP} = '<font color="green">' . $aRef->[$i]{CRITICAL_PB_CPP} . '</font>&nbsp;';
    }
    else
    {
      $aRef->[$i]{CRITICAL_PB_CPP} = '<font color="red">' . $aRef->[$i]{CRITICAL_PB_CPP} . '</font>&nbsp;';
    }

    if( $aRef->[$i]{MAJOR_PB_CPP} < $MAJOR_CPP_THRESHOLD )
    {
      $aRef->[$i]{MAJOR_PB_CPP} = '<font color="green">' . $aRef->[$i]{MAJOR_PB_CPP} . '</font>&nbsp;';
    }
    else
    {
      $aRef->[$i]{MAJOR_PB_CPP} = '<font color="red">' . $aRef->[$i]{MAJOR_PB_CPP} . '</font>&nbsp;';
    }

    if( $aRef->[$i]{MINOR_PB_CPP} < $MINOR_CPP_THRESHOLD )
    {
      $aRef->[$i]{MINOR_PB_CPP} = '<font color="green">' . $aRef->[$i]{MINOR_PB_CPP} . '</font>&nbsp;';
    }
    else
    {
      $aRef->[$i]{MINOR_PB_CPP} = '<font color="red">' . $aRef->[$i]{MINOR_PB_CPP} . '</font>&nbsp;';
    }
  }
  return;
}


sub getData
{
  # read/process input .csv
  # EXAMPLE: 5/12/2013,16,92,11,68,79,71,335,264,212
  #
  while( <> )
  {
    $nextArgv = $ARGV if $nextArgv ne $ARGV;

    if( $nextArgv =~ /xl/x )
    {
      chomp;
      my %xlDate;
      @xlDate{@xlColumns}   = split /,/x;

      my( $mon, $day, $year ) = split '/', $xlDate{DATE};
      $xlDate{FILEDATE} = sprintf( '%02u%02u%4u', $mon, $day, $year );

      push @xlDates, \%xlDate;
    }
    else
    {
      chomp;
      my %date;
      @date{@columns} = split /,/x;
      push @dates, \%date;
    }
  }
  return;
}

sub setConfiguration
{
  Readonly::Scalar $TRUE  => 1;
  Readonly::Scalar $FALSE => 0;
  Readonly::Scalar $logFileName => 'logs/defectMetrics.log';

  Readonly::Scalar $CRITICAL_CPP_THRESHOLD => 25;
  Readonly::Scalar $MAJOR_CPP_THRESHOLD    => 50;
  Readonly::Scalar $MINOR_CPP_THRESHOLD    => 262;

  Readonly::Scalar $CRITICAL_JAVA_THRESHOLD => 60;
  Readonly::Scalar $MAJOR_JAVA_THRESHOLD    => 75;
  Readonly::Scalar $MINOR_JAVA_THRESHOLD    => 250;

  return;
}


__END__
