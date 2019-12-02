using System;
using System.Collections.Generic;
using System.Text;

namespace NxtpData.Response
{
    public interface INxtpResponse
    {
        public byte[] Serialize();
        public INxtpResponse Deserialize(byte[] Data, int DataSize);
        public string ToHex();
        public string ToText();
    }
}
