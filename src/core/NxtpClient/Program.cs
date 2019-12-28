using NxtpData;
using NxtpData.Request;
using NxtpData.Response;
using System;
using System.Linq;
using System.Net.Sockets;
using System.Text;

namespace NxtpClient
{
    public class Program
    {
        public const byte VERSION = 1;
        public static string ServerAddress;
        public static int Port;
        public static bool Interactive;
        public static bool Help;
        public static string Zone;
        public static bool TestMode;

        private static int Main(string[] args)
        {
            try
            {
                Interactive = args.Any(a => a == "-i");
                Help = args.Any(a => a == "-h");
                TestMode = args.Any(a => (a ?? "").Trim().ToUpper() == "TEST");
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
                if (zArgs.Count > 1)
                    return Usage();
                if (zArgs.Count > 0 && zArgs[0].Length <= 3)
                    return Usage();
                Zone = "";
                if (zArgs.Count > 0)
                {
                    Zone = (zArgs[0] ?? "").Substring(3).Trim();
                    if (string.IsNullOrWhiteSpace(Zone))
                        return Usage();
                }

                NxtpRequestV1 req;
                if (TestMode)
                    req = new NxtpRequestV1("TEST");
                else
                    req = new NxtpRequestV1(Zone);

                if (TestMode)
                    Console.WriteLine("Requesting time in TEST mode (GMT)...");
                else if (string.IsNullOrWhiteSpace(Zone))
                    Console.WriteLine("Requesting time for default timezone (GMT)...");
                else
                    Console.WriteLine("Requesting time for timezone \"" + Zone + "\"...");

                Console.WriteLine("Connecting to server " + ServerAddress + " on port " + Port + "...");
                using (var client = new TcpClient(ServerAddress, Port))
                {
                    Byte[] data = req.Serialize();
                    Console.WriteLine("Request: {0}", req.ToHex());
                    using (var stream = client.GetStream())
                    {
                        stream.Write(data, 0, data.Length);
                        data = new Byte[1024];
                        int read = stream.Read(data, 0, data.Length);
                        Console.WriteLine("Response: {0}", ToHex(data, read));
                        var resp = (NxtpResponseV1)req.GetResponse().Deserialize(data, read);
                        if (resp == null)
                            Console.WriteLine("Result could not be processed");
                        else
                            Console.WriteLine("Result: {0} {1} ({2})",
                              resp.DateFormatted, resp.TimeFormatted, resp.Result.ToString("s"));
                    }
                    Console.WriteLine("Closing connection");
                }
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
