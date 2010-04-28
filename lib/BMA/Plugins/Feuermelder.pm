package BMA::Plugins::Feuermelder;

use strict;
use warnings;

use threads;
use threads::shared;

use Wx qw(:everything);
use Wx::Event qw(:everything);

use Win32::SerialPort;

my $port      = 'COM3';
my $baud      = 9600;
my $parity    = 'none';
my $data      = 2;
my $stop      = 1;
my $handshake = 'none';

sub new {
    bless {}, shift;
}

sub run {
    my ($self,$handler,$done_event,$text) = @_;

    my $conn = Win32::SerialPort->new( $port ) or die $^E;

    $conn->databits( $data );
    $conn->baudrate( $baud );
    $conn->parity( $parity );
    $conn->stopbits( $stop );

    my $counter = 1;

    my $is_alarm     = 0;
    my $is_resetable = 0;
    my $can_alarm    = 1;

    while ( 1 ) {
        my $char = $conn->lookfor;
        
        no warnings 'numeric';
        
        if ( defined $char and $char and int( $char ) == 1 ) {
            if ( !$is_alarm and $can_alarm ) {
                $is_alarm = 1;
                $can_alarm = 0;
    
                $$text = 'start_alarm';

                my $thread_event = Wx::PlThreadEvent->new(-1, $$done_event, $$text);
                Wx::PostEvent($handler, $thread_event);
            }
            if ( $is_resetable ) {
                print "Reset...\n";
                $is_alarm = 0;
                $is_resetable = 0;
            }
        }
        elsif ( defined $char and $char and int( $char ) == 0 and $is_alarm ) {
            $is_resetable = 1;
        }
        elsif ( defined $char and $char and int( $char ) == 0 and !$is_resetable and !$can_alarm ) {
            $can_alarm = 1;
        }
        
        $conn->lookclear;
    }
}

1;