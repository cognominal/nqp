sub hash(*%new) {
    %new
}

# Usually only a small number of keys are seen,
# so a bubble sort would be fine. However, the
# number can get much larger (e.g., when profiling
# a build of the Rakudo settings), so use a heapsort
# instead.  Note that this sorts in **reverse** order.
sub sorted_keys($hash) {
    my @keys := nqp::list_s();
    my $iter := nqp::iterator($hash);
    nqp::while(
      $iter,
      nqp::push_s(@keys,nqp::iterkey_s(nqp::shift($iter)))
    );

    sub sift_down(int $start, int $end) {
        my int $root := $start;
        my int $child;
        my int $swap;

        while 2*$root + 1 <= $end {
            $child := 2*$root + 1;
            $swap := nqp::atpos_s(@keys, $root) gt nqp::atpos_s(@keys, $child)
              ?? $child
              !! $root;

            $swap := $child + 1
              if $child + 1 <= $end
              && nqp::atpos_s(@keys, $swap) ge nqp::atpos_s(@keys, $child + 1);

            if $swap == $root { return }

            my str $tmp := nqp::atpos_s(@keys, $root);
            nqp::bindpos_s(@keys, $root, nqp::atpos_s(@keys, $swap));
            nqp::bindpos_s(@keys, $swap, $tmp);
            $root := $swap;
        }
    }

    my int $count := +@keys;
    if $count > 2 {
        my int $start := $count / 2;
        my int $end := $count - 1;
        while --$start >= 0 {
            sift_down($start, $end);
        }

        while $end {
            my str $swap := nqp::atpos_s(@keys, $end);
            nqp::bindpos_s(@keys, $end, nqp::atpos_s(@keys, 0));
            nqp::bindpos_s(@keys, 0, $swap);
            sift_down(0, --$end);
        }
    }
    elsif $count == 2 && nqp::atpos_s(@keys, 0) lt nqp::atpos_s(@keys, 1) {
        nqp::push_s(@keys, nqp::shift_s(@keys));
    }

    @keys
}

sub dd(*@_) {

    sub ddd($it) {

        if nqp::can($it, 'dump') {
            $it.dump;
        }
        elsif nqp::can($it, 'ast') {
            $it.ast;
        }
        elsif nqp::isstr($it) {
            CATCH { return ~$! }
            nqp::isnull_s($it)
              ?? ''
              !! ('"' ~ $it ~ '"')
        }
        elsif nqp::isint($it) || nqp::isnum($it) {
            ~$it;
        }
        elsif nqp::islist($it) {
            my @parts := nqp::list_s;

            for $it {
                nqp::push_s(@parts, ddd($_));
            }
            '[' ~ nqp::join(", ", @parts) ~ ']'
        }
        elsif nqp::ishash($it) {
            my @parts := nqp::list_s;

            my @keys  := sorted_keys($it);
            my int $i := nqp::elems(@keys);
            while --$i >= 0 {
                my $_ := nqp::atpos_s(@keys, $i);
                nqp::push_s(@parts, $_ ~ " => " ~ ddd($it{$_}));
            }
            '{' ~ nqp::join(", ", @parts) ~ '}'
        }
        elsif nqp::isconcrete($it) {
            CATCH { return $it.HOW.name($it) }
            nqp::can($it, 'gist')
                ?? $it.gist
                !! nqp::can($it, 'Str')
                    ?? $it.Str
                    !! ~$it
        }
        else {
            $it.HOW.name($it)
        }
    }

    my @result := nqp::list_s;
    for @_ { nqp::push_s(@result, ddd($_)) }
    note(nqp::join("\n", @result));
}
