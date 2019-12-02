using NxtpData.Request;
using System;
using System.Collections.Generic;
using System.Text;
using System.Text.RegularExpressions;

namespace NxtpData.Response
{
    public class NxtpResponseV1 : INxtpResponse
    {
        private NxtpRequestV1 request;
        private DateTime result;
        public string DateFormatted { get; set; }
        public string TimeFormatted { get; set; }
        public DateTime Result { get; set; }

        // Must have a parameterless constructor
        public NxtpResponseV1()
        {
        }

        public NxtpResponseV1(NxtpRequestV1 Request)
        {
            request = Request;
        }

        public string ToHex()
        {
            var sb = new StringBuilder();
            foreach (byte b in Serialize())
                sb.Append(b.ToString("X2"));
            return sb.ToString();
        }


        public string ToText()
        {
            return result.ToString("yyyy-MM-dd")
                + " " + result.ToString("HH:mm:ss")
                + " in zone " + request.ZoneInfo.DisplayName;
        }

        public byte[] Serialize()
        {
            var rv = new List<byte>();
            rv.Add(request.Version);
            rv.Add(0);  // Date length (index 1)
            rv.Add(0);  // Time length (index 2)
            var zoneInfo = TimeZoneInfo.FindSystemTimeZoneById(request.ZoneInfo.Id);
            var now = DateTime.UtcNow;
            result = TimeZoneInfo.ConvertTimeFromUtc(now, zoneInfo);
            string date = result.ToString("dd/MM/yyyy");
            var dateB = Encoding.ASCII.GetBytes(date.ToString());
            string time = result.ToString("HH:mm:ss");
            var timeB = Encoding.ASCII.GetBytes(time.ToString());
            rv[1] = Convert.ToByte(dateB.Length);
            rv[2] = Convert.ToByte(timeB.Length);
            rv.AddRange(dateB);
            rv.AddRange(timeB);
            byte cs = request.ChecksumSeed;
            foreach (byte b in rv)
                cs ^= b;
            rv.Add(cs);
            return rv.ToArray();
        }

        public INxtpResponse Deserialize(byte[] Data, int DataSize)
        {
            INxtpResponse rv = null;

            // Must be at least one byte for version
            if (Data == null || Data.Length <= 0 || Data.Length < DataSize || Data[0] != request.Version)
                return rv;

            // Must be at least four bytes excluding payload
            if (Data.Length < 4)
                return rv;

            // Must be four bytes longer than payload
            int dateLength = Data[1];
            int timeLength = Data[2];
            int dataLength = dateLength + timeLength + 4;
            if (DataSize < dataLength)
                return rv;

            // Checksum for all bytes except last must match last byte
            byte cs = request.ChecksumSeed;
            for (int i = 0; i < dataLength - 1; i++)
                cs ^= Data[i];
            if (Data[dataLength - 1] != cs)
                return rv;

            // Get date and validate
            DateFormatted = System.Text.Encoding.ASCII.GetString(Data, 3, dateLength);
            var m = Regex.Match(DateFormatted, @"^(?<Day>\d{2})/(?<Month>\d{2})/(?<Year>\d{4})$");     
            if (!m.Success)
                return rv;
            int day, month, year;
            int.TryParse(m.Groups["Day"].Value, out day);
            int.TryParse(m.Groups["Month"].Value, out month);
            int.TryParse(m.Groups["Year"].Value, out year);
            
            // Get time and validate
            TimeFormatted = System.Text.Encoding.ASCII.GetString(Data, 3 + dateLength, timeLength);
            m = Regex.Match(TimeFormatted, @"^(?<Hours>\d{2}):(?<Mins>\d{2}):(?<Secs>\d{2})$");
            if (!m.Success)
                return rv;
            int hours, mins, secs;
            int.TryParse(m.Groups["Hours"].Value, out hours);
            int.TryParse(m.Groups["Mins"].Value, out mins);
            int.TryParse(m.Groups["Secs"].Value, out secs);

            // Create date and time and trap out of range errors
            try
            {
                Result = new DateTime(year, month, day, hours, mins, secs, DateTimeKind.Local);
            }
            catch
            {
                return rv;
            }

            return this;
        }
    }
}
