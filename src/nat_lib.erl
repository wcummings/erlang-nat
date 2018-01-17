%%% -*- erlang -*-
%%% This file is part of erlang-nat released under the MIT license.
%%% See the NOTICE for more information.
%%%
%%% Copyright (c) 2016 Benoît Chesneau <benoitc@refuge.io>

-module(nat_lib).
-compile(nowarn_deprecated_function).

-export([soap_request/3]).
-export([random_port/0]).
-export([timestamp/0]).
-export([random_uniform/1]).
-export([random_seed/3]).

soap_request(Url, Function, Msg0) ->
    Msg =  "<?xml version=\"1.0\"?>"
           "<s:Envelope"
           " xmlns:s=\"http://schemas.xmlsoap.org/soap/envelope/\""
           " s:encodingStyle=\"http://schemas.xmlsoap.org/soap/encoding/\">"
           "<s:Body>" ++  Msg0 ++ "</s:Body></s:Envelope>",

    Action = "\"urn:schemas-upnp-org:service:WANIPConnection:1#"
             ++ Function ++ "\"",

    Headers = [{"Content-Length", integer_to_list(length(Msg))},
               {"User-Agent", "Darwin/10.0.0, UPnP/1.0, MiniUPnPc/1.3"},
               {"SOAPAction", Action},
               {"Connection", "close"},
               {"Cache-Control", "no-cache"},
               {"Pragma", "no-cache"}],


    Req = {Url, Headers, "text/xml; charset=\"utf-8\"", Msg},

    case httpc:request(post, Req, [], []) of
        {ok, {{_, 200, _}, _, Body}} ->
            {ok, Body};
        {ok, {{_, Status, _}, _, _}}=Msg ->
            error_logger:info_msg("UPNP SOAP error: ~p~n", [Msg]),
            {error, integer_to_list(Status)};
        Error ->
            Error
    end.

random_port() ->
    random_uniform(16#FFFF - 10000) + 10000.

timestamp() ->
    {Mega,Sec, _} = erlang_ts(),
    Mega*1000000+Sec.

erlang_ts() ->
    try
        erlang:timestamp()
    catch
        error:undef ->
            erlang:now()
    end.

-ifdef(rand_module).
%% Do nothing, rand module will automatically create a seed for us
random_seed(A, B, C) ->
    {A, B, C}.

random_uniform(N) ->
    rand:uniform(N).
-else.
random_seed(A, B, C) ->
    random:seed(A, B, C).

random_uniform(N) ->
    random:uniform(N).
-endif.
