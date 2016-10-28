# Erlang

To make this work with your rebar project you have to add this dependencies to your reaber project. 
{erl_opts, [debug_info]}.
{deps, [{emqttc, {git, "https://github.com/emqtt/emqttc.git", {ref, %"815ebeca103025bbb5eb8e4b2f6a5f79e1236d4c"}}},
{mysql, ".*", {git, "https://github.com/mysql-otp/mysql-otp", {tag, "1.2.0"}}}
]}.
