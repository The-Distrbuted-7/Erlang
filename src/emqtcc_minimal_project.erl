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
  emqttc:subscribe(C, <<"RootGro/#">>, qos1),
  loop(dict_new(), C).
  
  
%Parse the request(JSon) which fullfil our RFC to erlang terms  
%@para MQTTmsg @return [{_,Request},{_,DataList}]
decode(Message) ->   
	[{_,Request},{_,DataList}] = jsx:decode(Message).
%Parse erlang varaibles into JSon 
%@para List @return binary message UTF-8
encode(L) -> 
	jsx:encode([L]).
	
%loop to listen for requests and responde
%@para Dictionary
loop(Dict) -> 
	receive 
		%%Topic will tell us where to store the values
		{publish ,Topic, Message} ->
			%%decode the message, if the message doesn't fullfill our RFC the process will crash
			[{_,Request},{_,DataList}] = decode(Message),
			%% check whether it's add,del or fetch request
			case Request of 
				<<"add">> -> Updated_dict = add(DataList,Dict,Topic), loop(Updated_dict,C);
				<<"delete">> -> implement;
				<<"fetch">> -> implement
			end
	end,
	io:format("Topic:~p~n",[Topic]),
	io:format("Message~p~n",[Message]),
	loop(Dict,C) end.
			
%%reply back to client @publish to broker
reply(Topic,Reply) ->
	 emqttc:publish(C, Topic, jsx:encode(Reply)).
%%Helper functions to add to the dict
add(Data,Dict,To) ->
	to_implement.
del(Data,Dict,To) ->
	to_implement.
fetch(Dict,To) ->
	to)implement.
%%Tmp functions used for offline storing for now
dict_new() -> {dict,[]}.
%@return [{found,Vlaue},{found,Value2}....]
dict_get({dict,L}, Key) ->
	X = [{found,Val} || {K,Val}<- L , K==Key],
	case X of
		[] -> not_found;
		%return the whole list
		_ -> X end.
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
