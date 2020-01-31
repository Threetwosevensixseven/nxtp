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
using System.Linq;
using System.Text;

namespace NxtpData.Request
{
    public class NxtpRequestFactory
    {
        public static INxtpRequest Create(byte Version, byte[] Data, int DataSize)
        {
            var types = AppDomain.CurrentDomain.GetAssemblies().SelectMany(x => x.GetTypes())
                .Where(x => typeof(INxtpRequest).IsAssignableFrom(x) && !x.IsInterface && !x.IsAbstract);
            foreach (Type type in types)
            {
                INxtpRequest creator = null;
                INxtpRequest request = null;
                try
                {
                    creator = (INxtpRequest)Activator.CreateInstance(type);
                }
                catch
                {
                    // Any error means this class can't handle the protocol,
                    // so try the next class
                }
                try
                {
                    bool testMode = false;
                    if (creator != null && Data != null && DataSize == 4)
                    {
                        var text = (Encoding.ASCII.GetString(Data, 0, 4) ?? "").Trim().ToUpper();
                        testMode = text == "TEST";
                    }
                    if (creator != null && (testMode || creator.Version == Version))
                        request = creator.Deserialize(Data, DataSize);
                }
                catch
                {
                    // Any error means this is the correct class for the protocol,
                    // but we had an error handling it, so return immediately
                    return null;
                }
                return request;
            }
            // No classes can handle the protocol
            return null;
        }
    }
}
