#!./perl

BEGIN {
  if ($ENV{PERL_CORE}){
    chdir('t') if -d 't';
    @INC = ('.', '../lib');
  }
}

use strict;

use Test;
use Time::Local;

# Set up time values to test
my @time =
  (
   #year,mon,day,hour,min,sec
   [1970,  1,  2, 00, 00, 00],
   [1980,  2, 28, 12, 00, 00],
   [1980,  2, 29, 12, 00, 00],
   [1999, 12, 31, 23, 59, 59],
   [2000,  1,  1, 00, 00, 00],
   [2010, 10, 12, 14, 13, 12],
   [2020,  2, 29, 12, 59, 59],
   [2030,  7,  4, 17, 07, 06],
# The following test fails on a surprising number of systems
# so it is commented out. The end of the Epoch for a 32-bit signed
# implementation of time_t should be Jan 19, 2038  03:14:07 UTC.
#  [2038,  1, 17, 23, 59, 59],     # last full day in any tz
  );

# use vmsish 'time' makes for oddness around the Unix epoch
if ($^O eq 'VMS') { $time[0][2]++ }

my $tests = (@time * 12) + 46;
$tests += 2 if $ENV{PERL_CORE};

plan tests => $tests;

for (@time) {
    my($year, $mon, $mday, $hour, $min, $sec) = @$_;
    $year -= 1900;
    $mon--;

    if ($^O eq 'vos' && $year == 70) {
        skip(1, "skipping 1970 test on VOS.\n") for 1..6;
    } else {
        my $time = timelocal($sec,$min,$hour,$mday,$mon,$year);

        my($s,$m,$h,$D,$M,$Y) = localtime($time);

        ok($s, $sec, 'second');
        ok($m, $min, 'minute');
        ok($h, $hour, 'hour');
        ok($D, $mday, 'day');
        ok($M, $mon, 'month');
        ok($Y, $year, 'year');
    }

    if ($^O eq 'vos' && $year == 70) {
        skip(1, "skipping 1970 test on VOS.\n") for 1..6;
    } else {
        my $time = timelocal($sec,$min,$hour,$mday,$mon,$year);

        my($s,$m,$h,$D,$M,$Y) = localtime($time);

        ok($s, $sec, 'second');
        ok($m, $min, 'minute');
        ok($h, $hour, 'hour');
        ok($D, $mday, 'day');
        ok($M, $mon, 'month');
        ok($Y, $year, 'year');
    }
}

ok(timelocal(0,0,1,1,0,90) - timelocal(0,0,0,1,0,90), 3600,
   'one hour difference between two calls to timelocal');

ok(timelocal(1,2,3,1,0,100) - timelocal(1,2,3,31,11,99), 24 * 3600,
   'one day difference between two calls to timelocal');

# Diff beween Jan 1, 1980 and Mar 1, 1980 = (31 + 29 = 60 days)
ok(timegm(0,0,0, 1, 2, 80) - timegm(0,0,0, 1, 0, 80), 60 * 24 * 3600,
   '60 day difference between two calls to timegm');

# bugid #19393
# At a DST transition, the clock skips forward, eg from 01:59:59 to
# 03:00:00. In this case, 02:00:00 is an invalid time, and should be
# treated like 03:00:00 rather than 01:00:00 - negative zone offsets used
# to do the latter
{
    my $hour = (localtime(timelocal(0, 0, 2, 7, 3, 102)))[2];
    # testers in US/Pacific should get 3,
    # other testers should get 2
    ok($hour == 2 || $hour == 3, 1, 'hour should be 2 or 3');
}

# round trip was broken for edge cases
ok(sprintf('%x', timegm(gmtime(0x7fffffff))), sprintf('%x', 0x7fffffff),
   '0x7fffffff round trip through gmtime then timegm');

ok(sprintf('%x', timelocal(localtime(0x7fffffff))), sprintf('%x', 0x7fffffff),
   '0x7fffffff round trip through localtime then timelocal');

{
    local $ENV{TZ} = 'Europe/Vienna';
    eval { require POSIX; POSIX::tzset() };

    if ($@) {
        skip(1, "cannot set time zone to Europe/Vienna") for 1..10;
    } else {
        my $time = 1004226198;
        for (1..20)
        {
            my $result = timelocal(localtime($time));
            ok($time - $result, 0,
               "round trip via localtime -> timelocal should always work ($time -> $result)");

            $result = timegm(gmtime($time));
            ok($time - $result, 0,
               "round trip via gmtime -> timegm should always work ($time -> $result)");

            $time += 300;
        }
    }
}

if ($ENV{PERL_CORE}) {
  package test;
  require 'timelocal.pl';
  ok(timegm(0,0,0,1,0,80), main::timegm(0,0,0,1,0,80),
     'timegm in timelocal.pl');

  ok(timelocal(1,2,3,4,5,88), main::timelocal(1,2,3,4,5,88),
     'timelocal in timelocal.pl');
}
