using NxtpServer.Classes;
using System;

namespace NxtpServer
{
    class Program
    {
        static void Main(string[] args)
        {
            //var list = new NxtpData.TimezoneList().ToString();
            TcpHelper.StartServer(Options.TCPListeningPort);
            TcpHelper.Listen();
        }
    }
}
