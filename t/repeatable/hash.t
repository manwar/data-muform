
use strict;
use warnings;
use Test::More;

{
    package MyApp::Form::RepHash;
    use Moo;
    use Data::MuForm::Meta;
    extends 'Data::MuForm';

    has_field 'lookup' => (
      type => 'Repeatable',
      transform_default_to_value => *inflate_default,
      transform_value_after_validate => *deflate_value,
    );
    has_field 'lookup.key';
    has_field 'lookup.value';

    sub inflate_default {
      my ($self, $value) = @_;
      # convert hash to array of hashes
      # { k1 => v1, k2 => v2 } becomes
      #   [ { key => k1, value => v1 }, { key => k2, value => v2 } ]
      return [map +{key => $_, value => $value->{$_}}, sort keys %$value];
    }

    sub deflate_value {
      my ($self, $value) = @_;
      # convert array of hashes to hash
      # [ { key => k1, value => v1 }, { key => k2, value => v2 } ] becomes
      #   { k1 => v1, k2 => v2 }
      return { map { ($_->{'key'} => $_->{'value'}) } @$value };
    }

}

my $form = MyApp::Form::RepHash->new;
ok( $form );
my $model = {
  'lookup' => {
    'k1' => 'v1',
    'k2' => 'v2',
  }
};
my $params = {
  'lookup.0.key'   => 'k1',
  'lookup.0.value' => 'v1',
  'lookup.1.key'   => 'k2',
  'lookup.1.value' => 'v2',
};
my $inflated = {
  'lookup' => [
    { key => 'k1', value => 'v1' },
    { key => 'k2', value => 'v2' },
  ],
};

{
  $form->process(model => $model);
  my $fif = $form->fif;
  my $value = $form->value;
  is_deeply( $fif, $params, 'fif is correct' );
  is_deeply( $value, $inflated, 'value from model is correct' );
}

{
  $form->process(params => $params);
  my $value = $form->value;
  is_deeply( $value, $model, 'value from params is correct' );
}

done_testing;
