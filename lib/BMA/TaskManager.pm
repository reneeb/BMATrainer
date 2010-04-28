package BMA::TaskManager;

=pod

=head1 NAME

BMA::TaskManager - Task Scheduler for input plugins in the BMA-Trainer

=head1 SYNOPSIS

  require BMA::Task::Foo;
  my $task = Padre::Task::Foo->new(some => 'data');
  $task->schedule; # handed off to the task manager

=head1 DESCRIPTION

BMA-Trainer uses threads for asynchronous background operations
which may take so long that they would make the GUI unresponsive
if run in the main (GUI) thread.

This class implements a pool of a configurable number of
re-usable worker threads. For each input plugin there is one thread
created

=head1 INTERFACE

=head2 Class Methods

=head3 C<new>

The constructor returns a C<BMA::TaskManager> object.
At the moment, C<BMA::TaskManager> is a singleton.
An object is instantiated when the trainer object is created.

Optional parameters:

=over 2

=item min_no_workers / max_no_workers

Set the minimum and maximum number of worker threads
to spawn. Default: 1 to 3

The first workers are spawned lazily: I.e. only when
the first task is being scheduled.

=item use_threads

Disable for profiling runs. In the degraded, thread-less mode,
all tasks are run in the main thread. Default: 1 (use threads)

=item reap_interval

The number of milliseconds to wait before checking for dead
worker threads. Default: 15000ms

=back

=cut

use 5.008;
use strict;
use warnings;

our $VERSION = '0.01';

# According to Wx docs,
# this MUST be loaded before Wx,
# so this also happens in the script.
use threads;
use threads::shared;
use Thread::Queue 2.11;

use Wx qw(:everything);

# This event is triggered by the worker thread main loop after
# finishing a task.
our $TASK_DONE_EVENT : shared = Wx::NewEventType;

# This event is triggered by a worker thread DURING ->run to incrementally
# communicate to the main thread over the life of a service.
our $SERVICE_POLL_EVENT : shared = Wx::NewEventType;

# Timer to reap dead workers every N milliseconds
our $REAP_TIMER;

# You can instantiate this class only once.
our $SINGLETON;

our $PULL_TEXT : shared = '';

# This is set in the worker threads only!
our $_main;

sub new {
    my ($class,%args) = @_;

    return $SINGLETON if defined $SINGLETON;

    my $self = $SINGLETON = bless {
        reap_interval  => 15000,
        workers       => [],
        task_queue    => undef,
        running_tasks => {},
        BMA           => $args{BMA},
    }, $class;

    Wx::Event::EVT_COMMAND(
        $self->{BMA}, -1,
        $SERVICE_POLL_EVENT,
        \&on_service_poll_event,
    );

    $self->{task_queue} = Thread::Queue->new;

    return $self;
}

=pod

=head2 Instance Methods

=head3 C<run_tasks>

starts one thread for each input plugin registered for the trainer.
After the thread was created, the method "run" of the plugin is called

=cut

sub run_tasks {
    my ($self, @plugins) = @_;
    
    for my $plugin ( @plugins ) {
        my $file = $plugin->{file};
        my $object;
        
        eval {
        
            require $file;
        
            $object = $plugin->{package}->new(
                %{$plugin},
            );
            
            1;
        } or next;
        
        my $sub = $plugin->{package}->can( 'run' );
         
        my $task = threads->create(
            $sub, $object, $self->{BMA}, \$SERVICE_POLL_EVENT, \$PULL_TEXT
        );
        
        push @{ $self->{workers} }, $task;
    }

    return 1;
}

sub on_service_poll_event {
    my ($self) = @_;
    my $sub = $self->can( $PULL_TEXT );
    
    $self->$sub() if $sub;
}

sub DESTROY {
    my ($self) = @_;
    
    for my $task ( @{ $self->{workers} } ) {
        $task->join;
    }
}

1;
