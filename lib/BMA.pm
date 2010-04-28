package BMA;

use strict;
use warnings;

use threads;
use threads::shared;

use Wx qw(:everything);
use Wx::Event qw(:everything);
use Wx::XRC;

use Data::Dumper;
use File::Basename;
use Log::Log4perl;
use Path::Class;
use YAML::Tiny;

use BMA::Actions qw(:all);
use BMA::ContextMenu;
use BMA::EventHandler;
use BMA::TaskManager;
use BMA::Plugins;
use BMA::Szenario;

our @ISA = qw(Wx::App);

our $VERSION = '0.01';

sub OnInit {
    my ( $self ) = @_;
    
    # create new frame
    my( $frame ) = Wx::Frame->new( undef, -1, "BMA", [20,20], [1025,640] );
    $self->{frame} = $frame;
    
    Wx::InitAllImageHandlers();
    
    # red color
    my $bg = Wx::Colour->new( '#ff0000' );
    $frame->SetBackgroundColour( $bg );
    
    # set default szenario file
    my $szenario_file = Path::Class::File->new(
        $self->directory,
        'Szenario.xls',
    );
    $self->szenario_file( $szenario_file->absolute->stringify );
    
    # prepare logging
    my $logging_conf = Path::Class::File->new(
        $self->directory,
        'logging.conf',
    );
    Log::Log4perl->init_once( $logging_conf->absolute->stringify );
    
    # --
    # create threads for input plugins (that are active)
    # --
    my @input_plugins = $self->plugins->get_type( 'input', 1 );
    my $task_manager  = BMA::TaskManager->new(
        BMA => $self,
    );
    $task_manager->run_tasks(
        @input_plugins,
    );
    
    # --
    # handle XRC
    # --
    
    # the XRC handler for the tableau
    $self->logger->debug( 'load tableau.xrc' );
    my $tableau_xrc_file = Path::Class::File->new(
        $self->directory,
        'tableau.xrc',
    );
    my $tableau_xrc = Wx::XmlResource->new;
    $tableau_xrc->InitAllHandlers;
    $tableau_xrc->Load( $tableau_xrc_file->absolute->stringify );
    $self->{tableau_xrc} = $tableau_xrc;
    
    # the XRC handler for the control panel
    $self->logger->debug( 'load control_panel.xrc' );
    my $control_xrc_file = Path::Class::File->new(
        $self->directory,
        'control_panel.xrc',
    );
    my $control_xrc = Wx::XmlResource->new;
    $control_xrc->InitAllHandlers;
    $control_xrc->Load( $control_xrc_file->absolute->stringify );
    $self->{control_xrc} = $control_xrc;
    
    $self->plugins;
        
    # --
    # build UI
    # --
    
    # insert main window here        
    my $main_sizer    = Wx::GridBagSizer->new( 0, 2 );
    my $tableau       = $tableau_xrc->LoadPanel( $frame, 'MyPanel1' );
    my $control_panel = $control_xrc->LoadPanel( $frame, 'ControlPanel' );;
    
    $main_sizer->Add( $tableau, Wx::GBPosition->new( 0, 0 ),
                Wx::GBSpan->new(1,1), wxLEFT | wxALIGN_CENTER_VERTICAL , 2);
    $main_sizer->Add( $control_panel, Wx::GBPosition->new( 0, 1 ),
                Wx::GBSpan->new(1,1), wxLEFT | wxALIGN_CENTER_VERTICAL , 2);
    
    # --
    # show leds
    # --
    $self->set_led( 'tableau_operating_lamp', 1 );
    $self->set_led( 'tableau_alarm_lamp',     0 );
    $self->set_led( 'tableau_error_lamp',     0 );
    $self->set_led( 'tableau_off_lamp',       0 );
    $self->set_led( 'control_operating',      1 );
    $self->set_led( 'control_extinguisher',   0 );
    $self->set_led( 'control_audio',          0 );
    $self->set_led( 'control_off',            0 );
    $self->set_led( 'control_alarm',          0 );
    $self->set_led( 'control_firecontrol',    0 );
    $self->set_led( 'control_bmz',            0 );
    
    # --
    # handle events
    # --
    # hidden menu
    EVT_KEY_DOWN( $self, sub {
        my ($app,$event) = @_;
        
        # if key 'F4' is pressed
        if ( $event->GetKeyCode == 343 ) {
            my $contextmenu = BMA::ContextMenu->new( $app );
            $app->{frame}->PopupMenu( $contextmenu, [20,20] );
        }
    });
    
    # button events
    # tableau buttons
    my $up_button   = $self->get_element( 'tableau_upbutton' );
    my $down_button = $self->get_element( 'tableau_downbutton' );
    
    EVT_BUTTON( $self, $up_button, sub{ $self->change_message( 'up' ) } );
    EVT_BUTTON( $self, $down_button, sub{ $self->change_message( 'down' ) } );
    
    # reset bmz
    my $bmz_button = $self->get_element( 'control_btn_bmz' );
    EVT_BUTTON( $self, $bmz_button, sub{ $self->reset_bmz } );
    
    # add logging
    
    $frame->SetSizer( $main_sizer );
    $frame->SetAutoLayout(1);
    
    $frame->Show(1);
    
    1;
}

=head2 directory

This method returns the directory where all needed files are. The needed files
include the configuration for the lamps and the XRC files

=cut

sub directory {
    my ($self) = @_;
    
    unless( $self->{conf_directory} ) {
        # directory with all needed files
        $self->{conf_directory} = Path::Class::Dir->new(
            dirname( __FILE__ ),
            '..',
            'conf',
        );
    }
    
    return $self->{conf_directory};
}

=head2 event_handler

=cut

sub event_handler {
    my ($self) = @_;
    
    unless ( $self->{event_handler} ) {
        $self->{event_handler} = BMA::EventHandler->new(
            directory => $self->directory,
            BMA       => $self,
        );
    }
    
    return $self->{event_handler};
}

=head2 event

=cut

sub event {
    my ($self, %args) = @_;
    
    $self->event_handler->run(
        %args,
        BMA => $self,
    );
    
    return;
}

=head2 get_element

returns the object that represents the widget for the given name. The name is the
name specified in the XRC file

=cut

sub get_element {
    my ($self,$name) = @_;
    
    $self->logger->debug( 'get element: ' . $name );
    my $element = $self->{frame}->FindWindow(
        Wx::XmlResource::GetXRCID( $name )
    );
    
    return $element;
}

=head2 get_label

similar to get_element, but this is intended to return the two objects that
represent the two lines of the message display.

=cut

sub get_label {
    my ($self,$type) = @_;
    
    my $message_line1 = $self->{frame}->FindWindow(
        Wx::XmlResource::GetXRCID( 'tableau_' . $type . 'Message_line1' )
    );
    
    my $message_line2 = $self->{frame}->FindWindow(
        Wx::XmlResource::GetXRCID( 'tableau_' . $type . 'Message_line2' )
    );
    
    return ($message_line1, $message_line2);
}

=head2 set_lamp

switch the lamp on/off.

=cut

sub set_led {
    my ($self,$name,$on_off) = @_;
    
    $on_off ||= 0;
        
    my $led = $self->get_element( $name );
    
    if( $led ) {
        my ($led_file) = $self->led_conf( $name )->{$on_off};
        
        my $bitmap_file = Path::Class::File->new(
            $self->directory,
            '..',
            'img',
            $led_file,
        )->absolute->stringify;
                
        my $bitmap = Wx::Bitmap->new( $bitmap_file, wxBITMAP_TYPE_ANY );
        
        $led->SetBitmap( $bitmap );
    }
    
    return 1;
}

=head2 led_conf

=cut

sub led_conf {
    my ($self,$name) = @_;
    
    unless( $self->{lamp_conf} ) {
        my $lamp_conf_file = Path::Class::File->new(
            $self->directory,
            'lamps.yml',
        );
        
        my $yaml = YAML::Tiny->read( $lamp_conf_file->absolute->stringify );
        if ( $yaml ) {
            $self->{lamp_conf} = $yaml->[0];
        }
    }
    
    return $self->{lamp_conf}->{$name} || {};
}

=head2 message_get

=cut

sub plugins {
    my ($self) = @_;
    
    unless ( $self->{__plugins} ) {
        $self->{__plugins} = BMA::Plugins->new(
            directory => $self->directory,
        );
    }

    return $self->{__plugins};
}

=head2 message_push

=cut

sub message_push {
    my ($self,$message) = @_;
    
    push @{ $self->{messages} }, $message;
}

=head2 message_get

=cut

sub message_get {
    my ($self,$index) = @_;
    
    my $value = $self->{messages}->[$index];
    $value ||= {};

    return $value;
}

=head2 message_reset

=cut

sub message_reset {
    my ($self) = @_;
    
    $self->{messages} = [];
    1;
}

=head2 szenario_file

=cut

sub szenario_file {
    my ($self,$file) = @_;
    
    $self->{szenario} = $file if @_ == 2;
    return $self->{szenario};
}

=head2 logger

=cut

sub logger {
    my ($self) = @_;
    
    $self->{logger} = Log::Log4perl->get_logger unless $self->{logger};
    return $self->{logger};
}


1;