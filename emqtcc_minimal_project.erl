-module(emqtcc_minimal_project).

%% API exports
-export([init/0, subscribe/2, start/0, connect/0, getList/2, addToDB/2, removeFromDB/2]).


%To make this work you have to add this dependencies to your reaber project. 
%{erl_opts, [debug_info]}.
%{deps, [{emqttc, {git, "https://github.com/emqtt/emqttc.git", {ref, %"815ebeca103025bbb5eb8e4b2f6a5f79e1236d4c"}}},
%{mysql, ".*", {git, "https://github.com/mysql-otp/mysql-otp", {tag, "1.2.0"}}}
%]}.
%%====================================================================
%% API functions
%%====================================================================
init()->
    %Connects to hivem online broker
  {ok, C} = emqttc:start_link([{host, "test.mosquitto.org"}, {client_id, <<"GroCood2016">>}, {keepalive, 300}, {connack_timeout, 60}]),
  {ok,PidDbD}=connect(),
  emqttc:subscribe(C, <<"RootGro/#">>, qos1),    %Start subscribing to a topic.
  subscribe(C, PidDbD).  % Start receiveloop to receive messages on the subscribed topic.
  
% Databas connect dunction  
connect()->
    {ok, Pid} = mysql:start_link([{host, "127.0.0.1"}, {user, "root"},
                              {password, "Ranyrg1324"}, {database, "grocerys"}]).

% Receiveloop to receive messages on the subscribed topic
subscribe(C,PidDbD) ->    
            receive 
                {publish, Topic, Product} -> 
                    [{BinTodo, BinMsg}] = jsx:decode(Product),
                        case [{BinTodo, BinMsg}] of
                        [{<<"add">>, BinMsg}] ->
                            addToDB(PidDbD, BinMsg);
                        [{<<"remove">>, BinMsg}] ->
                        removeFromDB(PidDbD, BinMsg);
                        [{<<"getList">>, BinMsg}] ->
                            {ok, ColumnNames, Rows} = getList(PidDbD, BinMsg),
                            
                            BinRows = [list_to_binary(R)|| R <- Rows],
                            io:format(">>Rows>> ~p", [BinRows]),
                            emqttc:publish(C, <<"JohanPhone/List">>, jsx:encode(BinRows))

                     end, 
                     subscribe(C, PidDbD)
                
            end.
                    
 createList(PidDbD, Value)-> implemnt.
 
 getList(PidDbD, Value) ->
     mysql:query(PidDbD, "SELECT listName FROM lists").
    
 
 %Add to database
addToDB(PidDbD, Value )-> 
    ok = mysql:query(PidDbD, "INSERT INTO  lists (ListName) VALUES (?)", [Value]).

%Remove from database.
removeFromDB(PidDbD, Value) ->
    ok = mysql:query(PidDbD, "DELETE FROM  lists where listName=(?)", [Value]).
        


%If the process sts is spawned the is_pid funktion will return true and return ok and the sts pid. 
%Otherweise it spawns the init function that initializes the serverloop with an empty list. And register the spawned 
%function with the name sts and returns an ok and the sts pid.
start() ->
	case is_pid(whereis(sts)) of
  	true -> {ok, whereis(sts)};
	 _	 -> Pid= spawn(emqtcc_minimal_project, init, []),
			register(sts, Pid),
			{ok, Pid}
	end.
