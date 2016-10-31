# Erlang

{erl_opts, [debug_info]}.
{deps, [{emqttc, {git, "https://github.com/emqtt/emqttc.git", {ref, "815ebeca103025bbb5eb8e4b2f6a5f79e1236d4c"}}},
{mysql, ".*", {git, "https://github.com/mysql-otp/mysql-otp", {tag, "1.2.0"}}}, {jsx, {git, "https://github.com/talentdeficit/jsx.git", {branch, "v2.8.0"}}}
]}.
