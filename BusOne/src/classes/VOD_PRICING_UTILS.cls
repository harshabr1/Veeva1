public class VOD_PRICING_UTILS {
    public static boolean withinRange(Decimal value, Decimal min, Decimal max) {
        return !(min != null && value < min) && !(max != null && value > max);
    }

    // Returns true if [min1, max1] is within/overlapping [min2, max2] OR [min2, max2] is within/overlapping [min1, max1]
    // max1 and max2 can be null
    public static boolean isOverlapping(Decimal min1, Decimal max1, Decimal min2, Decimal max2) {
        if(withinRange(min1, min2, max2)) {
            //System.debug('Within Range: ' + '[' + min1 + ', ' + max1 + '] -> [' + min2 + ', ' + max2 + ']');
            return true;
        }
        if(max1 != null && withinRange(max1, min2, max2)) {
            //System.debug('Within Range: ' + '[' + min1 + ', ' + max1 + '] -> [' + min2 + ', ' + max2 + ']');
            return true;
        }
        if(withinRange(min2, min1, max1)) {
            //System.debug('Within Range: ' + '[' + min1 + ', ' + max1 + '] -> [' + min2 + ', ' + max2 + ']');
            return true;
        }
        if(max2 != null && withinRange(max2, min1, max1)) {
            //System.debug('Within Range: ' + '[' + min1 + ', ' + max1 + '] -> [' + min2 + ', ' + max2 + ']');
            return true;
        }
        //System.debug('NOT Within Range: ' + '[' + min1 + ', ' + max1 + '] -> [' + min2 + ', ' + max2 + ']');
        return false;
    }
    
    public static boolean datesOverlap(Date start1, Date end1, Date start2, Date end2) {
        return (start1 >= start2 && start1<= end2) || (start2 >= start1 && start2 <= end1);
        return false;
    }
}