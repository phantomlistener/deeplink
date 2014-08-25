#!/usr/bin/perl

use strict;
use Data::Dumper;
use ListMgr;
use Test::More tests => 9;


my $node_idx = {
	r => [0, 6],
	h => [1, 2],
	b => [3, 5],
	c => [4, 4],
};

my $lm = ListMgr->new($node_idx);

is_deeply($lm->indexes(), [0, 1, 2, 3, 4, 5, 6], 'original list');
is_deeply($lm->indexes_inst(), [0, 1, 2, 3, 4, 5, 6], 'instance list before change');

$lm->repeat('b');

is_deeply(
	$lm->indexes_inst(),
	[0, 1, 2, 3, 4, 5, 3, 4, 5, 6],
	'after repeat b'
);

is_deeply(
	$lm->node_idx_inst(),
	{r => [0, 9], h => [1, 2], b => [6, 8], c => [7, 7] },
	'index update after repeat b'
);

$lm->repeat('c');

is_deeply(
	$lm->indexes_inst(),
	[0, 1, 2, 3, 4, 5, 3, 4, 4, 5, 6],
	'after repeat c'
);

is_deeply(
	$lm->node_idx_inst(),
	{r => [0, 10], h => [1, 2], b => [6, 9], c => [8, 8] },
	'index update after repeat c'
);

$lm->repeat('h');

is_deeply(
	$lm->indexes_inst(),
	[0, 1, 2, 1, 2, 3, 4, 5, 3, 4, 4, 5, 6],
	'after repeat h'
);

is_deeply(
	$lm->node_idx_inst(),
	{r => [0, 12], h => [3, 4], b => [8, 11], c => [10, 10] },
	'index update after repeat h'
);

$lm->repeat('b');

is_deeply(
	$lm->indexes_inst(),
	[0, 1, 2, 1, 2, 3, 4, 5, 3, 4, 4, 5, 3, 4, 5, 6],
	'after another repeat b'
);

is_deeply(
	$lm->node_idx_inst(),
	{r => [0, 15], h => [3, 4], b => [11, 14], c => [13, 13]},
	'index update after repeat b'
);

