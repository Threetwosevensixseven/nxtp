using Microsoft.Extensions.Configuration;
using System;
using System.Collections.Generic;
using System.IO;
using System.Text;

namespace NxtpServer.Classes
{
    public class Options
    {
        private static IConfigurationRoot options;

        static Options()
        {
            var builder = new ConfigurationBuilder()
                   .SetBasePath(Directory.GetCurrentDirectory())
                   .AddJsonFile("NxtpServer.appsettings.json", optional: true, reloadOnChange: true);
            options = builder.Build();
        }

        private static string Get(string Key)
        {
            return (options[Key] ?? "").Trim();
        }

        public static int TCPListeningPort
        {
            get

            {
                int val;
                int.TryParse(Get("appSettings:TCPListeningPort"), out val);
                return val;
            }
        }

        public static int ConnectTimeoutMilliseconds
        {
            get

            {
                int val;
                int.TryParse(Get("appSettings:ConnectTimeoutMilliseconds"), out val);
                if (val <= 0)
                    val = 5000;
                return val;
            }
        }

        public static int SendTimeoutMilliseconds
        {
            get

            {
                int val;
                int.TryParse(Get("appSettings:SendTimeoutMilliseconds"), out val);
                if (val < 0)
                    val = 0;
                return val;
            }
        }

        public static int ReceiveTimeoutMilliseconds
        {
            get

            {
                int val;
                int.TryParse(Get("appSettings:ReceiveTimeoutMilliseconds"), out val);
                if (val < 0)
                    val = 0;
                return val;
            }
        }
    }
}
