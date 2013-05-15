#!/usr/bin/perl

=pod

create confluence wiki markup for coverity metrics

$ perl coverityMetrics.pl

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

#print $script, ' ', __LINE__, ' $Net::Twitter::VERSION = ', $Net::Twitter::VERSION, "\n\n";

my( $TRUE, $FALSE, $logFileName, $CRITICAL_C_THRESHOLD, $MAJOR_C_THRESHOLD, $MINOR_C_THRESHOLD,
    $CRITICAL_J_THRESHOLD, $MAJOR_J_THRESHOLD, $MINOR_J_THRESHOLD );

setConfiguration();

my $debugTrace = $TRUE;

my $project  = 'sdb-common-android-jb-4.2';
my $hardware = 'CA20130401';

my @columns   = qw(DATE CRITICAL_AP_C CRITICAL_CP_C CRITICAL_AP_J MAJOR_AP_C MAJOR_CP_C MAJOR_AP_J MINOR_AP_C MINOR_CP_C MINOR_AP_J);
my @xlColumns = qw(DATE FILENAME);
my $nextArgv  = '';
my (@dates, @xlDates);

getData();

print $script, ' ', __LINE__, ' ', Dumper( @dates )   if $debugTrace;
print $script, ' ', __LINE__, ' ', Dumper( @xlDates ) if $debugTrace;

# re-format data for wiki
# keep no-color copy for metrics
#
my @colorDates = @{ dclone( \@dates ) };

createColorMarkup( \@colorDates );

print $script, ' ', __LINE__, ' ', Dumper( @colorDates )   if $debugTrace;

# date field will need to be epoch time

my @sortedDates = map{ $_->[0] }
                  sort{ $a->[1] cmp $b->[1] }
                  map{ [ $_, $_->{DATE} ] } @dates;

print $script, ' ', __LINE__, ' ', Dumper( @sortedDates )   if $debugTrace;

my $latestDate = $sortedDates[0]->{DATE};
print $script, ' ', __LINE__, ' $latestDate = ', $latestDate if $debugTrace;
my( $mm, $dd, $yyyy ) = split '/', $latestDate;
my $fileDate = sprintf( '%02u%02u%4u', $mm, $dd, $yyyy );

# Template::Toolkit
# template file, $script.tt will map data to the wiki format
#
my $tt = Template->new;

$tt->process( $script . '.tt',
             { project    => $project,
               hardware   => $hardware,
               colordates => \@colorDates,
               dates      => \@dates,
               exceldates => \@xlDates,
               latestdate => $fileDate,
             },
             $script . '.csv' )
  or croak '__CROAK__ $tt->error = ', $tt->error;



exit;

################################################################################

sub createColorMarkup
{
  my $aRef    = shift;
  my $aLength = @$aRef;


  for( my $i=0; $i<$aLength; $i++ )
  {
    # configuration AP
    #
    if( $aRef->[$i]{CRITICAL_AP_C} < $CRITICAL_C_THRESHOLD )
    {
      $aRef->[$i]{CRITICAL_AP_C} = '{color:green}' . $aRef->[$i]{CRITICAL_AP_C} . '{color}';
    }
    else
    {
      $aRef->[$i]{CRITICAL_AP_C} = '{color:red}' . $aRef->[$i]{CRITICAL_AP_C} . '{color}';
    }

    if( $aRef->[$i]{MAJOR_AP_C} < $MAJOR_C_THRESHOLD )
    {
      $aRef->[$i]{MAJOR_AP_C} = '{color:green}' . $aRef->[$i]{MAJOR_AP_C} . '{color}';
    }
    else
    {
      $aRef->[$i]{MAJOR_AP_C} = '{color:red}' . $aRef->[$i]{MAJOR_AP_C} . '{color}';
    }

    if( $aRef->[$i]{MINOR_AP_C} < $MINOR_C_THRESHOLD )
    {
      $aRef->[$i]{MINOR_AP_C} = '{color:green}' . $aRef->[$i]{MINOR_AP_C} . '{color}';
    }
    else
    {
      $aRef->[$i]{MINOR_AP_C} = '{color:red}' . $aRef->[$i]{MINOR_AP_C} . '{color}';
    }


    if( $aRef->[$i]{CRITICAL_AP_J} < $CRITICAL_C_THRESHOLD )
    {
      $aRef->[$i]{CRITICAL_AP_J} = '{color:green}' . $aRef->[$i]{CRITICAL_AP_J} . '{color}';
    }
    else
    {
      $aRef->[$i]{CRITICAL_AP_J} = '{color:red}' . $aRef->[$i]{CRITICAL_AP_J} . '{color}';
    }

    if( $aRef->[$i]{MAJOR_AP_J} < $MAJOR_C_THRESHOLD )
    {
      $aRef->[$i]{MAJOR_AP_J} = '{color:green}' . $aRef->[$i]{MAJOR_AP_J} . '{color}';
    }
    else
    {
      $aRef->[$i]{MAJOR_AP_J} = '{color:red}' . $aRef->[$i]{MAJOR_AP_J} . '{color}';
    }

    if( $aRef->[$i]{MINOR_AP_J} < $MINOR_C_THRESHOLD )
    {
      $aRef->[$i]{MINOR_AP_J} = '{color:green}' . $aRef->[$i]{MINOR_AP_J} . '{color}';
    }
    else
    {
      $aRef->[$i]{MINOR_AP_J} = '{color:red}' . $aRef->[$i]{MINOR_AP_J} . '{color}';
    }


    # configuration CP
    #
    if( $aRef->[$i]{CRITICAL_CP_C} < $CRITICAL_C_THRESHOLD )
    {
      $aRef->[$i]{CRITICAL_CP_C} = '{color:green}' . $aRef->[$i]{CRITICAL_CP_C} . '{color}';
    }
    else
    {
      $aRef->[$i]{CRITICAL_CP_C} = '{color:red}' . $aRef->[$i]{CRITICAL_CP_C} . '{color}';
    }

    if( $aRef->[$i]{MAJOR_CP_C} < $MAJOR_C_THRESHOLD )
    {
      $aRef->[$i]{MAJOR_CP_C} = '{color:green}' . $aRef->[$i]{MAJOR_CP_C} . '{color}';
    }
    else
    {
      $aRef->[$i]{MAJOR_CP_C} = '{color:red}' . $aRef->[$i]{MAJOR_CP_C} . '{color}';
    }

    if( $aRef->[$i]{MINOR_CP_C} < $MINOR_C_THRESHOLD )
    {
      $aRef->[$i]{MINOR_CP_C} = '{color:green}' . $aRef->[$i]{MINOR_CP_C} . '{color}';
    }
    else
    {
      $aRef->[$i]{MINOR_CP_C} = '{color:red}' . $aRef->[$i]{MINOR_CP_C} . '{color}';
    }
  }
  return;
}


sub getData
{
  # read/process input .csv
  #
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
      my( $mm, $dd, $yyyy ) = split '/', $xlDate{DATE};
      $xlDate{FILEDATE} = sprintf( '%02u%02u%4u', $mm, $dd, $yyyy );
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
  Readonly::Scalar $logFileName => 'logs/coverityMetrics.log';

  Readonly::Scalar $CRITICAL_C_THRESHOLD => 64;
  Readonly::Scalar $MAJOR_C_THRESHOLD    => 95;
  Readonly::Scalar $MINOR_C_THRESHOLD    => 290;

  Readonly::Scalar $CRITICAL_J_THRESHOLD => 64;
  Readonly::Scalar $MAJOR_J_THRESHOLD    => 95;
  Readonly::Scalar $MINOR_J_THRESHOLD    => 290;

  return;
}


__END__


open my $fh, '>', $logFileName
  or croak "Can't open $logFileName: $!\n";


my %opts = (

	   );

GetOptions(
	   \%opts,
	   'passwordfile|pf=s',
	   'username|u=s',
	   'password|p=s',
	   'verbose|v',
	   'help|h',
	  );

if (exists $opts{passwordfile} && !exists $opts{password} )
{
 open my $pwf, '<', $opts{ passwordfile }
   or croak "Can't open $opts{ passwordfile }: $!";
 $opts{ password } = <$pwf>;
 close $pwf;
 chomp $opts{ password };
}

print usage() && exit(0) if exists $opts{ help };



my $handle = Net::Twitter->new({
				username => $opts{username},
				password => $opts{password}
			       });

for my $item( @ARGV )
{
 searchTwitter( $item );
}
