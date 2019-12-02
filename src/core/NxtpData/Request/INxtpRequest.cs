using NxtpData.Response;
using System;
using System.Collections.Generic;
using System.Text;

namespace NxtpData.Request
{
    public interface INxtpRequest
    {
        public byte Version { get; }
        public byte ChecksumSeed { get; }
        public byte[] Serialize();
        public INxtpRequest Deserialize(byte[] Data, int DataSize);
        public INxtpResponse GetResponse();
        public string ToHex();
    }
}
