package Math::Util::CalculatedValue::Validatable;

use Moose;

use MooseX::NonMoose;
extends 'Math::Util::CalculatedValue';
with 'MooseX::Role::Validatable';

=head1 NAME

Math::Util::CalculatedValue::Validatable - math adjustment, which can containe another adjustments with validation

=head1 VERSION

Version 0.01

=head1 DESCRIPTION

Represents an adjustment to a value (which can contain additional adjustments) with validation.

=cut

our $VERSION = '0.01';

=head1 SYNOPSIS

    my $tid = Math::Util::CalculatedValue::Validatable->new({
        name        => 'time_in_days',
        description => 'Duration in days',
        set_by      => 'Contract',
        base_amount => 0,
    });

    my $tiy = Math::Util::CalculatedValue::Validatable->new({
        name        => 'time_in_years',
        description => 'Duration in years',
        set_by      => 'Contract',
        base_amount => 1,
    });

    my $dpy = Math::Util::CalculatedValue::Validatable->new({
        name        => 'days_per_year',
        description => 'days in a year',
        set_by      => 'Contract',
        base_amount => 365,
    });

    $tid->include_adjustment('reset', $tiy);
    $tid->include_adjustment('multiply', $dpy);

    print $tid->amount;


=head2 BUILD

Bulder args to add validation method

=cut

sub BUILD {
    my $self = shift;
    $self->{validation_methods} = [qw(_validate_all_sub_adjustments)];
    return;
}

sub _validate_all_sub_adjustments {
    my $self = shift;

    my @errors;
    foreach my $cv (map { $_->[1] } @{$self->adjustments}) {
        push @errors, $cv->all_errors unless ($cv->confirm_validity);
    }

    return @errors;
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

no Moose;

1;    # End of Math::Util::CalculatedValue::Validatable
