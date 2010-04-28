package BMA::ContextMenu;

use strict;
use warnings;

use Wx qw(:everything);
use Wx::Event qw(:everything);

use Path::Class;
use File::Basename;

our @ISA = qw(Wx::Menu);

sub new {
    my ($class,$app) = @_;
    
    my $self = $class->SUPER::new();
    
    # build menu
    my $start_alarm = Wx::MenuItem->new( $self, wxID_ANY, 'Starte Alarm', '', wxITEM_NORMAL );
    $self->Append( $start_alarm );
    
    my $set_szenario = Wx::MenuItem->new( 
        $self, wxID_ANY, 'Setze Szenario-Datei...', '', wxITEM_NORMAL,
    );
    $self->Append( $set_szenario );
    
    # set event handler
    EVT_MENU( $app, $start_alarm, sub { $app->start_alarm() } );
    EVT_MENU( $app, $set_szenario, sub {
        
        my $path       = Path::Class::Dir->new(
            dirname( __FILE__ ),
        );
        
        my ($file) = Wx::FileSelector(
            $app->{frame}, 
            wxID_ANY,
            $path->absolute->stringify,
            'Szenario-Datei setzen',
            'Excel-Spreadsheets (*.xls) | *.xls',
        );
        
        $app->szenario_file( $file ) if $file;
    } );
    
    return $self;
}

1;

=head1 NAME

BMA::ContextMenu - the hidden menu in BMA training

=head1 SYNOPSIS

    my $contextmenu = BMA::ContextMenu->new( $main_class );
    $mainwindow->PopupMenu( $contextmenu, [20,20] );

=head1 AUTHOR AND LICENSE

Copyright (c) 2009 - Renee Baecker

=cut