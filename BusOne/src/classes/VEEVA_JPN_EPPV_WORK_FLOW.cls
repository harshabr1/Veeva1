public class VEEVA_JPN_EPPV_WORK_FLOW {
    public enum RANGE { DAY, WEEK, MONTH, YEAR }
    public class RangeValue
    {
        public Integer value;
        public RANGE range;
    }
    
    public class WorkUnit
    {
        public RangeValue Frequency;
        public RangeValue Length;
    }
    
    public static RangeValue EPPV = new RangeValue();
    public static WorkUnit[] units = null;
    static
    {
        EPPV.value = 6;
        EPPV.range = RANGE.MONTH;
        
        units = new WorkUnit[2];
        
        RangeValue freq = new RangeValue();
        freq.value = 2;
        freq.range = RANGE.WEEK;
        RangeValue length = new RangeValue();
        length.value = 2;
        length.range = RANGE.MONTH;
        units[0] = new WorkUnit();
        units[0].Frequency = freq;
        units[0].Length = length;
        
        freq = new RangeValue();
        freq.value = 1;
        freq.range = RANGE.MONTH;
        length = new RangeValue();
        length.value = 4;
        length.range = RANGE.MONTH;
        units[1] = new WorkUnit();
        units[1].Frequency = freq;
        units[1].Length = length;                
    }
    
    public static List<Date> createWorkFlow(Date launchDate, Date purchaseDate)
    {
        // what about half period, does it count one cycle?         
        List<Date> work_flow = new List<Date>();
        if (purchaseDate < launchDate)
        {
            // Can customer purchase a drug before it is launched
            return work_flow;
        }    
        Date workflow_end_date = getNextRange(launchDate, EPPV);
        Integer idx = 0;
        Date period_end_date = getNextRange(purchaseDate, units[idx].Length);        
        Date next_date = purchaseDate;
        Date prev_date = next_date;
              
        while (idx < units.size() && 
             (next_date = getNextRange(next_date, units[idx].Frequency)).daysBetween(workflow_end_date) >= 0)
        {
            if (next_date.daysBetween(period_end_date) < 0)
            {
                idx++;
                next_date = prev_date;
                period_end_date = getNextRange(prev_date, units[idx].Length);
                continue;
            }
            work_flow.add(next_date);            
            prev_date = next_date;
        }
        
        return work_flow;        
    }
    
    private static Date getNextRange(Date today, RangeValue rv)
    {
        if (rv.range == RANGE.DAY)
        {
            return today.addDays(rv.value);
        }
        else if (rv.range == RANGE.WEEK)
        {
            return today.addDays(rv.value * 7);
        }
        else if (rv.range == RANGE.MONTH)
        {
            return today.addMonths(rv.value);
        }
        
        return today;
    }

}