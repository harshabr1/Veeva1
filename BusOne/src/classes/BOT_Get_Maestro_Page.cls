public class BOT_Get_Maestro_Page 
{
    public String userName {get;set;}
    public String password {get;set;}
    public List <String> pwd {get;set;}
    public pageReference getPage()
    {           
        pageReference pg = new pageReference('https://www.salesforce.com/login.jsp?pw='+password+'&un='+userName);
        pg.setRedirect(true);
        return pg;
    }
}