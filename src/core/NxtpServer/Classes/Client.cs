//  Copyright 2019-2020 Robin Verhagen-Guest
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Sockets;
using System.Text;

namespace NxtpServer.Classes
{
    public class Client
    {
        public static Dictionary<Socket, Client> ClientList = new Dictionary<Socket, Client>();

        public IPEndPoint remoteEndPoint;
        public Socket Socket;
        private bool disconnected = false;
        private static object sync = new object();

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

        public void Register(Socket Socket)
        {
            this.Socket = Socket;
            lock (sync)
            {
                ClientList.Add(Socket, this);
            }
        }

        public static Client Find(Socket Socket)
        {
            Client client = null;
            lock (sync)
            {
                ClientList.TryGetValue(Socket, out client);
            }
            return client;
        }

        public void Disconnect()
        {
            if (!disconnected)
            {
                Log("Disconnected");
                disconnected = true;
            }
            Socket.Close();
            lock (sync)
            {
                if (ClientList.ContainsKey(Socket))
                    ClientList.Remove(Socket);
            }
        }
    }
}
