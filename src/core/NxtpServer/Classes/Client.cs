using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Sockets;
using System.Text;

namespace NxtpServer.Classes
{
    public class Client
    {
        public IPEndPoint remoteEndPoint;
        public Socket Socket;

        public Client(IPEndPoint _remoteEndPoint)
        {
            this.remoteEndPoint = _remoteEndPoint;
        }

        public void Log(string Text)
        {
            Console.WriteLine((remoteEndPoint.Address.ToString()
                + ":" + remoteEndPoint.Port.ToString()).PadRight(22)
                + (Text ?? ""));
        }
    }
}
