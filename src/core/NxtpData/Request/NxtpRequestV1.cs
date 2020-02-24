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
using System.Runtime.InteropServices;
using System.Text;
using NxtpData.Response;
using TimeZoneConverter;

namespace NxtpData.Request
{
    public class NxtpRequestV1 : INxtpRequest
    {
        public string TimeZoneCode { get; set; }
        public TimeZoneInfo ZoneInfo { get; set; }
        public virtual Client Client { get; private set; }

        // Must have a parameterless constructor
        public NxtpRequestV1()
        {
        }

        public NxtpRequestV1(string TimeZoneCode)
        {
            bool testMode = (TimeZoneCode ?? "").Trim().ToUpper() == "TEST";
            if (testMode)
                this.TimeZoneCode = "TEST";
            else
                this.TimeZoneCode = TimeZoneCode;
            string zone = (TimeZoneCode ?? "").Replace(" ", "").ToLower();
            foreach (var tz in TimeZoneInfo.GetSystemTimeZones())
            {
                string id = tz.Id;
                if (!RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
                    TZConvert.TryIanaToWindows(tz.Id, out id);
                if (testMode && id == "GMT Standard Time")
                {
                    this.ZoneInfo = tz;
                    break;
                }
                else if (zone == id.Replace(" ", "").ToLower())
                {
                    this.ZoneInfo = tz;
                    break;
                }
            }
        }

        public byte Version { get { return 1; } }

        public byte ChecksumSeed { get { return 123; } }

        public string ToHex()
        {
            var sb = new StringBuilder();
            foreach (byte b in Serialize())
                sb.Append(b.ToString("X2"));
            return sb.ToString();
        }

        public virtual byte[] Serialize()
        {
            if ((TimeZoneCode ?? "").Trim().ToUpper() == "TEST")
                return Encoding.ASCII.GetBytes("tEsT");
            var rv = new List<byte>();
            rv.Add(Version);
            rv.Add(0);
            var payload = Encoding.ASCII.GetBytes(TimeZoneCode.ToString());
            rv.AddRange(payload); ;
            rv[1] = Convert.ToByte(payload.Length); // Total length of payload only
            byte cs = ChecksumSeed;
            foreach (byte b in rv)
                cs ^= b;
            rv.Add(cs);
            return rv.ToArray();
        }

        public virtual INxtpRequest Deserialize(Client Client, byte[] Data, int DataSize)
        {
            INxtpRequest rv = null;

            // Explicitly check for test mode
            bool testMode = false;
            if (Data != null && Data.Length >= 4 && DataSize == 4)
            {
                var text = (Encoding.ASCII.GetString(Data, 0, 4) ?? "").Trim().ToUpper();
                testMode = text == "TEST";
            }

            // Test mode always validates
            if (testMode)
            {
                foreach (var tz in TimeZoneInfo.GetSystemTimeZones())
                {
                    string id = tz.Id;
                    if (!RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
                        TZConvert.TryIanaToWindows(tz.Id, out id);
                    if (id == "GMT Standard Time")
                    {
                        this.TimeZoneCode = id.Replace(" ", "");
                        this.ZoneInfo = tz;
                        return this;
                    }
                }
            }

            // Must be at least one byte for version
            if (Data == null || Data.Length <= 0 || Data.Length < DataSize || Data[0] != Version)
            return rv;

            // Must be at least three bytes excluding payload
            if (Data.Length < 3) 
                return rv;

            // Must be three bytes longer than payload
            int payloadLength = Data[1];
            int dataLength = payloadLength + 3;
            if (DataSize < dataLength)
                return rv;

            // Checksum for all bytes except last must match last byte
            byte cs = ChecksumSeed;
            for (int i = 0; i < dataLength - 1; i++)
                cs ^= Data[i];
            if (Data[dataLength - 1] != cs)
                return rv;

            // Get timezone and see if it is in the current server list
            string zone = (Encoding.ASCII.GetString(Data, 2, payloadLength) ?? "").Replace(" ", "").Trim().ToLower();
            zone = TimezoneList.ResolveAlias(zone);
            if (string.IsNullOrWhiteSpace(zone))
                return rv;
            TimeZoneInfo zoneMatched = null;
            var zones = TimeZoneInfo.GetSystemTimeZones();
            if (zone == "phoebustime")
            {
                var rnd = new Random();
                int i = rnd.Next(0, zones.Count);
                this.TimeZoneCode = zone;
                this.ZoneInfo = zones[i];
                return this;
            }
            foreach (var tz in zones)
            {
                string id = tz.Id;
                if (!RuntimeInformation.IsOSPlatform(OSPlatform.Windows))
                    TZConvert.TryIanaToWindows(tz.Id, out id);
                if (zone == id.Replace(" ", "").ToLower())
                {
                    zoneMatched = tz;
                    break;
                }
            }
            if (zoneMatched == null)
                return rv;

            // Passed validation, set timezone
            this.Client = Client;
            this.TimeZoneCode = zone;
            this.ZoneInfo = zoneMatched;

            return this;
        }

        public virtual INxtpResponse GetResponse()
        {
            return new NxtpResponseV1(this);
        }
    }
}
