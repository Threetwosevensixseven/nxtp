using NxtpData;
using NxtpData.Request;
using System;
using System.Collections.Generic;
using System.Net;
using System.Net.Sockets;
using System.Text;

namespace NxtpServer.Classes
{
    public class TcpHelper
    {
        private static TcpListener listener { get; set; }
        private static bool accept { get; set; } = false;

        public static void StartServer(int port)
        {
            IPEndPoint endPoint = new IPEndPoint(IPAddress.Any, port);
            listener = new TcpListener(endPoint);
            listener.Start();
            accept = true;
            Console.WriteLine($"Server started. Listening to TCP clients on port {port}");
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

        public static void Listen()
        {
            if (listener != null && accept)
            {

                // Continue listening.  
                while (true)
                {
                    Console.WriteLine("Waiting for client...");
                    var clientTask = listener.AcceptTcpClientAsync(); // Get the client  

                    if (clientTask.Result != null)
                    {
                        Console.WriteLine("Client connected, waiting for data...");
                        using (var client = clientTask.Result)
                        {
                            //byte[] data = Encoding.ASCII.GetBytes("Send next data: [enter 'quit' to terminate] ");
                            //client.GetStream().Write(data, 0, data.Length);

                            byte[] buffer = new byte[1024];
                            int read = client.GetStream().Read(buffer, 0, buffer.Length);
                            Console.WriteLine("Request: " + ToHex(buffer, read));

                            byte version = buffer[0];
                            Console.WriteLine("Trying protocol version " + version + "...");
                            var req = NxtpRequestFactory.Create(version, buffer, read);
                            if (req == null)
                            {
                                Console.WriteLine("Cannot process protocol version");
                            }
                            else
                            {
                                var resp = req.GetResponse();
                                var bytes = resp.Serialize();
                                Console.WriteLine("Returning " + resp.ToText());
                                Console.WriteLine("Response: " + ToHex(bytes, bytes.Length));
                                client.GetStream().Write(bytes, 0, bytes.Length);
                            }
                            Console.WriteLine("Closing connection");
                        }
                    }
                }
            }
        }
    }
}
