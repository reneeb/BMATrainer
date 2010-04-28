package BMA::Plugins::Sirene;

use strict;
use warnings;

use Data::Dumper;
use Path::Class::Dir;
use Win32::Sound;

use base qw/Class::Accessor/;

__PACKAGE__->mk_accessors( 
    qw/
        sound_file logger
    /
);

sub new {
    my ($class, %args) = @_;
    
    my $self = bless {}, $class;
    
    for my $key ( keys %args ){
        my $sub = $self->can( $key );
        next unless $sub;
        
        my $value = $self->$sub();
        next if $value;
        
        if ( $key eq 'sound_file' ) {
            my $base = Path::Class::Dir->new(
                $args{BMA}->directory,
                '..',
            )->stringify;
            $args{$key} =~ s{ ^\$BASE }{$base}x;
        }
        
        $self->$sub( $args{$key} );
    }
    return $self;
}

sub run {
    my ($self,%args) = @_;
    
    return unless $args{event};
    
    if ( $args{event} eq 'AlarmStart' ) {
        $self->logger->debug( 'starte alarm' );
        $self->start_sound;
    }
    elsif ( $args{event} eq 'SoundOff' ) {
        $self->logger->debug( 'schalte alarm aus!' );
        $self->stop_sound;
    }
}

sub start_sound {
    my ($self) = @_;
    
    Win32::Sound::Volume( '100%' );
    Win32::Sound::Play( $self->sound_file, SND_ASYNC );
}

sub stop_sound {
    Win32::Sound::Stop();
}

1;