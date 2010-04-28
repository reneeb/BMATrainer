package BMA::Plugins;

use strict;
use warnings;

use BMA::Config;

use Path::Class;

sub new {
    my ($class,%args) = @_;
    
    my $self = bless {}, $class;
    $self->_init( %args );
    
    return $self;
}

sub get_type {
    my ($self,$type,$active) = @_;
    
    my @plugins = @{ $self->{$type} };
    
    if ( $active ) {
        @plugins = grep{ $_->{active} }@plugins;
    }
    
    return @plugins;
}

=head2 _init

=cut

sub _init {
    my ($self, %args) = @_;
    
    my $config_file = Path::Class::File->new(
        $args{directory},
        'plugins.yml',
    );
    
    my $config = BMA::Config->new( $config_file->absolute->stringify );
    
    my $plugins = $config->get( 'plugins' );
    
    for my $plugin ( @{$plugins} ) {
        $plugin->{package} = 'BMA::Plugins::' .  $plugin->{module};
        my $file = $plugin->{package} . '.pm';
        $file =~ s{ :: }{/}gxms;
        
        $plugin->{file} = $file;
        
        push @{ $self->{ $plugin->{type} } }, $plugin;
    }
}

1;