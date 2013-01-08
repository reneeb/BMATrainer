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
    change_display_level
    show_history
    turn_off_audio
    turn_off_local_alarm
    turn_off_bma
    start_local_alarm
    check_bma
    _bma_is_off
);

our %EXPORT_TAGS = (
    all => [ @EXPORT_OK ],
);

sub _bma_is_off {
    my ($self) = @_;

    return 1 if $self->{bma_off};
}

sub turn_off_bma {
    my ($self) = @_;

    my $new_value = $self->{bma_off} ^ 1;

    $self->set_led( 'tableau_off_lamp', $new_value );
    $self->set_led( 'control_off',      $new_value );
    $self->{bma_off} = $new_value;
}

sub check_bma {
    my ($self) = @_;

    $self->event(
        event => 'CheckBMA',
    );
    
    $self->set_led( 'tableau_alarm_lamp', 1 );
    $self->set_led( 'control_alarm',      1 );
}

sub turn_off_local_alarm {
    my ($self) = @_;

    $self->event(
        event => 'StopLocalAlarm',
    );
    
    $self->{stop_local_alarm} = 1;
}

sub start_local_alarm {
    my ($self) = @_;

    $self->event(
        event => 'StartLocalAlarm',
    );
    
    my $sleep = 0.5;

    while ( !$self->{stop_local_alarm} ) {
        $self->logger->debug( 'beep' );
        my $timer = Wx::Timer->new( $self->{frame}, wxID_ANY );
        $timer->Start( ( $sleep * 1000 ) + 1, 1 );
        EVT_TIMER( $self->{frame}, $timer, sub{ print "\a" } );
        select undef, undef, undef, $sleep;
    }

    $self->{stop_local_alarm} = 0;
}

sub turn_off_audio {
    my ($self) = @_;

    $self->event(
        event => 'TurnOffGlobalAlarm',
    );
}

sub change_display_level {
    my ($self) = @_;

    $self->event(
        event => 'ChangeDisplayLevel',
    );
}

sub show_history {
    my ($self) = @_;

    $self->event(
        event => 'ShowHistory',
    );
    
}

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
    $self->set_led( 'control_bmz',        1 );

    # reset displayed messages
    my ($line1,$line2) = $self->get_label( 'first' );
    $line1->SetLabel( '' );
    $line2->SetLabel( '' );
    my ($last1,$last2) = $self->get_label( 'last' );
    $last1->SetLabel( '' );
    $last2->SetLabel( '' );

    # the control led will be reset after 15 minutes
    # and the history will be deleted
    my $timer = Wx::Timer->new( $self->{frame}, wxID_ANY );
    my $wait  = 15 * 60 * 1000;
    $timer->Start( $wait + 1, 1 );
    EVT_TIMER( $self->{frame}, $timer, sub{ $self->{messages} = []; $self->set_led( 'control_bmz', 0 ); } );
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
