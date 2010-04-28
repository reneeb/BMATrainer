package BMA::Config;

use strict;
use warnings;

use Carp;
use YAML::Tiny;

our $VERSION = 0.01;

sub new{
    my ($class,$file) = @_;
    
    my $self = {};
    bless $self,$class;
    
    $self->load( $file ) if defined $file;
    return $self;
}

sub load{
    my ($self,$file) = @_;
    croak "no config file given" unless defined $file;
    $self->{_config} = YAML::Tiny->read( $file )->[0] or undef;
    return $self->{_config};
}


sub get {
    my ($self,$key) = @_;

    my $return = $self->{_config};

    if( @_ == 2 ){
        my @level  = split /\./, $key;

        for my $subkey ( @level ){
            $return = $return->{$subkey};
        }
    }

    return $return;
}

1;