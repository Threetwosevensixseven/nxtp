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
                   .AddJsonFile("appsettings.json", optional: true, reloadOnChange: true);
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
    }
}
