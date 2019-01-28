global class VEEVA_LIMIT_WRAPPER{
    webservice static Integer getFutureCalls(){
         return Limits.getFutureCalls();   
    }
    
    webservice static Integer getLimitFutureCalls(){
         return Limits.getLimitFutureCalls();   
    }
}