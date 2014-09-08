package Math::Util::CalculatedValue;

use 5.006;
use strict;
use warnings FATAL => 'all';

use Carp qw(confess);
use List::Util qw(min max);

=head1 NAME

Math::Util::CalculatedValue

=head1 VERSION

Version 0.01

=head1 DESCRIPTION

Represents an adjustment to a value (which can contain additional adjustments).

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    my $tid = Math::Util::CalculatedValue->new({
        name        => 'time_in_days',
        description => 'Duration in days',
        set_by      => 'Contract',
        base_amount => 0,
    });

    my $tiy = Math::Util::CalculatedValue->new({
        name        => 'time_in_years',
        description => 'Duration in years',
        set_by      => 'Contract',
        base_amount => 1,
    });

    my $dpy = Math::Util::CalculatedValue->new({
        name        => 'days_per_year',
        description => 'days in a year',
        set_by      => 'Contract',
        base_amount => 365,
    });

    $tid->include_adjustment('reset', $tiy);
    $tid->include_adjustment('multiply', $dpy);

    print $tid->amount;

=head1 ATTRIBUTES

=head2 name

This is the name of the operation which called this module

=cut

sub name {
    my ($self) = @_;
    return $self->{'name'};
}

=head2 description

This is the description of the operation which called this module

=cut

sub description {
    my ($self) = @_;
    return $self->{'description'};
}

=head2 set_by

This is the name of the module which called this module

=cut

sub set_by {
    my ($self) = @_;
    return $self->{'set_by'};
}

=head2 base_amount

This is the base amount on which the adjustments are to be made

=cut

sub base_amount {
    my ($self) = @_;
    return $self->{'base_amount'} || 0;
}

=head2 metadata

Additional information that you wish to include.

=cut

sub metadata {
    my ($self) = @_;
    return $self->{'metadata'};
}

=head2 minimum

The minimum value for amount

=cut

sub minimum {
    my ($self) = @_;
    return $self->{'minimum'};
}

=head2 maximum

The maximum value for amount

=cut

sub maximum {
    my ($self) = @_;
    return $self->{'maximum'};
}

my %available_adjustments = (
    'add'       => sub { my ( $this, $prev ) = @_; return $prev + $this->amount; },
    'multiply'  => sub { my ( $this, $prev ) = @_; return $prev * $this->amount; },
    'subtract'  => sub { my ( $this, $prev ) = @_; return $prev - $this->amount; },
    'divide'    => sub { my ( $this, $prev ) = @_; return $prev / $this->amount; },
    'reset'     => sub { my ( $this, $prev ) = @_; return $this->amount; },
    'exp'       => sub { my ( $this, $prev ) = @_; return exp( $this->amount ); },
    'log'       => sub { my ( $this, $prev ) = @_; return log( $this->amount ); },
    'info'      => sub { my ( $this, $prev ) = @_; return $prev; },
    'absolute'  => sub { my ( $this, $prev ) = @_; return abs( $this->amount ); },
);

=head1 Methods

=head2 new

New instance method

=cut

sub new {
    my $class = shift;
    my %params_ref = ref( $_[0] ) ? %{ $_[0] } : @_;

    foreach my $required ( 'name', 'description', 'set_by' ) {
        confess "missing required $required parameter"
          unless $params_ref{$required};
    }

    my $self    = \%params_ref;
    my $minimum = $self->{'minimum'};
    my $maximum = $self->{'maximum'};

    confess
      "Provided maximum [$maximum] is less than the provided minimum [$minimum]"
      if (  defined $minimum
        and defined $maximum
        and $maximum < $minimum );
    $self->{validation_methods} = [qw(_validate_all_sub_adjustments)];

    my $obj = bless $self, $class;
    return $obj;
}

=head2 amount

This is the final amount from this object, after applying all adjustments.

=cut

sub amount {
    my $self = shift;

    my $value = $self->_verified_cached_value;
    if ( not defined $value ) {
        $value = $self->_apply_all_adjustments;
        my $min = $self->{'minimum'};
        $value = max( $min, $value ) if ( defined $min );
        my $max = $self->{'maximum'};
        $value = min( $max, $value ) if ( defined $max );

        $self->{_cached_amount} = $value;
    }

    return $value;
}

=head2 adjustments

The ordered adjustments (if any) applied to arrive at the final value.

=cut

sub adjustments {
    my ($self) = @_;
    return $self->{'_adjustments'} || [];
}

=head2 include_adjustment

Creates the ordered adjustments as per the operation.

=cut

sub include_adjustment {
    my ( $self, $operation, $adjustment ) = @_;

    confess 'Operation [' . $operation . '] is not supported by ' . __PACKAGE__
      unless ( $available_adjustments{$operation} );
    my $adj_type = ref $adjustment;
    confess 'Supplied adjustment must be of type '
      . __PACKAGE__
      . ' got ['
      . $adj_type . ']'
      unless ( $adj_type eq __PACKAGE__ );

    delete $self->{_cached_amount};
    my $adjustments = $self->{'_adjustments'} || [];
    push @{$adjustments}, [ $operation, $adjustment ];
    $self->{'_adjustments'} = $adjustments;
}

=head2 exclude_adjustment

Remove an adjustment by name.  Returns the number of instances found and excluded.

Excluded items are changed into 'info' so that that still show up but are do not alter the parent value

THis can be extremely dangerous, so make sure you know where and why you are doing it.

=cut

sub exclude_adjustment {
    my ( $self, $adj_name ) = @_;

    my $excluded = 0;

    foreach my $sub_adj ( @{ $self->adjustments } ) {
        my $obj = $sub_adj->[1];
        $excluded += $obj->exclude_adjustment($adj_name);
        if ( $obj->name eq $adj_name ) {
            $sub_adj->[0] = 'info';
            $excluded++;
        }
    }

    delete $self->{_cached_amount} if ($excluded);

    return $excluded;
}

=head2 replace_adjustment

Replace all instances of the same named adjustment with the provided adjustment

Returns the number of instances replaced.

=cut

sub replace_adjustment {
    my ( $self, $replacement ) = @_;

    confess 'Replacement is not a CalculatedValue'
      unless ( ( ref $replacement ) =~ /Math::Util::CalculatedValue/ );

    my $replaced = 0;

    foreach my $sub_adj ( @{ $self->adjustments } ) {
        my $obj = $sub_adj->[1];
        $replaced += $obj->replace_adjustment($replacement)
          if ( $obj != $replacement );
        if ( $obj->name eq $replacement->name ) {
            $sub_adj->[1] = $replacement;
            $replaced++;
        }
    }

    delete $self->{_cached_amount} if ($replaced);

    return $replaced;
}

# Loops through the ordered adjustments and performs the operation/adjustment
sub _apply_all_adjustments {
    my ($self) = @_;
    my $value       = $self->{'base_amount'}  || 0;
    my $adjustments = $self->{'_adjustments'} || [];
    foreach my $adjustment ( @{$adjustments} ) {
        $value =
          $available_adjustments{ $adjustment->[0] }
          ->( $adjustment->[1], $value );
    }
    return $value;
}

sub _verified_cached_value {
    my ($self) = @_;
    my $can;
    if ( exists $self->{_cached_amount} ) {
        $can = $self->{_cached_amount};
        my $adjustments = $self->{'_adjustments'} || [];
        foreach my $adjustment ( @{$adjustments} ) {
            if ( not defined $adjustment->[-1]->_verified_cached_value ) {
                delete $self->{_cached_amount};
                $can = undef;
                last;
            }
        }
    }
    return $can;
}

=head2 peek

Peek at an included adjustment by name.

=cut

sub peek {
    my ( $self, $adj_name ) = @_;

    my $picked;

    if ( $self->name eq $adj_name ) {
        $picked = $self;
    }
    else {
# Depth first traversal.  We assume that if there are two things named the same
# in any given CV that they are, in fact, the same value.  So we can just return the first one we find.
        my $adjustments = $self->{'_adjustments'} || [];
        foreach my $sub_adj ( @{$adjustments} ) {
            my $obj = $sub_adj->[1];
            $picked = $obj->peek($adj_name);
            last if $picked;
        }
    }

    return $picked;
}

=head2 peek_amount

Peek at the value of an included adjustment by name.

=cut

sub peek_amount {
    my ( $self, $adj_name ) = @_;
    my $adj = $self->peek($adj_name);
    return ($adj) ? $adj->amount : undef;
}

=head1 AUTHOR

binary.com, C<< <rakesh at binary.com> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-math-util-calculatedvalue at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Math-Util-CalculatedValue>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.


=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc Math::Util::CalculatedValue


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker (report bugs here)

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=Math-Util-CalculatedValue>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/Math-Util-CalculatedValue>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/Math-Util-CalculatedValue>

=item * Search CPAN

L<http://search.cpan.org/dist/Math-Util-CalculatedValue/>

=back


=head1 ACKNOWLEDGEMENTS


=head1 LICENSE AND COPYRIGHT

Copyright 2014 binary.com.

This program is free software; you can redistribute it and/or modify it
under the terms of the the Artistic License (2.0). You may obtain a
copy of the full license at:

L<http://www.perlfoundation.org/artistic_license_2_0>

Any use, modification, and distribution of the Standard or Modified
Versions is governed by this Artistic License. By using, modifying or
distributing the Package, you accept this license. Do not use, modify,
or distribute the Package, if you do not accept this license.

If your Modified Version has been derived from a Modified Version made
by someone other than you, you are nevertheless required to ensure that
your Modified Version complies with the requirements of this license.

This license does not grant you the right to use any trademark, service
mark, tradename, or logo of the Copyright Holder.

This license includes the non-exclusive, worldwide, free-of-charge
patent license to make, have made, use, offer to sell, sell, import and
otherwise transfer the Package with respect to any patent claims
licensable by the Copyright Holder that are necessarily infringed by the
Package. If you institute patent litigation (including a cross-claim or
counterclaim) against any party alleging that the Package constitutes
direct or contributory patent infringement, then this Artistic License
to you shall terminate on the date that such litigation is filed.

Disclaimer of Warranty: THE PACKAGE IS PROVIDED BY THE COPYRIGHT HOLDER
AND CONTRIBUTORS "AS IS' AND WITHOUT ANY EXPRESS OR IMPLIED WARRANTIES.
THE IMPLIED WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR
PURPOSE, OR NON-INFRINGEMENT ARE DISCLAIMED TO THE EXTENT PERMITTED BY
YOUR LOCAL LAW. UNLESS REQUIRED BY LAW, NO COPYRIGHT HOLDER OR
CONTRIBUTOR WILL BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, OR
CONSEQUENTIAL DAMAGES ARISING IN ANY WAY OUT OF THE USE OF THE PACKAGE,
EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.


=cut

1;    # End of Math::Util::CalculatedValue
