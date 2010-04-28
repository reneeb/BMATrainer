package BMA::Plugins::Counter;

use strict;
use warnings;

use threads;
use threads::shared;

use Wx qw(:everything);
use Wx::Event qw(:everything);

sub new {
    bless {}, shift;
}

sub run {
    my ($self,$handler,$done_event,$text) = @_;
    sleep 5;
    
    $$text = 'start_alarm';

    my $thread_event = Wx::PlThreadEvent->new(-1, $$done_event, $$text);
    Wx::PostEvent($handler, $thread_event);
}

1;