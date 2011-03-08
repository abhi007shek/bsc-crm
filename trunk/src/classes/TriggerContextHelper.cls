/*
	Created by Ben Mansfield 30 July 2010
	Modified by
	
	Description:
		Helper class for triggers to stop recursive triggers from trying to run something the
		record isn't ready for. Used for account hierarchy and account owner assignment.
		
	Changes:
		
		
*/
public with sharing class TriggerContextHelper {

	private static Boolean alreadyRunning = false;
	public Boolean runningFirstTime = false;
	public static String triggerStage = null;
	
	public TriggerContextHelper()
	{
		if (alreadyRunning == false)
		{
			alreadyRunning = true;
			runningFirstTime = true;
		}
	}
	
	public static void resetRun()
	{
		alreadyRunning = false;
		triggerStage = null;
	}

}