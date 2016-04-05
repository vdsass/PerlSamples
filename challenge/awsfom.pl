################################################################################## 
#
# awsfom.pl - AWS File and Object Manager
#
# Challenge part 2 / I'm done with part 1, now what?
# --------------------------------------------------------------------------------
# 
# The second part of the challenge is writing a script to upload your updated repo
# to Amazon Simple Storage Service (S3) so we can see your results.
# 
# Contact perlchallenge@insidesales.com and provide us with an AWS username you control.
# You can find your "Canonical User Id" in the "Account Identifiers" section of the
# "Security Credentials" page of the AWS Console.
# 
# We will respond by creating an S3 bucket and giving you read/write access to it.
# 
# R-0: Then, write a script using `Getopt::NounVerb` that supports the following operations:
#   R-1: Upload a file to a bucket
#   R-2: Delete a file from a bucket
#   R-3: List files in a bucket
#   R-4: The bucket, access keys, AWS region, and file (where appropriate) should all be
#       `Getopt::NounVerb` parameters.
#
# #####  Other requirements:
#
#   R-5: Your script should detect .zip files and set the Content-Type accordingly.
#   R-6: When uploading files, give the bucket owner full permission.
# 
# For S3 interactions, use this AWS-provided perl library:
# 
#   R-7: https://aws.amazon.com/items/133?externalID=133
# 
# ##### Once your script is complete & tested:
# 
# 1.  Add it to your local insidesales_challenge repo and commit it
# 2.  Zip up the entire repo.
# 3.  Use the script to upload the resulting zip file to the bucket we've shared with you.
# 4.  Email us to let us know you are done!
#
# VERSION     DATE        WHO     DESCRIPTION
# -----------------------------------------------------------
# v1.0.000  2015-04-15    vdsass  Initial release
# v1.0.001  2015-04-16    vdsass  Fix Bucket ACL access
#
################################################################################## 
use strict;
use warnings;

use Carp;
use English qw(-no_match_vars);
use File::Basename;
use Getopt::Long qw(GetOptions);
use Getopt::NounVerb qw(get_nv_opts opfunc); # R-0

use HTTP::Status qw(:constants :is status_message);

use Pod::Usage;

use S3;                                      # R-7
use S3::AWSAuthConnection;
use S3::QueryStringAuthGenerator;

use constant {FALSE   => 0, TRUE  => 1};
use constant {NEWLINE => qq{\n}};

use constant {BUCKET                => q{isdc-challenge-swdeveloper},
              AWS_ACCESS_KEY_ID     => q{AKIAIQPZTHSZCCU3YNEA},
              AWS_SECRET_ACCESS_KEY => q{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},
              REGION                => q{us-west-1},
              IS_SECURE             => FALSE,
             };

use constant SUFFIX_LIST => qw( .pl .pm .txt .log .zip );

my $opt_action = q{};
my ($opt_help, $opt_man, $opt_list, $opt_delete, $opt_upload);
my ($delete, $file, $list, $upload);

my $conn      = S3::AWSAuthConnection->new(AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, IS_SECURE);
my $generator = S3::QueryStringAuthGenerator->new(AWS_ACCESS_KEY_ID, AWS_SECRET_ACCESS_KEY, IS_SECURE);

my $awsFMcmds = {
                file => { h => q{AWS file management routines},
                          list  => { h => 'list files in a AWS Bucket',
                                 bucket => { h => 'AWS Bucket name',
                                             d => BUCKET,
                                           },
                                 key1   => { h => 'first key',
                                             d => AWS_ACCESS_KEY_ID,
                                            },
                                 key2   => { h => 'second key',
                                             d => AWS_SECRET_ACCESS_KEY,
                                            },
                                 region => { h => 'AWS region',
                                             d => 'us-west-1',                                      
                                           },														 
                               },
                          delete  => { h => 'delete files from a AWS Bucket',
                                 bucket => { h => 'Bucket name',
                                             d => BUCKET,
                                           },
                                 object => { h => 'AWS object (file) to delete from the specified bucket',

                                            },                                 
                                 key1   => { h => 'first key',
                                             d => AWS_ACCESS_KEY_ID,
                                            },
                                 key2   => { h => 'second key',
                                             d => AWS_SECRET_ACCESS_KEY,
                                            },
                                 region => { h => 'AWS region',
                                             d => 'us-west-1',                                            
                                           },
                               },
                          upload  => { h => 'upload local files to a AWS Bucket',
                                 bucket => { h => 'Bucket name',
                                             d => BUCKET,
                                           },
                                 file   => { h => 'local file to upload as an AWS object to the specified AWS bucket',
                                            
                                            },
                                 key1   => { h => 'first key',
                                             d => AWS_ACCESS_KEY_ID,
                                            },
                                 key2   => { h => 'second key',
                                             d => AWS_SECRET_ACCESS_KEY,
                                            },
                                 region => { h => 'AWS region',
                                             d => 'us-west-1',                                                                                  
                                           },
                               },                                            
                        },
               };

use HTTP::Status qw(:constants :is status_message);

GetOptions(
  q{help!}      => \$opt_help,  # Help text - display helpful text
  q{man!}       => \$opt_man,   # 'Manual' - display all of the POD below
  q{l|list!}    => \$opt_list,  # List the AWS Bucket contents
  q{d|delete=s} => \$opt_delete,# Delete an object (name as argument) from the AWS Bucket
  q{u|upload=s} => \$opt_upload,# Write a local file (name as argument) to a AWS Bucket
) or pod2usage(-verbose => 1) && exit;

pod2usage(-verbose => 1) && exit if defined $opt_help;
pod2usage(-verbose => 2) && exit if defined $opt_man;

pod2usage(-verbose => 1) && exit if( !( $opt_list or $opt_delete or $opt_upload ) );

my ($action, $arg, $path, $what);

if( $opt_list ) {
    $action = q{list};
    $what   = q{-};         # required by NounVerb.pm
} elsif( $opt_delete ) {
    $action = q{delete};
    $what    = $opt_delete;  
    ($path)  = @ARGV;
} elsif( $opt_upload ) {
    $action = q{upload};
    $what    = $opt_upload;
    ($path)  = @ARGV;
} else {
    croak q{ CROAK! Option logic failed! }
}

# Returns a function reference for "main::NOUN_VERB"; typically used like so:
#  my ($NOUN, $VERB, $OPTS) = get_nv_opts(...);
#  opfunc($NOUN, $VERB)->($OPTS); # execute NOUN_VERB function defined here

my ($noun, $verb, $options) = get_nv_opts($awsFMcmds, [qw(file), $action, $what, $path]);
opfunc($noun, $verb)->($options);

exit;

##################################################################################
# sub list - lists files in the specified AWS bucket
#   R-3: List files in a bucket
##################################################################################
sub file_list {
  my $info   = shift;
  my $bucket = $info->{bucket};

  _displayHeader();
  
  my $response = $conn->list_bucket($bucket);
  if($response->http_response->code == HTTP_OK){        
    my $ar = $response->{ENTRIES};
    for( my $i=0; $i<=$#{$ar}; $i++) {
      my $entry = $ar->[$i]->{Key};
      print $bucket, q{:entry[}, $i, q{]= }, $entry, NEWLINE;      
    }
    
  _displayFooter();
    
  } else {
    my $errorCode = $response->http_response->code;
    croak q{ERROR! }, q{$response->http_response->code: }, $errorCode, q{ }, status_message($errorCode);
  }
  return;
}

sub _listAWSObjects {
    my $bucket = shift;
    _displayHeader();
    my $response = $conn->list_bucket($bucket);
    if($response->http_response->code == HTTP_OK){        
      my $ar = $response->{ENTRIES};
      for( my $i=0; $i<=$#{$ar}; $i++) {
        my $entry = $ar->[$i]->{Key};
        print $bucket, q{:entry[}, $i, q{]= }, $entry, NEWLINE;      
      }
    } else {
      my $errorCode = $response->http_response->code;
      carp q{WARN! }, q{$response->http_response->code: }, $errorCode, q{ }, status_message($errorCode);
    }
    _displayFooter();
    return;
}

##################################################################################
# sub delete - deletes a file in the specified AWS bucket
#   R-2: Delete a file from a bucket
#           objects are listed before and after deletion
##################################################################################
sub file_delete {
  my $info   = shift;
  my $bucket = $info->{bucket};
  my $object = $info->{object};
  _listAWSObjects($bucket);
  my $response = $conn->delete($bucket, $object);
  if($response->http_response->code == HTTP_NO_CONTENT){
    print NEWLINE, q{Deleted: }, $bucket, q{:object = }, $object, NEWLINE;      
  } else {
    my $errorCode = $response->http_response->code;
    carp q{WARN! }, q{$response->http_response->code: }, $errorCode, q{ }, status_message($errorCode);
  }  
  _listAWSObjects($bucket);
  return;
}

##################################################################################
# sub upload - uploads (writes) a file to the specified AWS bucket
#   R-1: Upload a file to a bucket
#   R-4: Your script should detect .zip files and set the Content-Type accordingly.
#   R-5: When uploading files, give the bucket owner full permission.
##################################################################################
sub file_upload {
  my $info       = shift;
  my $bucket     = $info->{bucket};
  my $file       = $info->{file};

  _listAWSObjects($bucket);
  
  my ($name,$path,$suffix) = fileparse($file, SUFFIX_LIST);
  
  my $data = _getFileData( $file );
  my $key  = $name . $suffix;
  my $contentType;
  if( $suffix =~ /[.]zip/imsx ) {
      $contentType = q{'application/zip'};
  } else {
      $contentType = q{'text/plain'};
  }
    
  my $response =
      $conn->put( BUCKET,
                  $key,
                  S3::S3Object->new( $data ),
                  {
                   'x-amz-acl'    => 'bucket-owner-full-control',
                   'Content-Type' => $contentType
                  }
                );

  my $filePath = $path . $name . $suffix;
  
  if( $response->http_response->code == HTTP_OK ) {
    print q{Successfully uploaded file: }, BUCKET, q{: }, $filePath, NEWLINE;
  } else {
    carp q{WARN! }, $filePath, q{ put response : }, $response->http_response->code, NEWLINE;
  }
  _listAWSObjects($bucket);  
  return;
}

sub _getFileData {
  my $filePath = shift;
  return do { local( @ARGV, $/ ) = $filePath; <> }; # slurp file
}

sub _displayHeader {
  print ( NEWLINE, qq{\tBUCKET\t\t\tOBJECT}, NEWLINE);
}

sub _displayFooter {
  print ( NEWLINE, qq{\t\tEND OF LIST}, NEWLINE);
}

=head1 NAME

awsFM.pl - AWS File Manager

=head1 SYNOPSIS

perl awsFM.pl -l|-list [-d|-delete -object <object name>]
                       [-u|-upload -file <filepath>]
                       [-h|help] [-m|-man]

=head1 DESCRIPTION

The script uses `Getopt::NounVerb` to support the following operations:

=over 4

=item o
List files in a AWS bucket

=item o
Delete a AWS file (aka key, object) from a AWS bucket

=item o
Upload a local file to a AWS bucket

=back

=head1 OPTIONS

=over 4

=item o
-h|-help        print usage information

=item o
-l|-list        list contents of AWS Bucket

=item o
-d|-delete      delete AWS key specified in the argument following the option

=item o
-u|-upload      write contents of local file, specified in the argument following the option, to an AWS key [object]
 
=back
 
=head1 ARGUMENTS

If the option specified is -delete or -upload, provide the appropriate argument following the option:

=over 4

=item o
local file path of file to -upload to AWS

=item o
AWS object to delete

=back

=head1 AUTHOR

Dennis Sass (vdsass, swdeveloper@cox.net)

=head1 CREDITS

=head1 VERIFIED

=over 4

=item o
$HTTP::Status         6.03

=item o
Pod::Usage            1.64

=item o
Getopt::Long          2.42

=item o
Perl                  5.20.1

=item o
Windows 7 Professional

=back

=head1 BUGS

No known bugs.

=head1 TODO

TBD

=cut


__END__
