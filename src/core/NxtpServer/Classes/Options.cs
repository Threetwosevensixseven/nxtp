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
