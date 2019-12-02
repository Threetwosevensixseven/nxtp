using NxtpData.Request;
using System;
using System.Collections.Generic;
using System.Text;

namespace NxtpData.Response
{
    public class NxtpResponseV1 : INxtpResponse
    {
        private NxtpRequestV1 request;
        private DateTime result;

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

        public INxtpResponse Deserialize(byte[] Data)
        {
            throw new NotImplementedException();
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
            string date = result.ToString("dd/MM/YYYY");
            var dateB = Encoding.ASCII.GetBytes(date.ToString());
            string time = result.ToString("HH/mm/ss");
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
    }
}
