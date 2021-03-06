﻿//  Copyright 2019-2020 Robin Verhagen-Guest
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

using NxtpData.Request;
using NxtpServer.Classes;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Net.Sockets;
using System.Text;
using System.Threading;

namespace NxtpServer
{
    class Program
    {
        private static Socket serverSocket;
        private static bool newClients = true;
        private static byte[] data = new byte[dataSize];
        private const int dataSize = 1024;

        static void Main(string[] args)
        {
            Console.WriteLine("Starting NXTP Server...");

            if (args.Any(a => a == "-z"))
            {
                Console.WriteLine("Listing server timezone codes...");
                Console.WriteLine();
                Console.WriteLine(new NxtpData.TimezoneList().ToString());
                Console.WriteLine();
            }

            Console.WriteLine("Connect timeout: " + Options.ConnectTimeoutMilliseconds + " ms");
            Console.WriteLine("Send timeout:    " + Options.SendTimeoutMilliseconds + " ms");
            Console.WriteLine("Receive timeout: " + Options.ReceiveTimeoutMilliseconds + " ms");

            serverSocket = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
            IPEndPoint endPoint = new IPEndPoint(IPAddress.Any, Options.TCPListeningPort); //12300
            serverSocket.Bind(endPoint);
            serverSocket.Listen(0);
            serverSocket.BeginAccept(new AsyncCallback(AcceptConnection), serverSocket);
            Console.WriteLine("Listening for TCP connections on port " + endPoint.Port + "...");
            while (true)
            {
                Thread.Sleep(1);
            }
        }

        private static void AcceptConnection(IAsyncResult result)
        {
            if (!newClients) return;
            Socket oldSocket = (Socket)result.AsyncState;
            Socket newSocket = oldSocket.EndAccept(result);
            newSocket.SendTimeout = Options.SendTimeoutMilliseconds;
            newSocket.ReceiveTimeout = Options.ReceiveTimeoutMilliseconds;
            var client = new NxtpData.Client((IPEndPoint)newSocket.RemoteEndPoint);
            client.Register(newSocket);
            client.Socket = newSocket;
            client.Log("Connected");
            try
            {
                var acceptResult = serverSocket.BeginAccept(new AsyncCallback(AcceptConnection), serverSocket);
                client.Socket.BeginReceive(data, 0, dataSize, SocketFlags.None, new AsyncCallback(ReceiveData), client.Socket);
                Thread.Sleep(Options.ConnectTimeoutMilliseconds);
                if (client.Socket.Connected)
                {
                    client.Log("Connection timeout");
                    client.Disconnect();
                }
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                Console.WriteLine(ex.StackTrace);
            }
        }

        private static void ReceiveData(IAsyncResult result)
        {
            try
            {
                Socket clientSocket = (Socket)result.AsyncState;
                var client = NxtpData.Client.Find(clientSocket);
                int received = clientSocket.EndReceive(result);
                if (received == 0)
                {
                    clientSocket.Close();
                    client.Disconnect();
                    return;
                }
                client.Log("Request " + ToHex(data, received));
                byte version = data[0];
                bool testMode = false;
                if (data != null && data.Length >= 4 && received == 4)
                {
                    var text = (Encoding.ASCII.GetString(data, 0, 4) ?? "").Trim().ToUpper();
                    testMode = text == "TEST";
                }
                if (testMode)
                    client.Log("Trying protocol version 1 (TEST mode)");
                else
                    client.Log("Trying protocol version " + version);
                var req = NxtpRequestFactory.Create(client, version, data, received);
                if (req == null)
                {
                    client.Log("Cannot process protocol version");
                    if (client.Socket.Connected)
                    {
                        client.Disconnect();
                    }
                }
                else
                {
                    var resp = req.GetResponse();
                    var bytes = resp.Serialize();
                    client.Log("Returning " + resp.ToText());
                    client.Log("Response " + ToHex(bytes, bytes.Length));
                    clientSocket.BeginSend(bytes, 0, bytes.Length, SocketFlags.None,
                        new AsyncCallback(SendData), clientSocket);
                }
            }
            catch (InvalidOperationException)
            {
                // Catch timeout errors
            }
            catch (Exception ex)
            {
                // Report other errors without dying
                Console.WriteLine(ex.Message);
                Console.WriteLine(ex.StackTrace);
            }
        }

        public static void SendData(IAsyncResult result)
        {
            try
            {
                Socket clientSocket = (Socket)result.AsyncState;
                var client = NxtpData.Client.Find(clientSocket);
                client.Disconnect();
            }
            catch
            {
            }
        }

        private static string ToHex(Byte[] Data, int Length)
        {
            if (Data == null || Data.Length < Length)
                return "";
            var sb = new StringBuilder();
            for (int i = 0; i < Length; i++)
                sb.Append(Data[i].ToString("X2"));
            return sb.ToString();
        }
    }
}
