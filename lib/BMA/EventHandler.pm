package BMA::EventHandler;

=head1 NAME

BMA::EventHandler

=cut

use strict;
use warnings;

use BMA::Config;
use BMA;

use Log::Log4perl;
use Path::Class;

=head2 new

=cut

sub new {
    my ($class, %args) = @_;
    
    my $self = bless {}, $class;
    
    $self->_init( %args );
    
    return $self;
}

=head2 run

=cut

sub run {
    my ($self, %args) = @_;
    
    my $event = $args{event} || 'none';
    
    my $logger = Log::Log4perl->get_logger;
    $logger->debug( "run plugins for event $event" );
    
    for my $plugin ( $self->plugins( $event ) ) {
        my $file = $plugin->{file};
        
        eval {
        
            $logger->debug( "require $file" );
        
            require $file;
        
            my $object = $plugin->{package}->new(
                %{$plugin},
                logger => $logger,
                BMA    => $args{BMA},
            );
            $object->run( %args );
            1;
        } or $logger->debug( "Could not load $file: $@" );
    }
}

=head2 plugins

=cut

sub plugins {
    my ($self,$event) = @_;
    
    my @plugins = $self->{__BMA}->plugins->get_type( 'output', 1 );
    @plugins = grep{ 
        '|' . $_->{event} . '|' =~ /\|\Q$event\E\|/
    }@plugins;
    
    return @plugins;
}

sub _init {
    my ($self,%args) = @_;
    
    for my $key ( keys %args ) {
        $self->{'__' . $key} = $args{$key};
    }
}

1;