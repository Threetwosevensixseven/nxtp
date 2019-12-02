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
    }
}
