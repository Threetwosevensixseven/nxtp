using NxtpData.Request;
using NxtpServer.Classes;
using System;
using System.Collections.Generic;
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
        private static Dictionary<Socket, Client> clientList = new Dictionary<Socket, Client>();

        static void Main(string[] args)
        {
            Console.WriteLine("Starting NXTP Server");
            //var list = new NxtpData.TimezoneList().ToString();
            //TcpHelper.StartServer(Options.TCPListeningPort);
            //TcpHelper.Listen();

            //new Thread(new ThreadStart(backgroundThread)) { IsBackground = false }.Start();
            serverSocket = new Socket(AddressFamily.InterNetwork, SocketType.Stream, ProtocolType.Tcp);
            IPEndPoint endPoint = new IPEndPoint(IPAddress.Any, Options.TCPListeningPort); //12300
            serverSocket.Bind(endPoint);
            serverSocket.Listen(0);
            serverSocket.BeginAccept(new AsyncCallback(AcceptConnection), serverSocket);
            Console.WriteLine("Listening for TCP connections on port " + endPoint.Port + "...");
            while(true)
            {
                Thread.Sleep(1);
            }
        }

        private static void AcceptConnection(IAsyncResult result)
        {
            if (!newClients) return;
            Socket oldSocket = (Socket)result.AsyncState;
            Socket newSocket = oldSocket.EndAccept(result);
            Client client = new Client((IPEndPoint)newSocket.RemoteEndPoint);
            client.Socket = newSocket;
            clientList.Add(newSocket, client);
            client.Log("Connected");
            try
            {
                serverSocket.BeginAccept(new AsyncCallback(AcceptConnection), serverSocket);
                client.Socket.BeginReceive(data, 0, dataSize, SocketFlags.None, new AsyncCallback(ReceiveData), client.Socket);
            }
            catch (Exception ex)
            {
                Console.WriteLine(ex.Message);
                Console.WriteLine(ex.StackTrace);
            }

        }

        private static void ReceiveData(IAsyncResult result)
        {
            Client client;
            Socket clientSocket = (Socket)result.AsyncState;
            clientList.TryGetValue(clientSocket, out client);
            int received = clientSocket.EndReceive(result);
            if (received == 0)
            {
                clientSocket.Close();
                clientList.Remove(clientSocket);
                client.Log("Disconnected");
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
            var req = NxtpRequestFactory.Create(version, data, received);
            if (req == null)
            {
                client.Log("Cannot process protocol version");
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

        public static void SendData(IAsyncResult result)
        {
            try
            {
                Client client;
                Socket clientSocket = (Socket)result.AsyncState;
                clientList.TryGetValue(clientSocket, out client);
                client.Log("Disconnected");
                clientSocket.EndSend(result);
                clientSocket.Close();
            }
            catch { }
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
