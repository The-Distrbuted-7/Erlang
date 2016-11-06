-module(emqtcc_minimal_project).

%% API exports
-export([start/0,init/0]).

start() ->
	%%check if the process is already spawned
	case whereis(sts) of
	  %%in case not
	  undefined -> 
	  %%spawn it and return the PID
	  Pid=spawn(emqtcc_minimal_project, init, []),
	  register(sts, Pid),
	  {ok, Pid};
	  %%in case it is already spawned just return the PID
	  _ -> 
	  {ok, whereis(sts)}
	end.

init()->
  %Connect to a broker
  {ok, C} = emqttc:start_link([{host, "localhost"},
  %Client_id
  {client_id, <<"GroMaster">>},
  {keepalive, 300},
  {connack_timeout, 60}]),
  %subscribe to all the sub topics with QOS 1
  emqttc:subscribe(C, <<"Gro/#">>, qos1),
  loop(dict_new(), C).
  
  
%Parse the request(JSon) which fullfil our RFC to erlang terms  
%@para MQTTmsg @return <<"client-id">>,<<"list-name">>,<<"add-delete">>,<<"{"item":"item1"}">>
decode(Message) ->  
try	
[{<<"client_id">>,_},
 {<<"list">>,_},
 {<<"request">>,_},
 {<<"data">>,[{<<"item">>,_}]}]
 = jsx:decode(Message)
 %%in case the message doesn't fullfil our RFC 
 catch error:E -> [{<<"client_id">>,error},{<<"list">>,error},
 {<<"request">>,error},
 {<<"data">>,[{<<"item">>,error}]}]
 end.
%loop to listen for requests and responde
%@para {dict,LIST}, MQTTCLIENT
loop(Dict,C) -> 
	receive 
		{publish ,Topic, Message} ->
			[{_,Client_id},{_,List},{_,Req},{_,[{_,Item}]}]  = decode(Message), io:format("~p~n",[Req]),
			%check whether it's add,del or fetch request
			case Req of 
				%% add the values, update the dict and reply to client (on the same topic)
				<<"add">> -> Updated_dict = add(Client_id,List,Dict,Topic,Item,C), loop(Updated_dict,C);
				%% delete the values, update the dict and reply to client (on the same topic)
				<<"delete">> -> Updated_dict = del(Client_id,List,Dict,Topic,Item,C), loop(Updated_dict,C);
				%% get the values, reply to client (on the same topic)
				<<"fetch">> -> Updated_dict = add(Client_id,List,Dict,Topic,Item,C), loop(Updated_dict,C);
				%% in case of a decode crash just loop again
				_ -> loop(Dict,C)
			end
	end.
% get the list of values in a form that fullfil the RFC	
encode_list(L) ->
		[[{<<"item">>,X}] || {X,X} <- L].
		
%% Explaination: the Master dict conatins keys of form {<<"client-id">>,<<"list-name">>} and the values 
%% are dictionaries with keys equal to the values i.e {dict,[{apple,apple}]}
 
%% add the item and reply to client
add(Client_id,List,Dict,Topic,Item,C) ->
	%% see if we have a dict with the key {<<Client_id>>,<<List>>}
	OldDict = dict_get(Dict,{Client_id,List}),
	case OldDict of 
		%case it's a new list or a new  client
		not_found -> %% do some magic 
					{New_Dict,_} = dict_put(dict_new(),Item,Item), {Updated,_} = dict_put(Dict,{Client_id,List},New_Dict), {dict,Listt} = New_Dict,
					 emqttc:publish(C, Topic, jsx:encode([{<<"reply">>,<<"done">>},{<<"data">>,encode_list(Listt)}])),
					 Updated;
		%%case we already have a dictionary for that list and client			 
		_ -> % do some more magic
			 {UpdatedChild,_} = dict_put(OldDict,Item,Item), {Updated,_} = dict_put(Dict,{Client_id,List},UpdatedChild), {dict,Listt} = UpdatedChild,
			 emqttc:publish(C, Topic, jsx:encode([{<<"reply">>,<<"done">>},{<<"data">>,encode_list(Listt)}])),
			 Updated
	end.
del(Client_id,List,Dict,Topic,Item,C) ->
	OldDict = dict_get(Dict,{Client_id,List}),
	case OldDict of 
		not_found -> Dict;
		_ -> UpdatedChild = dict_del(OldDict,Item,[]), {Updated,_} = dict_put(Dict,{Client_id,List},UpdatedChild), {dict,Listt} = UpdatedChild,
			 emqttc:publish(C, Topic, jsx:encode([{<<"reply">>,<<"done">>},{<<"data">>,encode_list(Listt)}])),
			 Updated
	end.
fetch(Dict,To) ->
	to_implement.
%%Tmp functions used for offline storing for now
dict_new() -> {dict,[]}.
%@return [{Vlaue},{Value2}....] || not_found
dict_get({dict,L}, Key) ->
	X = [Val || {K,Val}<- L , K==Key],
	case X of
		[] -> not_found;
		_ -> hd(X) end.
%@return {{dict,[....]},fresh} or {{dict,[.....]},{previous,OldVal}}
dict_put({dict,L}, Key, Val) -> 
	Tuple = dict_get({dict,L},Key), 
		case Tuple of
			not_found ->
				Var = fresh, {{dict,lists:map(fun ({K,V}) -> {K,V} end, L)++[{Key,Val}]},Var};
			_-> 
				Var={previous,element(2,Tuple)},
					{{dict,lists:map(fun ({K,V}) -> 
								if
								K==Key ->
								{Key,Val};
								true ->
								{K,V}
								end
						end,L)},Var} 
			        end.
dict_del({dict,[]},_,Elements) -> {dict,Elements};			        
dict_del({dict,L},Key,Elements) ->
	{K,_} = hd(L),
	case K of
		Key -> dict_del({dict,tl(L)},Key,Elements);
		_ -> dict_del({dict,tl(L)},Key,Elements++[hd(L)])
	end.			
