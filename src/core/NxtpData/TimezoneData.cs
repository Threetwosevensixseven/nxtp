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
using System.Text;

namespace NxtpData
{
    public class TimezoneList
    {
        public override string ToString()
        {
            string list = "Code\tTimezone Name\tSummer Time?";
            var x = TimeZoneInfo.GetSystemTimeZones();
            foreach (var item in x)
            {
                list += "\r\n" + item.Id.Replace(" ", "") + "\t"
                    + item.DisplayName + "\t"
                    + (item.SupportsDaylightSavingTime ? "Yes" : "No");
            }
            return list;
        }

        public static string ResolveAlias(string TimeZoneCode)
        {
            if (string.IsNullOrWhiteSpace(TimeZoneCode))
                return "gmtstandardtime";
            else if (TimeZoneCode == "gmt")
                return "gmtstandardtime";
            return TimeZoneCode;
        }
    }
}
