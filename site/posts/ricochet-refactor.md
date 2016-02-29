# Refactoring go-ricochet

I spent much of this weekend working on go-ricochet.


# Refactoring go-ricochet

I spent much of this weekend working on [go-ricochet](https://github.com/s-rah/go-ricochet). I originally hacked the
library together some 5 months ago in order to write a security testing tool
for [ricochet](https://ricochet.im). With the release of Ricochet 1.1.2 last week
I decided to take this weekend to fix up some of the issues that I had identified
with it.

## What Has Changed?

Not much, feature wise. There is still much I want to add to the core library,
including the ability to accept new inbound connections. 

This refactor is a progression towards those goals - adding a new event-driven
API.

## The New API

        package goricochet

        type RicochetService interface {
            OnConnect(serverHostname string)
            OnAuthenticationChallenge(channelID int32, serverHostname string, serverCookie [16]byte)
            OnAuthenticationResult(channelID int32, serverHostname string, result bool)

            OnOpenChannelRequest(channelID int32, serverHostname string)
            OnOpenChannelRequestAck(channelID int32, serverHostname string, result bool)
            OnChannelClose(channelID int32, serverHostname string)

            OnContactRequest(channelID string, serverHostname string, nick string, message string)

            OnChatMessage(channelID int32, serverHostname string, messageID int32, message string)
            OnChatMessageAck(channelID int32, serverHostname string, messageID int32)
        }
        
The event driven API is pretty simple, but allows the calling client a more fine-grained
control - by providing them with a way to override each event i.e. receiving an authentication challenge
or a channel close - before these were hidden inside the protocol.

## EchoBot Example

You can see how this new approach works by looking at the new EchoBot example:

        package main

        import (
            "github.com/s-rah/go-ricochet"
        )

        type EchoBotService struct {
            goricochet.StandardRicochetService
        }

        func (ebs * EchoBotService) OnAuthenticationResult(channelID int32, serverHostname string, result bool) {
            if true {
                ebs.Ricochet().OpenChatChannel(5)
                ebs.Ricochet().SendMessage(5, "Hi I'm an echo bot, I echo what you say!")
            }
        }

        func (ebs * EchoBotService) OnChatMessage(channelID int32, serverHostname string, messageId int32, message string) {
           ebs.Ricochet().AckChatMessage(channelID, messageId)
           ebs.Ricochet().SendMessage(5, message)
        }

        func main() {
            ricochetService := new(EchoBotService)
            ricochetService.Init("./private_key", "kwke2hntvyfqm7dr") 
            err := ricochetService.Ricochet().Connect("kwke2hntvyfqm7dr", "127.0.0.1:55555|jlq67qzo6s4yp3sp")
            if err == nil { 
                ricochetService.OnConnect("jlq67qzo6s4yp3sp")
                ricochetService.Ricochet().ListenAndWait("jlq67qzo6s4yp3sp", ricochetService)
            }
        }
 
There are still issues with the above, namely I don't like the OnConnect() call.
However, the EchoBot is able to override only the API points necessary and build
out a complete Ricochet application in less than 30 lines of code.

## What Is Next?

Next up I need to alter the API to make it more easy to track multiple connected
clients (and allow inbound client connections).

Added to that there are a few more issues to fix:

* Tracking Channel Types - At the moment there are still some hardcoded channel
numbers linked to channel types in ricochet.go - These will have to be more dynamic
to allow the building of better tools.
* Tracking Channel States - At least in the Default implementation we don't want
calling client to be able to open more than one chat channel, for example.
* Removing that Initial OnConnect() - This should be driven by the initial Connect() call,
I'm looking for a nice way to express this.
* New MultiClient Examples - It would be nice to have an EchoBot which anyone can
connect to.
* Default implementations for handling ContactRequest
