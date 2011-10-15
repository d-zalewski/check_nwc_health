package NWC::Cisco::Component::SupplySubsystem;
our @ISA = qw(NWC::Cisco::Component::EnvironmentalSubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    supplies => [],
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  $self->init(%params);
  return $self;
}

sub init {
  my $self = shift;
  foreach ($self->get_snmp_table_objects(
      'CISCO-ENVMON-MIB', 'ciscoEnvMonFanStatusTable')) {
    push(@{$self->{supplies}},
        NWC::Cisco::Component::SupplySubsystem::Supply->new(%{$_}));
  }
}

sub check {
  my $self = shift;
  my $errorfound = 0;
  $self->add_info('checking supplies');
  $self->blacklist('ps', '');
  if (scalar (@{$self->{supplies}}) == 0) {
  } else {
    foreach (@{$self->{supplies}}) {
      $_->check();
    }
  }
}


sub dump {
  my $self = shift;
  foreach (@{$self->{supplies}}) {
    $_->dump();
  }
}


package NWC::Cisco::Component::SupplySubsystem::Supply;
our @ISA = qw(NWC::Cisco::Component::SupplySubsystem);

use strict;
use constant { OK => 0, WARNING => 1, CRITICAL => 2, UNKNOWN => 3 };

sub new {
  my $class = shift;
  my %params = @_;
  my $self = {
    ciscoEnvMonSupplyStatusIndex => $params{ciscoEnvMonSupplyStatusIndex} || 0,
    ciscoEnvMonSupplyStatusDescr => $params{ciscoEnvMonSupplyStatusDescr},
    ciscoEnvMonSupplyState => $params{ciscoEnvMonSupplyState},
    ciscoEnvMonSupplySource => $params{ciscoEnvMonSupplySource},
    blacklisted => 0,
    info => undef,
    extendedinfo => undef,
  };
  bless $self, $class;
  return $self;
}

sub check {
  my $self = shift;
  $self->blacklist('f', $self->{ciscoEnvMonSupplyStatusIndex});
  $self->add_info(sprintf 'powersupply %d (%s) is %s',
      $self->{ciscoEnvMonSupplyStatusIndex},
      $self->{ciscoEnvMonSupplyStatusDescr},
      $self->{ciscoEnvMonSupplyState});
  if ($self->{ciscoEnvMonSupplyState} eq 'notPresent') {
  } elsif ($self->{ciscoEnvMonSupplyState} ne 'normal') {
    $self->add_message(CRITICAL, $self->{info});
  }
}

sub dump {
  my $self = shift;
  printf "[PS_%s]\n", $self->{ciscoEnvMonSupplyStatusIndex};
  foreach (qw(ciscoEnvMonSupplyStatusIndex ciscoEnvMonSupplyStatusDescr ciscoEnvMonSupplyState ciscoEnvMonSupplySource)) {
    printf "%s: %s\n", $_, $self->{$_};
  }
  printf "info: %s\n", $self->{info};
  printf "\n";
}
