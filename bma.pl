#!/usr/bin/perl

use strict;
use warnings;

use threads;
use threads::shared;

use lib qw(lib);
use BMA;

my $bma = BMA->new;

$bma->MainLoop;

1;
