-module(emqtcc_minimal_project).

%% API exports
-export([init/0,decode/1]).

start() ->
	%%check if the process is already spawned
	case whereis(sts) of
	  %%in case it is just return the PID
	  _ -> 
	  {ok, whereis(sts)};
	  %%in case not
	  undefined -> 
	  %%spawn it and return the PID
	  Pid=spawn(emqtcc_minimal_project, init, []),
	  register(sts, Pid),
	  {ok, Pid}
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
%@para MQTTmsg @return Client-id,Req,Item
decode(Message) ->  
try	
[{<<"client_id">>,ID},
 {<<"request">>,Req},
 {<<"data">>,[{<<"item">>,Item}]}]
 = jsx:decode(Message)
 catch error:E -> [{<<"client_id">>,1},
 {<<"request">>,<<"ERROR">>},
 {<<"data">>,[{<<"item">>,c}]}]
 end.
%loop to listen for requests and responde
%@para Dictionary
loop(Dict,C) -> 
	receive 
		%%Topic will tell us where to store the values
		{publish ,Topic, Message} ->
			%decode the message, if the message doesn't fullfill our RFC the process will crash
			[{_,Client_id},{_,Req},{_,[{_,Item}]}]  = decode(Message),
			%check whether it's add,del or fetch request
			case Req of 
				<<"add">> -> Updated_dict = add(Client_id,Dict,Topic,Item,C), loop(Updated_dict,C);
				<<"delete">> -> Updated_dict = del(Client_id,Dict,Topic,Item,C), loop(Updated_dict,C);
				<<"fetch">> -> Updated_dict = add(Client_id,Dict,Topic,Item,C), loop(Updated_dict,C);
				_ -> loop(Dict,C)
			end
	end,
	io:format("Topic:~p~n",[Topic]),
	io:format("Message~p~n",[Message]),
	loop(Dict,C).
encode_list(L) -> 
		[[{<<"item">>,X}] || {X,X} <- L].
%%get the list name	
get_list(L) ->  case hd(L) of 47 -> tl(L); _ -> get_list(tl(L)) end.
%%Helper functions to add to the dict
add(Client_id,Dict,Topic,Item,C) ->
	List = get_list(binary:bin_to_list(Topic)),
	OldDict = dict_get(Dict,{Client_id,List}),
	case OldDict of 
		not_found -> {New_Dict,_} = dict_put(dict_new(),Item,Item), {Updated,_} = dict_put(Dict,{Client_id,List},New_Dict), {dict,Listt} = New_Dict,
					 emqttc:publish(C, Topic, jsx:encode([{<<"reply">>,<<"done">>},{<<"data">>,encode_list(Listt)}])),
					 Updated;
		_ -> {UpdatedChild,_} = dict_put(OldDict,Item,Item), {Updated,_} = dict_put(Dict,{Client_id,List},UpdatedChild), {dict,Listt} = UpdatedChild,
			 emqttc:publish(C, Topic, jsx:encode([{<<"reply">>,<<"done">>},{<<"data">>,encode_list(Listt)}])),
			 Updated
	end.
del(Client_id,Dict,Topic,Item,C) ->
	List = get_list(binary:bin_to_list(Topic)),
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
dict_del({dict,[]},Key,Elements) -> {dict,Elements};			        
dict_del({dict,L},Key,Elements) ->
	{K,_} = hd(L),
	case K of
		Key -> dict_del({dict,tl(L)},Key,Elements);
		_ -> dict_del({dict,tl(L)},Key,Elements++[hd(L)])
	end.			
