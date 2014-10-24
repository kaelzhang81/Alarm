-module(alarm).
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
