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
	 {tim, [bbe,bdi]},
	]
