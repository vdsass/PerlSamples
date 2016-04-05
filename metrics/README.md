#NAME

**metrics.pl**

##SYNOPSIS

Perl script to read software defect measures and create an HTML file to display
the data in table and graph form.

##DESCRIPTION

metrics.pl was created to demonstrate use of Perl CPAN modules, Perl coding style,
and integration with HTML and JavaScript.

CPAN modules demonstrated include:

* Log::Log4Perl     - For debugging.
* Readonly          - To maintain constants.
* Template::Toolkit - Templates to create HTML.
* XML::LibXML       - API to libxml2 for XML file read/write. For a long time the ActiveState ppm lib did not have a working port of XML::LibXML. It's available for Perl 5.20 making XML::LibXML easier to support on a Windows platform.

##USAGE

```
Usage: perl metrics.pl -datafile 'file path' -configfile 'configuration file path'
                      [-loglevel [DEBUG|INFO|WARN|ERROR|FATAL]] [-debug] [-h|?|help]"
```
Example: perl metrics.pl -datafile measures.csv -configfile metrics.xml

##REQUIRED ARGUMENTS

A comma-separated variable (.csv) data file and a configuration file (.xml) are
required. See measures.csv for data file format.

An unsorted (by date) .csv data file will be sorted on output ('unsorted_measures.csv'
is included in the local directory for demonstration).

See metrics.xml for configuration format.

##OPTIONS

Optional command line arguments are shown in USAGE surrounded by brackets ( [] ).
If the optional argument is not present the script will use a default value.

* -debug : (boolean) prints trace statements to show script progress and data details

##DIAGNOSTICS

log4perl trace statements

##EXIT STATUS

Exits with 0 for non-error execution.
Error conditions within the script will cause it to croak at the point of failure.

##CONFIGURATION

metrics.xml contains log file path and threshold measurement values.

##DEPENDENCIES

See the 'use <module>' list at the top of the script.
Developed and tested using ActiveState Perl v5.16.3 and v5.20.1 on Windows and Perl v5.10.1 on Linux.
See 'INCOMPATIBILITIES.'

##INCOMPATIBILITIES

Using Amazon (AWS) RHEL instance and Perl v5.10.1 required changing switch statements
in createColorMarkup() to a set of if statements due to backward incompatibility. This
results in a Perl::Critic high complexity complaint for createColorMarkup().

##BUGS AND LIMITATIONS

none observed

##AUTHOR

vdsass, *swdeveloperatcoxdotnet*

##LICENSE AND COPYRIGHT

Copyright 2013-2016 vdsass, All rights reserved.
This program is free software; you can redistribute it and/or modify it under the
same terms as Perl itself.
