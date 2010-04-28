package BMA::Actions;

use strict;
use warnings;
use parent 'Exporter';

use Wx qw(:everything);
use Wx::Event qw(:everything);

our @EXPORT_OK = qw(
    change_message
    display_message
    start_alarm
    reset_bmz
);

our %EXPORT_TAGS = (
    all => [ @EXPORT_OK ],
);

sub display_message {
    my ($self,$message,$timer) = @_;
    
    my @timeinfo = localtime;
    my $time = sprintf "%02d.%02d.%04d %02d:%02d:%02d",
        $timeinfo[3],
        $timeinfo[4]+1,
        $timeinfo[5]+1900,
        reverse @timeinfo[0..2];
    
    unless( $self->{first_message_set} ) {
        $self->{first_message_set} = 1;
        
        my ($first_line1,$first_line2) = $self->get_label( 'first' );
        $first_line1->SetLabel( $message->{text} );
        $first_line2->SetLabel( $time );
    }
    
    $self->logger->warn( '110: ' . $message->{text} );
    
    my ($last_message_line1,$last_message_line2) = $self->get_label( 'last' );
    $last_message_line1->SetLabel( $message->{text} );
    $last_message_line2->SetLabel( $time );
    
    $self->message_push( { %{$message}, time => $time } );
    
    $timer->Stop;
}

sub change_message {
    my ($self, $type) = @_;
    
    return if not ( $self->{messages} and @{ $self->{messages} } );
    
    my $index = $self->{message_index} || 0;
    
    $index = $type eq 'up' ? --$index : ++$index;
    
    if ( $index > $#{ $self->{messages} } ) {
        $index = $#{ $self->{messages} };
    }
    elsif( $index < 0 ) {
        $index = 0;
    }
    
    my $message = $self->message_get( $index );
    $self->logger->warn( '120: Zeige Meldung ' . ( $index + 1 ) );
    
    $self->{message_index} = $index;
    
    my ($line1,$line2) = $self->get_label( 'first' );
    $line1->SetLabel( $message->{text} );
    $line2->SetLabel( $message->{time} );
}

sub reset_bmz {
    my ($self) = @_;
    
    $self->logger->warn( '102: Reset BMZ' );
    
    $self->event(
        event => 'ResetBMZ',
    );
    
    $self->set_led( 'tableau_alarm_lamp', 0 );
    $self->set_led( 'control_alarm',      0 );
}

sub start_alarm {
    my ($self) = @_;
    
    $self->logger->warn( '100: Start Alarm' );
    $self->message_reset;
    $self->event(
        event => 'StartAlarm',
    );
    
    $self->set_led( 'tableau_alarm_lamp', 1 );
    $self->set_led( 'control_alarm',      1 );
    
    my $szenario = BMA::Szenario->new( $self->szenario_file, $self );
    my $sum      = 0;
    for my $message ( $szenario->messages ) {
        
        my $timer = Wx::Timer->new( $self->{frame}, wxID_ANY );
        $sum     += $message->{time};
        
        $timer->Start( ( $sum * 1000 ) + 1, 1 );
        EVT_TIMER( $self->{frame}, $timer, sub{ $self->display_message( $message, $timer ) } );
    }
}

1;

=head1 NAME

BMA::Actions - all actions for BMA events

=head1 SYNOPSIS

    use BMA::Actions qw(:all);
    
    $self->change_message( 2 );