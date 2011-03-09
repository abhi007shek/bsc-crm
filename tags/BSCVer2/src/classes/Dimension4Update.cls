public with sharing class Dimension4Update {

	public class DimensionInfo
	{
		public String Name;
		public String Id;	
	}
	   
  
   public static void createDimension (id bookingId)
   {
   	
    string currencyIso = null;
	try
	{
	   // Currency ISO
	   currencyIso =
	                [Select s.currencyIsoCode From Special_Event__c s Where s.id = :bookingId][0].currencyIsoCode;
	}
	catch (Exception e)
	{
	   // Cater for this later
	}
	List<Map<String, DimensionInfo>> dimensions = new List<Map<String, DimensionInfo>>();
	dimensions.add(new Map<String, DimensionInfo>());	
   	List<c2g.CODAAPIDimension_3_0.Dimension> dimension4 = new List<c2g.CODAAPIDimension_3_0.Dimension>();
   	Integer dimensionIdx = 4;
   	for(Map<String, DimensionInfo> dimensionNames : dimensions)
	{ 
		for(DimensionInfo dimensionInfo : dimensionNames.values())
		{
			String dimensionName = dimensionInfo.Name;
			String dimensionId = dimensionInfo.Id;
		    // Create a Dimension 4 record
		    c2g.CODAAPIDimension_3_0.Dimension dimension = new c2g.CODAAPIDimension_3_0.Dimension();
			dimension.Name = dimensionName;
			dimension.CurrencyIsoCode = currencyIso; 
			dimension.ReportingCode = dimensionId; 
			dimension.ExternalId = dimensionId; 
			dimension4.add(dimension);
		}
	}
    List<String> companies = c2g.CODAAPICompany_2_0.GetCurrentCompanies(null);
    List<c2g.CODAAPICommon.Reference> dimension4Refs = new List<c2g.CODAAPICommon.Reference>();
    dimension4Refs = c2g.CODAAPIDimension_3_0.UpsertDimensions4(null, dimension4);
   }
}