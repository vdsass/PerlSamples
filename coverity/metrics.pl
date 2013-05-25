#!/usr/bin/perl

=pod

create html for C++/Java metrics on two hardware platforms

$ perl metrics.pl datafile

=cut

use warnings;
use strict;

use Carp;
use Data::Dumper::Simple;

use feature "switch";
use File::Path qw(make_path remove_tree);
use FindBin qw($Bin);

use Getopt::Long;

use Log::Log4perl qw( get_logger :levels );

use Readonly;

use Sys::Hostname;

use Storable qw( dclone ); #deep copy array w/refs

use Template;

use utf8;

local $| = 1;
my( $script ) = $FindBin::Script =~ /(.*)\.pl$/x;

my( $TRUE, $FALSE, $g_currentDir, $CRITICAL_CPP_THRESHOLD, $MAJOR_CPP_THRESHOLD,
    $MINOR_CPP_THRESHOLD, $CRITICAL_JAVA_THRESHOLD, $MAJOR_JAVA_THRESHOLD,
    $MINOR_JAVA_THRESHOLD );

setConfiguration();

my $debugError  = $FALSE;
my $debugLevel0 = $FALSE;

GetOptions( "datafile=s" => \my $dataFilePath,
	    "debug"      => \my $testMode
	  );

my $logFilePath = createDir('logs');
Log::Log4perl::init( loggerInit( $logFilePath, $testMode ) );
my $loggerMain  = get_logger( $script );
   $loggerMain->level( $DEBUG );

my $project  = 'Project:';
my $hardware = 'Andromeda';

my @columns   = qw(DATE CRITICAL_GPP_CPP CRITICAL_MODEM_CPP CRITICAL_GPP_JAVA MAJOR_GPP_CPP MAJOR_MODEM_CPP MAJOR_GPP_JAVA MINOR_GPP_CPP MINOR_MODEM_CPP MINOR_GPP_JAVA);
my @xlColumns = qw(DATE FILENAME);
my $nextArgv  = '';
my ( @dates, @xlDates );

getData( $dataFilePath );

print $script, ' ', __LINE__, ' ', Dumper( @dates )   if $debugLevel0;
print $script, ' ', __LINE__, ' ', Dumper( @xlDates ) if $debugLevel0;

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
print $script, ' ', __LINE__, ' ', Dumper( @colorDates )   if $debugLevel0;

# Template::Toolkit
# template file, $script.tt will map data to html
#
my $tt = Template->new;

my %linePointColors = (
                        critical => {
                                      CPP => {
                                                line => '"rgba(255,0,0,1)"',
                                                point=> '"rgba(255,0,0,1)"',
                                             },
                                      JAVA=> {
                                               line => '"rgba(0,0,255,1)"',
                                               point=> '"rgba(0,0,255,1)"',
                                             },
                                    },
                        major    => {
                                      CPP => {
                                                line => '"rgba(0,255,0,1)"',
                                                point=> '"rgba(0,255,0,1)"',
                                             },
                                      JAVA=> {
                                               line => '"rgba(225,100,25,1)"',
                                               point=> '"rgba(225,100,25,1)"',
                                             },
                                    },
                      );

print Dumper(%linePointColors) if $debugLevel0;

$tt->process( $script . '_html.tt',
             { project    => $project,
               hardware   => $hardware,
               colordates => \@colorDates,
               dates      => \@dates,
               exceldates => \@xlDates,
               colors     => \%linePointColors,
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
    # configuration GPP
    #
    if( $aRef->[$i]{CRITICAL_GPP_CPP} < $CRITICAL_CPP_THRESHOLD )
    {
      $aRef->[$i]{CRITICAL_GPP_CPP} = '<font color="green">' . $aRef->[$i]{CRITICAL_GPP_CPP} . '</font>&nbsp;';
    }
    else
    {
      $aRef->[$i]{CRITICAL_GPP_CPP} = '<font color="red">' . $aRef->[$i]{CRITICAL_GPP_CPP} . '</font>&nbsp;';
    }

    if( $aRef->[$i]{MAJOR_GPP_CPP} < $MAJOR_CPP_THRESHOLD )
    {
      $aRef->[$i]{MAJOR_GPP_CPP} = '<font color="green">' . $aRef->[$i]{MAJOR_GPP_CPP} . '</font>&nbsp;';
    }
    else
    {
      $aRef->[$i]{MAJOR_GPP_CPP} = '<font color="red">' . $aRef->[$i]{MAJOR_GPP_CPP} . '</font>&nbsp;';
    }

    if( $aRef->[$i]{MINOR_GPP_CPP} < $MINOR_CPP_THRESHOLD )
    {
      $aRef->[$i]{MINOR_GPP_CPP} = '<font color="green">' . $aRef->[$i]{MINOR_GPP_CPP} . '</font>&nbsp;';
    }
    else
    {
      $aRef->[$i]{MINOR_GPP_CPP} = '<font color="red">' . $aRef->[$i]{MINOR_GPP_CPP} . '</font>&nbsp;';
    }


    if( $aRef->[$i]{CRITICAL_GPP_JAVA} < $CRITICAL_JAVA_THRESHOLD )
    {
      $aRef->[$i]{CRITICAL_GPP_JAVA} = '<font color="green">' . $aRef->[$i]{CRITICAL_GPP_JAVA} . '</font>&nbsp;';
    }
    else
    {
      $aRef->[$i]{CRITICAL_GPP_JAVA} = '<font color="red">' . $aRef->[$i]{CRITICAL_GPP_JAVA} . '</font>&nbsp;';
    }

    if( $aRef->[$i]{MAJOR_GPP_JAVA} < $MAJOR_JAVA_THRESHOLD )
    {
      $aRef->[$i]{MAJOR_GPP_JAVA} = '<font color="green">' . $aRef->[$i]{MAJOR_GPP_JAVA} . '</font>&nbsp;';
    }
    else
    {
      $aRef->[$i]{MAJOR_GPP_JAVA} = '<font color="red">' . $aRef->[$i]{MAJOR_GPP_JAVA} . '</font>&nbsp;';
    }

    if( $aRef->[$i]{MINOR_GPP_JAVA} < $MINOR_JAVA_THRESHOLD )
    {
      $aRef->[$i]{MINOR_GPP_JAVA} = '<font color="green">' . $aRef->[$i]{MINOR_GPP_JAVA} . '</font>&nbsp;';
    }
    else
    {
      $aRef->[$i]{MINOR_GPP_JAVA} = '<font color="red">' . $aRef->[$i]{MINOR_GPP_JAVA} . '</font>&nbsp;';
    }

    # configuration MODEM
    #
    if( $aRef->[$i]{CRITICAL_MODEM_CPP} < $CRITICAL_CPP_THRESHOLD )
    {
      $aRef->[$i]{CRITICAL_MODEM_CPP} = '<font color="green">' . $aRef->[$i]{CRITICAL_MODEM_CPP} . '</font>&nbsp;';
    }
    else
    {
      $aRef->[$i]{CRITICAL_MODEM_CPP} = '<font color="red">' . $aRef->[$i]{CRITICAL_MODEM_CPP} . '</font>&nbsp;';
    }

    if( $aRef->[$i]{MAJOR_MODEM_CPP} < $MAJOR_CPP_THRESHOLD )
    {
      $aRef->[$i]{MAJOR_MODEM_CPP} = '<font color="green">' . $aRef->[$i]{MAJOR_MODEM_CPP} . '</font>&nbsp;';
    }
    else
    {
      $aRef->[$i]{MAJOR_MODEM_CPP} = '<font color="red">' . $aRef->[$i]{MAJOR_MODEM_CPP} . '</font>&nbsp;';
    }

    if( $aRef->[$i]{MINOR_MODEM_CPP} < $MINOR_CPP_THRESHOLD )
    {
      $aRef->[$i]{MINOR_MODEM_CPP} = '<font color="green">' . $aRef->[$i]{MINOR_MODEM_CPP} . '</font>&nbsp;';
    }
    else
    {
      $aRef->[$i]{MINOR_MODEM_CPP} = '<font color="red">' . $aRef->[$i]{MINOR_MODEM_CPP} . '</font>&nbsp;';
    }
  }
  return;
}


sub getData
{
  my $file = shift;

  # read/process input .csv identified on the command line
  # EXAMPLE: 5/12/2013,16,92,11,68,79,71,335,264,212
  #
  open my $fh, '<', $file;
  while( <$fh> )
  {
    chomp;
    my %date;
    @date{@columns} = split /,/x;
    push @dates, \%date;
  }
  close $fh;
  return;
}

sub setConfiguration
{
  Readonly::Scalar $TRUE  => 1;
  Readonly::Scalar $FALSE => 0;

  Readonly::Scalar $g_currentDir => $Bin;

  Readonly::Scalar $CRITICAL_CPP_THRESHOLD => 25;
  Readonly::Scalar $MAJOR_CPP_THRESHOLD    => 50;
  Readonly::Scalar $MINOR_CPP_THRESHOLD    => 262;

  Readonly::Scalar $CRITICAL_JAVA_THRESHOLD => 60;
  Readonly::Scalar $MAJOR_JAVA_THRESHOLD    => 75;
  Readonly::Scalar $MINOR_JAVA_THRESHOLD    => 250;

  return;
}


sub createDir
{
  my $dir    = shift;
  my $logDir = $g_currentDir . '/' . $dir;
  return $logDir if -e $logDir;

  my( $subroutine )   = (caller(0))[3];
  local $| = 1;
  print "$subroutine ", __LINE__, ": directory is $dir\n" if $debugLevel0;

  my $makePathResponse = make_path( $logDir,
                                    { verbose => $FALSE,
                                      error   => \my $err,
                                    }
                                   );

  print "$subroutine ", __LINE__, ": attempted to create directory $logDir \$makePathResponse = $makePathResponse\n" if $debugLevel0;

  if( @$err )
  {
    for my $diag( @$err )
    {
     my( $file, $message ) = %$diag;
     if( $file eq '' )
     {
      print "$subroutine ", __LINE__, "__ERROR__ : general error : \$message = $message\n" if $debugError;
     }
     else
     {
      print "$subroutine ", __LINE__, "__ERROR__ : creating \$file = $file : \$message = $message\n" if $debugError;
     }
    }
  }
  else
  {
    print "$subroutine ", __LINE__, ": No make_path errors encountered \$logDir = $logDir\n" if $debugLevel0;
  }
  return $logDir;
}

#
# loggerInit: Log::Log4perl Setup
#
# message filter levels
#
# FATAL < highest
# ERROR
# WARN
# INFO
# DEBUG < lowest
#
# Initialize Logger
# PatternLayout: http://jakarta.apache.org/log4j/docs/api/org/apache/log4j/PatternLayout.html
#
# %c Category of the logging event.
# %C Fully qualified package (or class) name of the caller
# %d Current date in yyyy/MM/dd hh:mm:ss format
# %d{...} Current date in customized format (see below)
# %F File where the logging event occurred
# %H Hostname (if Sys::Hostname is available)
# %l Fully qualified name of the calling method followed by the
#    callers source the file name and line number between
#    parentheses.
# %L Line number within the file where the log statement was issued
# %m The message to be logged
# %m{chomp} The message to be logged, stripped off a trailing newline
# %M Method or function where the logging request was issued
# %n Newline (OS-independent)
# %p Priority of the logging event (%p{1} shows the first letter)
# %P pid of the current process
# %r Number of milliseconds elapsed from program start to logging
#    event
# %R Number of milliseconds elapsed from last logging event to
#    current logging event
# %T A stack trace of functions called
# %x The topmost NDC (see below)
# %X{key} The entry 'key' of the MDC (see below)
# %% A literal percent (%) sign
#
sub loggerInit
{
  my $dir      = shift;
  my $test     = shift;

  my $logFileName = $dir . '/' . formattedDateTime()->{ yyyymmddhhmmss } . '_' . $script . '.log';

  # $testMode writes to the screen and a file
  #
  my $log_conf;
  if( $test )
  {
    $log_conf = << "__EOT__";
log4perl.rootLogger                               = DEBUG, LOG1, SCREEN
log4perl.appender.SCREEN                          = Log::Log4perl::Appender::Screen
log4perl.appender.SCREEN.stderr                   = 0
log4perl.appender.SCREEN.layout                   = Log::Log4perl::Layout::PatternLayout
log4perl.appender.SCREEN.layout.ConversionPattern = %d %M %L %p %m %n
log4perl.appender.LOG1                            = Log::Log4perl::Appender::File
log4perl.appender.LOG1.filename                   = ${logFileName}
log4perl.appender.LOG1.mode                       = write
log4perl.appender.LOG1.layout                     = Log::Log4perl::Layout::PatternLayout
log4perl.appender.LOG1.layout.ConversionPattern   = %d %M %L %p %m %n
__EOT__

}
else
{
  $log_conf = << "__EOT__";
log4perl.rootLogger                               = DEBUG, LOG1
log4perl.appender.LOG1                            = Log::Log4perl::Appender::File
log4perl.appender.LOG1.filename                   = ${logFileName}
log4perl.appender.LOG1.mode                       = write
log4perl.appender.LOG1.layout                     = Log::Log4perl::Layout::PatternLayout
log4perl.appender.LOG1.layout.ConversionPattern   = %d %M %L %p %m %n
__EOT__

}
  return \$log_conf;
}

sub formattedDateTime
{
  my $t = shift || time;
  my ( $sec, $min, $hour, $mday, $mon, $year, $wday, $yday, $isdst ) = localtime( $t );
  $year += 1900;
  ++$mon;
  my $yyyymmdd        = sprintf( '%d%02d%02d', $year, $mon, $mday );
  my $yyyymmdd_hhmmss = sprintf( '%d%02d%02d_%02d%02d%02d', $year, $mon, $mday, $hour, $min, $sec );
  my $mm_dd_yyyy      = sprintf( '%02d/%02d/%d', $mon, $mday, $year );
  return(
         {
          yyyymmdd       => $yyyymmdd,
          yyyymmddhhmmss => $yyyymmdd_hhmmss,
          mmddyyyy       => $mm_dd_yyyy,
         }
        );
}

__END__
