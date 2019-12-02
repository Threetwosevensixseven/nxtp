using NxtpData;
using NxtpData.Request;
using System;
using System.Linq;
using System.Net.Sockets;
using System.Text;

namespace NxtpClient
{
    public class Program
    {
        public static string ServerAddress;
        public static int Port;
        public static bool Interactive;
        public static bool Help;
        public static string Zone;

        private static int Main(string[] args)
        {
            try
            {
                Interactive = args.Any(a => a == "-i");
                Help = args.Any(a => a == "-h");
                if (Help)
                    return Usage();
                var address = (args.Length > 0 ? args[0] : "").Split(':', 2);
                ServerAddress = (address.Length > 0 ? address[0] : "").Trim();
                string cPort = (address.Length > 1 ? address[1] : "").Trim();
                int.TryParse(cPort, out Port);
                if (string.IsNullOrWhiteSpace(ServerAddress) || ServerAddress.StartsWith('-'))
                    return Usage();
                if (Port <= 0 || Port > 65535)
                    return Usage();
                var zArgs = args.Where(a => a.StartsWith("-z=")).ToList();
                if (zArgs.Count != 1)
                    return Usage();
                if (zArgs[0].Length <= 3)
                    return Usage();
                Zone = (zArgs[0] ?? "").Substring(3).Trim();
                if (string.IsNullOrWhiteSpace(Zone))
                    return Usage();

                var req = new NxtpRequestV1(Zone);
                Console.WriteLine("Requesting time for timezone \"" + Zone + "\"...");

                Console.WriteLine("Connecting to server " + ServerAddress + " on port " + Port + "...");
                TcpClient client = new TcpClient(ServerAddress, Port);
                Byte[] data = req.Serialize();
                Console.WriteLine("Request: {0}", req.ToHex());
                NetworkStream stream = client.GetStream();
                stream.Write(data, 0, data.Length);

                data = new Byte[256];
                String responseData = String.Empty;
                int read = stream.Read(data, 0, data.Length);

                responseData = System.Text.Encoding.ASCII.GetString(data, 0, read);
                Console.WriteLine("Response: {0}", ToHex(data, read));

                stream.Close();
                client.Close();

                return 0;
            }
            catch (SocketException ex)
            {
                Console.WriteLine(ex.Message);
                return 2;
            }
            catch (Exception ex)
            {
                var x = ex.GetType();
                Console.WriteLine();
                Console.WriteLine(ex.Message);
                Console.WriteLine(ex.StackTrace);
                return 2;
            }
            finally
            {
                if (Interactive)
                {
                    Console.WriteLine();
                    Console.WriteLine("Press any key to continue...");
                    Console.ReadKey();
                }
            }
        }

        private static int Usage()
        {
            Console.WriteLine("NXTP ServerAddress:Port [-h [-i]]");
            return 1;
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
