package BMA::Szenario;

use strict;
use warnings;
use Spreadsheet::ParseExcel;

sub new {
    my ($class,$file,$app) = @_;
    
    # create new object and set attributes
    my $self = bless {}, $class;
    $self->file( $file );
    $self->app( $app );
    
    return $self;
}

sub file {
    my ($self,$file) = @_;
    
    # save value for file
    $self->{file} = $file if @_ == 2;
    return $self->{file};
}

sub app {
    my ($self,$app) = @_;
    
    # save value for app
    $self->{app} = $app if @_ == 2;
    return $self->{app};
}

sub messages {
    my ($self) = @_;
    
    # if the file is not parsed yet, parse it
    unless ( $self->{messages} ) {
        $self->{messages} = $self->_parse;
    }
    
    # return the messages
    return @{ $self->{messages} || [] };
}

sub _parse {
    my ($self) = @_;
    
    # file has to exist
    unless ( -e $self->file and -f $self->file ) {
        $self->app->logger->info( 'Szenario-Datei ' . $self->file . ' existiert nicht' );
        return [];
    }
    
    # parse the szenario file
    my $parser = Spreadsheet::ParseExcel->new;
    my $book   = $parser->Parse( $self->file );
    
    # get first worksheet
    my $sheet  = $book->worksheet(0);
    
    # get start and end row
    my ($min,$max) = $sheet->row_range;
    
    # get all messages
    my @messages;
    ROW:
    for my $row ( $min .. $max ) {
        
        # first line are the headers
        next ROW if $row == $min;
        
        # text is in first column, timer in second column
        my $text = $sheet->get_cell( $row, 0 );
        my $time = $sheet->get_cell( $row, 1 );
        
        # save messages
        push @messages, { text => $text->value, time => $time->value };
    }
    
    # return the messages
    return \@messages;
}
    

1;

=head1 NAME

BMA::Szenario - parse messages from xls file

=head1 SYNOPSIS

=head1 AUTHOR AND LICENSE

Copyright (c) 2009 - Renee Baecker

E<lt>module@renee-baecker.deE<gt>

=cut