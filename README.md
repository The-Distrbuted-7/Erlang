to Register java should send:
{"request":"register","data":{"email":"raf1@me.com","password":"123","name":"raf"}}
and receive:
{"reply":"done"} or {"reply":"error"} or {"reply":"email_already_exists"}
to login java should send:
{"request":"login","data":{"email":"raf@me.com","password":"123"}}
and reiceve: 
{"reply":"done"} or {"reply":"error"}
to add/delete a list java should send:
{"client-id":"ID","request":"add-list/delete-list","data":"list-name"}
and receive:
{"reply":"done"} or {"reply":"error"}
to get all the lists the user has java should send:
{"client-id":"ID","request":"fetch-lists"}
and receive:
{
"reply":"done"
"data":[{"item":"list1"},{"item":"list2"},{"item":"list3"}...etc]
}
for items adding, deleting and fetching from a list
java should send:
{
"client-id":"ID"
"request":"add/delete"
"list":"list-name"
"data":{"item":"item-name"}
}
and reiceve:
{
"reply":"done"
}
or 
{
"reply":"error"
}
and for fetch java should send:
{
"client-id":"ID"
"request":"fetch"
"list":"list-name"
"data":{"item":"null"}
}
and recieve 
{
"reply":"done"
"data":[{"item":"item1"},{"item":"item2"},{"item":"item3"}...etc]
}
