/**************************************

**************************************/
public  class VEEVA_CSL  
{
    public static String errMsg = '';
    public static String sInfo = '';        //just for test
    public static Integer nrOfLimits = 0;   //just for test  
    
    //2013.05.23. NO longer needed! private static ID UserID;
    
    //when looking for Templates, we have to find those which has
    //Template Group = with a Public Group Name the current user 
    //belongs at this involve that All user belonging to a country 
    //must belong to a group  and that Group must be set as Template Group. !!! 
    //2013.05.23. NO longer needed! private static set<String>  UGroupNames = new set<String>();

    //Templates are RecordType based.  We have to fill this Map for all
    //accounts  involved in current  sampling process.
    public static Map<id, Account> MapAccRecTypes = new Map<Id,Account>();
    
    
    static Date minCallDate; //used just to limit the size of SL base result set   
    
    static Set<ID> AffectedAccounts = new set<ID>();           //set including accounts  involved in current sampling
    static Set<ID> ExtendedAffectedProducts = new set<ID>();   //set including  Products involved in current Sampling 
                                                               //AND the Class Products where the sampled prod belong
    
    
    /*********************************************************************************************
    Key is the concatenation of Account+Produt+LimitPerCall+templateID  
    *********************************************************************************************/
    static Map<String,Sample_Limit_vod__c> MapSL_toUpdate = new Map<String,Sample_Limit_vod__c>(); 
    static Map<String,Sample_Limit_vod__c> MapSL_toCreate = new Map<String,Sample_Limit_vod__c>();
    static set<Sample_Limit_vod__c> SL_toDelete = new Set<Sample_Limit_vod__c>();
    /********************************************************************************************/
        
    /** when we create limit based on a template set the Template_InUse__c field to true **/
    static Map<Id,Sample_Limit_vod__c> MapTemplateInUse = new Map<Id,Sample_Limit_vod__c>();
    
    /******************************************************************************************
    collect all exisitng sample limits  and templates  for Accounts/AccountTypes  and  products 
    present in the Call2_Sample_vod__c collection passed from the trigger. Not sure all needed.
    *******************************************************************************************/
    static List<Sample_Limit_vod__c> SLs_base_Product = new List<Sample_Limit_vod__c>();
    static List<Sample_Limit_vod__c> SLs_base_ProductPerCall = new List<Sample_Limit_vod__c>(); 

    //2013.05.23. NO longer needed static List<Sample_Limit_vod__c> SLTs_base_Product = new List<Sample_Limit_vod__c>();
    //2013.05.23. NO longer needed static List<Sample_Limit_vod__c> SLTs_base_ProductPerCall = new List<Sample_Limit_vod__c>();

    //2013.05.23  collect  SLTs   based on sharing rule
    static List<Sample_Limit_vod__c> SLTs_base_SharedRule = new List<Sample_Limit_vod__c>(); 
    //2013.05.23. collect  SLTs   based on sharing rule    
    
    static List<Sample_Limit_vod__c> SLs_base = new List<Sample_Limit_vod__c>(); //Needed by splitted scenario 
    /******************************************************************************************/
    
    /************************** collect all Product groups *******************************/
    static List<Product_Group_vod__c> ProductGroup_base = new List<Product_Group_vod__c>();
    /************************** collect all Product groups *******************************/ 
    
    static List<Call2_Sample_vod__c> CallSamples = new List<Call2_Sample_vod__c>();
    static List<Call2_Sample_vod__c> PseudoCallSamples = new List<Call2_Sample_vod__c>();
    /************************************************************************************
    PseudoCallSample  contain in-memory created  Call Sample records  where the sampled 
    product is actually the group product where the sampled products belongs at   *****
    ************************************************************************************/
    /*************Variable to hold if the org is multicurrency or not ****************/
    static boolean isMultiCurrency = false;
    
    

    
           /*****************************************************
    *Function called from within the Call Sample trigger.*
    *****************************************************/
    public static void Main(Call2_Sample_vod__c[] CSs)
    {
    try
    {
        system.debug('CS Batch size = ' + CSs.size());
        // check for multi currency here
        if (CSs.size() > 0) {
            SOBject csInterface = (SObject) CSs[0];
            String currCode = null;
            try {
                currCode = (String)csInterface.get('CurrencyIsoCode');
            } catch ( System.SObjectException e) {
            } 
        
            if (currCode  != null) {               
               isMultiCurrency = true;             
            }    
        }
        
        System.debug(' the value of multicurrency org isMulticurrency is   ' + isMultiCurrency);
        
        for(Call2_Sample_vod__c CS :CSs)
        {
            //if(Cs.Limit_Applied_vod__c == true) //Cs.Apply_Limit_vod__c == false ALWAYS FALSE IN IREP!!! 
            //   continue;  //Ed suggestion.  not claer how iRep behave
            
            System.debug('CSABA INIT DATA: accountID = ' + Cs.Account_vod__c + ' Entity_Reference_Id_vod__c = ' + Cs.Entity_Reference_Id_vod__c);
            Affectedaccounts.add(getAccountIDforCall(CS));
            
            CallSamples.add(CS);
            
            //calculate Mincalldate  in order to 
            //reduce the Sample Limit query base
            if (minCallDate == NULL) 
                minCalldate = CS.Call_Date_vod__c;
            else
            {
                if(minCalldate > CS.Call_Date_vod__c)
                   minCalldate = CS.Call_Date_vod__c;
            }               
        }
        system.debug('Min Call Date: ' + minCalldate + ' CS size = ' + CallSamples.size());
        
        
     if(Affectedaccounts.size() == 0)
     {
        System.debug('Missing Account on sample  Call object.  (Limit applied = TRUE for all Calls)');
        return;
     }  
            
     //2013.05.23. NO longer needed!  setUser();
     //2013.05.23. NO longer needed!  BuildUserGroupID();        

     BuildProdGrup_Base();              //build a Product Group  base   
     
     BuildExtendedAffectedProductList();//build affected product list including products from the current Sampling process and their Group Prod  
     
     BuildSampleLimit_Base();           //collect potential Sample limits/templates used to find existing Limits  or Templates for new limits

     CollectRecordtypes();  //2013.06.18.
    
    //2013.05.23.
    System.Debug('Shared templates collection. START');   
    CollectTemplate HelperObj = new CollectTemplate();
    HelperObj.getValidTemplate(minCalldate);
    System.Debug('Shared templates collection END');
    //2013.05.23.
         
     //2013.06.18.  CollectRecordtypes();
         
     /**** collect existing / New  Limits *********/
     StartOperation(CSs,false);              //second parameter = false  means is limit for product
     StartOperation(PseudoCallSamples,false);//PseudoCallSamples means is limit for product GROUP
     

     StartOperation(CSs,true);               //second parameter = true means is limit/Call
     StartOperation(PseudoCallSamples,true); //PseudoCallSamples means is limit for product GROUP
     /**** collect existing / New  Limits *********/     
     
     /**** update/create Limits *********/
     if(MapSL_toUpdate.size() > 0)
        UpsertInsertSampleLimit(MapSL_toUpdate.values());

     
     if(MapSL_toCreate.size() > 0)
        UpsertInsertSampleLimit(MapSL_toCreate.values());
     /**** update/create Limits *********/
       
        
     if(MapTemplateInUse.size() > 0)
        UpsertInsertSampleLimit(MapTemplateInUse.values());   
              
    }   
    catch(Exception ex)
    {
    errMsg = 'Exception of type ' + ex.getTypeName() + ' Occured at Line ' + ex.getLineNumber() + '  ' + ex.getMessage(); 
    CSs[0].adderror(errMsg, false);
    }
                
    }
    
  
        
    /***************************************
    try to avoid  Select  statements.
    If use try to gather other need info too
    ***************************************/
    Private static void CollectRecordtypes()
    {
        //first check in the collected SampleLimit 
        //records how many AccountRecord types are
        //if(MapAccRecTypes.size() >= AffectedAccounts.size())
        //   return;
        
        Account[] Accs = [Select Id, RecordType.Name, Name 
                          from Account 
                          where id in :AffectedAccounts
                          ];
                                                   
        for(Account theAcc :Accs)
        {
            MapAccRecTypes.put(theAcc.id,theAcc);  
        }
        
        System.Debug('CSABA3: affected accounts nr = ' +  MapAccRecTypes.size()); 
    }


    /***********************************************************************************************************************************************
    param1: the Current Sample Limit
    Param2 Rolling Period  of the Template
    param3: the current Limit Template
    param4: the current Call Sample
    ***********************************************************************************************************************************************/
    private static void AdjustSL_SE_Date_START(Sample_Limit_vod__c theSL, Decimal rollingPer,Sample_Limit_vod__c theSLT, Call2_Sample_vod__c theCS)
    {
        system.debug('SPLIT PERIODU: ' + theSLT.Split_Period_vod__c);
        
        if(theSLT.Split_Period_vod__c == NULL)
        {
        AdjustSL_SE_Date(theCS.Call_Date_vod__c,theSL,rollingPer,NULL);
        return; 
        }   
        
        if(theSLT.Split_Period_vod__c == 'Year')
        {
            if(theSLT.Limit_Per_Call_vod__c == true)
                {
                AdjustSL_SE_Date(theCS.Call_Date_vod__c,theSL,24,1); //in case of Limit  per call there is only 1 limit  for 24  months.
                return;
                }   
                
            
            Integer Jan1Scenario = CheckJanuary1_Scenario(theCS, theSL);
            List<Sample_limit_vod__c> SplittedSLs = FindExistingPL_NextSplitted(theSL,false,'Year',Jan1Scenario);
            System.debug('Handle From January 1 scenario  and to January 1 Scenario: ' + Jan1Scenario + ' Ssize= ' +SplittedSLs.size());
            if(Jan1Scenario == -1)
            {
            System.Debug('TO JANUARY 1 ');  
            AdjustSL_SE_Date_ToJanuary(theCS,theSL,theSL,SplittedSLs);
            return; 
            }
            
            if (Jan1Scenario == 1)
            {
            System.Debug('FROM JANUARY 1 ');    
            AdjustSL_SE_Date_FromJanuary(theCS,theSL,theSL,SplittedSLs);    
            return; 
            }
                        

            Integer CallYear = theCS.Call_Date_vod__c.year();
            Integer LimitYear = theSL.Start_Date_vod__c.year();
            if(CallYear < LimitYear)
                {
                System.Debug('Cross year Adjustment trwat different!!');    
                AdjustCreate_CrossYearSplittedLimits(theCS,theSL,theSLT,SplittedSLs);
                return;
                }
            
            
            Integer DaysBetween = theSL.Start_Date_vod__c.daysBetween(theCS.Call_Date_vod__c);
            
            System.Debug('BEFORE ADJUSTMENT: SD = ' + theSL.Start_date_vod__c + ' ED = ' + theSL.End_Date_vod__c);
            AdjustSL_SE_Date_SPLITTED_YEAR(theCS.Call_Date_vod__c,theSL,0, DaysBetween);  
            System.Debug('AFTER ADJUSTMENT: SD = ' + theSL.Start_date_vod__c + ' ED = ' + theSL.End_Date_vod__c);  
    
    
            //build the Map Key
            String MapKey = String.valueOf(theSL.Account_vod__c) + 
                            String.ValueOf(theSL.Product_vod__c) + 
                            string.ValueOf(theSL.Limit_Per_Call_vod__c);
                            
            if (theSL.Limit_Quantity_vod__c != null) {
                // check for both amount and quantity case
                if (theSL.Limit_Amount_vod__c != null) {
                    MapKey += 'BOTH_AMT_QTY'; 
                } else {
                    MapKey += 'QTY';    
                }       
            } else if (theSL.Limit_Amount_vod__c != null) {
                MapKey += 'AMT';     
            }
            
            MapKey += '_0'; 
            
                                    
            CheckUniquenessExistingSL(theSL,MapKey);
            
            Date newSD = theSL.End_Date_vod__c;
            newSD = newSD.addDays(1);
            
            Integer counter = 1;
            for(Sample_Limit_vod__c SplittedSL :SplittedSLs)  
                {
                    System.Debug('BEFORE ADJUSTMENT: SD = ' + SplittedSL.Start_date_vod__c + ' ED = ' + SplittedSL.End_Date_vod__c);
                    SplittedSL = AdjustSL_SE_Date_SPLITTED_YEAR(newSD,SplittedSL,counter,DaysBetween);
                    newSD = SplittedSL.End_Date_vod__c;  
                    newSD = newSD.addDays(1);
                    
                    System.Debug('AFTER ADJUSTMENT: SD = ' + SplittedSL.Start_date_vod__c + ' ED = ' + SplittedSL.End_Date_vod__c);
                
                    MapKey = String.valueOf(SplittedSL.Account_vod__c) + 
                                    String.ValueOf(SplittedSL.Product_vod__c) + 
                                    string.ValueOf(SplittedSL.Limit_Per_Call_vod__c); 
                                    
                    if (SplittedSL.Limit_Quantity_vod__c != null) {
                        // check for both amount and quantity case
                        if (SplittedSL.Limit_Amount_vod__c != null) {
                            MapKey += 'BOTH_AMT_QTY'; 
                        } else {
                            MapKey += 'QTY';    
                        }       
                    } else if (SplittedSL.Limit_Amount_vod__c != null) {
                        MapKey += 'AMT';     
                    }
                    
                    MapKey += '_' + string.ValueOf(counter);
                          
                    
                    CheckUniquenessExistingSL(SplittedSL,MapKey);
                    
                    counter = counter + 1;          
                }
            return; 
        }
        
        if(theSLT.Split_Period_vod__c == '12Months')
        {
            if(theSLT.Limit_Per_Call_vod__c == true)
                {
                AdjustSL_SE_Date(theCS.Call_Date_vod__c,theSL,24,1); //in case of Limit  per call there is only 1 limit  for 24  months.        
                return;  
                }
                                        
            List<Sample_limit_vod__c> SplittedSLs = FindExistingPL_NextSplitted(theSL,false,'12Months',0);  
    
            AdjustSL_SE_Date(theCS.Call_Date_vod__c,theSL,12,1);  
            Date newSD = theSL.end_Date_vod__c;
            newSD = newSD.addDays(1);
                
            for(Sample_Limit_vod__c SplittedSL :SplittedSLs) 
                { 
                 if(SplittedSL.End_Date_vod__c.year() != 2099)
                    AdjustSL_SE_Date(newSD,SplittedSL,12,2);
                 else
                    {
                    Date newED = SplittedSL.End_Date_vod__c;
                    AdjustSL_SE_Date(newSD,SplittedSL,12,3);
                    SplittedSL.End_Date_vod__c = newED; 
                    } 
                       
              newSD = SplittedSL.end_Date_vod__c;
              newSD = newSD.addDays(1);      
             }      
      }
      
      
    }
    
    /**************************************************************************************************
    param1: the current Call Sample record
    param2: the current Sample Limit record
    Retur values
    -1 ToJanuary 1
    0  No January1
    +1 from January 1
    **************************************************************************************************/
    private static Integer CheckJanuary1_Scenario(Call2_Sample_vod__c theCS, Sample_Limit_vod__c theSL)
    {
        
        Date CallDate = theCs.Call_Date_vod__c;
        //Integer theCallMonth = Calldate.month();
        //Integer theCallday = calldate.day();
        
        if(Calldate.month() == 1  && calldate.day()  == 1)
        return -1;
        
        Date SLdate = theSL.Start_Date_vod__c;
        //Integer SL_Month= SLdate.month();
        //Integer SL_day = SLdate.day(); 
        
        if(SLdate.month() == 1 && SLdate.day() == 1)
        return 1;
        
        return 0;
        
    }
    
    /*********************************************************************************************************************************************************************************
    Start point:  we have 4 limits  L1:Mar-Dec; L2:Jan-Dec: L3:Jan-Mar; L4:Mar-forever(Q=0)  
    end Point  we need 3+1 limits   L1;Jan-dec; L2:Jan-dec: L3:Jan-Mar(Q=0) L4:Mar-forever(Q=0)
    To simplify processing  We will not delete  any limits.  Just adjust some dates and Make the L3  to have LimitQty. = 0
    L1  is the current limit(theSL);  L2-4  are in the  NextLimits list  
    *********************************************************************************************************************************************************************************/
    private static void AdjustSL_SE_Date_ToJanuary(Call2_Sample_vod__c theCS, Sample_Limit_vod__c theSL, Sample_Limit_vod__c theCurrentTemplate, List<Sample_Limit_vod__c> NextLimits)
    {
        Integer splitsize = NextLimits.size();
        
        //1.Adjsut theSL
        AdjustSL_SE_Date(theCS.Call_date_vod__c,theSL,12,null);
        
    
        //2 Do not touch L2
        
        
        //3.1 delete L3
        if(splitsize >=  2)
            //SL_toDelete.add(NextLimits[1]);
            delete NextLimits[1];   
        
                
        /*****************4.2 adjsut L4 ************************************/ 
        Date ForeverSD = NextLimits[0].End_Date_vod__c;
        ForeverSD = ForeverSD.addDays(1);       
        
        if(splitsize >=  3)
        {
        NextLimits[2].Start_Date_vod__c = ForeverSD;
        String MapKey = String.valueOf(NextLimits[2].Account_vod__c) + 
                    String.ValueOf(NextLimits[2].Product_vod__c) + 
                    string.ValueOf(NextLimits[2].Limit_Per_Call_vod__c);
                    
        // update the map key based on quantity and value
        if (NextLimits[2].Limit_Quantity_vod__c != null) {
            // check for both amount and quantity case
            if (NextLimits[2].Limit_Amount_vod__c != null) {
                MapKey += 'BOTH_AMT_QTY'; 
            } else {
                MapKey += 'QTY';    
            }       
        } else if (NextLimits[2].Limit_Amount_vod__c != null) {
            MapKey += 'AMT';     
        }

                     
        MapKey = MapKey + '_0';          
                    
        System.Debug('CSABA: New SL KEY =' + MapKey);   
        CheckUniquenessExistingSL(NextLimits[2],MapKey);            
        }
        /********************************************************************/
    }
    
    /***********************************************************************************************************************************************************************************
    Start Point: we have 3 Limits:              L1:jan-dec L2:jan-dec  L3:Jan-forever(Q=0) 
    End Point:   we need 4 Limits    L0:Oct-Dec L1:Jan-dec L2:jan-Oct  L3:Oct-forever(Q=0)  
    ***********************************************************************************************************************************************************************************/
    private static void AdjustSL_SE_Date_FromJanuary(Call2_Sample_vod__c theCS, Sample_Limit_vod__c theSL, Sample_Limit_vod__c theCurrentTemplate, List<Sample_Limit_vod__c> NextLimits)
    {
        Integer splitsize = NextLimits.size();
        String MapKey;
        
        //1 create L0
        /**************** create new Limit  from Call date to end of taht Year *********************************/
        Integer theYear = theCS.Call_Date_vod__c.year();     
        Date NewEndDate = Date.newInstance(theYear, 12, 31); 
        Sample_Limit_vod__c NewSL = CreateSampleLimitFromDate(theCS,theCurrentTemplate,theCS.Call_Date_vod__c,NewEndDate,0);  
        /**************** create new Limit  from Call date to end of taht Year *********************************/       
        
        
        //2 do not touch L1
        
        //3 adjsut L2 End date
        if(splitsize >= 1)
        {
        System.debug('BEFORE UPDATE: SD = ' + NextLimits[0].Start_Date_vod__c + ' ED = ' + NextLimits[0].End_Date_vod__c);
        NewEndDate = theCS.Call_Date_vod__c;
        NewEndDate = NewEndDate.addYears(2);
        NewEndDate = NewEndDate.addDays(-1);
        NextLimits[0].End_Date_vod__c = NewEndDate;
        MapKey = String.valueOf(NextLimits[0].Account_vod__c) + 
                    String.ValueOf(NextLimits[0].Product_vod__c) + 
                    string.ValueOf(NextLimits[0].Limit_Per_Call_vod__c);                
                   
        // now based on the quantity or amount update the map key
        if (NextLimits[0].Limit_Quantity_vod__c != null) {
            // check for both amount and quantity case
            if (NextLimits[0].Limit_Amount_vod__c != null) {
                MapKey += 'BOTH_AMT_QTY'; 
            } else {
                MapKey += 'QTY';    
            }       
        } else if (NextLimits[0].Limit_Amount_vod__c != null) {
            MapKey += 'AMT';     
        }  
                
                     
        MapKey = MapKey + '_0';          
                        
        CheckUniquenessExistingSL(NextLimits[0],MapKey);
        System.debug('AFTER UPDATE: SD = ' + NextLimits[0].Start_Date_vod__c + ' ED = ' + NextLimits[0].End_Date_vod__c);           
        }
    
            

        
        //4 adust L3 Start date
        if(splitsize >= 2)
        {
        System.debug('BEFORE UPDATE: SD = ' + NextLimits[1].Start_Date_vod__c + ' ED = ' + NextLimits[1].End_Date_vod__c);
        NextLimits[1].start_Date_vod__c = NewEndDate.addDays(1);
        MapKey = String.valueOf(NextLimits[1].Account_vod__c) +   
                    String.ValueOf(NextLimits[1].Product_vod__c) + 
                    string.ValueOf(NextLimits[1].Limit_Per_Call_vod__c); 
        
        if (NextLimits[1].Limit_Quantity_vod__c != null) {
            // check for both amount and quantity case
            if (NextLimits[1].Limit_Amount_vod__c != null) {
                MapKey += 'BOTH_AMT_QTY'; 
            } else {
                MapKey += 'QTY';    
            }       
        } else if (NextLimits[1].Limit_Amount_vod__c != null) {
            MapKey += 'AMT';     
        }   
                     
        MapKey = MapKey + '_1';          
                        
        CheckUniquenessExistingSL(NextLimits[1],MapKey);
        System.debug('AFTER UPDATE: SD = ' + NextLimits[1].Start_Date_vod__c + ' ED = ' + NextLimits[1].End_Date_vod__c);           
        }
        
        
    }   
    
    /***************************************************************************************************************************************
    Initial: we have 4 Limits  L1:mar-dec;  L2:Jan-dec: L3:Jan-mar; L4:mar-forever
    After:   we have 4 limits(but other 4)  L0:Oct-Dec; L1:Jan-dec; L2:Jan-Oct;L3 deleted L4:Oct-forever;
    Create New limit form call Date to end of the Call year
    Adjust start Date of the current limit  to Jan 1
    Adjust  the end date of the first in the List to call date 
    Adjust the start date of the second to calldate + 1 and make Limit quantity = 0 
    Leave the last as it is.  there will be 2 Limit with quantity = 0  but no harm
    ***************************************************************************************************************************************/
    private static void AdjustCreate_CrossYearSplittedLimits(Call2_Sample_vod__c theCS, Sample_Limit_vod__c theSL, Sample_Limit_vod__c theCurrentTemplate, List<Sample_Limit_vod__c> NextLimits)
    {

        Integer splitsize = NextLimits.size();
        Date NewSD;
        
        /* Step 1 **************** create new Limit  from Call date to end of taht Year *********************************/
        Integer theYear = theCS.Call_Date_vod__c.year();     
        Date NewEndDate = Date.newInstance(theYear, 12, 31); 
        Sample_Limit_vod__c NewSL = CreateSampleLimitFromDate(theCS,theCurrentTemplate,theCS.Call_Date_vod__c,NewEndDate,0);  
        /* step 1 **************** create new Limit  from Call date to end of taht Year *********************************/
                
        /* Step 2 **** Adjust  the Current Limit startdate L1 ********/    
        NewSD = NewEndDate.addDays(1);
        theSL.Start_date_vod__c = NewSD;
        //build  the Map Key
        String MapKey = String.valueOf(theSL.Account_vod__c) + 
                        String.ValueOf(theSL.Product_vod__c) + 
                        string.ValueOf(theSL.Limit_Per_Call_vod__c); 
        
        if (theSL.Limit_Quantity_vod__c != null) {
            // check for both amount and quantity case
            if (theSL.Limit_Amount_vod__c != null) {
                MapKey += 'BOTH_AMT_QTY'; 
            } else {
                MapKey += 'QTY';    
            }       
        } else if (theSL.Limit_Amount_vod__c != null) {
            MapKey += 'AMT';     
        }
        
         MapKey += '_0';                          
        
        CheckUniquenessExistingSL(theSL,MapKey);        
        /* Step 2 *** Adjust  the Current Limit startdate L1 ********/
        

        /* Step 3 ******* adjust End Date of the  first in the List L2 *********/  
        //Integer CallMonth = theCS.Call_Date_vod__c.month();
        //Integer CallDay = theCS.Call_Date_vod__c.day();     
        NewEndDate = Date.newInstance(theYear+2, theCS.Call_Date_vod__c.month(), theCS.Call_Date_vod__c.day()); 
        NewEndDate = NewEndDate.addDays(-1);
        if(splitsize >= 1)
        {
        NextLimits[0].End_Date_vod__c = NewEndDate;
        //build  the Map Key
        MapKey = String.valueOf(NextLimits[0].Account_vod__c) +   
                 String.ValueOf(NextLimits[0].Product_vod__c) + 
                 string.ValueOf(NextLimits[0].Limit_Per_Call_vod__c); 
                 
        if (NextLimits[0].Limit_Quantity_vod__c != null) {
            // check for both amount and quantity case
            if (NextLimits[0].Limit_Amount_vod__c != null) {
                MapKey += 'BOTH_AMT_QTY'; 
            } else {
                MapKey += 'QTY';    
            }       
        } else if (NextLimits[0].Limit_Amount_vod__c != null) {
            MapKey += 'AMT';     
        }
        
         MapKey += '_1';   
                        
        CheckUniquenessExistingSL(NextLimits[0],MapKey);            
        }      
        /* step 3 ****** adjust End Date of the  first in the List L2 *********/

                      
        /*  4 ************* Delete L3 ***************/
        //SL_toDelete.add(NextLimits[1]);
        if(splitsize >= 2)
          delete NextLimits[1];
        /*  4 ************* Delete L3 ***************/
        
        
        
        /* step 5 **********************************************************/
        if(splitsize >= 3)
        {
        NewSD = NewEndDate.addDays(1);
        NextLimits[2].Start_Date_vod__c = NewSD;
        //build  the Map Key
        MapKey = String.valueOf(NextLimits[2].Account_vod__c) + 
                 String.ValueOf(NextLimits[2].Product_vod__c) + 
                 string.ValueOf(NextLimits[2].Limit_Per_Call_vod__c);
                 
        // now based on the quantity or amount update the map key
        if (NextLimits[2].Limit_Quantity_vod__c != null) {
            // check for both amount and quantity case
            if (NextLimits[2].Limit_Amount_vod__c != null) {
                MapKey += 'BOTH_AMT_QTY'; 
            } else {
                MapKey += 'QTY';    
            }       
        } else if (NextLimits[2].Limit_Amount_vod__c != null) {
            MapKey += 'AMT';     
        }
        
        MapKey += '_2';
                 
                                                    
        CheckUniquenessExistingSL(NextLimits[2],MapKey);
        }       
        /* Step 5 ***********************************************************/
                
    }
    
    /***********************************************************************************************************************************************
    
    ***********************************************************************************************************************************************/
    private static Sample_Limit_vod__c AdjustSL_SE_Date_SPLITTED_YEAR(Date theNewSD, Sample_Limit_vod__c theSL, Integer index, Integer daysBetween)
    {
          
        Date SD = theSL.Start_Date_vod__c;
           
        if(index == 0)
        {
        theSL.Start_Date_vod__c = theNewSD;
        Integer Year = theSL.Start_Date_vod__c.year();
        Date ED = date.newinstance(Year, 12, 31);
        theSL.End_Date_vod__c = ED; 
        return theSL;           
        }
        
        if(index == 1)
        {
            if(theNewSD == theSL.Start_Date_vod__c)
               return theSL;
            else
            {
            theSL.Start_Date_vod__c = theNewSD;
            theSL.End_Date_vod__c = theSL.End_Date_vod__c.addYears(-1); 
            }       
        }
        
        if(index == 2)
        {
        Date ED = theSL.End_Date_vod__c;
        ED = Ed.addDays(daysBetween);
        theSL.End_Date_vod__c = ED;
        
        if(theNewSD < theSL.Start_Date_vod__c)
           theSL.Start_Date_vod__c = theNewSD;

        return theSL;
        }
        
        if(index == 3)
        {
        theSL.Start_Date_vod__c = theNewSD;
        
        if(theNewSD < theSL.Start_Date_vod__c)
            theSL.End_Date_vod__c = theSL.End_Date_vod__c.addYears(-1);             

        return theSL;
        }        
        
        return theSL;
    }
    
    /**************************************************************************************************************************************
    Adjust start end date of an existing Sample Limit  based on the Call date  and rolling periond.
    Start date  should  be the CallDate
    End date should  be StartDate + Roling Period
    **************************************************************************************************************************************/
    private static Sample_Limit_vod__c AdjustSL_SE_Date(Date thecallDate, Sample_Limit_vod__c theSL, Decimal rollingPer,Integer splitIndex)
    {
    if(rollingPer == NULL)
    {
       System.debug('CSABA: We are not adjusting a fixed period limit');    
       return NULL; 
    }   
        
    system.Debug('CSABA: ADJUSTING  Datetime for Acc/Prod: ' + theSL.Account_vod__r.Name + '/' + theSL.Product_vod__r.Name + 
                 ' SD = ' + theSL.Start_Date_vod__c + ' ED = ' + theSL.End_Date_vod__c + ' theSL = ' + theSL);  
        
    system.Debug('CSABA RollingPeriod = ' + rollingPer);    

    theSL.Start_Date_vod__c = thecalldate;
    Date endDate = thecalldate.addMonths(Integer.Valueof(rollingPer));   

    //2013.05.11. ALWAYS SUBSTREACT 1 DAY
    //Integer CalldateDAY = thecalldate.day();
    //Integer EndDateDAY = endDate.day();
    
    //if(CalldateDAY == EndDateDAY)
       endDate = endDate.addDays(-1);
       
    //if new end date < today  DO NOT ADJUST!!!
    if(endDate < system.today())  
    {
       System.Debug('Start/end date adjustment denied.  New End Date would be in the past');   
       return  theSL;
    }        
       
    theSL.End_Date_vod__c = endDate;
    
    system.Debug('CSABA: ADJUSTED  Datetime for Acc/Prod: ' + theSL.Account_vod__r.Name + '/' + theSL.Product_vod__r.Name + ' SD = ' + theSL.Start_Date_vod__c + ' ED = ' + theSL.End_Date_vod__c + ' theSL = ' + theSL);   
    
    //build  the Map Key
    String MapKey = String.valueOf(theSL.Account_vod__c) + 
                    String.ValueOf(theSL.Product_vod__c) + 
                    string.ValueOf(theSL.Limit_Per_Call_vod__c);
    
    // update the map key
    // now based on the quantity or amount update the map key
    if (theSL.Limit_Quantity_vod__c != null) {
        // check for both amount and quantity case
        if (theSL.Limit_Amount_vod__c != null) {
                MapKey += 'BOTH_AMT_QTY'; 
        } else {
                MapKey += 'QTY';    
       }       
    } else if (theSL.Limit_Amount_vod__c != null) {
            MapKey += 'AMT';     
    }
                    
    if(splitindex != NULL)
           MapKey = MapKey + '_' + splitIndex;  //         
                        
    CheckUniquenessExistingSL(theSL,MapKey);
    
    return theSL;
    }


     /******************************************
     Create the Sample Limit base.  Collect all 
     possible SLs or SL templates and dispatch 
     them into dedicated List collection. 
     ******************************************/
     private static void BuildSampleLimit_Base()
     {

                             /*SLs_base =  [select Account_vod__c,
                                          Account_vod__r.RecordType.Name,Account_vod__r.Name,
                                          User_vod__c,
                                          Account_Types_vod__c,
                                          Start_Date_vod__c,End_Date_vod__c,
                                          Product_vod__c,Product_vod__r.Name,  
                                          Sample_Limit_Type_vod__c,
                                          Rolling_Period_vod__c,  
                                          Limit_Per_Call_vod__c,
                                          Limit_Quantity_vod__c,
                                          Limit_Amount_vod__c,   
                                          Enforce_Limit_vod__c,  
                                          Template_Group_vod__c,
                                          Template_Unique_Key_vod__c,
                                          Split_Period_vod__c
                                          from Sample_Limit_vod__c
                                          where 
                                          //2013.05.23.(
                                          //2013.05.23.  (Account_vod__c != NULL and Account_vod__c in :AffectedAccounts and Product_vod__c in :ExtendedAffectedProducts)
                                          //2013.05.23.  or
                                          //2013.05.23.  (Account_vod__c = NULL and Account_Types_vod__c != NULL and Product_vod__c in :ExtendedAffectedProducts)
                                          //2013.05.23.) //add Affected RecordTypes in the above OR  not just Account_Types_vod__c != NULL
                                          Account_vod__c != NULL and Account_vod__c in :AffectedAccounts and Product_vod__c in :ExtendedAffectedProducts
                                          and 
                                          End_Date_vod__c >= :minCalldate
                                          order by Account_vod__c, Product_vod__c,
                                                   Limit_Per_Call_vod__c,
                                                   End_Date_vod__c asc
                                          ]; */

               
        // check for multi currency or not and query accordingly 
        System.debug(' the value of multicurrency before query isMulticurrency is   ' + isMultiCurrency);               
        if (isMultiCurrency) {
            SLs_base = Database.query('select Account_vod__c,Account_vod__r.RecordType.Name,Account_vod__r.Name,' +
                               'User_vod__c,Account_Types_vod__c,Start_Date_vod__c,End_Date_vod__c,Product_vod__c,Product_vod__r.Name,CurrencyIsoCode,' +  
                               'Sample_Limit_Type_vod__c,Rolling_Period_vod__c, Limit_Per_Call_vod__c,Limit_Quantity_vod__c,Limit_Amount_vod__c,' +   
                               'Enforce_Limit_vod__c, Template_Group_vod__c,Template_Unique_Key_vod__c,Split_Period_vod__c from Sample_Limit_vod__c ' +
                               'where Account_vod__c != null and Account_vod__c in :AffectedAccounts and Product_vod__c in :ExtendedAffectedProducts ' +
                               'and End_Date_vod__c >= :minCalldate order by Account_vod__c, Product_vod__c, Limit_Per_Call_vod__c,End_Date_vod__c asc');
        } else {
             SLs_base = Database.query('select Account_vod__c,Account_vod__r.RecordType.Name,Account_vod__r.Name,' +
                               'User_vod__c,Account_Types_vod__c,Start_Date_vod__c,End_Date_vod__c,Product_vod__c,Product_vod__r.Name,' +  
                               'Sample_Limit_Type_vod__c,Rolling_Period_vod__c, Limit_Per_Call_vod__c,Limit_Quantity_vod__c,Limit_Amount_vod__c,' +   
                               'Enforce_Limit_vod__c, Template_Group_vod__c,Template_Unique_Key_vod__c,Split_Period_vod__c from Sample_Limit_vod__c ' +
                               'where Account_vod__c != null and Account_vod__c in :AffectedAccounts and Product_vod__c in :ExtendedAffectedProducts ' +
                               'and End_Date_vod__c >= :minCalldate order by Account_vod__c, Product_vod__c, Limit_Per_Call_vod__c,End_Date_vod__c asc');
        
        }       
        
        System.Debug('debug message after changing to query to support  = ' + nrOfLimits);
        nrOfLimits = SLs_base.size();
        System.Debug('CSABA SLBASE = ' + nrOfLimits);
               
        //distribute Sample limits  base  into the corresponding List 
        for(Sample_Limit_vod__c theSL :SLs_base)
        {
            
        System.debug('CSABA BuildBase: ' + theSL.Account_vod__r.Name + '/' + theSL.Product_vod__r.Name + '/' + 
                                           theSL.Start_Date_vod__c + '/' + theSL.End_Date_vod__c);  
        
         
        if(theSL.User_vod__c != NULL)
           continue;  //exclude User based Sample Limit 
           
        //exclude those Sample Limits  which does not belongs  to the affected products    
        if(ExtendedAffectedProducts.contains(theSL.Product_vod__c) == false)
            { 
            system.Debug('CSABA: Skip non-affected Product');   
            continue;   
            }           
        

        if(theSL.Account_vod__c != NULL) //EXISTING LIMIT
            {
                //exclude those Sample Limits  which does not belongs  to the affected accounts   
                if(Affectedaccounts.contains(theSL.Account_vod__c) == false)
                {
                  system.Debug('CSABA:  Skip non-affected Account');    
                  continue; 
                }
                                        
                if(theSL.Limit_Per_Call_vod__c == true)
                {
                   SLs_base_ProductPerCall.add(theSL);
                   System.debug('CSABA Build_P/C_Base: ' + theSL.Account_vod__r.Name + '/' + theSL.Product_vod__r.Name + '/' + theSL.Start_Date_vod__c + '/' + theSL.End_Date_vod__c);
                }
                else 
                {
                   SLs_base_Product.add(theSL);
                   System.debug('CSABA Build_P_Base: ' + theSL.Account_vod__r.Name + '/' + theSL.Product_vod__r.Name + '/' + theSL.Start_Date_vod__c + '/' + theSL.End_Date_vod__c);
                }
            }
        else //EXISTING TEMPLATES  2013.05.23. No longer used. delete later
            {
             //2013.05.23. No longer used.   if(theSL.Limit_Per_Call_vod__c == true)
             //2013.05.23. No longer used.      SLTs_base_ProductPerCall.add(theSL);
             //2013.05.23. No longer used.   else 
             //2013.05.23. No longer used.      SLTs_base_Product.add(theSL);                
            }     
        } 
        
        /****************************************************************/
        //just for debugging purposes
        sInfo = 'Total Base = ' + SLs_base.size() + 
                ' SL_P = ' + SLs_base_Product.size() + 
                ' SL_PPerCall = ' +  SLs_base_ProductPerCall.size() +  
               // ' SLT_P = ' + SLTs_base_Product.size() + 
               // ' SLT_PPerCall = ' +  SLTs_base_ProductPerCall.size() + 
                ' mincall Date = ' + minCalldate + 
                ' ExtendedAffected Products = ' + ExtendedAffectedProducts.size();  
        /****************************************************************/   
        system.Debug('CSABA: ' + sInfo);        
        sInfo = '';
     }
     
    /**********************************************************************************************************************************************************
    Iterate through the original base  and find the next splitted
    **********************************************************************************************************************************************************/   
    private static Sample_Limit_vod__c[] FindExistingPL_NextSplitted(Sample_Limit_vod__c theCurrentSL, Boolean LpC, String SplitPeriod, Integer To_FromJanuary1)
    {
        
        Date newstartDate = theCurrentSL.end_Date_vod__c; 
        newstartDate = newstartDate.addDays(1);
        system.debug('newstartDate = ' + newstartDate);
        
        Id accId = theCurrentSL.Account_vod__c;
        ID ProdId = theCurrentSL.Product_vod__c;    
        
        List<Sample_Limit_vod__c> splitedSLList = new List<Sample_Limit_vod__c>();
        
        
        for(Sample_Limit_vod__c theSL :SLs_base)
        {
              System.debug('CSABA SPLIT Acc = ' + theSL.Account_vod__r.Name + ' prod = ' + theSL.Product_vod__r.Name +  ' SD = ' + theSL.Start_Date_vod__c + ' ED = ' + theSL.End_Date_vod__c); 
                 
              if(theSL.Account_vod__c != accId  || 
                 theSL.Product_vod__c != ProdID ||
                 theSL.Limit_Per_Call_vod__c != LpC ||
                 theSL == theCurrentSL
                )
                 continue;
                 
              if(theSL.Start_Date_vod__c != newstartDate)
                 return splitedSLList;
              else
              {
                 splitedSLList.add(theSL);  
                 newstartDate = theSL.End_Date_vod__c;
                 newstartDate = newstartDate.addDays(1);
              }
              
              if(splitedSLList.size() == 2 && SplitPeriod == 'Year' && To_FromJanuary1 == 1)
                 break;   
              
              if(splitedSLList.size() == 3 && SplitPeriod == 'Year')
                 break;  
                 
              if(splitedSLList.size() == 2 && SplitPeriod == '12Months')
                 break;              
          
        }
        
        
        return splitedSLList;
        
    }
     
     /****************************************************************************************
     Identify Exisitng current OR closest future Sample Limit for the time of call
     Params:  theCS  the current Call sample records
              LpC  Limit per call flag  used to know  in which List to look for the Limit
     return:  The identified Sample Limit       
     ****************************************************************************************/
     private static  List<Sample_Limit_vod__c> FindExistingPL(Call2_Sample_vod__c theCS, Boolean LpC)
     {
        List<Sample_Limit_vod__c> CurrentLimits = new List<Sample_Limit_vod__c> ();
        Id theAcc = getAccountIDforCall(theCS);
        ID theProd = theCS.Product_vod__c;
        Date theCallDate = theCS.Call_Date_vod__c; 
        
        System.Debug('Find Exisitng Limit for: AccountID=' + theAcc + ' ProductID = ' + theProd + ' CallDate = ' + theCallDate);
        
        List<Sample_Limit_vod__c> SL_Base = new List<Sample_Limit_vod__c>();
        if(LpC == true)
           SL_Base = SLs_base_ProductperCall;
        else
           SL_Base = SLs_base_Product;
        
        System.Debug('Base size = ' + SL_Base.size());
        for(Sample_Limit_vod__c theSL :SL_Base)
        {
            system.Debug('CSABA: SL Acc/Name=' + theSL.Account_vod__c + '/' + theSL.Account_vod__r.Name + 
                         ' SLProduct = ' + theSL.Product_vod__r.Name + ' CallDate = ' + theCS.Call_Date_vod__c + 
                         ' CallAcc = ' + theAcc);
            
            
            if(theSL.Account_vod__c != theAcc || theSL.Product_vod__c != theProd)
               continue;      //exclude non-affected Account and Product  limits.                       
               

            if(theSL.End_Date_vod__c < theCallDate)
               continue; 
                           
            //if we are here we found a matching sample Limit
            String info = LpC == false ? 'Product':'Limit per Call ';
            System.Debug('CSABA: SL ' + info + ' identified: ' + theSL);  
            
            CurrentLimits.add(theSL);                
        }
        
        return CurrentLimits;
     }   
    

     /************************************************************************************************
     Find Existing Sample Limit template valid  for the Call Date and User Group (if Usergroup exitst)
     Params:  the current Call Sample record
              LPC  True for LimitPerCall  otherwise false.  Used to know in which List to iterate.
     2013.05.23. No longer needed!
     private static Sample_Limit_vod__c FindExistingPLTemplate(Call2_Sample_vod__c theCS, Boolean LPC)
     {
        Sample_Limit_vod__c CurrentTemplate = NULL;
        
        ID callProd = theCS.Product_vod__c;
        ID accID = getaccountIdforCall(theCS);
        string theAccRecordType =  MapAccRecTypes.get(accID).Recordtype.Name;
        Date callDate = theCS.Call_Date_vod__c;
        
        System.Debug('CallProd = ' + callProd + ' Accrectype = ' + theAccRecordType + ' callDate = ' + callDate);

        List<Sample_Limit_vod__c>  SLT_Base = new List<Sample_Limit_vod__c>();
        if(LpC == true)
        {
           system.debug('Looking  for template for ProdCall');  
           SLT_Base = SLTs_base_ProductPerCall;
        }
        else
        {
           system.debug('Looking  for template for Prod');
           SLT_Base = SLTs_base_Product; 
        }  
    
        system.debug('Template base size = ' + SLT_base.size()); 
        for(Sample_Limit_vod__c theSLT :SLT_Base)
        {
            ID theSLTProduct = theSLT.Product_vod__c; 
            system.debug('SLT Prod = ' + theSLTProduct + ' SLT AccRecType = ' + theSLT.Account_Types_vod__c); 
            
            
            if(theAccRecordType != theSLT.Account_Types_vod__c)
               continue;
            system.debug('Rec type Matched');     
            
   
            if(theSLTProduct != callProd)
               continue;
            system.debug('Prod Matched');     
            
            
            
            if(callDate > theSLT.End_Date_vod__c || callDate < theSLT.Start_Date_vod__c)
               continue;
               
            system.debug('timeframe  Matched');  
               
            
            String theGroup = NULL;
            if(theSLT.Template_Group_vod__c != NULL)  
            {
                String[] GroupItems = theSLT.Template_Unique_Key_vod__c.split('_');
                Integer sizu = GroupItems.size();
                theGroup = GroupItems[sizu-1]; 
                System.debug('theGROUP = ' + theGroup);
                if(UGroupNames.contains(thegroup) == true)
                   {
                   System.debug('CSABA GROUP Template Identified: ' + theSLT);  
                   return theSLT;
                   }
                else
                   continue;   
            }
            else
            {
                CurrentTemplate = theSLT; 
                System.debug('CSABA Generic Template Identified: ' + theSLT);  
            }   
        }  
        
        return CurrentTemplate;
     }
     ************************************************************************************/
     
     
private static List<Sample_Limit_vod__c> FindExistingPLTemplate_Shared(Call2_Sample_vod__c theCS, Boolean LPC)
     {
        List<Sample_Limit_vod__c> CurrentTemplate = new List<Sample_Limit_vod__c> ();
        
        
        ID callProd = theCS.Product_vod__c;
        ID accID = getaccountIdforCall(theCS);
        string theAccRecordType =  MapAccRecTypes.get(accID).Recordtype.Name;
        Date callDate = theCS.Call_Date_vod__c;
        
        System.Debug('CallProd = ' + callProd + ' Accrectype = ' + theAccRecordType + ' callDate = ' + callDate);
 
    
        system.debug('Template base size = ' + SLTs_base_SharedRule.size()); 
        for(Sample_Limit_vod__c theSLT :SLTs_base_SharedRule)
        {
            if(theSLT.Limit_Per_Call_vod__c != LPC)   
               continue;
            
            ID theSLTProduct = theSLT.Product_vod__c; 
            system.debug('SLT Prod = ' + theSLTProduct + ' SLT AccRecType = ' + theSLT.Account_Types_vod__c); 
            
            /******************* exclude other Recordtypes  *******************/
            if(theAccRecordType != theSLT.Account_Types_vod__c)
               continue;
            system.debug('Rec type Matched');     
            /******************* exclude other Recordtypes  *******************/ 
              
            
            
            /** exclude other product's template ***/
            if(theSLTProduct != callProd)
               continue;
            system.debug('Prod Matched');     
            /** exclude other product's template ***/
            
            /* Exclude out of date template **/
            if(callDate > theSLT.End_Date_vod__c || callDate < theSLT.Start_Date_vod__c)
               continue;
               
            system.debug('timeframe  Matched. callDate ' + callDate + ' SD =' + theSLT.Start_Date_vod__c + ' ED = ' + theSLT.End_Date_vod__c);  
               
            /** handle here the UserGroup-based template group for multi-country ***/
            String theGroup = NULL;
            if(theSLT.Template_Group_vod__c != NULL)  
            { //is group is not NULL this is the good one. 
              //(hopefully  no  user  has visible to multiple  country-based  templates)
                  CurrentTemplate.add(theSLT);
                   //return theSLT;
            }
            else
            {
                CurrentTemplate.add(theSLT); 
                System.debug('CSABA Generic Template Identified: ' + theSLT);  
            }   
        }  
        // here add the system debug to find the number of sample limit templates returned
        System.Debug('the templates returned from FindExistingPLTemplate_Shared method size is ' + CurrentTemplate.size());
        return CurrentTemplate;
     }     
     
     /***************************************
     Use this later to find  to which group a
     Product belongs at  at the CallDate time
     AND which are the other products in this 
     group.
     ***************************************/
     private static void BuildProdGrup_Base() 
     {
        
        ProductGroup_base = [Select Product_vod__c, Product_vod__r.Name,            //sample product
                             Product_Catalog_vod__c, Product_Catalog_vod__r.Name,   //class product
                             Id,Name, 
                             End_Date_vod__c,Start_Date_vod__c   //the time frame when the product belongs to this class!  
                             From Product_Group_vod__c
                             order by Product_Catalog_vod__c
                             ];
                             
       system.Debug('CSABA:  Nr of GROUPO Base = ' + ProductGroup_base.size());                      
                                 
     }   
     
     /**********************************************************************************************
     Identify the class Product where the sample -able  Product belongs too, at the Call Date.
     Paramater:    CalDate,  Sampled ProductID
     return value: Class Product Set
     Operation:  Iterate through the ProductGroup_base  list and identify the Class where the 
     product passed as parameter belongs at  during callDate passed as second parameter  
     A product might belong  to multiple classes in the same time.
     **********************************************************************************************/
     private static Set<Product_vod__c> GetClassForProductAtCalltime(ID theProductID, Date calldate)
     {
        Product_vod__c ClassProd = NULL;
        
        Set<Product_vod__c> Classes = new set<Product_vod__c>(); //1 prod might belong to multiple Groups
        
        for(Product_Group_vod__c thePG :ProductGroup_base)
        {
            if(thePG.Product_vod__c != theProductID)
               continue;
               
            if(thePg.Start_Date_vod__c <= calldate && calldate <= thePg.End_Date_vod__c)
            {
                ClassProd = thePG.Product_Catalog_vod__r;
                Classes.add(ClassProd);
                continue;
            }
            else
            continue;    
        }
        
        System.debug('CSABA: ProductId = ' + theProductID + ' Belongs to nr of Classes = ' + classes.size());
        //return ClassProd;
        return classes;
     }
     
     
     /***********************************************************************************
     Identify all products belonging to the Class passes ad parameter.  NO LONGER NEEDED!
     ***********************************************************************************/
     private static List<ID> GetProductListFromClass(Product_vod__c theClass)
     {
        List<ID> ClassProducts = new List<ID>();
        
        for(Product_Group_vod__c thePG :ProductGroup_base)
        {
            if(thePG.Product_Catalog_vod__r != theclass)
               continue;
               
            ClassProducts.add(thePG.Product_vod__c);  
        }
        
        return ClassProducts;  

     }
     
     /*****************************************************
     ExtendedAffectedProduct  is a Set  containnig all
     product being sampled  +  the Group products where
     these products belongs.   
     Besides Building  the ExtendedAffectedProduct List
     Create "pseudo -Call Sample" records for the Extra
     Products.
     Clone the Current Call Sample and replace the Product
     Pseudo - Call Samples are only In-memory records.
     *****************************************************/
     private static void BuildExtendedAffectedProductList()  
     {
      String ProdNameList = '';
      ID currentProduct = NULL;
      
      for(Call2_Sample_vod__c theCS :CallSamples)
          {
            currentProduct = theCS.Product_vod__c;   
            
            if(ExtendedAffectedProducts.contains(currentProduct) == true)
               continue;   //do not add product twice
            
            ExtendedAffectedProducts.add(currentProduct);
            
            ProdNameList = ProdNameList + ',' + currentProduct; //just Test.  
            System.debug('Product Added to ExtendedList: ' + currentProduct);
            
            set<Product_vod__c> currentclass = GetClassForProductAtCalltime(currentProduct,theCs.Call_Date_vod__c);

                for(Product_vod__c classProd :currentclass) 
                    {
                    if(ExtendedAffectedProducts.contains(classProd.id) == true)
                       continue;    
                        
                    ExtendedAffectedProducts.add(classProd.id);
                    
                    System.debug('Class Added to ExtendedList: ' + classProd.id + '/' + classProd.Name);
                    
                    //create Pseudo - Call Sample record.
                    CreatePseudoCallSample(theCS,classProd);
                    
                    }         
            } 

          
     system.Debug('CSABA: ExtendedAffectedProduct size = ' + ExtendedAffectedProducts.size());       
     }
     
     /****************************************************************************************
     If the start date of the Limit is bigger then CallDate the Limit might need adjustment. *
     Might need!  To be sure we have to check later if the CallDate still have a valid template
     For ex:
     Initial status.  No Sample limit
     2 reps works offline  
     Rep1 Sample date 5 Jan
     Rep2 sample date 15 Jan.
     Rep2 sync first at Jan 20.  No existing Limit  create one jan 15 ----> Jan 15 next year.
     Rep 1 sync later at Jan 25   He found the previous Limit records
     This limit might need adjustment.  Here check the templates:
     If template identified check  Validity period
     if  Template Validity range from Jan1  to Jan1 next year  the Existing Limit need Update
     New Start/end date  Jan 5  ----> Jan 5  next year
     BUT if Template validity period  Jan 10 -------->  This mean that Rep1 call belongs to
     the previous sampling period  without having  dedicated template or Limit.  In this case
     we will  leave the existing Sample Limit  and the Rep 1 sampling is not limited.  
     
     conclusion We always need to use the Template not just when first Limit record is created  
     ****************************************************************************************/
     private static Boolean SLimit_NeedAdjustment(Sample_Limit_vod__c theSL, date thecalldate)
     {
        if(theSL == NULL)
            {
            system.Debug('CSABA: Mising Sample Limit.');
            return false;
            }
        else
            {
                System.debug('CSABA: CallDate = ' + thecalldate + ' SL_SD = ' + theSL.Start_Date_vod__c + ' SL_ED = ' + theSL.End_Date_vod__c);
                if(thecalldate < theSL.Start_Date_vod__c)
                {
                  system.debug('CSABA: Limit Needs Date adjustments.'); 
                  return true;
                }
                else 
                { 
                  system.debug('CSABA: Limit NO Needs Date adjustments.');
                  return false;
                }
            }
     }
     
     
     /****************************************************************************************************************
     
     ****************************************************************************************************************/
     private static Sample_Limit_vod__c CreateSampleLimit_START(Call2_Sample_vod__c theCS, Sample_Limit_vod__c theSLT)
     {
        if(theSLt.Split_Period_vod__c == NULL)
        {
            CreateSampleLimit(theCS,theSLT);  
        }
        else
        {
            if(theSLT.Limit_Per_Call_vod__c == true)
            {
            CreateSampleLimit_SplittedPerCall(theCS,theSLT);
            return NULL;   
            }
        
            if(theSLt.Split_Period_vod__c == 'Year')
                CreateSampleLimits_Splitted_Year(theCS,theSLT);  
            else
                CreateSampleLimits_Splitted_12month(theCS,theSLT);          
        }
        
        return null;
     }
     

     /***********************************************************************************************************
     If the SPLITTED Limit  is Per Call create  1 Limit for 24 month then a forever limit wiht 0 Limit Quantity
     ***********************************************************************************************************/
     private static void CreateSampleLimit_SplittedPerCall(Call2_Sample_vod__c theCS, Sample_Limit_vod__c theSLT)
     {
        Date SD = theCs.Call_Date_vod__c;
        Date ED = SD.addMonths(24);
        ED = ED.addDays(-1); 
        Sample_Limit_vod__c NewSL = CreateSampleLimitFromDate(theCS,theSLT,SD,ED,0); 
        
        //Overruled. Only 1 limit 
        //SD = Ed.addDays(1);
        //ED = Date.newInstance(2099, 12, 31);
        //NewSL = CreateSampleLimitFromDate(theCS,theSLT,SD,ED,1);    
        
     }

     /*********************************************************************************************************
     Create 4 sample Limits in a row. The last  las forever with quantity 0
     *********************************************************************************************************/
     private static void CreateSampleLimits_Splitted_Year(Call2_Sample_vod__c theCS, Sample_Limit_vod__c theSLT)
     {
        Sample_Limit_vod__c newSL = null;
        
        system.Debug('Create YEAR SPLITTED LIMIT 1');
        Date SD = theCS.Call_Date_vod__c;
        
        Integer  theYear = Sd.year();
        Date ED = date.newinstance(theYear, 12, 31);
        system.Debug('Create YEAR SPLITTED LIMIT 1: SD = ' + Sd + ' ED = ' + ED);
        newSL = CreateSampleLimitFromDate(theCs,theSLt,SD,ED,1);
        
        
        system.Debug('Create YEAR SPLITTED LIMIT 2');
        theYear = theYear + 1;
        SD = ED.addDays(1);
        //SD = date.newinstance(theYear, 01, 01);
        ED = date.newinstance(theYear, 12, 31);
        system.Debug('Create YEAR SPLITTED LIMIT 2: SD = ' + Sd + ' ED = ' + ED);
        newSL = CreateSampleLimitFromDate(theCs,theSLt,SD,ED,2);

        system.Debug('Create YEAR SPLITTED LIMIT 3');
        theYear = theYear + 1;
        SD = ED.addDays(1);
        if(theCS.Call_Date_vod__c.month() == 1 && theCS.Call_Date_vod__c.day() == 1)
            {
            ED = date.newinstance(2099, 12, 31);
            }
        else
        {
            Integer theMonth = theCS.Call_Date_vod__c.month();
            Integer theDay = theCS.Call_Date_vod__c.day();
            ED = date.newinstance(theYear, theMonth, theDay-1);
            system.Debug('Create YEAR SPLITTED LIMIT 3: SD = ' + Sd + ' ED = ' + ED);           
        }
        
            
        newSL =CreateSampleLimitFromDate(theCs,theSLT,SD,ED,3);

        system.Debug('Create YEAR SPLITTED LIMIT 4');
        //continue only if the Call date is not  january 1
        if(theCS.Call_Date_vod__c.month() > 1 || theCS.Call_Date_vod__c.day() > 1)
        {
        SD = ED.addDays(1);
        ED = date.newinstance(2099, 12, 31);
        system.Debug('Create YEAR SPLITTED LIMIT 4: SD = ' + Sd + ' ED = ' + ED);       
        newSL =CreateSampleLimitFromDate(theCs,theSLT,SD,ED,4);
        }
        
     }
    

     /************************************************************************************************************
     create 3 Sample limits in a row. the last last forever with quantity 0.
     ************************************************************************************************************/
     private static void CreateSampleLimits_Splitted_12month(Call2_Sample_vod__c theCS, Sample_Limit_vod__c theSLT)
     {
        system.Debug('Create 12month SPLITTED LIMIT');
        Date SD = theCS.Call_Date_vod__c;
        
        Date ED = SD.addmonths(12);
        ED = ED.addDays(-1);
        CreateSampleLimitFromDate(theCs,theSLt,SD,ED,1);
        
        SD = ED.adddays(1);
        ED = SD.addmonths(12);
        ED = ED.addDays(-1);
        CreateSampleLimitFromDate(theCs,theSLt,SD,ED,2);
        
    
        SD = ED.adddays(1);
        ED = date.newinstance(2099, 12, 31);
        CreateSampleLimitFromDate(theCs,theSLT,SD,ED,3);
      
     }
 
     /**********************************************************************************************************************************************************
     param1 theCs  the current Call Sample record
     param2 the SLT  the current Call's Temlate
     param3/4  Start/end date 
     ***********************************************************************************************************************************************************/
     private static Sample_Limit_vod__c CreateSampleLimitFromDate(Call2_Sample_vod__c theCS, Sample_Limit_vod__c theSLT, Date theSD, Date theED, Integer counter)
     {
        if(theSLT == NULL)  
            {
            System.Debug('CSABA: No Sample Limit Template. No Limit to create');
            return NULL;    
            }
            
            System.Debug('CSABA CurrentCall obj = ' + theCS);
            
            if(theCS.Limit_Applied_vod__c == true) //To Be Clarified with Bastien/Ed 
              return NULL;
               
           //if(theCS.Apply_Limit_vod__c == false)  //To Be Clarified with Bastien/Ed In iRep does not work!!!
           //   return NULL; 
              
            system.Debug('CSABA: create limit based on Template! ');       
            
            Sample_Limit_vod__c newSL =  new Sample_Limit_vod__c();
                       
            ID accID = getAccountIdforCall(theCS);
            newSL.Account_vod__c = accID;
            newSL.Product_vod__c = theCS.Product_vod__c;
            
            if(theED.year() == 2099) {
              if (theSLT.Limit_Quantity_vod__c != null) {
                  newSL.Limit_Quantity_vod__c = 0;  
              } else {
                  newSL.Limit_Amount_vod__c = 0.0;
              }
            }   
            else {                
                newSL.Limit_Quantity_vod__c = theSLT.Limit_Quantity_vod__c;             
                newSL.Limit_Amount_vod__c = theSLT.Limit_Amount_vod__c;      
                            
            }
            
            // here check if its multicurrency
            SOBject sltInterface = (SObject) theSLT;
            String currCodeSLT = null;
            try {
                currCodeSLT = (String)sltInterface.get('CurrencyIsoCode');
            } catch ( System.SObjectException e) {
            } 
        
            if (currCodeSLT  != null) {               
                newSL.put('CurrencyIsoCode', currCodeSLT);                
            }

            System.debug(' from the function CreateSampleLimitFromDate ');
            System.debug('the value of slt currency code for debugging reasons  ' + currCodeSLT);
            
            newSL.Limit_Per_Call_vod__c = theSLT.Limit_Per_Call_vod__c;
            
            newSL.Enforce_Limit_vod__c = theSLT.Enforce_Limit_vod__c;
            
            
            newSL.Start_Date_vod__c = theSD;
            newSL.End_Date_vod__c = theED;          
    
            
            String AccName = MapAccRecTypes.get(accID).Name;
            String prodName = theSLT.Product_vod__r.Name ;            
            newSL.Name = prodName.left(28) + '_' + AccName.left(28) + '_' + newSL.Start_Date_vod__c;
            if(theSLT.Limit_Per_Call_vod__c == true) {
               System.debug('inside the CreateSampleLimitFromDate function passed the limit per call'); 
               newSL.Name = newSL.Name + '_PC'; 
               System.debug('the final name value is ' + newSL.Name);
            }
            System.debug('no limit per call the final name value is inside CreateSampleLimitFromDate' + newSL.Name);
            
            //build  the Map Key
            String MapKey = String.valueOf(getAccountIdforCall(theCS)) + 
                            String.ValueOf(theCS.Product_vod__c) + 
                            string.ValueOf(theSLT.Limit_Per_Call_vod__c) + 
                            string.ValueOf(theSLT.id) + '_' +
                            string.ValueOf(counter);
            System.Debug('CSABA: New SL KEY =' + MapKey);
            
            CheckUniquenessNewSL(newSL,MapKey);
            
            /***************** mark the template as being used ****************/ 
            theSLT.Template_In_Use_vod__c = true;    
            Sample_Limit_vod__c thetemplatele = MapTemplateInUse.get(theSLT.id);
            if(thetemplatele == NULL)
              MapTemplateInUse.put(theSLT.id,theSLT);
            /***************** mark the template as being used ****************/  
            System.debug(' the value of sample limit for debugging pruposes from create samplelimit date ' + newSL);
            return newSL;       
     }   

     /**********************************************************************************************************
     Create a Limit for the account/product  based on the Sample Limit Template passed as second parameter 
     **********************************************************************************************************/
     private static Sample_Limit_vod__c CreateSampleLimit(Call2_Sample_vod__c theCS, Sample_Limit_vod__c theSLT)
     {
        if(theSLT == NULL)  
        {
        System.Debug('CSABA: No Sample Limit Template. No Limit to create');
        return NULL;    
        }
        
        System.Debug('CSABA CurrentCall obj = ' + theCS);
        
        if(theCS.Limit_Applied_vod__c == true) //To Be Clarified with Bastien/Ed 
          return NULL;
           
       //if(theCS.Apply_Limit_vod__c == false)  //To Be Clarified with Bastien/Ed In iRep does not work!!!
       //   return NULL; 
          
        system.Debug('CSABA: create limit based on Template! ');       
        
        Sample_Limit_vod__c newSL =  new Sample_Limit_vod__c();
                   
        ID accID = getAccountIdforCall(theCS);
        newSL.Account_vod__c = accID;
        newSL.Product_vod__c = theCS.Product_vod__c;                
        
        // no check to see if its quantity based or value based is not needed since whatever the value is null, zero, or greater than zero will be copied
        newSL.Limit_Quantity_vod__c = theSLT.Limit_Quantity_vod__c;
        newSL.Limit_Amount_vod__c = theSLT.Limit_Amount_vod__c;
        newSL.Limit_Per_Call_vod__c = theSLT.Limit_Per_Call_vod__c;        
        
        // here check if its multicurrency
        SOBject sltInterface = (SObject) theSLT;
        String currCodeSLT = null;
        try {
            currCodeSLT = (String)sltInterface.get('CurrencyIsoCode');
        } catch ( System.SObjectException e) {
        } 
        
        System.debug(' from the function create sample limit ');
        System.debug('the value of slt currency code for debugging reasons  ' + currCodeSLT); 
        
        if (currCodeSLT  != null) {               
            newSL.put('CurrencyIsoCode', currCodeSLT);                
        }
        
        newSL.Enforce_Limit_vod__c = theSLT.Enforce_Limit_vod__c;
        
        Decimal rollingPeriod = theSLT.Rolling_Period_vod__c;
        
        if(rollingPeriod != NULL)
        {
            newSL.Start_Date_vod__c = theCS.Call_Date_vod__c;
            Date theCalldate = theCS.Call_Date_vod__c;  
            Date endDate = thecalldate.addMonths(Integer.valueof(rollingperiod));
          
            endDate = endDate.addDays(-1);
               
            //if End date  < today DO NOT CREATE!!!    2013.05.11. TO BE CHECKED!! I think Only  in case of Adjustment we are denying.  For create we can create fixed  limits in the past
            //if(endDate < system.today())
            //   return NULL;
               
            newSL.End_Date_vod__c = endDate;            
        }
        else
        {   //in case of fixed Period just use the template's Start/end Dates
            newSL.Start_Date_vod__c = theSLT.Start_Date_vod__c;
            newSL.End_Date_vod__c = theSLT.End_Date_vod__c;  
        }
        
        String AccName = MapAccRecTypes.get(accID).Name;
        String prodName = theSLT.Product_vod__r.Name; 
        newSL.Name = prodName.left(28) + '_' + AccName.left(28) + '_' + newSL.Start_Date_vod__c;
        if(theSLT.Limit_Per_Call_vod__c == true) {
           System.debug('entered the limit per call option in function');
           newSL.Name = newSL.Name + '_PC'; 
           System.debug('Final SL name is  ' + newSL.Name);
         }
         System.debug('no limit per call the final name value is form inside CreateSampleLimit' + newSL.Name);
        
        
        //Sample_Limit_Type_vod__c is calculated automatically based on the veeva trigger
        
        //build  the Map Key
        String MapKey = String.valueOf(getAccountIdforCall(theCS)) + 
                        String.ValueOf(theCS.Product_vod__c) + 
                        string.ValueOf(theSLT.Limit_Per_Call_vod__c) + 
                        string.ValueOf(theSLT.id);
        System.Debug('CSABA: New SL KEY =' + MapKey);
        
        //add the update to the key
        
        CheckUniquenessNewSL(newSL,MapKey);
        
        /***************** mark the template as being used ****************/ 
        theSLT.Template_In_Use_vod__c = true;    
        Sample_Limit_vod__c thetemplatele = MapTemplateInUse.get(theSLT.id);
        if(thetemplatele == NULL)
          MapTemplateInUse.put(theSLT.id,theSLT);
        /***************** mark the template as being used ****************/  
        System.debug(' the value of sample limit for debugging pruposes from create samplelimit ' + newSL);
        return newSL;                                       
     }
     
     /*****************************************************************************************
     Relevant for data load.  What happen if a user records several calls against the same doc.
     giving him /her the same product sample at different time?  In this case I do not have to
     perform several updates, just one with the earliest startdate. So I have  to detect if in 
     memory there is already an Adjustable limit for Account/Prod  and see if it the good one! 
     2013.04.12.  No more relevant. In iRep  batch size = 1 ALWAYS !!
     *****************************************************************************************/
     private static void CheckUniquenessExistingSL(Sample_Limit_vod__c theNewSL, String MapKey)
     {
        Sample_Limit_vod__c ExistingSL = MapSL_toUpdate.get(MapKey);
        if(ExistingSL == NULL)
          {
            MapSL_toUpdate.put(MapKey,theNewSL);
          }
          else
          {
            //this mean there is already a SL  with the same Account/Prod/PerCall with different Period
            //compare start/endDate is theNewSL has earlier startDate put this in the Map else keep.
            if(theNewSL.Start_Date_vod__c < ExistingSL.Start_Date_vod__c)
               MapSL_toUpdate.put(MapKey,theNewSL);
          }
     }
     
     /************************************************************************************
     This function is the same as above. Unify later  with one Extra parameter  **********
     iRep relevance only.  what happen if there is no sample Limit  but user visit several 
     times the same doctor  and give him/her the same product.  In this case I do not have
     to create multiple  new Limits,  but create only  one with the earliest  start_Date !    
     ************************************************************************************/
     private static void CheckUniquenessNewSL(Sample_Limit_vod__c theNewSL, String MapKey)
     {
        if(theNewSL == NULL)
           return;
           
        System.debug('Unique KEY = ' + MapKey + '  Map size = ' + MapSL_toCreate.size());
        
        Sample_Limit_vod__c OlderNewSL = MapSL_toCreate.get(MapKey);
        if(OlderNewSL == NULL)
          {
            MapSL_toCreate.put(MapKey,theNewSL);
          }
          else
          {
            system.debug('NewED =  ' + theNewSL.Start_Date_vod__c + ' OldSD = ' + OlderNewSL.Start_Date_vod__c);
            if(theNewSL.Start_Date_vod__c < OlderNewSL.Start_Date_vod__c)
              {
              system.Debug('Replace  SL');        
               MapSL_toCreate.put(MapKey,theNewSL);
              }
          } 
          
     System.debug('Unique KEY = ' + MapKey + '  Map size = ' + MapSL_toCreate.size());      
     }   
     

     
     /*****************************************************************************************************************************
     This function relay on the assumption that we can not Adjust an existing sample Limit outside the boundary of its parent 
     template. This could cause problems. 
     Scenario:
     Rep1 work Offline record Call dec 25
     Rep2 work Offline record call jan 05
     2 rolling Templates available  T1:jan-dec  and T2:jan-dec  next year
     Rep 2 sinc  jan 10  Limit created based on template T2  L1: jan05-jan05
     Rep 1 sync  jan 15  he identify closest future  Limit L1 jan05-jan05  
     This limit might be subject to adjustment 
     code identify Template valid for dec25 call  This is T1
     code check Valid template for L1.  this is T2
     december call has Valid template: T1
     T1 != T2  so I do not allow adjustment of L1. 
     This would broke the rule that Limits are originated from Templates
     *****************************************************************************************************************************/
     private static boolean IsExisitingLimitBelongsToCurrentTemplate(Sample_Limit_vod__c theExisitingSL,Sample_Limit_vod__c TemplateForCall, Call2_Sample_vod__c currentcall)
     {
          System.debug('CSABA. check Limit/Template matching');  
          Date EL_SD = theExisitingSL.Start_Date_vod__c;
          Date EL_ED = theExisitingSL.end_Date_vod__c;
     
          Date STL_SD = TemplateForCall.Start_Date_vod__c;
          Date STL_ED = TemplateForCall.end_Date_vod__c;
     
         system.debug('LIMIT: SD = ' + EL_SD + ' ED = ' + EL_ED + 
                  '. TEMPLATE SD = ' + STL_SD + ' ED = ' + STL_ED);   
     
         if (EL_SD >= STL_SD && EL_SD <= STL_ED)  //the end date can exceed the Template validity date
            return true;
         
         return false;
     }
     

     
     
     /****************************************
     Get the current logged User.
     2013.05.23. No longer needed!   
     private static void setUser()
     {
        userId = Userinfo.getUserId();   
        System.debug('UserInfo = ' + userId);
     }
     ****************************************/ 
     
     
     /****************************************************
     User Group  is used t handle Multi-country single org 
     where the products are not country dependent.
     This mean we can have  similar  Sample Limit templates
     for the same accounttype/Product/start-end date but
     belonging to different countries.  The difference is
     made by the Template group field o the object.
     each contey has a GROUP
     The value if thei filed must match an existing Public
     Group where all Users  from a country are added.
     The code beow identify the GroupNames where the logged
     user belongs at. Concept migt need to be re-evaluated!   
     2013.05.23. No longer needed!
     private static void BuildUserGroupID()
     {
        
        GroupMember[] GMs =[SELECT UserOrGroupId,Group.Name FROM GroupMember where UserOrGroupId = :userId];
         
        System.Debug('build User group list for UserId = ' + userId + ' size = ' + GMs.size());                   
        for(GroupMember GM :GMs)
        {
            UGroupNames.add(GM.Group.Name);
        } 
        
        System.debug('USER GROUP LIST ' + UGroupNames);                  
     }
     ****************************************************/  
     
     /*******************************************************************************************************
     Clone the CallSample record passed as parameter and replace the Product with the one passed as parameter
     Mayabee we can just clone  the reference. The eproduct passed as parameter is in fact a GROUP PRODUCT.      
     *******************************************************************************************************/
     private static void CreatePseudoCallSample(Call2_Sample_vod__c referenceCS, Product_vod__c ExtraProduct)
     {
        system.Debug('CSABA: ClassProduct' + ExtraProduct + ' Reference CallSample: ' + referenceCS);
        Call2_Sample_vod__c NewCs = new Call2_Sample_vod__c();
        //QUESTION:  would clone()  method be a better  way??
        

        NewCs.Account_vod__c = getAccountIdforCall(referenceCS);
        NewCS.Apply_Limit_vod__c = referenceCS.Apply_Limit_vod__c;
        NewCs.Call_Date_vod__c = referenceCS.Call_Date_vod__c;
        NewCs.Limit_Applied_vod__c = referenceCS.Limit_Applied_vod__c;
        NewCs.Quantity_vod__c = referenceCS.Quantity_vod__c;

        NewCs.Product_vod__c = ExtraProduct.id;  //the Only different field
            
        system.debug('CSABA: Pseudo - CallSample: ' + NewCS); 
        
        PseudoCallSamples.add(NewCS);  
     }
     
     
     /************************************************************************
     
     ************************************************************************/
     private static void UpsertInsertSampleLimit(List<Sample_Limit_vod__c> SL)
     {
       System.Debug('Wre are going to upsert ' + SL.size() + ' Sample Limits');        
       Database.Upsertresult[] results = Database.upsert(SL);   
       if(results != null)
       {
        for(Database.Upsertresult result : results)
            {
                if(!result.isSuccess())
                {
                Database.Error[] errs = result.getErrors();
                for(Database.Error err: errs)
                    {
                     //?????
                    }   
                }
            }       
       }
       else
       {
        System.Debug('CSABA: Nothing ...');
       }            
     }
     
     /***************************************************************
     In iRep the account_vod__c field on call Sample is NULL!!!!!!!!! 
     WHY?                      Use Entity_Reference_Id_vod__c instead  
     ***************************************************************/
     private Static ID getAccountIDforCall(Call2_Sample_vod__c theCS)
     {
        if(theCS.account_vod__c == NULL)
          return theCS.Entity_Reference_Id_vod__c;
        else
          return theCs.account_vod__c;  
     }
     
    /*********************************************************************************
    Iterate through the Call Sample list passed as parameter and Create/Update Sample 
    limit records.
    *********************************************************************************/
    private static  void StartOperation(List<Call2_Sample_vod__c> theCSs, boolean LpC)
    {
         //List<Sample_Limit_vod__c> CurrentLimit_TEMPLATE = new List<Sample_Limit_vod__c> ();
         List<Sample_Limit_vod__c> validcurrentTEMPLATES = new List<Sample_Limit_vod__c> ();
         List<Sample_Limit_vod__c> validCurrentSampleLimits = new List<Sample_Limit_vod__c> ();
         List<Sample_Limit_vod__c> createLimitForTemplates = new List<Sample_Limit_vod__c> ();
         
         
         // now go through the call sample get all sample limits
         for(Call2_Sample_vod__c ActualCS : theCSs) {
            validCurrentSampleLimits.addAll(FindExistingPL(ActualCS,LpC));   //identify existing current/Closest future limit.            
         }
         system.debug('the size of the valid sample limits are ' + validCurrentSampleLimits.size());
         
         // now go through the list and get all valid sample limit templates
         for(Call2_Sample_vod__c ActualCS : theCSs) {
             validcurrentTEMPLATES.addAll(FindExistingPLTemplate_shared(ActualCS,LpC));
         }
         system.debug(' the size of the valid sample limits templates are ' + validcurrentTEMPLATES.size() );
         
         // now for each SL go through SLT's to see if SLT is valid for creating sample limit
         for(Sample_Limit_vod__c validTemplate: validcurrentTEMPLATES) {
             // get the type of sample limit template             
             Boolean SLTQty = false , SLTAmt = false, SLTBoth = false;
             if (validTemplate.Limit_Quantity_vod__c != null) {
                 SLTQty= true;
                 system.debug('type of existing SLT is qty only');
             } else if (validTemplate.Limit_Amount_vod__c != null) {
                 SLTAmt = true;  
                 system.debug('type of existing SLT is amount only');  
             }
             Boolean sameType = false;
             for(Sample_Limit_vod__c validLimit: validCurrentSampleLimits) {  
                 // if sample limit and sample limit template are for the different product continue
                 if (validLimit.Product_vod__c != validTemplate.Product_vod__c) {
                     continue;
                 } 
                 // check for sample limit types
                 Boolean SLQty = false, SLAmt = false, SLBoth = false;     
                
                 if (validLimit.Limit_Quantity_vod__c != null && validLimit.Limit_Amount_vod__c != null) {
                     SLBoth = true;                 
                     system.debug('type of existing SL is both');
                 } else if (validLimit.Limit_Quantity_vod__c != null) {
                     SLQty = true;                 
                     system.debug('type of existing SL is qty only');
                 } else if (validLimit.Limit_Amount_vod__c != null) {
                     SLAmt = true;                
                     system.debug('type of existing SL is amt only');    
                 }
                 // now for this template check if already sample limit exists                 
                 if (SLBoth) {
                     // if SL is for both then ignore qty or value SLT
                     if (SLTQty || SLTAmt) {
                         sameType = true;
                     }
                 } else if (SLQty && SLTQty) { 
                     sameType = true;
                 } else if (SLAmt && SLTAmt) {
                     sameType = true;
                 }                                 
             } 
             // now for the template we did not find any valid sample limit then add template to the list for sample limit creation
             // this conition also includes no sample limits of any type exists
             if (!sameType) {
                 createLimitForTemplates.add(validTemplate);
             } 
         }
         system.debug(' sample limit from template need to be created for templates size   ' + createLimitForTemplates.size() ); 
         // now we have identified the sample limit templates that need to create sample limit
         // for all of the templates recived call the create sample limit method separately
         for(Call2_Sample_vod__c ActualCS : theCSs) {
             for(Sample_Limit_vod__c currentTemp: createLimitForTemplates) {
                 // if sample limit template is for a product different than the one in call sample continue
                 if (ActualCS.Product_vod__c != currentTemp.Product_vod__c) {
                     continue;
                 } 
                 System.debug('the sample limit created for call sample is  ' + ActualCS);
                 System.debug(' the template used for creation is ' + currentTemp);
                 Sample_Limit_vod__c NewSL = CreateSampleLimit_START(ActualCS,currentTemp); 
             }
         }         
                       
         // now the creation of sample limit is done now lets focus on the adjustment part and restore old way of adjusting per sample limit basis than the list
         Sample_Limit_vod__c CurrentLimit = NULL;
         Sample_Limit_vod__c CurrentLimit_TEMPLATE = NULL;
         for(Call2_Sample_vod__c ActualCS : theCSs) {
             // find the current limit for quantity
             /*********************************************************************************************************************************************
             *********** now prcess the sample limit adjustment for quantity
             **********************************************************************************************************************************************/
             CurrentLimit = FindExistingPLOriginal(ActualCS,LpC, true);
             // if the current limit is not equal to null check if adjustment is needed
             if (CurrentLimit != null) { // now adjust
                Boolean NeedAdjustment = SLimit_NeedAdjustment(CurrentLimit,ActualCS.Call_Date_vod__c);
                if(NeedAdjustment == false) {
                    System.Debug('CSABA: Limit Exist and is OK.  No Action.');  
                }   
                else {
                    System.Debug('CSABA; Limit exists. Might Needs Adjustment. Find Template.');        
                    //2013.05.25. CurrentLimit_TEMPLATE = FindExistingPLTemplate(ActualCS,LpC);
                    CurrentLimit_TEMPLATE = FindExistingPLTemplate_SharedOriginal(ActualCS,LpC, true);
                
                    if(CurrentLimit_TEMPLATE == NULL)
                    {
                        System.debug('CSABA: No Template. The Current call does not have template. We have no info to adjust found closest future limit');
                    }
                    else
                    {
                        Boolean IsTermplateShared = IsExisitingLimitBelongsToCurrentTemplate(CurrentLimit,CurrentLimit_TEMPLATE, ActualCS);
                        if(IsTermplateShared == true)
                        {
                           AdjustSL_SE_date_START(CurrentLimit,CurrentLimit_TEMPLATE.Rolling_Period_vod__c,CurrentLimit_TEMPLATE,ActualCS);         
                        }
                        else
                        {
                            if(CurrentLimit_TEMPLATE.Rolling_Period_vod__c == NULL)
                            {
                                 System.Debug('CSABA: The current call does not belongs to the same template as the closest future. Is has a fixed Template. create Limit ');
                                 Sample_Limit_vod__c NewSL = CreateSampleLimit(actualCS,CurrentLimit_TEMPLATE); 
                            }
                            else
                                System.debug('CSABA: Call and Existing Limit does not share same Template. Adjustment denied.');
                        }
                    }
                }
             
             }
             
             
             /*****************************************************************************************
             ************Now do the same adjustment for value based limit and value based template
             ******************************************************************************************/
             CurrentLimit = FindExistingPLOriginal(ActualCS,LpC, false);
             // if the current limit is not equal to null check if adjustment is needed
             if (CurrentLimit != null) { // now adjust
                Boolean NeedAdjustment = SLimit_NeedAdjustment(CurrentLimit,ActualCS.Call_Date_vod__c);
                if(NeedAdjustment == false) {
                    System.Debug('CSABA: Limit Exist and is OK.  No Action.');  
                }   
                else {
                    System.Debug('CSABA; Limit exists. Might Needs Adjustment. Find Template.');        
                    //2013.05.25. CurrentLimit_TEMPLATE = FindExistingPLTemplate(ActualCS,LpC);
                    CurrentLimit_TEMPLATE = FindExistingPLTemplate_SharedOriginal(ActualCS,LpC, false);
                
                    if(CurrentLimit_TEMPLATE == NULL)
                    {
                        System.debug('CSABA: No Template. The Current call does not have template. We have no info to adjust found closest future limit');
                    }
                    else
                    {
                        Boolean IsTermplateShared = IsExisitingLimitBelongsToCurrentTemplate(CurrentLimit,CurrentLimit_TEMPLATE, ActualCS);
                        if(IsTermplateShared == true)
                        {
                           AdjustSL_SE_date_START(CurrentLimit,CurrentLimit_TEMPLATE.Rolling_Period_vod__c,CurrentLimit_TEMPLATE,ActualCS);         
                        }
                        else
                        {
                            if(CurrentLimit_TEMPLATE.Rolling_Period_vod__c == NULL)
                            {
                                 System.Debug('CSABA: The current call does not belongs to the same template as the closest future. Is has a fixed Template. create Limit ');
                                 Sample_Limit_vod__c NewSL = CreateSampleLimit(actualCS,CurrentLimit_TEMPLATE); 
                            }
                            else
                                System.debug('CSABA: Call and Existing Limit does not share same Template. Adjustment denied.');
                        }
                    }
                }
             
             }
         
         }
         
    }
    

    
 /***********************************************************************************************
 Sample Limit Template Related functions   called from a trigger.   Not part of the create/adjust
 process. The fucntion below will be called from anothetr sample Limit trigger VEEVA_SL_UniqueKey
 ***********************************************************************************************/ 
 public static Boolean IsOverlapping(Sample_Limit_vod__c theNewSLT,Sample_Limit_vod__c refSLT)
 {
    Boolean retval = true;
    system.debug('CSABA: Reference SLT: SD = ' + refSLT.Start_Date_vod__c + ' ED = ' + refSLT.End_Date_vod__c);
    system.debug('CSABA: NEW SLT: SD = ' + theNewSLT.Start_Date_vod__c + ' ED = ' + theNewSLT.End_Date_vod__c);

    //allow updating same sample limit
    if(theNewSLT.id == refSLT.id && theNewSLT.id != NULL && theNewSLT.id != NULL)
    {
    system.Debug('same Limits');    
    return false;
    }

    if(theNewSLT.Start_Date_vod__c >= refSLT.Start_Date_vod__c && 
       theNewSLt.Start_Date_vod__c <= refSLT.End_Date_vod__c)
       {
        system.debug('Overlap 1');
        return true;
       }
        
    if(theNewSLT.End_Date_vod__c >= refSLT.Start_Date_vod__c && 
       theNewSLT.End_Date_vod__c <= refSLt.End_Date_vod__c)  
       {
        system.debug('Overlap 2');      
        return true;
       }
        
    if(theNewSLt.Start_Date_vod__c <= refSLT.Start_Date_vod__c &&
       theNewSLT.End_Date_vod__c >= refSLt.End_Date_vod__c)
       {
        system.debug('Overlap 3');      
        return true;
       }   
       
       
    system.debug('No overlapping!');    
    return false;        
 }


/***************************************************************************************************************

***************************************************************************************************************/
public static String IsTemplateChanging(Sample_Limit_vod__c theNewSLT,Sample_Limit_vod__c refSLT, String FormatStr)
{  
    string retVal = '';     
    
    List<String> ErrMsgList = new List<String>();
        
    if(theNewSLT.Start_Date_vod__c != refSLt.Start_Date_vod__c)  
       ErrMsgList.add(Schema.sObjectType.Sample_Limit_vod__c.fields.Start_Date_vod__c.getLabel());
        
    if(theNewSLT.End_Date_vod__c != refSLt.End_Date_vod__c)    
       ErrMsgList.add(Schema.sObjectType.Sample_Limit_vod__c.fields.End_Date_vod__c.getLabel());


    if(theNewSLT.Account_Types_vod__c != refSLt.Account_Types_vod__c ) 
       ErrMsgList.add(Schema.sObjectType.Sample_Limit_vod__c.fields.Account_Types_vod__c.getLabel());       
       
        
    if(theNewSLT.Limit_Per_Call_vod__c != refSLt.Limit_Per_Call_vod__c)  
       ErrMsgList.add(Schema.sObjectType.Sample_Limit_vod__c.fields.Limit_Per_Call_vod__c.getLabel());


    if(theNewSLT.Limit_Quantity_vod__c != refSLt.Limit_Quantity_vod__c)  
       ErrMsgList.add(Schema.sObjectType.Sample_Limit_vod__c.fields.Limit_Quantity_vod__c.getLabel());
       
     // add a error message for the amount based field
     if(theNewSLT.Limit_Amount_vod__c != refSLt.Limit_Amount_vod__c)  
       ErrMsgList.add(Schema.sObjectType.Sample_Limit_vod__c.fields.Limit_Amount_vod__c.getLabel());

    if(theNewSLT.Product_vod__c != refSLt.Product_vod__c)  
       ErrMsgList.add(Schema.sObjectType.Sample_Limit_vod__c.fields.Product_vod__c.getLabel());
       
    if(theNewSLT.Rolling_Period_vod__c != refSLt.Rolling_Period_vod__c)  
       ErrMsgList.add(Schema.sObjectType.Sample_Limit_vod__c.fields.Rolling_Period_vod__c.getLabel());  
       
    if(theNewSLT.Template_Group_vod__c != refSLt.Template_Group_vod__c)  
       ErrMsgList.add(Schema.sObjectType.Sample_Limit_vod__c.fields.Template_Group_vod__c.getLabel());            
       
    if(theNewSLT.Disbursed_Quantity_vod__c != refSLt.Disbursed_Quantity_vod__c)       
       ErrMsgList.add(Schema.sObjectType.Sample_Limit_vod__c.fields.Disbursed_Quantity_vod__c.getLabel());

    if(theNewSLT.Enforce_Limit_vod__c != refSLt.Enforce_Limit_vod__c)  
       ErrMsgList.add(Schema.sObjectType.Sample_Limit_vod__c.fields.Enforce_Limit_vod__c.getLabel());
       
    if(theNewSLT.Split_Period_vod__c != refSLt.Split_Period_vod__c)      
       ErrMsgList.add(Schema.sObjectType.Sample_Limit_vod__c.fields.Split_Period_vod__c.getLabel());
           
       String[] longMsg = new string[]{''};       
       for(String s:ErrMsgList)
       {
        if(longMsg[0] <> '')
            longMsg[0] = longMsg[0] + ', ' + s;  
        else
            longMsg[0] = s;        
       }
       
       if(longMsg[0].length() > 0)
          retval =  string.format(FormatStr,longMsg); 
                 
       return retVal;
}

 /*******************************************************************************************
 ********  Maintian the functionality single return for adjustment sake**********************
 *******************************************************************************************/ 
 private static Sample_Limit_vod__c FindExistingPLOriginal(Call2_Sample_vod__c theCS, Boolean LpC, Boolean quantityCheck)
     {
        
        Id theAcc = getAccountIDforCall(theCS);
        ID theProd = theCS.Product_vod__c;
        Date theCallDate = theCS.Call_Date_vod__c; 
        
        System.Debug('Find Exisitng Limit for: AccountID=' + theAcc + ' ProductID = ' + theProd + ' CallDate = ' + theCallDate);
        
        List<Sample_Limit_vod__c> SL_Base = new List<Sample_Limit_vod__c>();
        if(LpC == true)
           SL_Base = SLs_base_ProductperCall;
        else
           SL_Base = SLs_base_Product;
        
        System.Debug('Base size = ' + SL_Base.size());
        for(Sample_Limit_vod__c theSL :SL_Base)
        {
            system.Debug('CSABA: SL Acc/Name=' + theSL.Account_vod__c + '/' + theSL.Account_vod__r.Name + 
                         ' SLProduct = ' + theSL.Product_vod__r.Name + ' CallDate = ' + theCS.Call_Date_vod__c + 
                         ' CallAcc = ' + theAcc);
            
            
            if(theSL.Account_vod__c != theAcc || theSL.Product_vod__c != theProd)
               continue;      //exclude non-affected Account and Product  limits.                       
               

            if(theSL.End_Date_vod__c < theCallDate)
               continue; 
               
            // if this is quantity check we can skip the value limits
            if (quantityCheck) {
                // if the limit quantity value is null then its not a quantity limit so continue
                if (theSL.Limit_Quantity_vod__c == null ) {
                    continue;
                }
            } else { // this is value limit check
                if (theSL.Limit_Amount_vod__c == null ) {
                    continue;
                }         
            
            }            
                           
            //if we are here we found a matching sample Limit
            String info = LpC == false ? 'Product':'Limit per Call ';
            System.Debug('CSABA: SL ' + info + ' identified: ' + theSL);  
            
            return theSL;                
        }
        
        return NULL;
     }
     
/*******************************************************************************************
 ********  Maintian the functionality single return for adjustment sake**********************
 *******************************************************************************************/ 
 private static Sample_Limit_vod__c FindExistingPLTemplate_SharedOriginal(Call2_Sample_vod__c theCS, Boolean LPC, Boolean quantityCheck) {
        Sample_Limit_vod__c CurrentTemplate = NULL;        
        
        ID callProd = theCS.Product_vod__c;
        ID accID = getaccountIdforCall(theCS);
        string theAccRecordType =  MapAccRecTypes.get(accID).Recordtype.Name;
        Date callDate = theCS.Call_Date_vod__c;
        
        System.Debug('CallProd = ' + callProd + ' Accrectype = ' + theAccRecordType + ' callDate = ' + callDate);
 
    
        system.debug('Template base size = ' + SLTs_base_SharedRule.size()); 
        for(Sample_Limit_vod__c theSLT :SLTs_base_SharedRule)
        {
            if(theSLT.Limit_Per_Call_vod__c != LPC)   
               continue;
            
            ID theSLTProduct = theSLT.Product_vod__c; 
            system.debug('SLT Prod = ' + theSLTProduct + ' SLT AccRecType = ' + theSLT.Account_Types_vod__c); 
            
            /******************* exclude other Recordtypes  *******************/
            if(theAccRecordType != theSLT.Account_Types_vod__c)
               continue;
            system.debug('Rec type Matched');     
            /******************* exclude other Recordtypes  *******************/         
            
            /** exclude other product's template ***/
            if(theSLTProduct != callProd)
               continue;
               
            // if this is quantity check we can skip the value limits
            if (quantityCheck) {
                // if the limit quantity value is null then its not a quantity limit so continue
                if (theSLT.Limit_Quantity_vod__c == null ) {
                    continue;
                }
            } else { // this is value limit check
                if (theSLT.Limit_Amount_vod__c == null ) {
                    continue;
                }         
            
            }  
            
            system.debug('Prod Matched');     
            /** exclude other product's template ***/
            
            /* Exclude out of date template **/
            if(callDate > theSLT.End_Date_vod__c || callDate < theSLT.Start_Date_vod__c)
               continue;
               
            system.debug('timeframe  Matched. callDate ' + callDate + ' SD =' + theSLT.Start_Date_vod__c + ' ED = ' + theSLT.End_Date_vod__c);  
               
            /** handle here the UserGroup-based template group for multi-country ***/
            String theGroup = NULL;
            if(theSLT.Template_Group_vod__c != NULL)  
            { //is group is not NULL this is the good one. 
              //(hopefully  no  user  has visible to multiple  country-based  templates)
                   return theSLT;
            }
            else
            {
                CurrentTemplate = theSLT; 
                System.debug('CSABA Generic Template Identified: ' + theSLT);  
            }   
        }  
        
        return CurrentTemplate;
}


   
 /*******************************************************************************************
 **********************  Sample Limit Template Related functions ****************************
 *******************************************************************************************/ 
public with sharing class CollectTemplate
{
    /********************************************************************
    2013.06.18.  ad second param
    ********************************************************************/
    public  void getValidTemplate(Date callDate)  
    {
        System.debug('Collecting  shared Templates  for current user ' + UserInfo.getUserId() + ' having startDate < ' + callDate + ' for Prod: ' +  ExtendedAffectedProducts);
        
    //2013.06.13.  we must build a non-selective query
    set<string> affectedaccTypes = new set<string>();
    string AcType = '';
    for(Account theAcc :MapAccRecTypes.values())
        {
        affectedaccTypes.add(theAcc.Recordtype.Name);   
        AcType = theAcc.Recordtype.Name;
        }

    //2013.06.13.  we must build a non-selective query
    
    //Added by CR for POC
    List<String> tempProdIds = new List<String>();
    for (Id i_x : ExtendedAffectedProducts) {         
         tempProdIds.add('__'+i_x+'____Template_vod__');          
    }
  
                                                
         String sampleLimitQuery;
         if (isMultiCurrency) {
             sampleLimitQuery = 'select User_vod__c, Account_Types_vod__c,Start_Date_vod__c,End_Date_vod__c,'+
                                'Product_vod__c,Product_vod__r.Name,Sample_Limit_Type_vod__c,Rolling_Period_vod__c,' +  
                                'Limit_Per_Call_vod__c,Limit_Quantity_vod__c, Limit_Amount_vod__c, CurrencyIsoCode,' + 
                                'Enforce_Limit_vod__c,Template_Group_vod__c,Template_Unique_Key_vod__c,Split_Period_vod__c ' +
                                'from Sample_limit_vod__c where End_Date_vod__c >= :callDate and Account_Types_vod__c in :affectedaccTypes ' +                                           
                                'and Product_vod__c in :ExtendedAffectedProducts and Group_Id_vod__c in :tempProdIds order by End_Date_vod__c asc';        
         } else {
             sampleLimitQuery = 'select User_vod__c, Account_Types_vod__c,Start_Date_vod__c,End_Date_vod__c,'+
                                'Product_vod__c,Product_vod__r.Name,Sample_Limit_Type_vod__c,Rolling_Period_vod__c,' +  
                                'Limit_Per_Call_vod__c,Limit_Quantity_vod__c, Limit_Amount_vod__c,' + 
                                'Enforce_Limit_vod__c,Template_Group_vod__c,Template_Unique_Key_vod__c,Split_Period_vod__c ' +
                                'from Sample_limit_vod__c where End_Date_vod__c >= :callDate and Account_Types_vod__c in :affectedaccTypes ' +                                           
                                'and Product_vod__c in :ExtendedAffectedProducts and Group_Id_vod__c in :tempProdIds order by End_Date_vod__c asc'; 
         }
         
         SLTs_base_SharedRule = Database.query(sampleLimitQuery); 
        system.Debug('Visible Template after chaning to query to support multicurrency = ' + SLTs_base_SharedRule.size());                                   
        system.Debug('Visible Template nr = ' + SLTs_base_SharedRule.size());                                   
                                          
    }
    
}
     
}