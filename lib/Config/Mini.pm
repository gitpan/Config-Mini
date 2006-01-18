=head1 NAME

Config::Mini - Very simple INI-style configuration parser


=head1 SYNOPSIS

In your config file:

  foo = bar
  baz = buz
  
  [section1]
  key1 = val1
  key2 = val2

  [section2]
  key3 = val3
  key4 = arrayvalue
  key4 = arrayvalue2
  key4 = arrayvalue3


In your perl code:

use Config::Mini;
Config::Mini::parse_file ('sample.cfg');

my $foo  = Config::Mini::get ("general", "foo");
my @key4 = Config::Mini::get ("section2", "key4");


=head1 SUMMARY

Config::Mini is a very simple INI style parser.


=head1 FUNCTIONS

=cut
package Config::Mini;
use warnings;
use strict;

our $VERSION = '0.01';
our %CONF = ();



=head2 Config::Mini::parse_file ($filename)

Parses config file $filename

=cut
sub parse_file
{
    my $file = shift;
    open FP, "<$file" or die "Cannot read-open $file";
    parse_data (<FP>);
    close FP;
}


=head2 Config::Mini::parse_data (@data)

Parses @data

=cut
sub parse_data
{
    my @lines = map { split /(\r\n|\n|\r)/ } @_;

    my $current = 'general';
    my $count   = 0;
    for (@lines)
    {
        my $orig = $_;
        $count++;

        s/#.*//;
        s/^\s+//;
        s/\s+$//;
        $_ || next;

        /^\[.+\]/ and do {
            ($current) = $_ =~ /^\[(.+)\]/;
            $CONF{$current} ||= {};
            next;
        };

        /^.+=.+$/ and do {
            my ($key, $value) = split /\s+=\s+/, $_, 2;
            $CONF{$current}->{$key} ||= [];
            push @{$CONF{$current}->{$key}}, $value;
            next;
        };
        
        print STDERR "ConfigParser: Cannot parse >>>$orig<<< (line $count)\n";
    }
}


=head2 Config::Mini::get ($context, $key)

Returns the value for $key in $context.

Returns the value as an array if the requested value is an array.

Return the first value otherwise.

=cut
sub get
{
    my $con = shift;
    my $key = shift;
    return wantarray ? @{$CONF{$con}->{$key}} : $CONF{$con}->{$key}->[0]; 
}


=head2 Config::Mini::instantiate ($context)

If $context is used to describe an object, Config::Mini will try to instantiate it.

If $section contains a "package" attribute, Config::Mini will try to load that package and call
a new() method to instantiate the object.

Otherwise, it will simply return a hash reference.

Values can be considered as a scalar or an array. Hence, Config::Mini uses
<attribute_name> for scalar values and '__<attribute_name>' for array values.

=cut
sub instantiate
{
    my $section = shift;
    my $config  = $CONF{$section} || return;
    my %args    = ();
    foreach my $key (keys %{$config})
    {
        $args{$key}     = $config->{$key}->[0];
        $args{"__$key"} = $config->{$key};
    }

    my $class = $args{package} || return \%args;
    eval "use $class";
    defined $@ and $@ and warn $@;
    return $class->new ( %args );
}


=head2 Config::Mini::select ($regex)

Selects all section entries matching $regex, and returns a list of instantiated
objects using instantiate() for each of them.

=cut
sub select
{
    my $regex = shift;
    return map  { instantiate ($_) }
           grep /$regex/, keys %CONF;
}


1;


__END__


=head1 AUTHOR

Copyright 2006 - Jean-Michel Hiver
All rights reserved

This module is free software and is distributed under the same license as Perl
itself. Use it at your own risk.
