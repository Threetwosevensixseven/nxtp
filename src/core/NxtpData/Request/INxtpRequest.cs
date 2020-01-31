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
