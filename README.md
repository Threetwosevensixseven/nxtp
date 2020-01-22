# nxtp (Network neXt Time Protocol)
*nxtp* is an easy way of setting your local time on retro computers equipped a RTC (Real Time Clock) and a network interface. It is similar to the well-known NTP Network Time Protocol but faster and more lightweight, and simpler to implement on retro computers.

## *nxtp* Client

An `.nxtp` dot command client for the [ZX Spectrum Next](https://www.specnext.com/about/)™ is provided, written in Z80N assembly language. You may add a command to your `AUTOEXEC.BAS` BASIC startup program to automatically sync the time whenever you boot into NextZXOS. Your Next must be equipped with a RTC in order to use *nxtp*.

You can tell *nxtp* to [set the local time in your own timezone](https://github.com/Threetwosevensixseven/nxtp/wiki/Timezone-Codes), including any daylight savings time currently in effect.

We also provide a C# reference client using .NET Core 3.0, to assist with porting to other architectures or machines.

If you haven't already done so, set up your Next WiFi using `WIFI.BAS` as described in [this wiki article](https://github.com/Threetwosevensixseven/nxtp/wiki/Setting-Up-Your-Next-WiFi).

To sync date and time every time you boot your Next, set up `AUTOEXEC.BAS` as described in [this wiki article](https://github.com/Threetwosevensixseven/nxtp/wiki/Syncing-Date-and-Time-From-AUTOEXEC.BAS).

## *nxtp* Server

The server is written in C# using .NET Core 3.0, and can be hosted on any Windows, Mac or linux computer. You may use the public server hosted by the Next team, or run your own private copy of the server on your PC. You may also run the server on a Raspberry Pi running Raspbian. It is lightweight enough to run on a wifi-equipped Raspberry Pi Zero W.

## Protocol

The *nxtp* protocol is documented [here](https://github.com/Threetwosevensixseven/nxtp/wiki/NXTP-Protocol).

## Project Status
*nxtp* is currently in beta testing. Download the latest Next client [here](https://github.com/Threetwosevensixseven/nxtp/releases/latest). 

If you have a GitHub account you can elect to be notified whenever there is a project release.

## Copyright and Licence
*nxtp* is © 2019-2020 Robin Verhagen-Guest, and licensed under [Apache 2.0](LICENSE). 

Everyone is encouraged to host a public *nxtp* server, or port the *nxtp* client to a different machine or architecture.

ZX Spectrum Next is a trademark of SpecNext Ltd.
