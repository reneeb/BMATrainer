package BMA::Bedienfeld;

use strict;
use warnings;

use Wx qw(:everything);
use Wx::Event qw(:everything);


sub create {
    my ($class, $parent, $size) = @_;
    
    my $panel = Wx::Panel->new( $parent, wxID_ANY, wxDefaultPosition, $size, 0 );
    my $black = Wx::Colour->new( '#000000' );
    $panel->SetBackgroundColour( $black );
    
    my $self  = bless {}, $class;
    my $sizer = $self->sizer;
    
    #my $browser  = $self->_browser( $parent, $size );
    $sizer->Add( $panel, wxID_ANY, wxEXPAND|wxGROW|wxALL, 0 );
    
    #$panel->SetSizer( $sizer );
    #$panel->SetAutoLayout( 1 );
    
    return $self;
}

sub sizer {
    my ($self) = @_;
    
    unless( $self->{sizer} ){
        $self->{sizer} = Wx::BoxSizer->new( wxVERTICAL );
    }

    $self->{sizer};
}

1;