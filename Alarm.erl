-module(alarm).
-include_lib("eunit/include/eunit.hrl").
-comple(export_all).

%% 领域模型
% 1）	当产生loflom告警后，屏蔽掉ais、lck、tim、bbe、bdi告警；
% 2）	当产生ais告警后，屏蔽掉tim、bbe、bdi告警；
% 3）	当产生lck告警后，屏蔽掉tim、bbe、bdi告警；
% 4）	当产生tim告警后，屏蔽掉bbe、bdi告警。
pri_spec() ->
	[{loflom, [ais,lck,tim,bbe,bdi]},
	 {ais, [tim,bbe,bdi]},
	 {lck, [tim,bbe,bdi]},
	 {tim, [bbe,bdi]}
	].

% 1）	当产生loflom或者ais、lck、tim告警后，则产生aais告警；
% 2）	当产生bbe告警，并且没有产生bdi告警，则生成arei告警。
mt_spec() ->
	[{aais, {'OR', [loflom,ais,lck,tim]}},
	 {arei, {'AND', [bbe, {'NOT', bdi}]}}
	].

%% 驱动API
clear(Alm) ->
	put(Alm, true),
	io:format("clear(~p)~n", [Alm]).

set_oh(Alm, Value) ->
	OK.

%% 解析器
% [ais,lck,tim,bbe,bdi] [{loflom, 0}, {ais, 1}, {lck, 0}, {tim, 1}, {bbe, 1}, {bdi, 0}]
shieldalms(ShieldList, PL) ->
	lists:foldl(fun(Alm, Prod) -> 
			clear(Alm), lists:keyreplace(Alm, 1, Prod, {Alm, 0}) 
		 end, PL, ShieldList).
	

% loflom [{loflom, 0}, {ais, 1}, {lck, 0}, {tim, 1}, {bbe, 1}, {bdi, 0}]
find_val(Alm, PL) -> 
	{Alm, Value} = lists:keyfind(Alm, 1, PL),
	Value.


pri_proc([], PL) -> PL;
pri_proc([{Alm, ShieldList} | T], PL) -> 
	case find_val(Alm, PL) of
		1 -> NewPL = shieldalms(ShieldList, PL), pri_proc(T, NewPL);
		0 -> pri_proc(T, PL)
	end.

% {'OR', [loflom,ais,lck,tim]}
% {'AND', [bbe, {'NOT', bdi}]}
logic_val(X, PL) when is_atom(X) ->
	find_val(X, PL);
logic_val({'NOT', R}, PL) ->
	1- logic_val(R, PL);
logic_val({'AND', R}, PL) ->
	Vals = [logic_val(X, PL) || X <- R],
	case lists:member(0, Vals) of
	 	true -> 1;
	 	false -> 0
	end.

% {aais, {'OR', [loflom,ais,lck,tim]}}
mt_proc([], PL) -> PL;
mt_proc([{Alm, Rule} | T], PL) ->
	Value = logic_val(Rule, PL),
	set_oh(Alm, Value),
	mt_proc(T, PL).
	

%% 测试用例loflom = 0, ais = 1, lck =0, tim = 1, bbe = 1, bdi = 0
test_proc() ->
	PL = [{loflom, 0}, {ais, 1}, {lck, 0}, {tim, 1}, {bbe, 1}, {bdi, 0}],
	NewPL = pri_proc(pri_spec(), PL),
	ExpectPL = [{loflom, 0}, {ais, 1}, {lck, 0}, {tim, 0}, {bbe, 0}, {bdi, 0}],
	?assertEqual(ExpectPL, NewPL),
	?assertEqual(true, get(tim)),
	?assertEqual(true, get(bbe)),
	mt_proc(mt_spec(), NewPL).

test_logic_val() ->
	PL = [{loflom, 0}, {ais, 1}, {lck, 0}, {tim, 1}, {bbe, 1}, {bdi, 0}],
	?assertEqual(0, logic_val({'AND',[bbe, bdi]}, PL)),
	?assertEqual(1, logic_val({'AND',[bbe, {'NOT', bdi}]}, PL)).